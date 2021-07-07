unit AddParameterToROWDATA;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TfrmAddParameterToROWDATA = class(TForm)
    OpenDialog1: TOpenDialog;
    btnSourceFile: TBitBtn;
    Memo1: TMemo;
    RadioGroup1: TRadioGroup;
    Edit1: TEdit;
    Label1: TLabel;
    BitBtn1: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure btnSourceFileClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAddParameterToROWDATA: TfrmAddParameterToROWDATA;
  SA: integer;
  fn :string;
  f: text;

implementation

uses dm;

{$R *.lfm}

procedure TfrmAddParameterToROWDATA.FormShow(Sender: TObject);
begin

    SA:=frmDM.Q.FieldByName('ABSNUM').AsInteger;
    frmAddParameterToROWDATA.Caption:=frmAddParameterToROWDATA.Caption+'  absnum='+inttostr(SA)
    +' RCM#='+inttostr(frmDM.Q.FieldByName('M_RCMNUM').AsInteger);

end;



procedure TfrmAddParameterToROWDATA.btnSourceFileClick(Sender: TObject);
var
mik: integer;
st: string;
begin

  {if OpenDialog1.Execute then
  begin
    fn := OpenDialog1.FileName;
    Memo1.Lines.Add('source file: ' + fn);
    Memo1.Lines.Add('');
  end;}

    fn:='c:\data\Currents\GFI\STROMDATAARKIV-301-400\310-ark-Faeroe\310b\195\195MA01.RAW';

  assignfile(f, fn);
  reset(f);

    memo1.Visible:=false;
    mik:=0;
{f}while not EOF(f) do begin
    mik:=mik+1;
    readln(f, st);
    Memo1.Lines.Add(inttostr(mik)+#9+st);
{f}end;
    closefile(f);
    memo1.Visible:=true;

end;



procedure TfrmAddParameterToROWDATA.BitBtn1Click(Sender: TObject);
var
par: string;
col,mik,val,k: integer;
val_arr: array[1..9] of integer;
begin
     par:=RadioGroup1.Items[RadioGroup1.ItemIndex];  //parameter to add
     col:=strtoint(Edit1.Text);                      //column in source file

     memo1.Clear;
     memo1.Lines.Add('Par: '+par);
     memo1.Lines.Add('Col: '+inttostr(col));
     memo1.Lines.Add('');

     reset(f);
     mik:=0;
{f}while not EOF(f) do begin
     read(f,val);
     if val=7 then readln(f);
{7}if val<>7 then begin
     mik:=mik+1;
     for k:=2 to col do read(f,val);
     readln(f);
     Memo1.Lines.Add(inttostr(mik)+#9+inttostr(val));
{7}end;
{f}end;
    closefile(f);


end;



end.
