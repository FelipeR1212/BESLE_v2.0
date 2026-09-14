#define MyAppName "BESLE"
#define MyAppVersion "2.1.0"
#define MyAppPublisher "BESLE contributors"
#define MyAppLauncher "run-besle.cmd"

[Setup]
AppId={{7D2A7DC5-1CD5-4A25-8C1B-87D31E2F7B10}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\BESLE\{#MyAppVersion}
DefaultGroupName=BESLE
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
OutputDir=..\..\dist
OutputBaseFilename=BESLE-{#MyAppVersion}-Windows-x64-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\BESLE.exe
VersionInfoVersion={#MyAppVersion}.0
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "stage\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\BESLE"; Filename: "{app}\{#MyAppLauncher}"
Name: "{autodesktop}\BESLE"; Filename: "{app}\{#MyAppLauncher}"; Tasks: desktopicon

[Run]
Filename: "{app}\redist\msmpisetup.exe"; Parameters: "-unattend"; StatusMsg: "Instalando Microsoft MPI..."; Flags: waituntilterminated runhidden; Check: not FileExists(ExpandConstant('{autopf}\Microsoft MPI\Bin\mpiexec.exe'))
Filename: "{app}\{#MyAppLauncher}"; Description: "Ejecutar BESLE"; Flags: postinstall nowait skipifsilent unchecked
