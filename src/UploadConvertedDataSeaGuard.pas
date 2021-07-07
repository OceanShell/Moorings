unit UploadConvertedDataSeaGuard;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DateUtils;

type
  TfrmUploadConvertedDataSeaGuard = class(TForm)
    Label1: TLabel;
    btnUpload: TBitBtn;
    Memo1: TMemo;
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    Label2: TLabel;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Edit8: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Edit9: TEdit;
    procedure FormShow(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmUploadConvertedDataSeaGuard: TfrmUploadConvertedDataSeaGuard;
  RCMAbsnum: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;

implementation

uses dm;

{$R *.lfm}


procedure TfrmUploadConvertedDataSeaGuard.FormShow(Sender: TObject);
var
i,mik: integer;
n,colnum,ref :integer;
symbol: char;
buf,st :string;
begin
     memo1.Clear;

     RCMAbsnum:=frmDM.Q.FieldByName('ABSNUM').AsInteger;  Showmessage('absnum='+inttostr(RCMabsnum));
     Start  :=frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;
     TimeInt:=frmDM.Q.FieldByName('M_RCMTimeInt').AsInteger;
     fn:=frmDM.Q.FieldByName('M_SourceFileName').AsString;

     Memo1.Lines.Add('source file: ' + fn);
     Memo1.Lines.Add('start: '+datetimetostr(Start));
     Memo1.Lines.Add('interval [min]: '+inttostr(TimeInt));
     Memo1.Lines.Add('');


     assignfile(f, fn);
     reset(f);

     //estimate columns number from titles in second line by counting tubs
     readln(f,st);
     readln(f,st);

       mik:=1;
     for i:=1 to length(st) do begin
       symbol:=st[i];
       if symbol=#9 then mik:=mik+1;
     end;
     closefile(f);

     Edit9.Text:=inttostr(mik); //set columns number in file, edit if necessarry

     colnum:=strtoint(edit9.text);


     memo1.Lines.Add('');
     reset(f);
    //first row
     readln(f,st);   showmessage(st);
     n:=0;
{c}for i:=1 to colnum do begin  //number of columns in file
     buf:='';
   repeat
     inc(n);
     symbol:=st[n];
     if symbol<>#9 then buf:=buf+symbol;
   until symbol=#9;   // !!! #9 tabulation
     if buf<>'' then memo1.lines.add(buf);
{c}end;
     memo1.Lines.Add('');

    //second row
     readln(f,st);   showmessage(st);
     n:=0;
{c}for i:=1 to colnum do begin  //number of columns in file
     buf:='';
   repeat
     inc(n);
     symbol:=st[n];
     if symbol<>#9 then buf:=buf+symbol;
   until symbol=#9;   // !!! #9 tabulation
     if buf<>'' then memo1.lines.add(inttostr(i)+#9+buf);

     //set columns automatically
     if (buf='Temperature') or (buf='Temperature(Deg.C)')       then Edit2.Text:=inttostr(i);
     if (buf='Salinity')    or (buf='Salinity(PSU)')            then Edit3.Text:=inttostr(i);
     if (buf='Pressure')    or (buf='Pressure(kPa)')            then Edit4.Text:=inttostr(i);
     if (buf='Direction')   or (buf='Direction(Deg.M)')         then Edit5.Text:=inttostr(i);
     if (buf='Abs Speed')   or  (buf='Abs Speed(cm/s)')         then Edit6.Text:=inttostr(i);
     if buf='Turbidity'                                         then Edit7.Text:=inttostr(i);
     if (buf='O2Concentration') or (buf='O2Concentration(uM)')  then Edit8.Text:=inttostr(i);

{c}end;
     memo1.Lines.Add('');


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




procedure TfrmUploadConvertedDataSeaGuard.btnUploadClick(Sender: TObject);
var
i,mik :integer;
n,colnum,ref :integer;
tempcol,saltcol,presscol,dircol,speedcol,turbcol,oxycol :integer;
d,m,y,h,min,sec,msec :word;
speed, dir, temp, salt, press, turb, oxy :real;
symbol: char;
buf,st :string;
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

     colnum:=strtoint(edit9.text);

     if(edit2.text<>'') then tempcol:=strtoint(edit2.text)  else tempcol:=-9;
     if(edit3.text<>'') then saltcol:=strtoint(edit3.text)  else saltcol:=-9;
     if(edit4.text<>'') then presscol:=strtoint(edit4.text) else presscol:=-9;
     if(edit5.text<>'') then dircol:=strtoint(edit5.text)   else dircol:=-9;
     if(edit6.text<>'') then speedcol:=strtoint(edit6.text) else speedcol:=-9;
     if(edit7.text<>'') then turbcol:=strtoint(edit7.text)  else turbcol:=-9;
     if(edit8.text<>'') then oxycol:=strtoint(edit8.text)   else oxycol:=-9;

     memo1.Lines.Add('column number in file: '+inttostr(colnum));
     memo1.Lines.Add('');
     memo1.Lines.Add('direction in column   : '+inttostr(dircol));
     memo1.Lines.Add('speed in column       : '+inttostr(speedcol));
     if tempcol<>-9 then
     memo1.Lines.Add('temperature in column : '+inttostr(tempcol));
     if saltcol<>-9 then
     memo1.Lines.Add('salinity in column    : '+inttostr(saltcol));
     if presscol<>-9 then
     memo1.Lines.Add('pressure in column    : '+inttostr(presscol));
     if presscol<>-9 then
     memo1.Lines.Add('turbidity in column   : '+inttostr(turbcol));
     if oxycol<>-9 then
     memo1.Lines.Add('oxygen in column      : '+inttostr(oxycol));


     memo1.Lines.Add('');
     reset(f);
    //first row
     readln(f,st);   //showmessage(st);
    //second row
     readln(f,st);   //showmessage(st);


     mik:=0;
     memo1.lines.add('');
     memo1.Lines.Add('#  time  dir  speed  temp  salt  press turb oxy');
{f}while not EOF(f) do begin

     ref:=-9;
     speed:=-9;
     dir:=-9;
     temp:=-9;
     salt:=-9;
     press:=-9;
     turb:=-9;
     oxy:=-9;

     mik:=mik+1;
     readln(f, st);

    n:=0;
{c}for i:=1 to colnum do begin  //number of columns in file
     buf:='';
   repeat
     inc(n);
     symbol:=st[n];
     if symbol<>#9 then buf:=buf+symbol;
   until symbol=#9;   // !!! #9 tabulation
   //showmessage('buf='+buf);

//column selection with required variables
     //ref
     if i=1 then ref:=strtoint(buf);
     //time
     if i=2 then begin  //ex: 06.09.12 13:00:01
       //memo1.lines.add('date='+buf);
       d:=strtoint(copy(buf,1,2));
       m:=strtoint(copy(buf,4,2));
       y:=strtoint(copy(buf,7,2));
       h:=strtoint(copy(buf,10,2));
       min:=strtoint(copy(buf,13,2));
       sec:=strtoint(copy(buf,16,2));
     end;
     //temperature
     if (i=tempcol)  and (tempcol<>-9)  then temp:=strtofloat(buf);
     //salinity
     if (i=saltcol)  and (saltcol<>-9)  then salt:=strtofloat(buf);

     //pressure
     if (i=presscol) and (presscol<>-9) then begin
      press:=strtofloat(buf);
      //convert from kPa to kg/cm2
      press:=0.010197*press;
     end;

     //direction
     if (i=dircol)   and (dircol<>-9)   then dir:=strtofloat(buf);
     //speed
     if (i=speedcol) and (speedcol<>-9) then speed:=strtofloat(buf);
     //turbidity
     if (i=turbcol) and (turbcol<>-9)   then turb:=strtofloat(buf);

     //oxygen
     if (i=oxycol) and (oxycol<>-9)     then begin
      oxy:=strtofloat(buf);
      // convert from uM (M=mole/litre) to ml/l
      oxy:=oxy/44.66;
     end;



{c}end;

    if y>50 then y:=y+1900 else y:=y+2000;
    msec:=0;
    recTime:=EncodeDateTime(y, m, d, h, min, sec, msec);

     Memo1.Lines.Add(inttostr(mik)
     +#9+inttostr(ref)
     +#9+datetimetostr(recTime)
     +#9+floattostr(dir)
     +#9+floattostr(speed)
     +#9+floattostr(temp)
     +#9+floattostr(salt)
     +#9+floattostrF(press,ffFixed,7,3)
     +#9+floattostr(turb)
     +#9+floattostrF(oxy,ffFixed,7,3)
     );


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
     ParamByName('recTime').AsDateTime:=recTime;
     ExecSQL;
   end;

   Memo1.Lines.Add('...done   records processed:'+inttostr(mik));

    frmDM.TR.Commit;


end;




end.
