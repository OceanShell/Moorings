unit SetFlag;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmSetFlag = class(TForm)
    ListBox1: TListBox;
    btnSetQFL: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure btnSetQFLClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSetFlag: TfrmSetFlag;

implementation

{$R *.lfm}

uses PlotConvertedData;


procedure TfrmSetFlag.btnSetQFLClick(Sender: TObject);
begin
     frmSetFlag.Close;
end;

procedure TfrmSetFlag.FormShow(Sender: TObject);
begin
     QFL:=0;
     ListBox1.SetFocus;
end;

procedure TfrmSetFlag.ListBox1Click(Sender: TObject);
Var
k:integer;
fl_str, buf_str:string;
begin

     fl_str:=ListBox1.Items.Strings[ListBox1.ItemIndex];
     k:=0; buf_str:='';
   repeat
     inc(k);
     if fl_str[k]<>']' then buf_str:=buf_str+fl_str[k];
   until fl_str[k]=']';

   QFL:=StrToInt(copy(trim(buf_str),2,length(buf_str)));

end;




end.
