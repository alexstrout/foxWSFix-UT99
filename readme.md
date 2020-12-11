foxWSFix99 v1.0.0
=================
Improved widescreen support for Unreal Tournament 1999

Features
--------
* Aspect-correct "Hor+" FOV adjustment, including weapon zoom values
* Aspect-correct rendering for first-person weapons
* Aspect-correct mouse sensitivity (auto-adjusts on resolution change)
* Entirely client-side - no mutators required

Install / Uninstall
-------------------
Extract the release archive to your UT install directory.

Open System\UnrealTournament.ini and find the following line:

    Console=UTMenu.UTConsole

Replace it with the following:

    ;Console=UTMenu.UTConsole
    Console=foxWSFix99.foxUTConsole

You're done! To uninstall, simply reverse your changes.

Usage
-----
Once installed, foxWSFix works automatically, with no configuration required.

Resolution can be adjusted via the game's built-in console command:

    SetRes <resolution>
     * <resolution> - new resolution to use, given as ##x##
        e.g. SetRes 1920x1080
             SetRes 3360x1440

In-game FOV can be adjusted via a new console command:

    SetFOV <fov>
     * <fov> - new FOV to use, given as a 4:3 ratio FOV (90 @ 4:3 == 106.2602 @ 16:9, etc.)
        e.g. SetFOV 90

Other Notes
-----------
The FOV changes should be compatible with all mods, provided they don't use a custom UTConsole class.

foxWSFix stores its settings in System\UnrealTournament.ini as such:

    [foxWSFix99.foxUTConsole]
    Desired43FOV=90.000000          ;Desired 4:3 FOV per SetFOV command
    bCorrectZoomFOV=True            ;Correct FOV values for weapon zoom?
    bCorrectMouseSensitivity=True   ;Correct MouseSensitivity for aspect ratio changes?
    <Normal UTConsole options etc.>

Note: bCorrectMouseSensitivity only applies after exiting all menus - be sure to do so after changing resolution!

Known Issues
------------
* HUDs grow larger with aspect ratio, but can be shrunk back down using the in-game HUD Scale slider.
* Unfortunately, HUD Scale does not apply to crosshairs. Crosshair scale will require either custom HUDs or ugly hacks. :(

Source Code / Compile Steps
---------------------------
Source code for the project is included in the "Src" folder or online:
https://www.taraxis.com/foxwsfix-ut99

To compile, move the "foxWSFix99" folder inside "Src" out into your root UT install directory.

Then simply add the following to the [Editor.EditorEngine] section in System\UnrealTournament.ini:

    EditPackages=foxWSFix99

Finally, run "foxWSFix99\Compile.bat" (or simply "UCC make") to compile the project.

Feedback
--------
If you have any questions or feedback, feel free to leave a comment on Steam:
https://steamcommunity.com/app/13240/discussions/0/2993169283946758056/

And of course, thanks for trying the mod!
~fox

Changes
-------
v1.0.0 (2020-12-10):
* Initial release.
