; Inno Setup script -> setup.exe.  Build: ISCC packaging\windows\mdv.iss   (after cargo build --release)
#define AppName "Markdown Viewer"
#define AppVersion "0.1.1"

[Setup]
AppId={{6F1D0B52-6C0B-4E1B-9B7A-4D4D2D6C8A11}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\mdv
DefaultGroupName={#AppName}
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ChangesAssociations=yes
OutputDir=Output
OutputBaseFilename=mdv-setup
Compression=lzma2/ultra64
SolidCompression=yes
UninstallDisplayIcon={app}\mdv.exe
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: assoc; Description: "Associate Markdown files (.md, .markdown) with {#AppName}"
Name: desktopicon; Description: "Create a &desktop shortcut"; Flags: unchecked

[Files]
Source: "..\..\target\release\mdv.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\mdv.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\mdv.exe"; Tasks: desktopicon

[Registry]
Root: HKA; Subkey: "Software\Classes\mdv.Markdown"; ValueType: string; ValueData: "Markdown Document"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\mdv.Markdown\DefaultIcon"; ValueType: string; ValueData: "{app}\mdv.exe,0"
Root: HKA; Subkey: "Software\Classes\mdv.Markdown\shell\open\command"; ValueType: string; ValueData: """{app}\mdv.exe"" ""%1"""
Root: HKA; Subkey: "Software\Classes\Applications\mdv.exe\shell\open\command"; ValueType: string; ValueData: """{app}\mdv.exe"" ""%1"""; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\.md\OpenWithProgids"; ValueType: string; ValueName: "mdv.Markdown"; ValueData: ""; Flags: uninsdeletevalue; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\.markdown\OpenWithProgids"; ValueType: string; ValueName: "mdv.Markdown"; ValueData: ""; Flags: uninsdeletevalue; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\.mdown\OpenWithProgids"; ValueType: string; ValueName: "mdv.Markdown"; ValueData: ""; Flags: uninsdeletevalue; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\.mkd\OpenWithProgids"; ValueType: string; ValueName: "mdv.Markdown"; ValueData: ""; Flags: uninsdeletevalue; Tasks: assoc

[Run]
Filename: "{app}\mdv.exe"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
