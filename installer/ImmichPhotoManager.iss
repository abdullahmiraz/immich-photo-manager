; Build: iscc installer\ImmichPhotoManager.iss /DManagerExe=path\to\ImmichPhotoManager.exe
; Or use GitHub Actions (see .github/workflows/release.yml)

#define MyAppName "Immich Photo Manager"
#ifndef MyAppVersion
#define MyAppVersion "1.0.0"
#endif
#define MyPublisher "Immich Photo Manager Contributors"
#define MyAppURL "https://github.com/abdullahmiraz/immich-photo-manager"
#define RepoRoot ".."

; CI passes absolute path via /DManagerExe=...
#ifndef ManagerExe
#define ManagerExe "..\manager\publish\ImmichPhotoManager.exe"
#endif

[Setup]
AppId={{8F4E2B1A-9C3D-4E5F-A6B7-1C2D3E4F5A6B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={localappdata}\ImmichPhotoManager
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=ImmichPhotoManager-{#MyAppVersion}-setup
OutputDir=output
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut to the manager"; GroupDescription: "Shortcuts:"; Flags: unchecked
; Tasks are checked by default in Inno Setup (no "checked" flag exists)
Name: "launchstack"; Description: "Pull images and start Docker stack after install"; GroupDescription: "Setup:"

[Files]
Source: "{#RepoRoot}\docker-compose.yml"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\docker-compose.deduper.yml"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\docker-compose.optimizer.yml"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\docker-compose.release.yml"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\docker-compose.cloudflare.yml"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\.env.example"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\optimizer\*"; DestDir: "{app}\optimizer"; Flags: ignoreversion recursesubdirs
Source: "{#RepoRoot}\optimizer-config\*"; DestDir: "{app}\optimizer-config"; Flags: ignoreversion recursesubdirs
Source: "{#RepoRoot}\docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs
Source: "{#RepoRoot}\tools\*"; DestDir: "{app}\tools"; Flags: ignoreversion recursesubdirs
Source: "{#RepoRoot}\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\SECURITY.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#RepoRoot}\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "payload\*"; DestDir: "{app}\installer\payload"; Flags: ignoreversion
Source: "{#ManagerExe}"; DestDir: "{app}"; DestName: "ImmichPhotoManager.exe"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\ImmichPhotoManager.exe"; WorkingDir: "{app}"
Name: "{group}\Start stack"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\installer\payload\stack-control.ps1"" -Action start"; WorkingDir: "{app}"
Name: "{group}\Stop stack"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\installer\payload\stack-control.ps1"" -Action stop"; WorkingDir: "{app}"
Name: "{group}\Update stack images"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\installer\payload\stack-control.ps1"" -Action update"; WorkingDir: "{app}"
Name: "{group}\Open Immich"; Filename: "http://localhost:2283"
Name: "{group}\Open deduper"; Filename: "http://localhost:8086"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\ImmichPhotoManager.exe"; Tasks: desktopicon

[Run]
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\installer\payload\install-stack.ps1"" -InstallDir ""{app}"""; WorkingDir: "{app}"; StatusMsg: "Configuring Docker stack (pull may take several minutes)..."; Flags: runhidden waituntilterminated; Tasks: launchstack
Filename: "{app}\ImmichPhotoManager.exe"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\ImmichPhotoManager"

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    if MsgBox('Stop the Docker stack before uninstall? (Photos in library\ are kept unless you delete the install folder.)',
      mbConfirmation, MB_YESNO) = IDYES then
    begin
      Exec('powershell.exe',
        '-ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\installer\payload\stack-control.ps1') + '" -Action stop',
        ExpandConstant('{app}'), SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;
