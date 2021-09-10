; ----------------------------------------------------------------------------
; LazyREST - Installation Script
; Author: Tristan Marlow
; Purpose: Install application
;
; ----------------------------------------------------------------------------
; Copyright (c) 2021 Little Earth Solutions
; All Rights Reserved
;
; This product is protected by copyright and distributed under
; licenses restricting copying, distribution and decompilation
;
; ----------------------------------------------------------------------------
; Application Variables
;-----------------------------------------------------------------------------
#define ConstAppVersion GetFileVersion("..\build\bin\win64\release\LazyREST.exe") ; define variable
#define ConstAppName "LazyREST"
#define ConstAppID "{{9CB0FFAC-22B9-451F-A199-59E9C91EF973}"
#define ConstAppMutex "{{9CB0FFAC-22B9-451F-A199-59E9C91EF973}"
#define ConstAppDescription "LazyREST"
#define ConstAppPublisher "Little Earth Solutions"
#define ConstAppCopyright "Copyright (C) 2021 Little Earth Solutions"
#define ConstAppURL "http://www.littleearthsolutions.net/"
#define ConstAppExeName "LazyREST.exe"
;-----------------------------------------------------------------------------

#ifdef AppSystemMode
  #define ConstAppSuffix "System"
  #define ConstAppUninstallSuffix "User"
  #define ConstPrivilegesRequired="admin"
  #define ConstAppRecommendation="This version is recommended for RDS and Citrix servers, administration rights are required."
 #else
  #define ConstAppSuffix "User"
  #define ConstAppUninstallSuffix "System"
  #define ConstPrivilegesRequired="lowest"
  #define ConstAppRecommendation="This version is recommended for user workstations, administration right are not required."
#endif

[Setup]
AppId={#ConstAppID}-{#ConstAppSuffix}
AppName={#ConstAppName} {#ConstAppSuffix}
AppVersion={#ConstAppVersion}
AppPublisher={#ConstAppPublisher}
AppPublisherURL={#ConstAppURL}
AppSupportURL={#ConstAppURL}
AppUpdatesURL={#ConstAppURL}
AppCopyright={#ConstAppCopyright}
VersionInfoCompany={#ConstAppPublisher}
VersionInfoDescription={#ConstAppName}
VersionInfoCopyright={#ConstAppCopyright}
VersionInfoVersion={#ConstAppVersion}
VersionInfoTextVersion={#ConstAppVersion}
OutputDir=..\build\installer\
OutputBaseFilename=LazyREST-{#ConstAppVersion}-{#ConstAppSuffix}
DefaultDirName={autopf}\{#ConstAppPublisher}\{#ConstAppName}
UninstallDisplayName={#ConstAppName}
DefaultGroupName={#ConstAppPublisher}\{#ConstAppName}
AllowNoIcons=true
MinVersion=0,6.1.7600
InfoBeforeFile=..\build\bin\win64\release\LazyREST - Release Notes.rtf
LicenseFile=..\build\bin\win64\release\LazyREST - License.rtf
WizardImageFile=..\images\installer\WizardImageFile.bmp
WizardSmallImageFile=..\images\installer\WizardSmallImageFile.bmp
SetupIconFile=..\images\icons\LazyREST.ico
UninstallDisplayIcon={app}\{#ConstAppExeName}
SolidCompression=True
InternalCompressLevel=ultra
Compression=lzma/ultra
RestartApplications=False
CloseApplications=False
PrivilegesRequired={#ConstPrivilegesRequired}
DisableWelcomePage=False
ArchitecturesAllowed=x64

[Tasks]
Name: "desktopicon"; Description: "Create a &Desktop icon"; GroupDescription: "Additional icons:"

[Files]
Source: "..\build\bin\win64\release\LazyREST.exe"; DestDir: "{app}"; Flags: promptifolder replacesameversion; BeforeInstall: TaskKill('{#ConstAppExeName}')
Source: "..\build\bin\win64\release\*"; DestDir: "{app}"; Flags: recursesubdirs restartreplace replacesameversion; Excludes: "*.~ra, *.map, *.drc"

[INI]
Filename: {app}\install.ini; Section: "Install"; Key: "PrivilegesRequired"; String: {#ConstPrivilegesRequired}
Filename: {app}\install.ini; Section: "Install"; Key: "Version"; String: {#ConstAppVersion}
Filename: {app}\install.ini; Section: "Install"; Key: "Installed"; String: {code:GetDateTime}

[Icons]
Name: "{group}\{#ConstAppName}"; Filename: "{app}\{#ConstAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\{#ConstAppName}.ico"
Name: "{autodesktop}\{#ConstAppName}"; Filename: "{app}\{#ConstAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\{#ConstAppName}.ico"; Tasks: desktopicon
Name: "{group}\LazyREST - Postman Samples"; Filename: "{app}\postman\"; WorkingDir: "{app}\postman"; Flags: foldershortcut; IconFilename: "{app}\LazyREST.exe"; IconIndex: 0
Name: "{group}\LazyREST - Data Samples"; Filename: "{app}\samples\"; WorkingDir: "{app}\samples"; Flags: foldershortcut; IconFilename: "{app}\LazyREST.exe"; IconIndex: 0
Name: "{group}\LazyREST - Application Folder"; Filename: "{app}"; WorkingDir: "{app}"; Flags: foldershortcut; IconFilename: "{app}\LazyREST.exe"; IconIndex: 0

[Run]
Filename: "{app}\{#ConstAppExeName}"; WorkingDir: "{app}"; Flags: nowait postinstall runasoriginaluser; Description: "Launch {#ConstAppName}"
Filename: "{app}\samples\install_sample_data.bat"; WorkingDir: "{app}\samples\"; Flags: postinstall runasoriginaluser shellexec unchecked; Description: "Install Sample Data"
Filename: "explorer"; Parameters: "/root,{app}\postman"; WorkingDir: "{app}\postman"; Flags: postinstall shellexec unchecked; Description: "Browse Postman Samples"

[Messages]
WelcomeLabel2=This will install [name/ver] on your computer.%n%nNOTE: {#ConstAppRecommendation}%n%nIt is recommended that you close all other applications before continuing.
AdminPrivilegesRequired=You must be logged in as an administrator when installing this program.%n%nTo install without administation rights please obtain the User mode setup.
PowerUserPrivilegesRequired=You must be logged in as an administrator or as a member of the Power Users group when installing this program.%n%nTo install without administation rights please obtain the User mode setup.

[UninstallDelete]
Type: files; Name: "{app}\defaults.ini"
Type: files; Name: "{app}\install.ini"

[InstallDelete]
Type: files; Name: "{app}\*.dll"
Type: files; Name: "{app}\LazyREST*.exe"

[Code]
#include "scripts\closeapplications.iss"
#include "scripts\uninstall.iss"

function GetDateTime(Param: String): String;
begin
  result := GetDateTimeString('yyyy-nn-dd hh:nn:ss', '-', ':');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
   if (CurStep=ssInstall) then
    begin
      if (IsUpgrade()) then
      begin
        UnInstallOldVersion();
     end;
   end;
end;


function NeedRestart(): Boolean;
begin
	{ Do not prompt for restart even if required, ClientUpdate.exe will request a restart as it is in use via Automatic updates }
	Result := False;
end;

