program LazyREST;

{$R 'version.res' 'version.rc'}

uses
  Vcl.Forms,
  frmLazyRestU in 'frmLazyRestU.pas' {frmLazyRest},
  LazyRest.Server in 'LazyRest.Server.pas',
  LazyRest.Utils in 'LazyRest.Utils.pas',
  LazyRest.Types in 'LazyRest.Types.pas',
  LazyRest.Log.Basic in 'LazyRest.Log.Basic.pas',
  LazyRest.Log in 'LazyRest.Log.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  SetLazyRestLogClass(TLazyRestLogBasic);
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'LazyREST';
  TStyleManager.TrySetStyle('Windows10');
  Application.CreateForm(TfrmLazyRest, frmLazyRest);
  Application.Run;

end.
