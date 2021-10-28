//Lazily hijacks UTConsole to provide mod-independent FOV scaling for both PlayerPawn and Weapon
class foxUTConsole extends UTConsole;

var bool bDoInit;

var float CachedSizeX;
var float CachedSizeY;
var float CachedClipX;
var float CachedClipY;
var float CachedDefaultFOV;
var float CachedDesiredFOV;

struct WeaponInfo
{
	var class<Weapon> WeaponClass;
	var vector DefaultPlayerViewOffset;
	var float DefaultMuzzleScale;
	var float DefaultFlashO;
};
var WeaponInfo CachedWeaponInfo;
var vector CachedPlayerViewOffset;

var float LastCorrectedFOVScale;

var globalconfig float Desired43FOV;
var globalconfig bool bCorrectZoomFOV;
var globalconfig bool bCorrectMouseSensitivity;

const DEGTORAD = 0.01745329251994329576923690768489; //Pi / 180
const RADTODEG = 57.295779513082320876798154814105; //180 / Pi

//fox: Set "desired" 4:3 FOV via console command (and menu if foxUT2K4Tab_PlayerSettings GUI override is active)
exec function SetFOV(float F)
{
	Desired43FOV = F;
	SaveConfig();

	//This will force a new weapon position / FOV calculation
	CachedSizeX = default.CachedSizeX;
}

//fox: Hijack this to force FOV per current aspect ratio - done every frame as a lazy catch-all since we're only hooking clientside PlayerInput
event PostRender(canvas Canvas)
{
	local PlayerPawn P;

	Super.PostRender(Canvas);

	//Do initialization stuff here, since we don't have init events
	if (bDoInit) {
		bDoInit = false;

		//Write settings to ini if first run
		SaveConfig();
		return;
	}

	//Detect screen aspect ratio changes and queue FOV / WeaponFOV updates
	if (Canvas.SizeX != CachedSizeX) {
		CachedSizeX = Canvas.SizeX;
		CachedSizeY = Canvas.SizeY;
		CachedClipX = Canvas.ClipX;
		CachedClipY = Canvas.ClipY;
		CachedDefaultFOV = default.CachedDefaultFOV;
		CachedDesiredFOV = default.CachedDesiredFOV;
		UpdateCachedWeaponInfo(None);
		CorrectMouseSensitivity();
		return;
	}

	//Durr
	P = Viewport.Actor;
	if (P == None)
		return;

	//Attempt to set an accurate FOV for our aspect ratio
	if (P.DefaultFOV != CachedDefaultFOV) {
		CachedDefaultFOV = GetHorPlusFOV(Desired43FOV);
		P.DefaultFOV = CachedDefaultFOV;
		P.DesiredFOV = CachedDefaultFOV;
		return;
	}

	//Attempt to do the same when we're zoomed in or out
	if (bCorrectZoomFOV
	&& P.DesiredFOV != P.DefaultFOV
	&& P.DesiredFOV != CachedDesiredFOV) {
		CachedDesiredFOV = GetHorPlusFOV(P.DesiredFOV);
		P.DesiredFOV = CachedDesiredFOV;
		return;
	}

	//Oh no! Work around weapon respawn bug where position isn't set correctly on respawn
	//(Note: This isn't actually necessary for UT99 but is still nice for consistency)
	if (P.Weapon == None) {
		UpdateCachedWeaponInfo(None);
		return;
	}

	//Set weapon FOV as well - only once per weapon
	//Repeat if needed for network clients, due to variable network latency (n/a to UT2k4)
	if (P.Weapon.Class != CachedWeaponInfo.WeaponClass
	|| P.Weapon.PlayerViewOffset != CachedPlayerViewOffset)
		ApplyWeaponFOV(P.Weapon);
}
function ApplyWeaponFOV(Weapon Weap)
{
	//First reset our "default default" values before doing anything else
	UpdateCachedWeaponInfo(Weap);

	//Fix bad FOV calculation in Inventory.CalcDrawOffset()
	//Note: FOVAngle sometimes too high when respawning, so just use CachedDefaultFOV
	Weap.default.PlayerViewOffset *= CachedDefaultFOV / 90f;
	ApplyWeaponViewOffset(Weap);

	//Also fix muzzle flash position
	Weap.default.MuzzleScale *= (CachedClipY * 4) / (CachedClipX * 3);
	Weap.default.FlashO *= (CachedClipY * 4) / (CachedClipX * 3);
	Weap.FlashO = Weap.default.FlashO; //Needed for weapons that don't recalc it (every weapon except Enforcer or Minigun)
}
function UpdateCachedWeaponInfo(Weapon Weap)
{
	if (CachedWeaponInfo.WeaponClass != None) {
		//Viewport.Actor.ClientMessage("UpdateCachedWeaponInfo from " $ CachedWeaponInfo.WeaponClass @ CachedWeaponInfo.WeaponClass.default.PlayerViewOffset);
		CachedWeaponInfo.WeaponClass.default.PlayerViewOffset = CachedWeaponInfo.DefaultPlayerViewOffset;
		CachedWeaponInfo.WeaponClass.default.MuzzleScale = CachedWeaponInfo.DefaultMuzzleScale;
		CachedWeaponInfo.WeaponClass.default.FlashO = CachedWeaponInfo.DefaultFlashO;
	}
	if (Weap == None)
		CachedWeaponInfo.WeaponClass = None;
	else {
		//Viewport.Actor.ClientMessage("UpdateCachedWeaponInfo to " $ Weap.Class @ Weap.default.PlayerViewOffset);
		CachedWeaponInfo.WeaponClass = Weap.Class;
		CachedWeaponInfo.DefaultPlayerViewOffset = Weap.default.PlayerViewOffset;
		CachedWeaponInfo.DefaultMuzzleScale = Weap.default.MuzzleScale;
		CachedWeaponInfo.DefaultFlashO = Weap.default.FlashO;
	}
	default.CachedWeaponInfo = CachedWeaponInfo; //Persist across levels (in case we're somehow destroyed)
}

//fox: Calculate a weapon view offset usable by network clients
function ApplyWeaponViewOffset(Weapon Weap)
{
	local Weapon W;

	//Weapon.SetHand will properly position our weapon based on scaled default values
	//However, as a network client, we don't actually own our weapon, so SetHand won't see our new values
	//To work around this, we'll quickly spawn and destroy a local weapon to call SetHand with
	W = Weap.Spawn(Weap.class);
	if (W != None) {
		//Viewport.Actor.ClientMessage("ApplyWeaponViewOffset " $ W.Class @ W.default.PlayerViewOffset);
		W.SetHand(Viewport.Actor.Handedness);
		CachedPlayerViewOffset = W.PlayerViewOffset;
		W.Destroy();

		//Pass the calculated offset back to our real weapon
		Weap.PlayerViewOffset = CachedPlayerViewOffset;
	}
}

//fox: Convert vFOV to hFOV (and vice versa)
function float hFOV(float BaseFOV, float AspectRatio)
{
	return 2 * ATan(Tan(BaseFOV / 2f) * AspectRatio);
}
function float vFOV(float BaseFOV, float AspectRatio)
{
	return 2 * ATan(Tan(BaseFOV / 2f) / AspectRatio);
}

//fox: Use screen aspect ratio to auto-generate a Hor+ FOV
function float GetHorPlusFOV(float BaseFOV)
{
	return FClamp(RADTODEG * hFOV(vFOV(BaseFOV * DEGTORAD, 4/3f), CachedSizeX / CachedSizeY), 1, 170);
}

//fox: Match mouse sensitivity to 90 FOV sensitivity, allowing it to be independent of our aspect ratio
function CorrectMouseSensitivity()
{
	local float CorrectedFOVScale;
	local string Sens;

	if (!bCorrectMouseSensitivity || Viewport.Actor == None)
		return;
	CorrectedFOVScale = GetHorPlusFOV(90f) * 0.01111; //"Undo" PlayerPawn FOVScale
	if (LastCorrectedFOVScale < 0f)
		LastCorrectedFOVScale = CorrectedFOVScale;
	if (LastCorrectedFOVScale == CorrectedFOVScale)
		return;
	Viewport.Actor.MouseSensitivity *= LastCorrectedFOVScale / CorrectedFOVScale;
	LastCorrectedFOVScale = CorrectedFOVScale;

	//Round to match original 2-precision menu value
	Viewport.Actor.MouseSensitivity += 0.005;
	Sens = string(Viewport.Actor.MouseSensitivity);
	Sens = Left(Sens, InStr(Sens, ".") + 3);
	Viewport.Actor.SetSensitivity(float(Sens)); //To also save updated value
}

defaultproperties
{
	bDoInit=true
	LastCorrectedFOVScale=-1f
	Desired43FOV=90f
	bCorrectZoomFOV=true
	bCorrectMouseSensitivity=true
}
