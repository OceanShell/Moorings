unit UploadConvertedData_MatLab;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmUploadConvertedData_MatLab = class(TForm)
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
  frmUploadConvertedData_MatLab: TfrmUploadConvertedData_MatLab;
  RCMAbsnum, csv: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;


implementation

uses dm;


{$R *.lfm}


procedure TfrmUploadConvertedData_MatLab.FormShow(Sender: TObject);
var
mik: integer;
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
{f}while not EOF(f) do begin
    mik:=mik+1;
    readln(f, st);
    Memo1.Lines.Add(inttostr(mik)+#9+st);
{f}end;
    closefile(f);

    memo1.Visible:=true;
    btnUpload.Visible:=true;
end;


procedure TfrmUploadConvertedData_MatLab.btnUploadClick(Sender: TObject);
var
k,n,mik: integer;
recT: real;
temp,salt,dens,press: real;
//symbol: string[1];
symbol: char;
st,buf_str: string;
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
     memo1.Lines.Add('#  time  speed  dir  temp');
     mik:=0;
{f}while not EOF(f) do begin

     readln(f,st);

     mik:=mik+1;
     if mik>0 then rectime:=Start+(TimeInt*(mik-1))/1440; //add min converted to day

     st:=trim(st);
     st:=st+',';

     temp:=-9;
     salt:=-9;
     dens:=-9;
     press:=-9;

     n:=0;
{s}for k:=1 to 5 do begin
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
      1: recT:=strtofloat(buf_str);
      2: if buf_str<>'NaN' then temp :=strtofloat(buf_str) else temp :=-9;
      3: if buf_str<>'NaN' then salt :=strtofloat(buf_str) else salt :=-9;
      4: if buf_str<>'NaN' then dens :=strtofloat(buf_str) else dens :=-9;
      5: if buf_str<>'NaN' then press:=strtofloat(buf_str) else press:=-9;
      end; {case}

{s}end;

     //press conversion dbar -> kg/cm2
     press:=press/10;               //dbar -> bar
     press:=press*1.01971621298;    //bar  -> kg/cm2  http://www.convertunits.com/from/kg/cm2/to/bar

    Memo1.Lines.Add(datetimetostr(rectime)
     +#9+floattostr(temp)
     +#9+floattostr(salt)
     +#9+floattostr(dens)
     +#9+floattostr(press)
     );

//insert converted data onto table CURRENTS
   with frmDM.ib1q1 do begin
     ParamByName('ABSNUM').AsInteger:=RCMabsnum;
     ParamByName('C_TIME').AsDateTime:=recTime;
     ParamByName('C_ANGLE').AsFloat:=-9;
     ParamByName('C_SPEED').AsFloat:=-9;
     ParamByName('C_TEMP').AsFloat:=temp; //prefered temperature channel
     ParamByName('C_SALT').AsFloat:=salt;
     ParamByName('C_PRESS').AsFloat:=press;//always channel 4
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


    Memo1.Lines.Add('...done');

end;



end.
