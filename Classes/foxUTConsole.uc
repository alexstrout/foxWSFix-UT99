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

var globalconfig float Desired43FOV;
var globalconfig bool bCorrectZoomFOV;
//var globalconfig bool bCorrectMouseSensitivity;

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
		//CorrectMouseSensitivity();
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

	//Set weapon FOV as well - only once per weapon
	if (P.Weapon != None
	&& P.Weapon.Class != CachedWeaponInfo.WeaponClass)
		ApplyWeaponFOV(P.Weapon);
}
function ApplyWeaponFOV(Weapon Weap)
{
	//First reset/save our "default default" values before doing anything else
	UpdateCachedWeaponInfo(Weap);

	//Fix bad FOV calculation in Inventory.CalcDrawOffset()
	//Note: FOVAngle sometimes too high when respawning, so just use CachedDefaultFOV
	//Weap.default.PlayerViewOffset *= Viewport.Actor.FOVAngle / 90f;
	Weap.default.PlayerViewOffset *= CachedDefaultFOV / 90f;
	Weap.SetHand(Viewport.Actor.Handedness);

	//Also fix muzzle flash position
	Weap.default.MuzzleScale *= (CachedClipY * 4) / (CachedClipX * 3);
	Weap.default.FlashO *= (CachedClipY * 4) / (CachedClipX * 3);
	Weap.FlashO = Weap.default.FlashO; //Needed for weapons that don't recalc it (every weapon except Enforcer or Minigun)
}
function UpdateCachedWeaponInfo(Weapon Weap)
{
	if (CachedWeaponInfo.WeaponClass != None) {
		CachedWeaponInfo.WeaponClass.default.PlayerViewOffset = CachedWeaponInfo.DefaultPlayerViewOffset;
		CachedWeaponInfo.WeaponClass.default.MuzzleScale = CachedWeaponInfo.DefaultMuzzleScale;
		CachedWeaponInfo.WeaponClass.default.FlashO = CachedWeaponInfo.DefaultFlashO;
	}
	if (Weap == None)
		CachedWeaponInfo.WeaponClass = None;
	else {
		CachedWeaponInfo.WeaponClass = Weap.Class;
		CachedWeaponInfo.DefaultPlayerViewOffset = Weap.default.PlayerViewOffset;
		CachedWeaponInfo.DefaultMuzzleScale = Weap.default.MuzzleScale;
		CachedWeaponInfo.DefaultFlashO = Weap.default.FlashO;
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
//TODO Need to wire up options menu to handle this properly
//function CorrectMouseSensitivity()
//{
//	if (!bCorrectMouseSensitivity
//	|| Viewport.Actor == None)
//		return;
//	Viewport.Actor.MouseSensitivity = class'PlayerPawn'.default.MouseSensitivity
//		/ (GetHorPlusFOV(Desired43FOV) * 0.01111); //"Undo" PlayerInput FOVScale
//}

defaultproperties
{
	bDoInit=true
	Desired43FOV=90f
	bCorrectZoomFOV=true
	//bCorrectMouseSensitivity=true
}
