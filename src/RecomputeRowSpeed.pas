unit RecomputeRowSpeed;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmRecomputeRowSpeed = class(TForm)
    btnOpenSourceFile: TBitBtn;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    Label1: TLabel;
    procedure btnOpenSourceFileClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmRecomputeRowSpeed: TfrmRecomputeRowSpeed;
  f,f_out: text;

implementation

{$R *.lfm}

procedure TfrmRecomputeRowSpeed.btnOpenSourceFileClick(Sender: TObject);
var
fn,fn_out,st: string;
i, mik, speed, speed1, speed2: integer;
rfn,temp,cond,press,dir: integer;
speed_arr :array[1..10000] of integer;
begin

    OpenDialog1.InitialDir:='d:\data\Currents\GFI\STROMDATAARKIV-100-001\071-ark-Overflow\';
   if OpenDialog1.Execute then
     fn:=OpenDialog1.FileName
   else begin
     showmessage('File not selected!');
     Exit;
   end;


    fn_out:=ChangeFileExt(fn,'.new');
    memo1.Lines.Add(fn);
    memo1.Lines.Add(fn_out);

    assignfile(f, fn);
    reset(f);

    assignfile(f_out, fn_out);
    rewrite(f_out);



     mik:=0;
{w}while not EOF(f) do begin
     readln(f,st);
     mik:=mik+1;
     if copy(st,33,4)<>'' then speed_arr[mik]:=strtoint(copy(st,33,4))
                          else speed_arr[mik]:=-9999;
{w}end;
    closefile(f);


    reset(f);
    readln(f); //skip first line
    memo1.Lines.Add('#  ref  temp  cond  press dir  speed  SpeedConv');

{w}for i:=2 to mik do begin

     readln(f,rfn,temp,cond,press,dir);

     speed1:=speed_arr[i-1];
     speed2:=speed_arr[i];
     speed:=speed2-speed1;
     if speed<0 then speed:=speed+1024;

     //memo1.Lines.Add(inttostr(i)
     //+#9+inttostr(speed1)
     //+#9+inttostr(speed2)
     //+#9+inttostr(speed));

     //control
     memo1.Lines.Add(inttostr(i)
     +#9+inttostr(rfn)
     +#9+inttostr(temp)
     +#9+inttostr(cond)
     +#9+inttostr(press)
     +#9+inttostr(dir)
     +#9+inttostr(speed1)
     +#9+inttostr(speed));

     writeln(f_out,rfn:6,temp:6,cond:6,press:6,dir:6,speed:6);


{w}end;
    closefile(f);
    closefile(f_out);


end;

end.
