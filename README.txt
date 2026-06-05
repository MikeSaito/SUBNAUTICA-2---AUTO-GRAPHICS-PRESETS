=======================================================================
  SUBNAUTICA 2 - AUTO GRAPHICS PRESETS
=======================================================================

  Manual install (no batch files):
  ..\GraphicsPresets-Manual\  ->  INSTALL.txt

  For Nexus Mods (no .bat / .ps1):
  ..\GraphicsPresets-Nexus\  ->  README.txt + PACK_FOR_NEXUS.txt

QUICK START
-----------
1. Launch the game ONCE and set resolution, display mode, VSync.
2. Fully close the game.
3. Run 00_Menu.bat (or batch file 01-07).
4. Launch the game again.

FILES
-----
  00_Menu.bat        - preset selection menu
  01_Minimum.bat     - minimum settings (max FPS)
  02_Low.bat         - low
  03_Medium.bat      - medium (balanced)
  04_High.bat        - high
  05_UltraMax.bat    - ultra max
  06_Potato.bat      - extreme FPS boost
  07_AMD_FSR.bat     - medium + FSR for AMD
  restore-backup.bat - restore saved config

PRESETS
-------
  Minimum   - DLSS Performance, 50% scale, Lumen off
  Low       - DLSS Balanced, 60% scale, basic shadows
  Medium    - DLSS Quality, 75% scale, Lumen GI
  High      - DLSS Quality+, 90% scale, Lumen reflections
  Ultra Max - DLSS DLAA, 100% scale, max Lumen (software). No hardware RT.

CONFIG PATH
-----------
  %LOCALAPPDATA%\Subnautica2\Saved\Config\Windows\

  GameUserSettings.ini - main game settings
  Engine.ini           - advanced UE5 CVars

WHAT IS PRESERVED
-----------------
When switching presets, these are NOT changed:
  - Screen resolution
  - Fullscreen / windowed mode
  - InstallGUID and benchmark data
  - Audio device

BACKUP
------
A copy is saved to backup\ before each apply.
To restore: restore-backup.bat or menu option 8.

IMPORTANT
---------
  - Game must be CLOSED when applying a preset.
  - Engine.ini is set Read-only - otherwise the game may delete it.
  - Major patches may reset or change parameters.
  - Ultra Max needs a strong GPU (12+ GB VRAM recommended).
  - On AMD GPU use 07_AMD_FSR.bat or set UpscalingMethod=U_FSR manually.
  - Game Pass config folder: WinGDK\ (detected automatically).
  - Full parameter reference: PARAMETERS.txt

EXTRA Engine.ini CVars (v2)
---------------------------
  r.PSOPrecache.Mode=1              - fewer shader hitches
  sg.DefaultScalabilityLevel      - UE5 base tier
  r.Shadow.CSM.MaxCascades          - shadow cascades
  r.Shadow.MaxResolution            - shadow map resolution
  foliage/grass.DensityScale        - vegetation density
  r.OneFrameThreadLag=0             - lower input lag
  r.Tonemapper.Sharpen              - image sharpness
  r.Streaming.FramesForFullUpdate   - texture streaming speed

=======================================================================
