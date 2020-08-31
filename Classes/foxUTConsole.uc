//Lazily hijacks UTConsole to provide mod-independent FOV scaling for both PlayerPawn and Weapon
class foxUTConsole extends UTConsole;

var bool bDoInit;

var float CachedSizeX;
var float CachedSizeY;
var float CachedClipX;
var float CachedClipY;
var float CachedDefaultFOV;
var float CachedDesiredFOV;

var class CachedWeaponClass;

struct DefaultWeaponInfo
{
	var class<Weapon> WeaponClass;
	var vector DefaultPlayerViewOffset;
	var float DefaultMuzzleScale;
	var float DefaultFlashO;
};
var DefaultWeaponInfo WeaponInfo[128];

var globalconfig float Desired43FOV;
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

	//... And this will correct our next FOV
	Viewport.Actor.DesiredFOV = F;
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
		CachedWeaponClass = default.CachedWeaponClass;
		//CorrectMouseSensitivity();
		return;
	}

	//Durr
	P = Viewport.Actor;
	if (P == None) {
		return;
	}

	//Attempt to set an accurate FOV for our aspect ratio
	if (P.DefaultFOV != CachedDefaultFOV) {
		CachedDefaultFOV = GetHorPlusFOV(Desired43FOV);
		P.DefaultFOV = CachedDefaultFOV;
		return;
	}

	//Actually set this FOV, including when we're zoomed
	if (P.DesiredFOV != P.DefaultFOV
	&& P.DesiredFOV != CachedDesiredFOV) {
		CachedDesiredFOV = GetHorPlusFOV(P.DesiredFOV);
		P.DesiredFOV = CachedDesiredFOV;
		return;
	}

	//Set weapon FOV as well - only once per weapon
	if (P != None && P.Weapon != None
	&& P.Weapon.Class != CachedWeaponClass)
		ApplyWeaponFOV(P.Weapon);
}
function ApplyWeaponFOV(Weapon Weap)
{
	local int i;

	//Remember our selected weapon
	CachedWeaponClass = Weap.Class;

	//First pull or cache our "default default" values before doing anything else
	i = ArrayCount(WeaponInfo) - 1;
	if (WeaponInfo[i].WeaponClass != None) {
		WeaponInfo[i].WeaponClass.default.PlayerViewOffset = WeaponInfo[i].DefaultPlayerViewOffset;
		WeaponInfo[i].WeaponClass.default.MuzzleScale = WeaponInfo[i].DefaultMuzzleScale;
		WeaponInfo[i].WeaponClass.default.FlashO = WeaponInfo[i].DefaultFlashO;
		/* Log("foxWSFix Cleared " $ i @ WeaponInfo[i].WeaponClass
			@ WeaponInfo[i].WeaponClass.default.PlayerViewOffset
			@ WeaponInfo[i].WeaponClass.default.MuzzleScale
			@ WeaponInfo[i].WeaponClass.default.FlashO); */
		WeaponInfo[i].WeaponClass = None;
	}
	for (i = 0; i < ArrayCount(WeaponInfo); i++) {
		if (WeaponInfo[i].WeaponClass == Weap.Class) {
			Weap.default.PlayerViewOffset = WeaponInfo[i].DefaultPlayerViewOffset;
			Weap.default.MuzzleScale = WeaponInfo[i].DefaultMuzzleScale;
			Weap.default.FlashO = WeaponInfo[i].DefaultFlashO;
			/* Log("foxWSFix Found " $ i @ Weap.Class
				@ Weap.default.PlayerViewOffset
				@ Weap.default.MuzzleScale
				@ Weap.default.FlashO); */
			break;
		}
		if (WeaponInfo[i].WeaponClass == None) {
			WeaponInfo[i].WeaponClass = Weap.Class;
			WeaponInfo[i].DefaultPlayerViewOffset = Weap.default.PlayerViewOffset;
			WeaponInfo[i].DefaultMuzzleScale = Weap.default.MuzzleScale;
			WeaponInfo[i].DefaultFlashO = Weap.default.FlashO;
			/* Log("foxWSFix Stored " $ i @ Weap.Class
				@ Weap.default.PlayerViewOffset
				@ Weap.default.MuzzleScale
				@ Weap.default.FlashO); */
			break;
		}
	}

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
	//bCorrectMouseSensitivity=true
}
