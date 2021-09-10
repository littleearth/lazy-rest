unit LazyRest.Server;

interface

uses
  LazyRest.Types, Winapi.Windows, Winapi.Messages, System.SysUtils,
  System.Variants, System.Classes, System.Types, IdCustomHTTPServer, IdContext,
  IdServerIOHandler, IdServerIOHandlerSocket, IdServerIOHandlerStack,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdHTTPServer, IdScheduler,
  IdSchedulerOfThread, IdSchedulerOfThreadPool, IdSSL, IdSSLOpenSSL, IdCTypes,
  IdSSLOpenSSLHeaders, IdGlobalProtocols;

type
  TLazyRestServer = class(TLazyRestComponent)
  private
    FIdHTTPServer: TIdHTTPServer;
    FIdSchedulerOfThreadPool: TIdSchedulerOfThreadPool;
    FIOHandleSSL: TIdServerIOHandlerSSLOpenSSL;
    FValidateJSON: boolean;
    FServerPort: integer;
    FDataFolder: string;
    FSSLKeyFile: string;
    FSSLEnabled: boolean;
    FSSLCertFile: string;
    FWebFolder: string;
    procedure InternalHTTPServerCommand(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure InternalSSLStatusInfo(const AMsg: String);
    procedure InternalSSLStatusInfoEx(ASender: TObject; const AsslSocket: PSSL;
      const AWhere, Aret: TIdC_INT; const AType, AMsg: String);
    procedure InternalSSLStatus(ASender: TObject; const AStatus: TIdStatus;
      const AStatusText: string);
    procedure InternalQuerySSLPort(APort: Word; var VUseSSL: boolean);
    function InternalSSLVerifyPeer(Certificate: TIdX509; AOk: boolean;
      ADepth, AError: integer): boolean;
    function GetMIMEType(AFilename: TFileName): string;
    function GetRequestedFileName(ADocument, ARootPath: string;
      var AFilename: TFileName): boolean;
    procedure SetWebFolder(const Value: string);
  protected
    procedure FileWebHandler(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
      var Handled: boolean); virtual;
    procedure EndPointWebHandler(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
      var Handled: boolean); virtual;
    procedure ErrorWebHandler(AContext: TIdContext; AErrorMessage: string;
      AErrorCode: integer; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo; var Handled: boolean); virtual;
    procedure ExceptionWebHandler(AContext: TIdContext; AException: Exception;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
      var Handled: boolean); virtual;

    function GetBody(ARequestInfo: TIdHTTPRequestInfo): string;
    function GetBaseFolder: string;
    function GetFileName(AEndPoint: string; var AID: string): string;
    function GetFileList(AEndPoint: string; AFileList: TStrings): boolean;
    function GetEndpoint(ARequestedDocument: string;
      var AEndPoint, AID: string): boolean;
    function IsValidateJSON(var AData: string): boolean;
    function SaveJSON(AEndPoint: string; var AID: string; AJSON: string;
      AParams: TStrings): boolean;
    function LoadJSON(AEndPoint: string; AID: string; var AJSON: string;
      AParams: TStrings): boolean;
    function DeleteJSON(AEndPoint: string; AID: string; var AJSON: string;
      AParams: TStrings): boolean;
    function GetGUID: string;
    procedure SetServerPort(const Value: integer);
    procedure SetValidateJSON(const Value: boolean);
    function GetActive: boolean;
    procedure SetActive(const Value: boolean);
    procedure SetDataFolder(const Value: string);
    procedure SetSSLCertFile(const Value: string);
    procedure SetSSLEnabled(const Value: boolean);
    procedure SetSSLKeyFile(const Value: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ValidateJSON: boolean read FValidateJSON write SetValidateJSON;
    property ServerPort: integer read FServerPort write SetServerPort;
    property Active: boolean read GetActive write SetActive;
    property DataFolder: string read FDataFolder write SetDataFolder;
    property WebFolder: string read FWebFolder write SetWebFolder;
    property SSLEnabled: boolean read FSSLEnabled write SetSSLEnabled;
    property SSLCertFile: string read FSSLCertFile write SetSSLCertFile;
    property SSLKeyFile: string read FSSLKeyFile write SetSSLKeyFile;
  end;

implementation

uses
  LazyRest.Utils, System.StrUtils, System.JSON, System.IOUtils;

constructor TLazyRestServer.Create(AOwner: TComponent);
begin
  inherited;
  FServerPort := 14544;
  FValidateJSON := TRue;
  FDataFolder := IncludeTrailingPathDelimiter(GetApplicationDirAppDataDir
    + 'Data');
  FWebFolder := IncludeTrailingPathDelimiter(GetApplicationDir + 'html');
  FSSLCertFile := IncludeTrailingPathDelimiter(GetApplicationDir +
    'certificates') + 'localhost.crt';
  FSSLKeyFile := IncludeTrailingPathDelimiter(GetApplicationDir +
    'certificates') + 'localhost.key';
  FSSLEnabled := FileExists(FSSLCertFile) and FileExists(FSSLKeyFile);
  FIdHTTPServer := TIdHTTPServer.Create(nil);
  FIdSchedulerOfThreadPool := TIdSchedulerOfThreadPool.Create(FIdHTTPServer);
  FIOHandleSSL := TIdServerIOHandlerSSLOpenSSL.Create(FIdHTTPServer);
  FIdHTTPServer.Scheduler := FIdSchedulerOfThreadPool;
  FIdHTTPServer.ListenQueue := 10000;
  FIdHTTPServer.OnCommandGet := InternalHTTPServerCommand;
  FIdHTTPServer.OnCommandOther := InternalHTTPServerCommand;
  FIdHTTPServer.OnQuerySSLPort := InternalQuerySSLPort;
  FIOHandleSSL.OnStatusInfo := InternalSSLStatusInfo;
  FIOHandleSSL.OnStatusInfoEx := InternalSSLStatusInfoEx;
  FIOHandleSSL.OnStatus := InternalSSLStatus;
  FIOHandleSSL.OnVerifyPeer := InternalSSLVerifyPeer;
end;

procedure TLazyRestServer.InternalQuerySSLPort(APort: Word;
  var VUseSSL: boolean);
begin
  APort := FServerPort;
  VUseSSL := FSSLEnabled;
end;

function TLazyRestServer.GetMIMEType(AFilename: TFileName): string;
begin
  if SameText(ExtractFileExt(AFilename), '.woff') then
  begin
    Result := 'application/x-font-woff';
  end;
  if SameText(ExtractFileExt(AFilename), '.woff2') then
  begin
    Result := 'application/x-font-woff2';
  end;
  if SameText(ExtractFileExt(AFilename), '.js') then
  begin
    Result := 'application/javascript';
  end;
  if IsEmptyString(Result) then
  begin
    Result := GetMIMETypeFromFile(AFilename);
  end;
  if IsEmptyString(Result) then
  begin
    // RFC 7231 https://tools.ietf.org/html/rfc7231#page-11
    Result := '';
  end;
end;

function TLazyRestServer.GetRequestedFileName(ADocument: string;
  ARootPath: string; var AFilename: TFileName): boolean;
begin

  AFilename := ADocument;
  if Length(Trim(AFilename)) > 0 then
  begin
    if AFilename[1] = '/' then
    begin
      Delete(AFilename, 1, 1);
    end;
  end;

  AFilename := StringReplace(AFilename, '/', '\', [rfReplaceAll]);
  AFilename := StringReplace(AFilename, '\\', '\', [rfReplaceAll]);

  AFilename := TPath.Combine(IncludeTrailingPathDelimiter(ARootPath),
    AFilename);

  if DirectoryExists(AFilename) then
  begin
    AFilename := IncludeTrailingPathDelimiter(AFilename);
    if FileExists(AFilename + 'index.html') then
      AFilename := AFilename + 'index.html'
    else if FileExists(AFilename + 'index.htm') then
      AFilename := AFilename + 'index.htm'
    else if FileExists(AFilename + 'default.htm') then
      AFilename := AFilename + 'default.htm'
    else if FileExists(AFilename + 'default.html') then
      AFilename := AFilename + 'default.html';
  end;

  AFilename := TPath.GetFullPath(AFilename);

  Result := ContainsText(AFilename, ARootPath) and FileExists(AFilename);

end;

function TLazyRestServer.DeleteJSON(AEndPoint, AID: string; var AJSON: string;
  AParams: TStrings): boolean;
var
  LFileName, LSoftDeleteFileName: TFileName;
  LFiles: TStringList;
  LSoftDelete: boolean;
  LDeleted: boolean;
begin
  AJSON := '';
  LFiles := TStringList.Create;
  try
    LFiles.Duplicates := dupIgnore;
    LFiles.Sorted := TRue;
    if IsEmptyString(AID) then
    begin
      GetFileList(AEndPoint, LFiles);
    end
    else
    begin
      LFileName := GetFileName(AEndPoint, AID);
      LFiles.Add(LFileName);
    end;

    LSoftDelete := False;
    if Assigned(AParams) then
    begin
      LSoftDelete := SameText(AParams.Values['softdelete'], 'true');
    end;

    for LFileName in LFiles do
    begin
      if FileExists(LFileName) then
      begin
        if LSoftDelete then
        begin
          LSoftDeleteFileName := ChangeFileExt(LFileName, '.del');
          if FileExists(LSoftDeleteFileName) then
            DeleteFile(LSoftDeleteFileName);
          LDeleted := RenameFile(LFileName, LSoftDeleteFileName);
        end
        else
        begin
          LDeleted := DeleteFile(LFileName);
        end;

        if LDeleted then
        begin
          if not IsEmptyString(AJSON) then
          begin
            AJSON := AJSON + ',';
          end;
          AJSON := AJSON + format('{ "id":"%s" }',
            [ChangeFileExt(ExtractFileName(LFileName), '')]);
        end;
      end;
    end;

    if IsEmptyString(AJSON) then
    begin
      Result := False;
    end
    else
    begin
      if LFiles.Count > 1 then
      begin
        AJSON := '[' + AJSON + ']';
      end;
      Result := TRue;
    end;

  finally
    FreeAndNil(LFiles);
  end;
end;

destructor TLazyRestServer.Destroy;
begin
  try
    SetActive(False);
    FreeAndNil(FIdHTTPServer)
  finally
    inherited;
  end;
end;

function TLazyRestServer.GetActive: boolean;
begin
  Result := FIdHTTPServer.Active;
end;

function TLazyRestServer.GetBaseFolder: string;
begin
  Result := IncludeTrailingPathDelimiter(FDataFolder);
  if not CheckDirectoryExists(Result, TRue) then
  begin
    raise EFileNotFoundException.CreateFmt('Directory "%s" does not exist',
      [Result]);
  end;
end;

function TLazyRestServer.IsValidateJSON(var AData: string): boolean;
var
  LJSONObject: TJSONObject;
begin
  Result := False;
  if FValidateJSON then
  begin
    LJSONObject := nil;
    try
      try
        LJSONObject := TJSONObject.ParseJSONValue
          (TEncoding.ASCII.GetBytes(AData), 0) as TJSONObject;
        AData := LJSONObject.format;
        Result := not IsEmptyString(AData);
      except
        on E: Exception do
        begin
          Error('JSON validation failure, JSON: ' + AData);
        end;
      end;
    finally
      if Assigned(LJSONObject) then
        LJSONObject.Free;
    end;
  end
  else
  begin
    Result := TRue;
  end;
end;

function TLazyRestServer.GetFileList(AEndPoint: string;
  AFileList: TStrings): boolean;
begin
  QuickFileSearch(IncludeTrailingPathDelimiter(GetBaseFolder + AEndPoint),
    '*.json', False, AFileList);
  Result := AFileList.Count > 0;
end;

function TLazyRestServer.GetGUID: string;
begin
  Result := TGUID.NewGuid.ToString();
  Result := StringReplace(Result, '{', '', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '', [rfReplaceAll]);
end;

function TLazyRestServer.GetFileName(AEndPoint: string;
  var AID: string): string;
var
  LFolder: string;
begin
  if IsEmptyString(AID) then
  begin
    AID := GetGUID;
  end;
  LFolder := IncludeTrailingPathDelimiter(GetBaseFolder + AEndPoint);
  if CheckDirectoryExists(LFolder, TRue) then
  begin
    Result := LFolder + ChangeFileExt(AID, '.json');
  end
  else
  begin
    raise EFileNotFoundException.CreateFmt('Directory "%s" does not exist',
      [LFolder]);
  end;
end;

function TLazyRestServer.GetBody(ARequestInfo: TIdHTTPRequestInfo): string;
var
  LMemoryStream: TStringStream;
begin
  LMemoryStream := TStringStream.Create;
  try
    LMemoryStream.LoadFromStream(ARequestInfo.PostStream);
    Result := LMemoryStream.DataString;
  finally
    LMemoryStream.Free;
  end;
end;

function TLazyRestServer.GetEndpoint(ARequestedDocument: string;
  var AEndPoint: string; var AID: string): boolean;
var
  LData: TStringDynArray;
begin
  AEndPoint := Copy(ARequestedDocument, 2, Length(ARequestedDocument)) + '/';
  LData := SplitString(AEndPoint, '/');
  if Length(LData) > 0 then
  begin
    AEndPoint := LData[0];
  end;
  if Length(LData) > 1 then
  begin
    AID := LData[1];
  end;
  Result := not IsEmptyString(AEndPoint);
end;

procedure TLazyRestServer.FileWebHandler(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
  var Handled: boolean);
var
  LRequestedDocument: String;
  LFileName: TFileName;
  LContentType: string;
  LFileStream: TFileStream;
begin
  Handled := False;

  LRequestedDocument := ARequestInfo.Document;

  if (ARequestInfo.CommandType = hcGET) and
    GetRequestedFileName(LRequestedDocument, FWebFolder, LFileName) then
  begin
    LContentType := GetMIMEType(LFileName);
    LFileStream := TFileStream.Create(LFileName, fmOpenRead + fmShareDenyWrite);
    AResponseInfo.ContentType := LContentType;
    AResponseInfo.ContentStream := LFileStream;
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentLength := LFileStream.Size;
    Handled := TRue;
  end;

end;

procedure TLazyRestServer.EndPointWebHandler(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
  var Handled: boolean);
var
  LRequestedDocument, LBody, LEndPoint, LID, LResponseText,
    LResponseContent: string;
  LResponseNo: integer;
begin
  Handled := False;
  LResponseNo := 200;
  LResponseText := 'Ok';
  LResponseContent := '';
  LRequestedDocument := ARequestInfo.Document;
  if GetEndpoint(LRequestedDocument, LEndPoint, LID) then
  begin

    if Assigned(ARequestInfo.PostStream) then
    begin
      LBody := GetBody(ARequestInfo);
    end;

    case ARequestInfo.CommandType of
      hcGET:
        begin
          if LoadJSON(LEndPoint, LID, LBody, ARequestInfo.Params) then
          begin
            LResponseContent := LBody;
          end
          else
          begin
            LResponseNo := 400;
            LResponseText := 'Bad Request';
            LResponseContent := '{"Error": " Failed to load ' + LID + '"}';
          end;
        end;
      hcPOST, hcPUT:
        begin
          if ARequestInfo.CommandType = hcPOST then
          begin
            LID := ARequestInfo.Params.Values['id'];
          end;
          if SaveJSON(LEndPoint, LID, LBody, ARequestInfo.Params) then
          begin
            LResponseContent := '{"id": "' + LID + '"}';
          end
          else
          begin
            LResponseNo := 400;
            LResponseText := 'Bad Request';
            LResponseContent := '{"Error": "Invalid JSON"}';
          end;
        end;
      hcDELETE:
        begin
          if DeleteJSON(LEndPoint, LID, LBody, ARequestInfo.Params) then
          begin
            LResponseContent := LBody;
          end
          else
          begin
            LResponseNo := 400;
            LResponseText := 'Bad Request';
            LResponseContent := '{"Error": " Failed to delete ' + LID + '"}';
          end;
        end;
    end;
    AResponseInfo.ResponseNo := LResponseNo;
    AResponseInfo.ResponseText := LResponseText;
    AResponseInfo.ContentType := 'application/json';
    AResponseInfo.ContentText := LResponseContent;
    Handled := TRue;
  end;
end;

procedure TLazyRestServer.ErrorWebHandler(AContext: TIdContext;
  AErrorMessage: string; AErrorCode: integer; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo; var Handled: boolean);
begin
  AResponseInfo.ResponseNo := AErrorCode;
  AResponseInfo.ResponseText := 'Error';
  AResponseInfo.ContentType := 'application/json';
  AResponseInfo.ContentText := format('{"Error":"%s"}', [AErrorMessage]);
  Handled := TRue;
end;

procedure TLazyRestServer.ExceptionWebHandler(AContext: TIdContext;
  AException: Exception; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo; var Handled: boolean);
begin
  ErrorWebHandler(AContext, AException.Message, 500, ARequestInfo,
    AResponseInfo, Handled);
end;

procedure TLazyRestServer.InternalHTTPServerCommand(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LHandled: boolean;
begin
  try
    Log('IP: %s, Command: %s, URL: %s, Params: %s, ContentEncoding: %s, ContentType: %s, ContentLength: %d',
      [ARequestInfo.RemoteIP, ARequestInfo.Command, ARequestInfo.URI,
      ARequestInfo.Params.Text, ARequestInfo.ContentEncoding,
      ARequestInfo.ContentType, ARequestInfo.ContentLength]);

    LHandled := False;

    if Copy(ARequestInfo.Document, 1, 1) <> '/' then
    begin
      ErrorWebHandler(AContext, format('Invalid request',
        [ARequestInfo.Document]), 400, ARequestInfo, AResponseInfo, LHandled);
    end;

    if not LHandled then
    begin
      FileWebHandler(AContext, ARequestInfo, AResponseInfo, LHandled);
    end;

    if not LHandled then
    begin
      EndPointWebHandler(AContext, ARequestInfo, AResponseInfo, LHandled);
    end;

  except
    on E: Exception do
    begin
      Error(E, 'Error during data handling');
      ExceptionWebHandler(AContext, E, ARequestInfo, AResponseInfo, LHandled);
    end;
  end;

  if not LHandled then
  begin
    ErrorWebHandler(AContext, format('Web request failed',
      [ARequestInfo.Document]), 500, ARequestInfo, AResponseInfo, LHandled);
  end;

end;

procedure TLazyRestServer.InternalSSLStatus(ASender: TObject;
  const AStatus: TIdStatus; const AStatusText: string);
begin
  Log('SSLStatus: ' + AStatusText);
end;

procedure TLazyRestServer.InternalSSLStatusInfo(const AMsg: String);
begin
  // Log('SSLStatusInfo', AMsg);
end;

procedure TLazyRestServer.InternalSSLStatusInfoEx(ASender: TObject;
  const AsslSocket: PSSL; const AWhere, Aret: TIdC_INT;
  const AType, AMsg: String);
begin
  // Log('SSLStatusInfoEx', AType + AMsg);
end;

function TLazyRestServer.InternalSSLVerifyPeer(Certificate: TIdX509;
  AOk: boolean; ADepth, AError: integer): boolean;
begin
  Result := TRue;
end;

function TLazyRestServer.LoadJSON(AEndPoint, AID: string; var AJSON: string;
  AParams: TStrings): boolean;
var
  LFileName: TFileName;
  LFiles: TStringList;
  LFileContent: TStringList;
  LJSON, LSearch: string;
  LCount, LIdx, LOffset, LLimit: integer;
  LAddRecord: boolean;
begin
  AJSON := '';
  LFiles := TStringList.Create;
  LFileContent := TStringList.Create;
  try
    LFiles.Duplicates := dupIgnore;
    LFiles.Sorted := TRue;
    if IsEmptyString(AID) then
    begin
      GetFileList(AEndPoint, LFiles);
    end
    else
    begin
      LFileName := GetFileName(AEndPoint, AID);
      LFiles.Add(LFileName);
    end;

    LCount := 0;
    LOffset := 0;
    LLimit := LFiles.Count;
    LSearch := '';
    if Assigned(AParams) then
    begin
      LOffset := StrToIntDef(AParams.Values['offset'], 0);
      LLimit := StrToIntDef(AParams.Values['limit'], LLimit);
      if LOffset > 0 then
      begin
        LLimit := LOffset + LLimit;
      end;
      if LLimit > LFiles.Count then
      begin
        LLimit := LFiles.Count;
      end;
      LSearch := AParams.Values['search'];
    end;

    for LIdx := LOffset to (LLimit - 1) do
    begin
      LFileName := LFiles[LIdx];
      if FileExists(LFileName) then
      begin
        LFileContent.LoadFromFile(LFileName);
        LJSON := LFileContent.Text;
        LAddRecord := IsValidateJSON(LJSON);
        if LAddRecord then
        begin
          if not IsEmptyString(LSearch) then
          begin
            LAddRecord := ContainsText(LJSON, LSearch);
          end;
        end;
        if LAddRecord then
        begin
          if LCount > 0 then
          begin
            AJSON := AJSON + ',';
          end;
          AJSON := AJSON + LJSON;
          Inc(LCount);
        end;
      end;
    end;

    if LCount > 1 then
    begin
      AJSON := '[' + #13#10 + Trim(AJSON) + #13#10 + ']';
    end;

    if IsEmptyString(AJSON) then
    begin
      if IsEmptyString(AID) then
      begin
        AJSON := '[]';
        Result := TRue;
      end
      else
      begin
        Result := False;
      end;
    end
    else
    begin
      Result := TRue;
    end;

  finally
    FreeAndNil(LFileContent);
    FreeAndNil(LFiles);
  end;
end;

function TLazyRestServer.SaveJSON(AEndPoint: string; var AID: string;
  AJSON: string; AParams: TStrings): boolean;
var
  LFileName: TFileName;
  LFileContent: TStringList;
  LAddRecord, LValidateJSON: boolean;
begin
  Result := False;
  LFileName := GetFileName(AEndPoint, AID);
  LFileContent := TStringList.Create;
  try
    LValidateJSON := FValidateJSON;
    if Assigned(AParams) then
    begin
      if not IsEmptyString(AParams.Values['validatejson']) then
      begin
        LValidateJSON := SameText(AParams.Values['validatejson'], 'true');
      end;
    end;
    LAddRecord := TRue;
    if LValidateJSON then
    begin
      LAddRecord := IsValidateJSON(AJSON);
    end;
    if LAddRecord then
    begin
      LFileContent.Text := AJSON;
      LFileContent.SaveToFile(LFileName);
      Result := FileExists(LFileName);
    end;
  finally
    FreeAndNil(LFileContent);
  end;
end;

procedure TLazyRestServer.SetActive(const Value: boolean);
begin
  if Value <> FIdHTTPServer.Active then
  begin
    try
      if Value then
      begin
        FIdHTTPServer.Active := False;
        FIdHTTPServer.IOHandler := nil;
        FIOHandleSSL.SSLOptions.CertFile := SSLCertFile;
        FIOHandleSSL.SSLOptions.KeyFile := SSLKeyFile;
        // FIOHandleSSL.SSLOptions.RootCertFile := SSLRootCertFile;
        FIOHandleSSL.SSLOptions.Mode := sslmServer;
        FIOHandleSSL.SSLOptions.VerifyMode := [];
        FIOHandleSSL.SSLOptions.VerifyDepth := 0;
        // FIOHandleSSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
        // FIOHandleSSL.SSLOptions.SSLVersions :=
        // [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
        FIOHandleSSL.SSLOptions.Method := sslvTLSv1_2;
        if FSSLEnabled then
        begin
          Log('SSL Enabled, Cert: %s, Key: %s', [SSLCertFile, SSLKeyFile]);
          FIdHTTPServer.IOHandler := FIOHandleSSL;
        end;
        FIdHTTPServer.Bindings.Clear;
        FIdHTTPServer.DefaultPort := FServerPort;
        Log('Starting LazyREST server on port %d', [FIdHTTPServer.DefaultPort]);
        FIdHTTPServer.Active := TRue;
      end
      else
      begin
        Log('Stopping LazyREST server on port %d', [FIdHTTPServer.DefaultPort]);
        FIdHTTPServer.Active := False;
      end;
    except
      on E: Exception do
      begin
        Error(E, format('Server port %d', [FIdHTTPServer.DefaultPort]));
      end;
    end;
  end;
end;

procedure TLazyRestServer.SetDataFolder(const Value: string);
begin
  FDataFolder := Value;
end;

procedure TLazyRestServer.SetServerPort(const Value: integer);
var
  LActive: boolean;
begin
  if Value <> FServerPort then
  begin
    LActive := GetActive;
    if LActive then
    begin
      SetActive(False);
    end;
    FServerPort := Value;
    if LActive then
    begin
      SetActive(TRue);
    end;
  end;
end;

procedure TLazyRestServer.SetSSLCertFile(const Value: string);
begin
  FSSLCertFile := Value;
end;

procedure TLazyRestServer.SetSSLEnabled(const Value: boolean);
begin
  FSSLEnabled := Value;
end;

procedure TLazyRestServer.SetSSLKeyFile(const Value: string);
begin
  FSSLKeyFile := Value;
end;

procedure TLazyRestServer.SetValidateJSON(const Value: boolean);
begin
  FValidateJSON := Value;
end;

procedure TLazyRestServer.SetWebFolder(const Value: string);
begin
  FWebFolder := Value;
end;

end.
