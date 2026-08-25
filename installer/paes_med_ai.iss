; =====================================================================
; PAES MED AI - Instalador Windows profissional (Inno Setup 6)
; Gera: installer/Output/PAESMedAI_Setup_<versao>.exe
; =====================================================================

#define MyAppName          "PAES MED AI"
#define MyAppFullName      "PAES MED AI - Estudos para Medicina"
#define MyAppPublisher     "PAES MED AI"
#define MyAppURL           "https://github.com/ymedeiros228/PAES_MED_AI"
#define MyAppExeName       "paes_med_ai.exe"
#define MyAppVersion "1.0.0.71"
#define MyAppIcon          "..\windows\runner\resources\app_icon.ico"

[Setup]
AppId={{B8F3A2E1-7C4D-4E9A-9F1B-PAESMEDAI2026}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppFullName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\PAES_MED_AI
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=license_portugues.txt
OutputDir=Output
OutputBaseFilename=PAESMedAI_Setup_{#MyAppVersion}
SetupIconFile={#MyAppIcon}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\app\{#MyAppExeName}
UninstallDisplayName={#MyAppFullName}
; Fecha automaticamente o app e o backend se estiverem em uso durante update/reinstalacao
CloseApplications=yes
RestartApplications=no
; Cria a pasta de instalacao se nao existir (evita "pasta nao encontrada")
CreateAppDir=yes

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
ReadyMemoDir=O PAES MED AI será instalado em:
InstallingLabel=Instalando PAES MED AI... aguarde.
FinishedHeadingLabel=Instalação concluída!
FinishedLabel=O PAES MED AI foi instalado com sucesso. Clique Concluir para finalizar.
FinishedRestartLabel=Seu computador não precisa ser reiniciado.
ConfirmUninstall=Tem certeza de que deseja remover o PAES MED AI?

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[InstallDelete]
; Limpa atalhos antigos na Area de Trabalho e Menu Iniciar
Type: files; Name: "{userdesktop}\PAES MED AI*.lnk"
Type: files; Name: "{userdesktop}\PAES MED AI Desktop.lnk"
Type: files; Name: "{userstartmenu}\PAES MED AI*.lnk"
Type: files; Name: "{commonstartmenu}\PAES MED AI*.lnk"

[Files]
; Aplicativo Flutter
Source: "staging\app\*"; DestDir: "{app}\app"; Flags: ignoreversion recursesubdirs createallsubdirs
; Backend FastAPI
Source: "staging\backend\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs
; Dados
Source: "staging\data\paes_med_ai.db"; DestDir: "{app}\data"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "staging\data\materiais\*"; DestDir: "{app}\data\materiais"; Flags: onlyifdoesntexist uninsneveruninstall recursesubdirs createallsubdirs
; Tools
Source: "staging\tools\*"; DestDir: "{app}\tools"; Flags: ignoreversion recursesubdirs createallsubdirs
; Launcher
Source: "staging\Iniciar_PAES_MED_AI.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "staging\Iniciar_PAES_MED_AI.vbs"; DestDir: "{app}"; Flags: ignoreversion
; Atualizador visual (bat na raiz + script em tools)
Source: "staging\Atualizar_PAES_MED_AI.bat"; DestDir: "{app}"; Flags: ignoreversion
; Versao
Source: "staging\VERSION.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Menu Iniciar
Name: "{group}\{#MyAppName}"; Filename: "wscript.exe"; Parameters: """{app}\Iniciar_PAES_MED_AI.vbs"""; IconFilename: "{app}\app\{#MyAppExeName}"; Comment: "Iniciar PAES MED AI"
Name: "{group}\Atualizar {#MyAppName}"; Filename: "{app}\Atualizar_PAES_MED_AI.bat"; IconFilename: "{app}\app\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
; Area de Trabalho - usa {userdesktop} pois PrivilegesRequired=lowest
Name: "{userdesktop}\PAES MED AI Desktop"; Filename: "wscript.exe"; Parameters: """{app}\Iniciar_PAES_MED_AI.vbs"""; IconFilename: "{app}\app\{#MyAppExeName}"; Tasks: desktopicon; Comment: "Iniciar PAES MED AI"

[Registry]
; Grava versao e caminho no registro de forma confiavel
Root: HKCU; Subkey: "Software\PAES_MED_AI"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersion}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\PAES_MED_AI"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey

[Run]
; Abrir app apos instalar (via VBS, sem tela preta)
Filename: "wscript.exe"; Parameters: """{app}\Iniciar_PAES_MED_AI.vbs"""; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Remove venv local criado pelo launcher
Type: filesandordirs; Name: "{app}\.venv"

[Code]
function InitializeSetup(): Boolean;
var
  InstalledVersion: String;
begin
  Result := True;
  if RegQueryStringValue(HKCU, 'Software\PAES_MED_AI', 'Version', InstalledVersion) then
  begin
    if InstalledVersion <> '{#MyAppVersion}' then
    begin
      if MsgBox(
        'Foi detectada uma versao anterior do PAES MED AI.' + #13#10 + #13#10 +
        'Versao instalada: ' + InstalledVersion + #13#10 +
        'Nova versao: {#MyAppVersion}' + #13#10 + #13#10 +
        'Seus dados de estudo serao preservados.' + #13#10 + #13#10 +
        'Deseja continuar com a atualizacao?',
        mbInformation, MB_YESNO) = IDNO then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;

procedure DeinitializeSetup();
begin
  RegWriteStringValue(HKCU, 'Software\PAES_MED_AI', 'Version', '{#MyAppVersion}');
  RegWriteStringValue(HKCU, 'Software\PAES_MED_AI', 'InstallPath', ExpandConstant('{app}'));
end;
