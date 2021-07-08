unit SetFlag;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type

  { TfrmSetFlag }

  TfrmSetFlag = class(TForm)
    ListBox1: TListBox;
    procedure FormShow(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
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


procedure TfrmSetFlag.FormShow(Sender: TObject);
begin
  QFL:=-9;
  ListBox1.SetFocus;
end;

procedure TfrmSetFlag.ListBox1DblClick(Sender: TObject);
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
 Close;
end;


end.
