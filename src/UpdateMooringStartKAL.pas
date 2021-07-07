unit UpdateMooringStartKAL;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DateUtils;

type
  TfrmUpdateMooringStartKAL = class(TForm)
    Memo1: TMemo;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmUpdateMooringStartKAL: TfrmUpdateMooringStartKAL;
  fn:string='d:\data\Currents\GFI\updates\UpdateStartTime_KAL.txt';
  f:text;

implementation

{$R *.lfm}

procedure TfrmUpdateMooringStartKAL.FormShow(Sender: TObject);
var
k :integer;
d,m,y,h,min,sec,msec :word;
absnum,instnum,int,rec1,rec2 :integer;
mt :double;
st :string;
recStart,MooringStart :TDateTime;
begin

     assignfile(f, fn);
     reset(f);

     memo1.Visible:=false;
     Memo1.Lines.Add('file: '+fn);
     readln(f, st);
     Memo1.Lines.Add('content: '+st);

     Memo1.Lines.Add('');
     Memo1.Lines.Add('');
     Memo1.Lines.Add('abs         inst#       start_record                      int(min)    count       start_mooring');
{f}while not EOF(f) do begin
    readln(f, absnum, instnum, d, m, y, h, min, int, rec1, rec2);

    sec:=0;
    msec:=0;

    recStart:=EncodeDateTime(y, m, d, h, min, sec, msec);
    MooringStart:=recStart-(int*(rec1-1))/1440;

    Memo1.Lines.Add(inttostr(absnum)
    +#9+inttostr(instnum)
    +#9+datetimetostr(recStart)
    +#9+inttostr(int)
    +#9+inttostr(rec1)
    +#9+datetimetostr(MooringStart)
    );

    //control
   for k:=1 to rec1 do begin
     mt:=MooringStart+(int*(k-1))/1440;
   end;
     memo1.Lines.Add('control: '+#9+inttostr(rec1)+#9+datetimetostr(mt));




{f}end;
    closefile(f);
    memo1.Visible:=true;

end;

end.
