#define MyAppName "P2pChords"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "YourName"
#define MyAppExeName "test_controller.exe"

[Setup]
AppId={{fbfa1f97-ce15-4701-a05a-0815aae5bbe9}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir={#SourcePath}\..\dist
OutputBaseFilename=P2pChordsSetup
Compression=lzma
SolidCompression=yes

[Files]
Source: "{#SourcePath}\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"