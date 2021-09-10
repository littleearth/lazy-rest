unit frmLazyRestU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Types, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, System.Actions,
  Vcl.ActnList, Vcl.Buttons, LazyRest.Server, Vcl.Mask, JvExMask, JvToolEdit,
  Vcl.Imaging.pngimage, Vcl.ComCtrls, Vcl.Menus, JvComponentBase, JvTrayIcon,
  System.ImageList, Vcl.ImgList, System.UITypes;

type
  TfrmLazyRest = class(TForm)
    ActionList: TActionList;
    ActionStartStop: TAction;
    pnlControl: TPanel;
    btnClearData: TBitBtn;
    LogTimer: TTimer;
    Panel4: TPanel;
    PageControlMain: TPageControl;
    tabOptions: TTabSheet;
    tabLog: TTabSheet;
    memoLog: TMemo;
    imgLogo: TImage;
    btnStartStop: TBitBtn;
    ActionBrowseData: TAction;
    ActionClearData: TAction;
    btnBrowseData: TBitBtn;
    ScrollBoxOptions: TScrollBox;
    pnlOptionsGrid: TGridPanel;
    pnlServerPort: TPanel;
    Label1: TLabel;
    editHTTPPort: TEdit;
    pnlDataFolder: TPanel;
    Label2: TLabel;
    editDataFolder: TJvDirectoryEdit;
    StatusBar: TStatusBar;
    pnlOtherOptions: TPanel;
    cbValidateJSON: TCheckBox;
    Panel1: TPanel;
    Label3: TLabel;
    Panel2: TPanel;
    Label4: TLabel;
    editSSLCertificate: TJvFilenameEdit;
    editSSLKeyFile: TJvFilenameEdit;
    cbSSLEnabled: TCheckBox;
    TrayIcon: TJvTrayIcon;
    PopupMenuTrayIcon: TPopupMenu;
    Start1: TMenuItem;
    ActionExit: TAction;
    btnExit: TBitBtn;
    ImageList: TImageList;
    Exit1: TMenuItem;
    N1: TMenuItem;
    ActionOpenBrowser: TAction;
    btnOpenBrowser: TBitBtn;
    OpenBrowser1: TMenuItem;
    procedure ActionBrowseDataExecute(Sender: TObject);
    procedure ActionClearDataExecute(Sender: TObject);
    procedure ActionExitExecute(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure ActionOpenBrowserExecute(Sender: TObject);
    procedure ActionStartStopExecute(Sender: TObject);
    procedure ActionStartStopUpdate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LogTimerTimer(Sender: TObject);
  private
    FApplicationActive: Boolean;
    FLazyRestServer: TLazyRestServer;
    function GetLogCache: string;
  public
    { Public declarations }
  end;

var
  frmLazyRest: TfrmLazyRest;

implementation

{$R *.dfm}

uses
  System.StrUtils, System.Json, LazyRest.Log, LazyRest.Log.Basic,
  LazyRest.Utils;

procedure TfrmLazyRest.ActionBrowseDataExecute(Sender: TObject);
var
  LFolder: string;
begin
  LFolder := editDataFolder.Directory;
  if CheckDirectoryExists(LFolder, false) then
  begin
    OpenFolder(Self.Handle, LFolder);
  end
  else
  begin
    MessageDlg(Format('Directory "%s" does not exist', [LFolder]),
      TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
  end;
end;

procedure TfrmLazyRest.ActionClearDataExecute(Sender: TObject);
var
  LFolder: string;
begin
  LFolder := editDataFolder.Directory;
  if CheckDirectoryExists(LFolder, false) then
  begin
    DeleteFolder(Self.Handle, LFolder);
  end
  else
  begin
    MessageDlg(Format('Directory "%s" does not exist', [LFolder]),
      TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
  end;
end;

procedure TfrmLazyRest.ActionExitExecute(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmLazyRest.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  pnlOptionsGrid.Enabled := not FLazyRestServer.Active;
end;

procedure TfrmLazyRest.ActionOpenBrowserExecute(Sender: TObject);
var
  LURL: string;
begin
  if FLazyRestServer.Active then
  begin
    LURL := 'http://';
    if FLazyRestServer.SSLEnabled then
    begin
      LURL := 'https://';
    end;
    LURL := LURL + Format('localhost:%d', [FLazyRestServer.ServerPort]);
    OpenDefaultBrowser(LURL);
  end;
end;

procedure TfrmLazyRest.ActionStartStopExecute(Sender: TObject);
begin
  if FLazyRestServer.Active then
  begin
    FLazyRestServer.Active := false;
  end
  else
  begin
    FLazyRestServer.ValidateJSON := cbValidateJSON.Checked;
    FLazyRestServer.ServerPort := StrToIntDef(editHTTPPort.Text, 14544);
    FLazyRestServer.SSLEnabled := cbSSLEnabled.Checked;
    FLazyRestServer.SSLCertFile := editSSLCertificate.FileName;
    FLazyRestServer.SSLKeyFile := editSSLKeyFile.FileName;
    FLazyRestServer.Active := True;
  end;
end;

procedure TfrmLazyRest.ActionStartStopUpdate(Sender: TObject);
begin
  if FLazyRestServer.Active then
  begin
    ActionStartStop.Caption := 'Stop';
    ActionStartStop.ImageIndex := 1;
  end
  else
  begin
    ActionStartStop.Caption := 'Start';
    ActionStartStop.ImageIndex := 0;
  end;
end;

procedure TfrmLazyRest.FormActivate(Sender: TObject);
begin
  if not FApplicationActive then
  begin
    FApplicationActive := True;
    ActionStartStop.Execute;
    LogTimerTimer(Sender);
  end;
end;

procedure TfrmLazyRest.FormCreate(Sender: TObject);
begin
  FApplicationActive := false;
  FLazyRestServer := TLazyRestServer.Create(Self);
  editDataFolder.Directory := FLazyRestServer.DataFolder;
  editHTTPPort.Text := IntToStr(FLazyRestServer.ServerPort);
  cbSSLEnabled.Enabled := FLazyRestServer.SSLEnabled;
  editSSLCertificate.FileName := FLazyRestServer.SSLCertFile;
  editSSLKeyFile.FileName := FLazyRestServer.SSLKeyFile;
  memoLog.Lines.Clear;
  PageControlMain.ActivePageIndex := 0;
end;

function TfrmLazyRest.GetLogCache: string;
begin
  if (_LazyRestLog is TLazyRestLogBasic) then
  begin
    Result := (_LazyRestLog as TLazyRestLogBasic).LogCache;
  end;
end;

procedure TfrmLazyRest.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FLazyRestServer.Active then
    ActionStartStop.Execute;
end;

procedure TfrmLazyRest.FormShow(Sender: TObject);
begin
  btnStartStop.SetFocus;
end;

procedure TfrmLazyRest.LogTimerTimer(Sender: TObject);
begin
  memoLog.Lines.BeginUpdate;
  try
    memoLog.Lines.Text := GetLogCache;
    if FLazyRestServer.Active then
    begin
      if memoLog.Lines.Count > 0 then
      begin
        StatusBar.Panels[1].Text := memoLog.Lines[0];
      end
      else
      begin
        StatusBar.Panels[1].Text := 'Online';
      end;
    end
    else
    begin
      StatusBar.Panels[1].Text := 'Offline';
    end;
  finally
    memoLog.Lines.EndUpdate;
  end;
end;

end.
