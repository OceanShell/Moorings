//MicroCat timeseries upload
//basic version reads cnv files with 7 colmns
// col1 julian days
// col2 - cond
// col3 - temp
// col4 - pressure (if exist)
// col5 - salinity
// col6 - depth (if exist)
// col7 - flag
// !!! change code if format is different or re-process data

unit UploadSBE37_cnv;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmUploadSBE37_cnv = class(TForm)
    Memo1: TMemo;
    btnUpload: TBitBtn;
    btnSimpleCSV: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
    procedure btnSimpleCSVClick(Sender: TObject);
  private
    { Private declarations }
  procedure convertToJulianDay(d,m,y:integer; var JD:real);

  public
    { Public declarations }
  end;

var
  frmUploadSBE37_cnv: TfrmUploadSBE37_cnv;
  RCMAbsnum: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;

implementation

uses dm;

{$R *.lfm}


procedure TfrmUploadSBE37_cnv.FormShow(Sender: TObject);
var
mik, cc: integer;
D,M,Y: integer;
JDN,cond,temp,press,salt,depth,flag: real;
JD_start,JD_4713BC: real;
st, start_str: string;
mt: TDateTime; //measurement time
begin
     memo1.Clear;

     RCMAbsnum:=frmDM.Q.FieldByName('ABSNUM').AsInteger;
     Start  :=frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;
     TimeInt:=frmDM.Q.FieldByName('M_RCMTimeInt').AsInteger;
     fn:=frmDM.Q.FieldByName('M_SourceFileName').AsString;

     Memo1.Lines.Add('source file: ' + fn);
     Memo1.Lines.Add('start: '+datetimetostr(Start));
     Memo1.Lines.Add('interval [min]: '+inttostr(TimeInt));
     Memo1.Lines.Add('');

     assignfile(f, fn);
     reset(f);

     memo1.Visible:=false;
     cc:=0;
     mik:=0;
{w}while not EOF(f) do begin
     readln(f,st);
     Memo1.Lines.Add(st);

   if (copy(st,1,6)='# name') then begin
     cc:=cc+1; //columns count
     Memo1.Lines.Add(inttostr(cc)+#9+st);
   end;


{c}if cc=7 then begin
   //extract start time and Julian day offset
   //# start_time = Aug 28 2014 09:00:01 [Instrument's time stamp, first data scan]
{t}if (copy(st,1,12)='# start_time') then begin
     start_str:=copy(st,16,20);
     //Aug 28 2014 09:00:01
     if (lowercase(Trim(copy(start_str,1,3)))='jan') then M:=1;
     if (lowercase(Trim(copy(start_str,1,3)))='feb') then M:=2;
     if (lowercase(Trim(copy(start_str,1,3)))='mar') then M:=3;
     if (lowercase(Trim(copy(start_str,1,3)))='apr') then M:=4;
     if (lowercase(Trim(copy(start_str,1,3)))='may') then M:=5;
     if (lowercase(Trim(copy(start_str,1,3)))='jun') then M:=6;
     if (lowercase(Trim(copy(start_str,1,3)))='jul') then M:=7;
     if (lowercase(Trim(copy(start_str,1,3)))='aug') then M:=8;
     if (lowercase(Trim(copy(start_str,1,3)))='sep') then M:=9;
     if (lowercase(Trim(copy(start_str,1,3)))='oct') then M:=10;
     if (lowercase(Trim(copy(start_str,1,3)))='nov') then M:=11;
     if (lowercase(Trim(copy(start_str,1,3)))='dec') then M:=12;

     D:=strtoint(trim(copy(start_str,5,2)));
     Y:=strtoint(trim(copy(start_str,8,4)));

     //test D:=15; M:=10; Y:=1582;
     //how to compute before Christmas ???
     //could be taken from calculator for adjust JD in file to real values not offset
     //http://www.onlineconversion.com/julian_date.htm

     //convertToJulianDay(D,M,Y,JD_start);
     //convertToJulianDay(D,M,4713,JD_4713BC);

     Memo1.Lines.Add('');
     Memo1.Lines.Add('start:'+start_str);
     Memo1.Lines.Add('D/M/Y:  '+inttostr(D)+'/'+inttostr(M)+'/'+inttostr(Y));


//     Memo1.Lines.Add('JD_start='+floattostr(JD_start));
//     Memo1.Lines.Add('JD_4713BC='+floattostr(JD_4713BC));


{t}end;



   if (copy(st,1,4)='*END') then begin
     Memo1.Lines.Add('');
     if cc<>7 then begin
      showmessage('... data cannot be processed: diffrent format - change code');
      Exit;
     end;
      Memo1.Lines.Add('mik  name0  name1  name2  name3  name4  name5  name6  time');
   end;




{s}if (copy(st,1,1)<>'*') and (copy(st,1,1)<>'#') then begin
     mik:=mik+1;
     if mik>0 then mt:=Start+(TimeInt*(mik-1))/1440; //add min converted to day

{!}if mik<10000 then begin  //temporally reduce output

     JDN:=-9;
     cond:=-9;
     temp:=-9;
     press:=-9;
     salt:=-9;
     depth:=-9;

// 259.076400   3.337831     4.7431    108.933    35.1229    107.753 0.0000e+00

     if cc=7 then begin
     JDN :=strtofloat(trim(copy(st,1,11)));    //# name 0 = timeJV2: Time, Instrument [julian days]
     cond:=strtofloat(trim(copy(st,12,11)));   //# name 1 = cond0S/m: Conductivity [S/m]
     temp:=strtofloat(trim(copy(st,23,11)));   //# name 2 = tv290C: Temperature [ITS-90, deg C]
     press:=strtofloat(trim(copy(st,34,11)));  //# name 3 = prdM: Pressure, Strain Gauge [db]
     salt:=strtofloat(trim(copy(st,45,11)));   //# name 4 = sal00: Salinity, Practical [PSU]
     depth:=strtofloat(trim(copy(st,56,11)));  //# name 5 = depSM: Depth [salt water, m], lat = 79.6201
     flag:=strtofloat(trim(copy(st,67,11)));   // flag
     end;

     Memo1.Lines.Add(inttostr(mik)
     +#9+floattostrF(JDN,ffFixed,12,6)
     +#9+floattostrF(cond,ffFixed,8,6)
     +#9+floattostrF(temp,ffFixed,10,4)
     +#9+floattostrF(press,ffFixed,6,3)
     +#9+floattostrF(salt,ffFixed,6,3)
     +#9+floattostrF(depth,ffFixed,6,3)
     +#9+floattostr(flag)
     +#9+datetimetostr(mt));

{!}end;
{s}end;
{c}end;
{w}end;
     memo1.Visible:=true;

     closefile(f);


     if cc<>7 then begin
      showmessage('... data cannot be processed: diffrent format - change code');
      Exit;
     end;


end;




//convert date to Julian day
//algorithm from http://quasar.as.utexas.edu/BillInfo/JulianDatesG.html
procedure TfrmUploadSBE37_cnv.convertToJulianDay(D,M,Y:integer; var JD:real);
  var
  A,B,C,E,F: integer;
  A1,B1,C1,E1,F1: real;
  begin
  A1:=Y/100;                 A:=trunc(A1);
  B1:=A1/4;                  B:=trunc(B1);
                             C:=2-A+B;
  E1:=365.25*(Y+4716);       E:=trunc(E1);
  F1:=30.6001*(M+1);         F:=trunc(F1);
  JD:=C+D+E+F-1524.5;

  //showmessage('A='+inttostr(A));
  //showmessage('B='+inttostr(B));
  //showmessage('C='+inttostr(C));
  //showmessage('E='+inttostr(E));
  //showmessage('F='+inttostr(F));
  end;






procedure TfrmUploadSBE37_cnv.btnUploadClick(Sender: TObject);
var
mik,ref: integer;
JDN,cond,depth,flag: real;
speed, dir, temp, salt, press, turb, oxy :real;
st: string;
mt: TDateTime;
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



     memo1.Lines.Add('');
     memo1.Lines.Add('#           time                                    temp       salt        press');

     reset(f);
     mik:=0;
{w}while not EOF(f) do begin
     readln(f,st);

     ref:=-9;
     speed:=-9;
     dir:=-9;
     temp:=-9;
     salt:=-9;
     press:=-9;
     turb:=-9;
     oxy:=-9;



{s}if (copy(st,1,1)<>'*') and (copy(st,1,1)<>'#') then begin
     mik:=mik+1;
     if mik>0 then mt:=Start+(TimeInt*(mik-1))/1440; //add min converted to day

//format 1
//    JD         Cond        Temp       Press      Salt       Depth Flag
//    0          1            2           3         4           5     6
// 265.269456   2.894059    -0.8081   1491.865    34.9112   1470.833 0.0000e+00
     JDN :=strtofloat(trim(copy(st,1,11)));    //# name 0 = timeJV2: Time, Instrument [julian days]
     cond:=strtofloat(trim(copy(st,12,11)));   //# name 1 = cond0S/m: Conductivity [S/m]
     temp:=strtofloat(trim(copy(st,23,11)));   //# name 2 = tv290C: Temperature [ITS-90, deg C]
     press:=strtofloat(trim(copy(st,34,11)));  //# name 3 = prdM: Pressure, Strain Gauge [db]
     salt:=strtofloat(trim(copy(st,45,11)));   //# name 4 = sal00: Salinity, Practical [PSU]
     depth:=strtofloat(trim(copy(st,56,11)));  //# name 5 = depSM: Depth [salt water, m], lat = 79.6201
     flag:=strtofloat(trim(copy(st,67,11)));   // flag

//format 2
// Temp        Cond        Press         JD      Salt       Depth   Flag
//    0          1            2           3         4           5     6
//     3.9851   3.256510     50.465 257.882292    35.0018     49.925 0.0000e+00
//     JDN :=strtofloat(trim(copy(st,34,11)));   //# name 0 = timeJV2: Time, Instrument [julian days]
//     cond:=strtofloat(trim(copy(st,12,11)));   //# name 1 = cond0S/m: Conductivity [S/m]
//     temp:=strtofloat(trim(copy(st,1,11)));    //# name 2 = tv290C: Temperature [ITS-90, deg C]
//     press:=strtofloat(trim(copy(st,23,11)));  //# name 3 = prdM: Pressure, Strain Gauge [db]
//     salt:=strtofloat(trim(copy(st,45,11)));   //# name 4 = sal00: Salinity, Practical [PSU]
//     depth:=strtofloat(trim(copy(st,56,11)));  //# name 5 = depSM: Depth [salt water, m], lat = 79.6201
//     flag:=strtofloat(trim(copy(st,67,11)));   // flag


     //press conversion dbar -> kg/cm2
     press:=press/10;               //dbar -> bar
     press:=press*1.01971621298;    //bar  -> kg/cm2  http://www.convertunits.com/from/kg/cm2/to/bar


     Memo1.Lines.Add(inttostr(mik)
     +#9+datetimetostr(mt)
     +#9+floattostrF(temp,ffFixed,10,4)
     +#9+floattostrF(salt,ffFixed,6,3)
     +#9+floattostrF(press,ffFixed,6,3));


//insert converted data onto table CURRENTS
   with frmDM.ib1q1 do begin
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('C_TIME').AsDateTime:=mt;
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
{s}end;
{w}end;
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

     //update time series end
   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' update MOORINGS set M_TIMEEND=:recTime ');
     SQL.Add(' where absnum=:absnum');
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('recTime').AsDateTime:=mt;
     ExecSQL;
   end;

    frmDM.TR.Commit;

   Memo1.Lines.Add('...done   records processed:'+inttostr(mik));
end;



procedure TfrmUploadSBE37_cnv.btnSimpleCSVClick(Sender: TObject);
var
mik: integer;
temp,pres,salt,speed,dir,turb,oxy: real;
st: string;
mt: TDateTime; //measurement time
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



     memo1.Lines.Add('#  temp  pres  salt');
     reset(f);
     mik:=0;
{w}while not EOF(f) do begin
     readln(f,st);
     mik:=mik+1;
     //memo1.Lines.Add(inttostr(mik)+#9+st);

     speed:=-9;
     dir:=-9;
     temp:=-9;
     salt:=-9;
     pres:=-9;
     turb:=-9;
     oxy:=-9;


     temp:=strtofloat(copy(st,1,8));
     pres:=strtofloat(copy(st,10,8));
     salt:=strtofloat(copy(st,19,9));

     //press conversion dbar -> kg/cm2
     pres:=pres/10;               //dbar -> bar
     pres:=pres*1.01971621298;    //bar  -> kg/cm2  http://www.convertunits.com/from/kg/cm2/to/bar

     mt:=Start+(TimeInt*(mik-1))/1440; //add min converted to day

     memo1.Lines.Add(inttostr(mik)
     +#9+datetimetostr(mt)
     +#9+floattostr(temp)
     +#9+floattostr(pres)
     +#9+floattostr(salt));

//insert converted data onto table CURRENTS
   with frmDM.ib1q1 do begin
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('C_TIME').AsDateTime:=mt;
     ParamByName('C_ANGLE').AsFloat:=dir;
     ParamByName('C_SPEED').AsFloat:=speed;
     ParamByName('C_TEMP').AsFloat:=temp;
     ParamByName('C_SALT').AsFloat:=salt;
     ParamByName('C_PRESS').AsFloat:=pres;
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

{w}end;
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

     //update time series end
   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' update MOORINGS set M_TIMEEND=:recTime ');
     SQL.Add(' where absnum=:absnum');
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('recTime').AsDateTime:=mt;
     ExecSQL;
   end;

    frmDM.TR.Commit;



     Memo1.Lines.Add('...done   records processed:'+inttostr(mik));
end;



end.
