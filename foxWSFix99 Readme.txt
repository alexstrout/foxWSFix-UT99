foxWSFix99 v1.0.0
Widescreen FOV support for Unreal Tournament 1999
By fox

==========
 Features
==========
-- Widescreen FOV support based on aspect ratio and configured FOV setting, including weapon zoom
-- Aspect-correct rendering for first-person weapons
-- Entirely client-side - no mutators required

=====================
 Install / Uninstall
=====================
First, navigate to the System folder and open up UnrealTournament.ini (e.g. "C:\Games\UnrealTournament\System\UnrealTournament.ini")
Find the following line:

	Console=UTMenu.UTConsole

And replace it with the following:

	;Console=UTMenu.UTConsole
	Console=foxWSFix99.foxUTConsole

You're done! To uninstall, simply reverse your changes.

=======
 Usage
=======
Once installed, foxWSFix requires no configuration. However, you may need to manually adjust your resolution to your native resolution.
This can be done via the game's built-in console command:

	SetRes <resolution>
	 * <resolution> - new resolution to use, given as ##x##
		e.g. SetRes 1920x1080
			 SetRes 3360x1440

In-game FOV can be adjusted via a new console command:

	SetFOV <fov>
	 * <fov> - new FOV to use, given as a 4:3 ratio FOV (90 @ 4:3 == 106.2602 @ 16:9, etc.)
		e.g. SetFOV 90

=============
 Other Notes
=============
The FOV changes should be compatible with all mods, provided they don't use a custom UTConsole class (they probably won't).

foxWSFix stores its settings in UnrealTournament.ini as such:

	[foxWSFix99.foxUTConsole]
	Desired43FOV=90.000000			;Desired 4:3 FOV per SetFOV command
	bCorrectZoomFOV=True			;Correct FOV for weapon zoom?
	bCorrectMouseSensitivity=True	;Correct MouseSensitivity for aspect ratio changes?
	<Normal UTConsole options etc.>

Note that bCorrectMouseSensitivity works slightly differently than foxWSFix for UT2004 - it only calculates / applies after exiting the menu.
Be sure to exit the menu after a resolution change to ensure the new sensitivity is saved. This works both in-game and at the main menu.

===================
 Known Bugs / TODO
===================
HUDs grow larger with aspect ratio, but are still aspect-correct and can be shrunk back down using the in-game HUD Scale slider.
Unfortunately, this setting does not apply to crosshairs. Crosshair scale will require either custom HUDs or ugly hacks. :(

========================
 Feedback / Source Code
========================
If you have any questions or feedback, feel free to leave a comment on Steam:
<steam thread here>

Source code for the project is included in the "Src" folder so you can laugh at my silly code. Also available at: https://www.taraxis.com/foxwsfix-ut99
If you would like to build the mod source code, there is a convenient batch file provided in the Src folder.
Just add the following to the [Editor.EditorEngine] section in UnrealTournament.ini:

	EditPackages=foxWSFix99

And of course, thanks for trying the mod!
~fox

=========
 Changes
=========
v1.0.0 (???):
-- Initial release.
