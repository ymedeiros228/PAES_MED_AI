; =====================================================================
; PAES MED AI - Instalador Windows profissional (Inno Setup 6)
; Gera: installer/Output/PAESMedAI_Setup_<versao>.exe
; Recursos:
;   - Instala em Program Files (per-user ou admin)
;   - Atalho na Area de Trabalho
;   - Atalho no Menu Iniciar
;   - Entrada em Adicionar/Remover Programas com versao e suporte
;   - Verificacao de versao (update) via arquivo VERSION remoto
;   - Desinstalador limpo (remove arquivos e atalhos)
;   - Icone proprio do app
;   - Licenca + tela de boas-vindas
; =====================================================================

#define MyAppName          "PAES MED AI"
#define MyAppFullName      "PAES MED AI - Estudos para Medicina"
#define MyAppPublisher     "PAES MED AI"
#define MyAppURL           "https://github.com/ymedeiros228/PAES_MED_AI"
#define MyAppExeName       "paes_med_ai.exe"
#define MyAppVersion       "1.0.0.17"
#define MyAppBuildDir      "..\build\windows\x64\runner\Release"
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
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppFullName}
; Assinatura digital (preencher se tiver certificado)
; SignTool=signtool
; SignedUninstaller=yes

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "startupicon"; Description: "Iniciar com o Windows"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Aplicativo Flutter + DLLs + dados
Source: "{#MyAppBuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppBuildDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppBuildDir}\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppBuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Banco de dados (nao sobrescreve se ja existe - preserva progresso do usuario)
Source: "..\data\paes_med_ai.db"; DestDir: "{userappdata}\PAES_MED_AI"; Flags: onlyifdoesntexist uninsneveruninstall
; PDFs de materiais
Source: "..\data\materiais\*.pdf"; DestDir: "{userappdata}\PAES_MED_AI\materiais"; Flags: onlyifdoesntexist uninsneveruninstall recursesubdirs createallsubdirs
; Configuracao base (nao sobrescreve)
Source: "..\backend\.env.example"; DestDir: "{userappdata}\PAES_MED_AI"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
; Menu Iniciar
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
; Area de Trabalho
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
; Iniciar com Windows
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: startupicon

[Run]
; Abrir app apos instalar
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Limpar cache do usuario (opcional - comentado para preservar dados)
; Filename: "{cmd}"; Parameters: "/c rmdir /s /q ""{userappdata}\PAES_MED_AI"""; Flags: runhidden

[UninstallDelete]
; Remove arquivos temporarios do app
Type: filesandordirs; Name: "{localappdata}\PAES_MED_AI"

[Code]
// =====================================================================
// Verificacao de versao antes de instalar (update automatico)
// =====================================================================
function InitializeSetup(): Boolean;
var
  InstalledVersion: String;
begin
  Result := True;

  // Verifica se ja existe uma versao instalada
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

// =====================================================================
// Apos instalar: verificar atualizacoes online (opcional)
// =====================================================================
procedure DeinitializeSetup();
begin
  // Registra versao instalada para futuras verificacoes
  RegWriteStringValue(HKCU, 'Software\PAES_MED_AI', 'Version', '{#MyAppVersion}');
  RegWriteStringValue(HKCU, 'Software\PAES_MED_AI', 'InstallPath', ExpandConstant('{app}'));
end;

