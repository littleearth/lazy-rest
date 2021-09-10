unit LazyRest.Log.Basic;

interface

uses
  SysUtils, Classes, LazyRest.Log, LazyRest.Types;

type
  TLazyRestLogBasic = class(TLazyRestLog)
  private
    FLog: TThreadStringList;
  protected
    procedure LogMessage(ALogLevel: TLogLevel; AMessage: string);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Log(ASender: TObject; AMessage: string); override;
    procedure Debug(ASender: TObject; AProcedure: string;
      AMessage: string); override;
    procedure Warning(ASender: TObject; AMessage: string); override;
    procedure Error(ASender: TObject; AMessage: string;
      AErrorCode: integer = 0); overload; override;
    procedure Error(ASender: TObject; AException: Exception;
      AMessage: string = ''); overload; override;
    function LogText: string;
    function LogCache(ALimit: integer = 100): string;
  end;

var
  LazyRestLogBasicCapacity: integer = 10000;

implementation

uses
  LazyRest.Utils;

{ TLazyRestLogBasic }

procedure TLazyRestLogBasic.AfterConstruction;
begin
  inherited;
  FLog := TThreadStringList.Create;
  FLog.Sorted := False;
end;

procedure TLazyRestLogBasic.BeforeDestruction;
begin
  inherited;
  FreeAndNil(FLog);
end;

procedure TLazyRestLogBasic.Debug(ASender: TObject;
  AProcedure, AMessage: string);
begin
  LogMessage(logDebug, Format('[%s] %s', [AProcedure, AMessage]));
end;

procedure TLazyRestLogBasic.Error(ASender: TObject; AException: Exception;
  AMessage: string);
begin
  LogMessage(logError, Format('%s %s', [AException.Message, AMessage]));
end;

procedure TLazyRestLogBasic.Error(ASender: TObject; AMessage: string;
  AErrorCode: integer);
begin
  LogMessage(logError, Format('(%d) %s', [AErrorCode, AMessage]));
end;

procedure TLazyRestLogBasic.Log(ASender: TObject; AMessage: string);
begin
  LogMessage(logInformation, AMessage);

end;

function TLazyRestLogBasic.LogCache(ALimit: integer): string;
var
  LLimit: integer;
  Lidx: integer;
begin
  Result := '';
  LLimit := ALimit;
  if LLimit > (FLog.Count - 1) then
    LLimit := FLog.Count - 1;
  for Lidx := 0 to LLimit do
  begin
    Result := Result + FLog[Lidx] + #13#10;
  end;
end;

procedure TLazyRestLogBasic.LogMessage(ALogLevel: TLogLevel; AMessage: string);
begin
  try
    if IsLogLevel(ALogLevel) then
    begin
      FLog.Insert(0, StripExtraSpaces(FormatDateTime('yyyymmddhhnn', Now) + ':'
        + GetLogLevelText(ALogLevel) + ':' + AMessage, true, true));
    end;
    while FLog.Count > LazyRestLogBasicCapacity do
    begin
      FLog.Delete(FLog.Count - 1);
    end;
  except
  end;
end;

function TLazyRestLogBasic.LogText: string;
begin
  try
    if Assigned(FLog) then
      Result := FLog.Text;
  except
    Result := '';
  end;
end;

procedure TLazyRestLogBasic.Warning(ASender: TObject; AMessage: string);
begin
  LogMessage(logWarning, AMessage);
end;

end.
