unit LazyRest.Utils;

interface

uses
  Winapi.ActiveX, Winapi.ShellAPI, Winapi.Windows,
  Winapi.ShlObj, System.SysUtils, System.Classes;

function IsEmptyString(AValue: string): boolean;
function CheckDirectoryExists(ADirectory: string;
  ACreate: boolean = true): boolean;
procedure QuickFileSearch(const PathName, FileName: string;
  const Recurse: boolean; FileList: TStrings);
function GetShellFolderPath(AFolder: integer): string;
function GetApplicationDir: string;
function GetApplicationDirAppDataDir: string;
function StripExtraSpaces(AValue: string; ARemoveTab: boolean = False;
  ARemoveCRLF: boolean = False): string;
function OpenFolder(AWindowHandle: THandle; const AFolder: string): boolean;
function ExecuteFile(AWindowHandle: THandle; const Operation, FileName, Params,
  DefaultDir: string; ShowCmd: word): integer;
procedure DeleteFolder(AWindowHandle: THandle; AFolder: string;
  AConfirm: boolean = true);
procedure OpenDefaultBrowser(AURL: string);

implementation

uses System.StrUtils;

procedure DeleteFolder(AWindowHandle: THandle; AFolder: string;
  AConfirm: boolean);
var
  LShOp: TSHFileOpStruct;
begin
  if DirectoryExists(AFolder) then
  begin
    LShOp.Wnd := AWindowHandle;
    LShOp.wFunc := FO_DELETE;
    LShOp.pFrom := PChar(AFolder + #0);
    LShOp.pTo := nil;
    if AConfirm then
    begin
      LShOp.fFlags := 0;
    end
    else
    begin
      LShOp.fFlags := FOF_NOCONFIRMATION;
    end;
    SHFileOperation(LShOp);
  end;
end;

function ExecuteFile(AWindowHandle: THandle; const Operation, FileName, Params,
  DefaultDir: string; ShowCmd: word): integer;
begin
  Result := ShellExecute(AWindowHandle, PWideChar(Operation),
    PWideChar(FileName), PWideChar(Params), PChar(DefaultDir), ShowCmd);
end;

function OpenFolder(AWindowHandle: THandle; const AFolder: string): boolean;
begin
  Result := ExecuteFile(AWindowHandle, 'open', PChar('explorer.exe'),
    PChar(AFolder), '', SW_SHOWNORMAL) > 32;
end;

function GetShellFolderPath(AFolder: integer): string;

const
  SHGFP_TYPE_CURRENT = 0;

var
  path: array [0 .. MAX_PATH] of char;
begin
  if SUCCEEDED(SHGetFolderPath(0, AFolder, 0, SHGFP_TYPE_CURRENT, @path[0]))
  then
    Result := path
  else
    Result := '';
end;

function GetApplicationDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function GetApplicationDirAppDataDir: string;

var
  LTitle: string;
begin
  LTitle := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  Result := IncludeTrailingPathDelimiter
    (IncludeTrailingPathDelimiter(GetShellFolderPath(CSIDL_APPDATA)) + LTitle);
  CheckDirectoryExists(Result, true);
end;

function IsEmptyString(AValue: string): boolean;
begin
  Result := Trim(AValue) = '';
end;

function CheckDirectoryExists(ADirectory: string; ACreate: boolean): boolean;
begin
  try
    if ACreate then
    begin
      if not DirectoryExists(ADirectory) then
      begin
        ForceDirectories(ADirectory);
      end;
    end;
  finally
    Result := DirectoryExists(ADirectory);
  end;
end;

procedure QuickFileSearch(const PathName, FileName: string;
  const Recurse: boolean; FileList: TStrings);

var
  LRec: TSearchRec;
  LPath: string;
begin
  LPath := IncludeTrailingPathDelimiter(PathName);
  if FindFirst(LPath + FileName, faAnyFile, LRec) = 0 then
    try
      repeat
        if (LRec.Name <> '.') and (LRec.Name <> '..') then
        begin
          FileList.Add(LPath + LRec.Name);
        end;
      until (FindNext(LRec) <> 0);
    finally
      FindClose(LRec);
    end;

  if (Recurse) then
  begin
    if FindFirst(LPath + '*', faDirectory, LRec) = 0 then
      try
        repeat
          if ((LRec.Attr and faDirectory) = faDirectory) and (LRec.Name <> '.')
            and (LRec.Name <> '..') then
          begin
            QuickFileSearch(LPath + LRec.Name, FileName, true, FileList);
          end;
        until (FindNext(LRec) <> 0);
      finally
        FindClose(LRec);
      end;
  end;
end;

function StripExtraSpaces(AValue: string; ARemoveTab: boolean = False;
  ARemoveCRLF: boolean = False): string;

var
  i: integer;
  Source: string;
begin
  Source := Trim(AValue);

  Source := StringReplace(Source, #160, ' ', [rfReplaceAll]);

  if ARemoveTab then
    Source := StringReplace(Source, #9, ' ', [rfReplaceAll]);
  if ARemoveCRLF then
  begin
    Source := StringReplace(Source, #10, ' ', [rfReplaceAll]);
    Source := StringReplace(Source, #13, ' ', [rfReplaceAll]);
  end;

  if Length(Source) > 1 then
  begin
    Result := Source[1];
    for i := 2 to Length(Source) do
    begin
      if Source[i] = ' ' then
      begin
        if not(Source[i - 1] = ' ') then
          Result := Result + ' ';
      end
      else
      begin
        Result := Result + Source[i];
      end;
    end;
  end
  else
  begin
    Result := Source;
  end;
  Result := Trim(Result);
end;

procedure OpenDefaultBrowser(AURL: string);
var
  URL: string;
  Allow: boolean;
begin
  Allow := true;
  URL := AURL;
  if Allow then
    Allow := Trim(AURL) <> '';
  if Allow then
  begin
    if (Pos('http', URL) = 0) and (Pos('mailto', URL) = 0) and
      (Pos('ftp', URL) = 0) then
    begin
      URL := 'http://' + URL;
    end;
  end;
  if Allow then
  begin
    ExecuteFile(0, 'open', URL, '', GetApplicationDir, SW_SHOWNORMAL);
  end;
end;

end.
