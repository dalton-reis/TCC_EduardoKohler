program Stereograma;

uses
  Forms,
  UStereo in 'UStereo.pas' {frmEstereograma},
  USplash in 'USplash.pas' {FSplash},
  Usirds in 'Usirds.pas' {frmSIRDS},
  USobre in 'USobre.pas' {frmSobre};

{$R *.RES}

begin
  Application.Initialize;
  FSplash :=TFSplash.Create(Application);
  FSplash.Show;
  FSplash.Update;
  Application.CreateForm(TfrmEstereograma, frmEstereograma);
  Application.CreateForm(TfrmSIRDS, frmSIRDS);
  Application.CreateForm(TfrmSobre, frmSobre);
  FSplash.Hide;
  FSplash.Free;
  Application.Run;

end.
