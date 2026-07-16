# Video cleanup (pre-import)

Optional batch transcode for `.mp4` files before uploading to Immich. Outputs go to an `encoded/` subfolder next to each source file.

## HandBrake CLI (required)

This repo does **not** ship `HandBrakeCLI.exe` (GPLv2 — obtain from the official project).

1. Download **HandBrake** for Windows from https://handbrake.fr/downloads.php  
2. Copy `HandBrakeCLI.exe` into one of:
   - `tools\handbrake\HandBrakeCLI.exe` (recommended)
   - `tools\video-cleanup\HandBrakeCLI.exe`

Use official builds only. Do not redistribute builds that include FDK-AAC if license-incompatible.

## Usage

1. Place or copy `.mp4` files under `tools\video-cleanup\` (or a subfolder).
2. From PowerShell:

```powershell
cd path\to\immich\tools\video-cleanup
.\optimize.ps1
```

3. Upload from the `encoded\` folders via Immich or [immich-go](../immich-go/README.md).
