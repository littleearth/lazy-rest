unit LazyRest.Log;

interface

uses
  SysUtils, Classes, LazyRest.Types;

type
  TLazyRestLog = class(TObject)
  private
    FLogLevel: TLogLevel;
    procedure SetLogLevel(const Value: TLogLevel);
  protected
    procedure OutputToDebugger(const AMessage: String);
    function GetLogLevelText(ALogLevel: TLogLevel): string;
    function IsLogLevel(ALogLevel: TLogLevel): boolean;
  public
    constructor Create;
    procedure Log(ASender: TObject; AMessage: string); virtual;
    procedure Debug(ASender: TObject; AProcedure: string;
      AMessage: string); virtual;
    procedure Warning(ASender: TObject; AMessage: string); virtual;
    procedure Error(ASender: TObject; AMessage: string;
      AErrorCode: integer = 0); overload; virtual;
    procedure Error(ASender: TObject; AException: Exception;
      AMessage: string = ''); overload; virtual;
    property LogLevel: TLogLevel read FLogLevel write SetLogLevel;
  end;

  TLazyRestLogClass = class of TLazyRestLog;

var
  _LazyRestLog: TLazyRestLog;
  _LazyRestLogClass: TLazyRestLogClass;

procedure SetLazyRestLogClass(ALazyRestLogClass: TLazyRestLogClass);
procedure InitLazyRestLog;
function LazyRestLog: TLazyRestLog;

implementation

uses
  Winapi.Windows;

{ TLazyRestLog }

procedure TLazyRestLog.OutputToDebugger(const AMessage: String);
begin
  OutputDebugString(PChar(AMessage))
end;

procedure TLazyRestLog.SetLogLevel(const Value: TLogLevel);
begin
  FLogLevel := Value;
end;

constructor TLazyRestLog.Create;
begin
  inherited;
{$IFDEF DEBUG}
  FLogLevel := logDebug;
{$ELSE}
  FLogLevel := logInformation;
{$ENDIF}
end;

procedure TLazyRestLog.Debug(ASender: TObject; AProcedure, AMessage: string);
begin
{$IFDEF DEBUG}
  OutputToDebugger('DEBUG:' + AProcedure + ': ' + AMessage);
{$ENDIF}
end;

procedure TLazyRestLog.Error(ASender: TObject; AException: Exception;
  AMessage: string);
begin
{$IFDEF DEBUG}
  OutputToDebugger('ERROR:' + AException.Message + ': ' + AMessage);
{$ENDIF}
end;

function TLazyRestLog.GetLogLevelText(ALogLevel: TLogLevel): string;
begin
  case ALogLevel of
    logDebug:
      Result := 'DEBUG';
    logInformation:
      Result := 'INFO';
    logWarning:
      Result := 'WARN';
  else
    begin
      Result := 'ERROR';
    end;
  end;
end;

function TLazyRestLog.IsLogLevel(ALogLevel: TLogLevel): boolean;
begin
  Result := (ord(ALogLevel) <= ord(FLogLevel));
end;

procedure TLazyRestLog.Error(ASender: TObject; AMessage: string;
  AErrorCode: integer);
begin
{$IFDEF DEBUG}
  OutputToDebugger('ERROR:' + IntToStr(AErrorCode) + ': ' + AMessage);
{$ENDIF}
end;

procedure TLazyRestLog.Log(ASender: TObject; AMessage: string);
begin
{$IFDEF DEBUG}
  OutputToDebugger('LOG:' + AMessage);
{$ENDIF}
end;

procedure TLazyRestLog.Warning(ASender: TObject; AMessage: string);
begin
{$IFDEF DEBUG}
  OutputToDebugger('WARN:' + AMessage);
{$ENDIF}
end;

procedure SetLazyRestLogClass(ALazyRestLogClass: TLazyRestLogClass);
begin
  _LazyRestLogClass := ALazyRestLogClass;
  try
    try
      if Assigned(_LazyRestLog) then
      begin
        FreeAndNil(_LazyRestLog);
      end;
    except
    end;
  finally
    _LazyRestLog := nil;
  end;
end;

procedure InitLazyRestLog;
begin
  if Assigned(_LazyRestLog) then
  begin
    FreeAndNil(_LazyRestLog);
  end;
  if not Assigned(_LazyRestLog) then
  begin
    if Assigned(_LazyRestLogClass) then
    begin
      _LazyRestLog := _LazyRestLogClass.Create;
    end
    else
    begin
      _LazyRestLog := TLazyRestLog.Create;
    end;
  end;
end;

function LazyRestLog: TLazyRestLog;
begin
  Result := nil;
  if not Assigned(_LazyRestLog) then
  begin
    InitLazyRestLog;
  end;
  if Assigned(_LazyRestLog) then
  begin
    Result := _LazyRestLog;
  end;
end;

initialization

SetLazyRestLogClass(nil);

finalization

SetLazyRestLogClass(nil);

end.
