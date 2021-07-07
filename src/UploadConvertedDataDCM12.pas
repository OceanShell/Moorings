// DCM12 Dopler Current Meter Aanderaa
// module uploads processed data from .ask file
//only speed and direction

unit UploadConvertedDataDCM12;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmUploadConvertedDataDCM12 = class(TForm)
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
  frmUploadConvertedDataDCM12: TfrmUploadConvertedDataDCM12;
  RCMAbsnum: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;


implementation

uses dm;

{$R *.lfm}



procedure TfrmUploadConvertedDataDCM12.FormShow(Sender: TObject);
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
     readln(f, st);
   if st<>'' then begin
     mik:=mik+1;
     Memo1.Lines.Add(inttostr(mik)+#9+st);
   end;

{f}end;
    closefile(f);

    memo1.Visible:=true;
    btnUpload.Visible:=true;

end;

procedure TfrmUploadConvertedDataDCM12.btnUploadClick(Sender: TObject);
var
mik: integer;
speed, dir, temp, salt, press, turb, oxy :real;
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



     memo1.Lines.Add('');
     memo1.Lines.Add('#           time                                    speed       dir');


     reset(f);
    //skip lines
     readln(f);
     readln(f);

     memo1.Lines.Add('#  time  speed  dir  ');
     mik:=0;
{w}while not EOF(f) do begin

     readln(f,st);

{s}if st<>'' then begin
     mik:=mik+1;
     mt:=Start+(TimeInt*(mik-1))/1440; //add min converted to day

     speed:=-9;
     dir:=-9;
     temp:=-9;
     salt:=-9;
     press:=-9;
     turb:=-9;
     oxy:=-9;

     speed:=strtofloat(trim(copy(st,13,8)));
     dir  :=strtofloat(trim(copy(st,21,8)));

     Memo1.Lines.Add(inttostr(mik)
     +#9+datetimetostr(mt)
     +#9+floattostrF(speed,ffFixed,10,1)
     +#9+floattostrF(dir,ffFixed,10,1));

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

{s}end; //skip empty lines
{w}end;
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
     ParamByName('recTime').AsDateTime:=mt;
     ExecSQL;
   end;

    frmDM.TR1.Commit;

    Memo1.Lines.Add('...done   records processed:'+inttostr(mik));

end;
end.
