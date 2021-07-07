unit UploadConvertedData_PRN;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DateUtils;

type
  TfrmUploadConvertedData_PRN = class(TForm)
    Memo1: TMemo;
    btnUpload: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmUploadConvertedData_PRN: TfrmUploadConvertedData_PRN;
  RCMAbsnum, csv: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;

implementation

uses dm;

{$R *.lfm}




procedure TfrmUploadConvertedData_PRN.FormShow(Sender: TObject);
var
mik,i: integer;
st: string;
begin
    RCMAbsnum:=frmDM.CDSMD.FieldByName('ABSNUM').AsInteger;

    Start  :=frmDM.CDSMD.FieldByName('M_TimeBeg').AsDateTime;
    TimeInt:=frmDM.CDSMD.FieldByName('M_RCMTimeInt').AsInteger;

    fn:=frmDM.CDSMD.FieldByName('M_SourceFileName').AsString;

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
     csv:=0;
{f}while not EOF(f) do begin
    mik:=mik+1;
    readln(f, st);
    Memo1.Lines.Add(inttostr(mik)+#9+st);

    //tab or csv?
{s}if mik=3 then begin
   for i:=1 to length(st) do if st[i]=',' then csv:=1;
{s}end;

{f}end;
    closefile(f);

    if csv=0 then Memo1.Lines.Add('file format: tab');
    if csv=1 then Memo1.Lines.Add('file format: csv');

    memo1.Visible:=true;
    btnUpload.Visible:=true;

end;



procedure TfrmUploadConvertedData_PRN.btnUploadClick(Sender: TObject);
var
k,n,mik: integer;
y,m,d,hh,mm: word;
count: integer;
speed,dir,temp,salt,press,turb,oxy: real;
//symbol: string[1];
symbol: char;
st,buf_str,datestr,timestr,m3: string;
rectime: TDateTime;

begin

     memo1.Clear;


     //delete mooring from CURRENTS
   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' Delete from CURRENTS where absnum=:absnum');
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ExecSQL;
   end;

     frmDM.TR1.Commit;

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




     reset(f);
    //skip lines
     readln(f);
     readln(f);
     readln(f);
     readln(f);
     readln(f);
     readln(f);
     readln(f);

     memo1.Lines.Add('#  time  speed  dir  temp');
     mik:=0;
{f}while not EOF(f) do begin

     readln(f,st);
     mik:=mik+1;

//tab: # temp speed dir
// 2604        7.55        1.0      299      31.Jul-96     04:34
//csv: # speed temp dir
// 2604        7.55        1.0      299      31.Jul-96     04:34
{1}if csv=1 then begin
     st:=trim(st);
     st:=st+',';

     n:=0;
     count:=0;
     speed:=-9;
     dir:=-9;
     temp:=-9;
     salt:=-9;
     press:=-9;
     turb:=-9;
     oxy:=-9;


     y:=0; m:=0; d:=0; hh:=0; mm:=0;

{s}for k:=1 to 9 do begin
     buf_str:='';
     repeat
      inc(n);
      symbol:=st[n];
      if symbol<>',' then begin
                          buf_str:=buf_str+symbol;
                          //showmessage('k='+inttostr(k)+'  n='+inttostr(n)+' -> '+buf_str);
                          end;
      until (symbol=',');

      case k of
      1: count:=strtoint(buf_str);
      2: speed:=strtofloat(buf_str);
      3: temp :=strtofloat(buf_str);
      4: dir  :=strtofloat(buf_str);
      5: y  :=strtoint(buf_str);
      6: m  :=strtoint(buf_str);
      7: d  :=strtoint(buf_str);
      8: hh :=strtoint(buf_str);
      9: mm :=strtoint(buf_str);
      end; {case}

{s}end;

     if y>50 then y:=y+1900 else y:=y+2000;
     rectime:=EncodeDateTime(y,m,d,hh,mm,0,0);

    Memo1.Lines.Add(inttostr(count)
     +#9+inttostr(d)
     +#9+inttostr(m)
     +#9+inttostr(y)
     +#9+inttostr(hh)
     +#9+inttostr(mm)
     +#9+DateTimeToStr(rectime)
     +#9+floattostr(speed)
     +#9+floattostr(dir)
     +#9+floattostr(temp));
{1}end; //csv





//tab: # speed dir temp
// 2604        7.55        1.0      299      31.Jul-96     04:34
{2}if csv=0 then begin
     //st:=trim(st);
     //st:=st+',';

     n:=0;
     count:=0;
     speed:=-9;
     dir:=-9;
     temp:=-9;
     salt:=-9;
     press:=-9;
     turb:=-9;
     oxy:=-9;


     y:=0; m:=0; d:=0; hh:=0; mm:=0;

//{s}for k:=1 to 6 do begin
//     buf_str:='';
//     repeat
//      inc(n);
//      symbol:=st[n];
//      if ord(symbol)<>9 then begin
//                          buf_str:=buf_str+symbol;
//                          showmessage('k='+inttostr(k)+'  n='+inttostr(n)+' -> '+buf_str);
//                          end;
//      until (ord(symbol)=9);
//
//      case k of
//      1: count:=strtoint(buf_str);
//      2: temp :=strtofloat(buf_str);
//      3: speed:=strtofloat(buf_str);
//      4: dir  :=strtofloat(buf_str);
//      5: datestr:=trim(buf_str);
//      6: timestr:=trim(buf_str);
//      end; {case}
//
//{s}end;


     count:=strtoint(trim(copy(st,1,5)));
     temp :=strtofloat(trim(copy(st,13,5)));
     speed:=strtofloat(trim(copy(st,24,5)));
     dir  :=strtofloat(trim(copy(st,35,3)));
     datestr:=copy(st,44,9);
     timestr:=copy(st,58,5);

     y:=strtoint(copy(datestr,8,2));
     d:=strtoint(copy(datestr,1,2));
     m3:=copy(datestr,4,3);

     if m3='Jun' then m:=6;
     if m3='Jul' then m:=7;
     if m3='Aug' then m:=8;

     hh:=strtoint(copy(timestr,1,2));
     mm:=strtoint(copy(timestr,4,2));


     if y>50 then y:=y+1900 else y:=y+2000;
     rectime:=EncodeDateTime(y,m,d,hh,mm,0,0);

    Memo1.Lines.Add(inttostr(count)
     +#9+inttostr(d)
     +#9+inttostr(m)
     +#9+inttostr(y)
     +#9+inttostr(hh)
     +#9+inttostr(mm)
     +#9+DateTimeToStr(rectime)
     +#9+floattostr(speed)
     +#9+floattostr(dir)
     +#9+floattostr(temp));
{2}end; //csv






//insert converted data onto table CURRENTS
   with frmDM.ib1q1 do begin
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('C_TIME').AsDateTime:=recTime;
     ParamByName('C_ANGLE').AsFloat:=dir;
     ParamByName('C_SPEED').AsFloat:=speed;
     ParamByName('C_TEMP').AsFloat:=temp; //prefered temperature channel
     ParamByName('C_SALT').AsFloat:=salt;
     ParamByName('C_PRESS').AsFloat:=press;//always channel 4
     ParamByName('C_TURB').AsFloat:=turb;
     ParamByName('C_OXYG').AsFloat:=oxy;

     ParamByName('C_CFL').AsInteger:=0;
     ParamByName('C_TFL').AsInteger:=0;
     ParamByName('C_SFL').AsInteger:=0;
     ParamByName('C_PFL').AsInteger:=0;
     ParamByName('C_UFL').AsInteger:=0;
     ParamByName('C_OFL').AsInteger:=0;
     ExecSQL;
   end;



{f}end;
     Closefile(f);

    frmDM.TR1.Commit;

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

     //update time series end
   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' update MOORINGS set M_TIMEEND=:recTime ');
     SQL.Add(' where absnum=:absnum');
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('recTime').AsDateTime:=recTime;
     ExecSQL;
   end;


    frmDM.TR1.Commit;



end;



end.
