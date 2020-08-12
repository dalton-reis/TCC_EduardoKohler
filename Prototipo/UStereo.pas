unit UStereo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Buttons, Spin, ComCtrls, ExtDlgs, Usirds, Gauges;

type
  TfrmEstereograma = class(TForm)
    rgCor: TRadioGroup;
    Panel1: TPanel;
    Panel2: TPanel;
    Imagem: TImage;
    Panel3: TPanel;
    Label1: TLabel;
    seOcorr: TSpinEdit;
    Label2: TLabel;
    dgAbrirArquivo: TOpenPictureDialog;
    Label3: TLabel;
    Label4: TLabel;
    seProf: TSpinEdit;
    Panel4: TPanel;
    lbMensagem: TLabel;
    gbAlgoritmo: TGroupBox;
    cbAlgo1: TCheckBox;
    cbAlgo2: TCheckBox;
    btCena: TSpeedButton;
    btGerar: TSpeedButton;
    btSobre: TSpeedButton;
    btSair: TSpeedButton;
    ggBarra: TGauge;
    Label5: TLabel;
    lbLargura: TLabel;
    lbAltura: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lbComplementar: TLabel;
    procedure btSairClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbAlgo1Click(Sender: TObject);
    procedure btCenaClick(Sender: TObject);
    procedure btGerarClick(Sender: TObject);
    procedure btSobreClick(Sender: TObject);
    procedure btEncerrarClick(Sender: TObject);
    procedure btCenaMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormActivate(Sender: TObject);
    procedure btGerarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure btSairMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure btSobreMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GerarMatrizRandomica;
    procedure ArmazenarMapaProfundidade;
    procedure GerarEstereograma1(Nome_Arquivo:string; NroCam: byte);
    procedure GerarEstereograma2(Nome_Arquivo:string);
    function MontaLinha(x:Integer; y:Integer; Cor:dword):string;
    procedure Cria_Arquivo_Geral(N:Byte);
    procedure Cria_Arquivo_Diferenca;
  end;

const
  Largura=640;
  Altura=480;
  Resolucao=75;
  Separacao=2.5; {Separacao fisica entre os olhos em polegadas}

var
  frmEstereograma: TfrmEstereograma;
  Matriz_Rand: array [0..Largura-1,0..Altura-1] of dword;
  Mapa_Prof: array [0..Largura-1,0..Altura-1] of byte;

implementation

uses USobre;

{$R *.DFM}

{Procedure que armazena valores aleatorios na Matriz Randomica}
procedure TfrmEstereograma.gerarMatrizRandomica;
var
  x,y: integer;
  cinza: byte;
begin
  randomize;
  for y:=0 to Altura-1 do
  begin
    for x:=0 to Largura-1 do
    begin
      {Se o estereograma será em escala de cinza}
      if rgCor.ItemIndex = 0 then
      begin
        cinza:=random(256);
        Matriz_Rand[x,y]:= RGB(cinza,cinza,cinza);
      end
      else {Se o estereograma será colorido}
        Matriz_Rand[x,y]:= random(16777216);
    end;
    ggBarra.Progress:= ggBarra.Progress+1;
  end;
end;

{Procedimento que Cria o mapa de profundidade}
procedure TfrmEstereograma.ArmazenarMapaProfundidade;
var
  x,y: integer;
  R,G,B, cinza: byte;
  cor: dword;
begin
  for y:=0 to Altura - 1 do
  begin
    for x:=0 to Largura - 1 do
    begin
       {Busca o valor RGB do ponto em questao}
       Cor:=Imagem.Canvas.Pixels[x,y];

       {Separa os valores R, G, B da Cor}
       R:=GetRValue(Cor);
       G:=GetGValue(Cor);
       B:=GetBValue(Cor);

       {Verifica se o ponto está em escala de cinza}
       If not((R=G) and (G=B)) then {Se não estiver}
          Cinza:=Round((R+G+B)/3) {Encontra o valor de cinza correspondente}
       else
          Cinza:=R;  {Se está em escala de cinza, atribiu qualquer valor
                      de R, G ou B}
       Mapa_Prof[x,y]:=Cinza;
    end;
    ggBarra.Progress:=ggBarra.Progress+1;
  end;
end;

{Procedimento que cria o estereograma a partir o Algoritmo 1
 onde os parametros de entrada sao o nome do arquivo, para deposito de dados,
 e o numero de camadas de profundidade}
procedure TfrmEstereograma.GerarEstereograma1(Nome_Arquivo:string; NroCam:byte);
var
  SEP,
  disObs,
  ESQUERDA,
  DIREITA,
  Prof,
  x, y: integer;
  disOlho: real;
  DEPENDENCIA : array [0..Largura-1] of integer;
  CORES: array [0..Largura-1] of  dword;
  Arquivo: TextFile;
begin
  disObs:= 12 * Resolucao; {Calcula a distancia do observador a tela em pixels}
  disOlho:= (Separacao* Resolucao); {Calcula a distancia ocular em pixels}

  AssignFile(Arquivo,Nome_Arquivo + '.txt');
  Rewrite(Arquivo);

  {Percorre todo o mapa de profundidade}
  for y:=0 to Altura-1 do
  begin
    {Zera o vetor de dependencias}
    for x:=0 to Largura - 1 do
      DEPENDENCIA[x]:=x;

    for x:=0 to Largura - 1 do
    begin
      {Calcula a profundidade do ponto em questão}
      Prof:= trunc(255 - Mapa_Prof[x,y]*(NroCam)/256);
      {Calcula a Separação Estereoscópica}
      sep:= trunc((disOlho*Prof)/(Prof+disObs));
      {calcula os extremos da separação estereoscópica}
      ESQUERDA:= trunc(x - SEP/2);
      DIREITA:= x + SEP;
      {verifica se os pontos estao dentro dos limites da imagem}
      if (ESQUERDA >= 0) and (DIREITA < largura) then
         DEPENDENCIA[DIREITA]:= ESQUERDA;
    end;

    {para cada ponto da linha em questão, verificar de ouve dependencia}
    for x:=0 to Largura - 1 do
    begin
       if (DEPENDENCIA[x]=x) then {Se nao houve dependência}
          CORES[x]:= Matriz_Rand[x,y]   {Atribuir valores aleatórios}
       else
          CORES[x]:= CORES[DEPENDENCIA[x]]; {Atribuir a mesma cor do ponto
                                             com o qual criou dependencia}
       {Deposita os dados no arquivo texto 1}
       Writeln(Arquivo,MontaLinha(x,y,CORES[x]));
    end;
    ggBarra.Progress:=ggBarra.Progress + 1;
  end;

  CloseFile(Arquivo);

end;

{Procedimento que cria um estereograma a partir do algortimo 2}
procedure TFrmEstereograma.GerarEstereograma2(Nome_Arquivo:String);
var
 x, y, SEP,
 ESQUERDA, DIREITA: integer;
 disOlho, m, prof: real;
 DEPENDENCIA:array [0..Largura-1] of integer;
 CORES: array [0..Largura-1] of dword;
 Arquivo: textfile;
begin
  disOlho:= Separacao*Resolucao; {Calcula a distancia ocular em pixels}
  m:= 1/3; {Abrangência da profundidade}

  AssignFile(Arquivo,Nome_Arquivo + '.txt');
  Rewrite(Arquivo);

 {Percorre todo o mapa de profundidade}
  for y:=0 to Altura - 1 do
  begin
    {Zera o vetor de dependencias}
    for x:=0 to Largura - 1 do
      DEPENDENCIA[x]:=x;

    {Para todos os pontos da linha em questão}
    for x:=0 to Largura - 1 do
    begin
      {Calcula a profunidade do ponto em questão}
      prof:=Mapa_Prof[x,y]/255;
      {Calcula a sepração estereoscópica}
      sep:= trunc( (1-m*Prof)*disOlho/(2-m*Prof));
      {Calcula os extremos da separação estereoscópica}
      ESQUERDA:= trunc(x - (sep/2));
      DIREITA:= ESQUERDA + sep;
      {Verifica se os extremos estão dentro das fronteiras da imagem}
      If (ESQUERDA >= 0) and (DIREITA < largura) then
         DEPENDENCIA[ESQUERDA]:=DIREITA;
    end;

    {para cada ponto da linha em questão, verificar de ouve dependencia}
    for x:=Largura - 1 downto 0 do
    begin
      If (DEPENDENCIA[x]=x) then  {Se nao houve dependência}
         CORES[x]:= Matriz_Rand[x,y] {Atribuir valores aleatórios}
      else
         CORES[x]:= CORES[DEPENDENCIA[x]];{Atribuir a mesma cor do ponto
                                             com o qual criou dependencia}
      {Deposita os dados no arquivo texto 1}
      Writeln(Arquivo,MontaLinha(x,y,CORES[x]));
    end;
    ggBarra.Progress:=ggBarra.Progress + 1;
  end;

  CloseFile(Arquivo);


end;

{Constroi o layout da linha dos arquivos texto 1 e 2}
function TfrmEstereograma.MontaLinha(x:Integer; y:Integer; Cor:dword):string;
var
  Linha: string[16];
  Valor_Cor, Cor_Ajustada: string[8];
  i, pos: byte;
begin
  case x of
     0..9     : linha:= '00'+inttoStr(x);
     10..99   : linha:= '0' +inttoStr(x);
     100..639 :  linha:= inttoStr(x);
  end;

  case y of
     0..9     : linha:= linha + ' 00' +inttoStr(y);
     10..99   : linha:= linha + ' 0'  +inttoStr(y);
     100..479 : linha:= linha + ' '   +inttoStr(y);
  end;
  Valor_Cor:= FloattoStr(Cor);

  pos:=8;
  Cor_Ajustada:='00000000';
  for i:=Length(Valor_Cor) downto 1 do
  begin
     Cor_Ajustada[pos]:= Valor_Cor[i];
     pos:= pos - 1;
  end;
  Linha:= Linha + ' ' + Cor_Ajustada;

  MontaLinha:= Linha;

end;

{Procedimento que cria o Arquivo texto 2
 Este procedimento utiliza a matriz randomica para armazenar o
 somatorio de das cores em todas as ocorrências}
procedure TfrmEstereograma.Cria_Arquivo_Geral(N:Byte);
var
 i,k, Nro_Oco: integer;
 NomeArq, Coord_Cor, Cor_String, X_String, Y_String: string;
 Cor,x,y:integer;
 Media: Dword;
 Arquivo: textfile;

begin
    Nro_Oco:= seOcorr.Value;

    {Zera a matriz randômica}
    for y:=0 to Altura - 1 do
    begin
      for x:=0 to Largura - 1 do
        Matriz_Rand[x,y]:=0;

    end;

    for i:=1 to Nro_Oco do
    begin
      {Abre o arquivo de acordo com o nome padrao}
      NomeArq:='Stereo_'+ inttoStr(N)+'_'+inttoStr(i)+'.txt';
      AssignFile(Arquivo,NomeArq);
      Reset(Arquivo);

      {Percorre todo o arquivo aberto anteriormente armazenando
       os valores das cores na matriz randomica}
      While not EOF(Arquivo) do
      begin
        Readln(Arquivo, Coord_Cor);

        X_String:='';
        for k:=1 to 3 do
          X_string:= X_String + Coord_Cor[k];

        Y_String:='';
        for k:=5 to 7 do
          Y_String:= Y_String + Coord_Cor[k];

        Cor_String:='';
        for k:=9 to 16 do
           Cor_String:=Cor_String + Coord_Cor[k];
        cor:=strtoint(Cor_String);
        x:=strtoint(X_String);
        y:=strtoint(Y_String);
        Matriz_Rand[x,y]:= Matriz_Rand[x,y] + Cor;
      end;
      CloseFile(Arquivo);
    end;

    {Cria o arquivo texto 2 do respectivo algoritmo.
     Este arquivo conterá a cor média a partir de todas as ocorrências}
    AssignFile(Arquivo,'Geral_'+inttostr(N)+'.txt');
    Rewrite(Arquivo);
    for y:=0 to Altura - 1 do
    Begin
      for x:=0 to Largura - 1 do
      begin
        media:=Round(Matriz_Rand[x,y]/Nro_Oco);
        Writeln(Arquivo, MontaLinha(x,y,media));
        {Caso o usuário só tenha escolhido um algoritmo,
         será exibido visualmente o estereograma}
        if not(cbAlgo1.Checked and cbAlgo2.Checked) then
           FrmSIRDS.Imagem.Canvas.Pixels[x,y]:= Media;
      end;
      ggBarra.Progress:=ggBarra.Progress+1;
    end;
    CloseFile(Arquivo);

    if not(cbAlgo1.Checked and cbAlgo2.Checked) then
    begin
       lbMensagem.Caption:='Visualizando Estereograma...';
       FrmSIRDS.ShowModal;
    end;


end;


procedure TfrmEstereograma.btSairClick(Sender: TObject);
begin
   close;
end;


procedure TfrmEstereograma.FormCreate(Sender: TObject);
begin
   Sleep(3000);
end;

{Procedimento que atualiza as informações dos respectivos algoritmos
 no quadro de informações}
procedure TfrmEstereograma.cbAlgo1Click(Sender: TObject);
begin
  if cbAlgo2.Checked or cbAlgo1.Checked then
  begin
     btGerar.Enabled:= true;
     if cbAlgo1.Checked and cbAlgo2.Checked then
     begin
       lbComplementar.Caption:='DistObs=30cm  m=1/3';
       seProf.Value:= 19;
       seProf.Enabled:= false;
     end
     else
       if cbAlgo2.Checked then
       begin
         seProf.Value:= 19;
         seProf.Enabled:= false;
         lbComplementar.Caption:='m = 1/3';
       end
       else
         if cbAlgo1.Checked then
         begin
            seProf.Enabled:= true;
            lbComplementar.Caption:='DistObs = 30 cm';
         end;

  end
  else
  begin
     btGerar.Enabled:= false;
     lbComplementar.Caption:='';
  end;

end;

{Procedimento que cria o arquivo da analise (Tipo 3)}
procedure TfrmEstereograma.Cria_Arquivo_Diferenca;
Var
 Arquivo1, Arquivo2, ArquivoDif: textfile;
 Linha1, Linha2, Cor1, Cor2, Coord:string;
 k,x,y,Diferenca: Integer;

begin
  {Abre os arquivos gerais (Tipo 2) de ambos os algoritmos}
  AssignFile(Arquivo1,'Geral_1.txt');
  AssignFile(Arquivo2,'Geral_2.txt');
  AssignFile(ArquivoDif,'Arq_Dif.txt');
  Reset(Arquivo1);
  Reset(Arquivo2);
  Rewrite(ArquivoDif);
  x:=0;
  y:=0;

  {Percorre todas as linhas dos dois arquivos simultaneamente}
  While not EOF(Arquivo1) do
  begin
    Readln(Arquivo1,Linha1);
    Readln(Arquivo2,Linha2);

    Cor1:='';
    Cor2:='';
    For k:=9 to 16 do
    begin
      Cor1:= Cor1 + Linha1[k];
      Cor2:= Cor2 + Linha2[k];
    end;
    {Calcula a diferença}
    Diferenca:= StrtoInt(Cor1) - StrtoInt(Cor2);

    case x of
     0..9     : coord:= '00'+inttoStr(x);
     10..99   : coord:= '0' +inttoStr(x);
     100..639 : coord:= inttoStr(x);
    end;
    case y of
     0..9     : coord:= coord + ' 00' +inttoStr(y);
     10..99   : coord:= coord + ' 0'  +inttoStr(y);
     100..479 : coord:= coord + ' '   +inttoStr(y);
    end;

    {Escreve o resultado no arquivo tipo 3}
    Writeln(ArquivoDif, coord + ' ' + InttoStr(Diferenca));
    x:=x+1;
    if x=Largura then
    begin
       y:=y+1;
       x:=0;
       ggBarra.Progress:=ggBarra.Progress+1;
    end;
  end;
  CloseFile(Arquivo1);
  CloseFile(Arquivo2);
  CloseFile(ArquivoDif);
end;

{PRocedimento que carrega a cena tridimensional}
procedure TfrmEstereograma.btCenaClick(Sender: TObject);
begin
   if dgAbrirArquivo.Execute then
      Imagem.Picture.LoadFromFile(dgAbrirArquivo.FileName);
end;

{Procedimento a partir do qual é criado o estereograma
 seguindo os passos descritos no Relatorio Final}
procedure TfrmEstereograma.btGerarClick(Sender: TObject);
var
  i: integer;
  Nome: string;
begin

  if seOcorr.Value > 10 then
     seOcorr.Value:=10;

  lbMensagem.Caption:='Armazenando Mapa de Profundidade...';
  Refresh;
  ggBarra.Progress:=1;
  ArmazenarMapaProfundidade;


  for i:=1 to seOcorr.Value do
  begin
    lbMensagem.Caption:='Gerando Matriz Aleatória da Ocorrência '+inttoStr(i)+' ...';
    Refresh;
    ggBarra.Progress:=1;
    Sleep(1000);
    GerarMatrizRandomica;
    If cbAlgo1.checked then
    begin
      lbMensagem.Caption:='Criando arquivo da Ocorrencia '+ inttoStr(i)+' do Algoritmo 1';
      Refresh;
      Nome:='Stereo_1_'+ inttoStr(i);
      ggBarra.Progress:=1;
      GerarEstereograma1(Nome,seProf.Value);
    end;
    If cbAlgo2.Checked then
    begin
      lbMensagem.Caption:='Criando arquivo da Ocorrencia '+ inttoStr(i)+' do Algoritmo 2';
      Refresh;
      Nome:='Stereo_2_'+ inttoStr(i);
      ggBarra.Progress:=1;
      GerarEstereograma2(Nome);
    end;

  end;

  if cbAlgo1.Checked then
  begin
     lbMensagem.Caption:='Criando Arquivo Geral do Algoritmo 1';
     Refresh;
     ggBarra.Progress:=1;
     Cria_Arquivo_Geral(1);
  end;
  if cbAlgo2.Checked then
  begin
     lbMensagem.Caption:='Criando Arquivo Geral do Algoritmo 2';
     Refresh;
     ggBarra.Progress:=1;
     Cria_Arquivo_Geral(2);
  end;

  {Só cria arquivo das diferenças se o usuário escolheu os dois algoritmos}
  If cbAlgo1.Checked and cbAlgo2.Checked then
  begin
    lbMensagem.Caption:='Criando Arquivo Diferença';
    Refresh;
    ggBarra.Progress:=1;
    Cria_Arquivo_Diferenca;
  end;
  lbMensagem.Caption:='';

  ggBarra.Progress:=1;

end;

procedure TfrmEstereograma.btSobreClick(Sender: TObject);
begin
   FrmSobre.ShowModal;
end;

procedure TfrmEstereograma.btEncerrarClick(Sender: TObject);
begin
    Close;
end;

procedure TfrmEstereograma.btCenaMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
   btCena.Font.Color:=clRed;
   btGerar.Font.Color:=clBlue;
   btSair.Font.Color:=clBlue;
end;

procedure TfrmEstereograma.FormMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  btCena.Font.Color:=clBlue;
  btGerar.Font.Color:=clBlue;
  btSair.Font.Color:=clBlue;
  btSobre.Font.Color:=clBlue;
end;

procedure TfrmEstereograma.FormActivate(Sender: TObject);
begin
  lbAltura.Caption:= 'Largura = '+ inttoStr(ALtura);
  lbLargura.Caption:= 'Altura = ' + inttoStr(Largura);
  ggBarra.MaxValue:= Altura;
end;

procedure TfrmEstereograma.btGerarMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
   btCena.Font.Color:=clBlue;
   btGerar.Font.Color:=clRed;
   btSair.Font.Color:=clBlue;
end;

procedure TfrmEstereograma.btSairMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
   btCena.Font.Color:=clBlue;
   btGerar.Font.Color:=clBlue;
   btSair.Font.Color:=clRed;
end;

procedure TfrmEstereograma.btSobreMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
   btSobre.Font.Color:= clRed;
end;

end.
