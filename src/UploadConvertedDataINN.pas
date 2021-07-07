unit UploadConvertedDataINN;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DateUtils;

type
  TfrmUploadConvertedDataINN = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    btnUpload: TBitBtn;
    Memo1: TMemo;
    procedure FormShow(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmUploadConvertedDataINN: TfrmUploadConvertedDataINN;
  RCMAbsnum: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;

implementation

uses dm;

{$R *.lfm}



procedure TfrmUploadConvertedDataINN.FormShow(Sender: TObject);
var
mik: integer;
st:string;
begin

    RCMAbsnum:=frmDM.Q.FieldByName('ABSNUM').AsInteger;

    Start  :=frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;
    TimeInt:=frmDM.Q.FieldByName('M_RCMTimeInt').AsInteger;

    fn:=frmDM.Q.FieldByName('M_SourceFileName').AsString;

     Memo1.Lines.Add('source file: ' + fn);
     Memo1.Lines.Add('start: '+datetimetostr(Start));
     Memo1.Lines.Add('interval [min]: '+inttostr(TimeInt));
     Memo1.Lines.Add('');

     //if ((extractfileext(fn))='.ark') or ((extractfileext(fn))='.ARK') then
     //RadioGroup1.ItemIndex:=1;

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
    btnUpload.Visible:=true;

end;


procedure TfrmUploadConvertedDataINN.btnUploadClick(Sender: TObject);
var
i,mik,n :integer;
d,m,y,h,min,sec,msec :word;
speed, dir, temp :real;
symbol: char;
buf :string;
st :string;
RecTime :TDateTime;
begin


     //delete mooring from CURRENTS
   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' Delete from CURRENTS where absnum=:absnum');
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ExecSQL;
   end;

     frmDM.TR.Commit;

   //insert converted data varuables(7) Qflags (6)
   //variables: angle speed temperature salinity pressure turbidity oxygen
   //flags:     current     temperature salinity pressure turbidity oxygen
   with frmDM.ib1q1 do begin
    Close;
    SQL.Clear;
    SQL.Add(' INSERT INTO CURRENTS ');
    SQL.Add(' (ABSNUM, C_TIME, C_ANGLE, C_SPEED, C_TEMP, C_SALT, C_PRESS, C_TURB, C_OXYG, ');
    SQL.Add('  C_CFL, C_TFL, C_SFL, C_PFL, C_UFL, C_OFL ) ');
    SQL.Add(' VALUES ');
    SQL.Add(' (:ABSNUM, :C_TIME, :C_ANGLE, :C_SPEED, :C_TEMP, :C_SALT, :C_PRESS, :C_TURB, :C_OXYG, ');
    SQL.Add('  :C_CFL, :C_TFL, :C_SFL, :C_PFL, :C_UFL, :C_OFL ) ');
    Prepare;
  end;


     memo1.Clear;

     reset(f);
    //skip the first two lines
     readln(f);
     readln(f);

    mik:=0;
    memo1.Lines.Add('#  time  dir  speed  temp');
{f}while not EOF(f) do begin

    speed:=-9;
    dir:=-9;
    temp:=-9;

    mik:=mik+1;
    readln(f, st);

    n:=0;
{c}for i:=1 to 6 do begin  //number of columns in file
     buf:='';
   repeat
     inc(n);
     symbol:=st[n];
     if symbol<>' ' then buf:=buf+symbol;
   until symbol=' ';

   case i of
   2: temp:=strtofloat(buf);
   3: speed:=strtofloat(buf);
   4: dir:=strtofloat(buf);
   5: begin //ex: 15.05.2001
       //memo1.lines.add('date='+buf);
       d:=strtoint(copy(buf,1,2));
       m:=strtoint(copy(buf,4,2));
       y:=strtoint(copy(buf,7,4));
      end;
   6: begin //ex: 05:49
       //memo1.lines.add('time='+buf);
       h:=strtoint(copy(buf,1,2));
       min:=strtoint(copy(buf,4,2));
      end;
   end; {case}
{c}end;

    sec:=0;
    msec:=0;
    recTime:=EncodeDateTime(y, m, d, h, min, sec, msec);


    Memo1.Lines.Add(inttostr(mik)
     +#9+datetimetostr(recTime)
     +#9+floattostr(dir)
     +#9+floattostr(speed)
     +#9+floattostr(temp)
     );


//insert converted data onto table CURRENTS
   with frmDM.ib1q1 do begin
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('C_TIME').AsDateTime:=recTime;
     ParamByName('C_ANGLE').AsFloat:=dir;
     ParamByName('C_SPEED').AsFloat:=speed;
     ParamByName('C_TEMP').AsFloat:=temp; //prefered temperature channel
     ParamByName('C_SALT').AsFloat:=-9;
     ParamByName('C_PRESS').AsFloat:=-9;//always channel 4
     ParamByName('C_TURB').AsFloat:=-9;
     ParamByName('C_OXYG').AsFloat:=-9;

     ParamByName('C_CFL').AsInteger:=0;
     ParamByName('C_TFL').AsInteger:=0;
     ParamByName('C_SFL').AsInteger:=0;
     ParamByName('C_PFL').AsInteger:=0;
     ParamByName('C_UFL').AsInteger:=0;
     ParamByName('C_OFL').AsInteger:=0;
     ExecSQL;
   end;

{f}end;
    closefile(f);


    frmDM.TR.Commit;

     //update row records #
   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' update MOORINGS set M_REC_ROW=:recnum ');
     SQL.Add(' where absnum=:absnum');
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('recnum').AsInteger:=0;
     ExecSQL;
   end;

     //update converted records #
   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' update MOORINGS set M_REC_CUR=:recnum ');
     SQL.Add(' where absnum=:absnum');
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('recnum').AsInteger:=mik;
     ExecSQL;
   end;

    frmDM.TR.Commit;




end;


end.
