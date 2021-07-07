unit UploadConvertedDataLST;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DateUtils, CheckLst;

type
  TfrmUploadConvertedDataLST = class(TForm)
    btnUpload: TBitBtn;
    Memo1: TMemo;
    CheckListBox1: TCheckListBox;
    Memo2: TMemo;
    procedure FormShow(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmUploadConvertedDataLST: TfrmUploadConvertedDataLST;
  RCMAbsnum: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;

implementation

uses dm;

{$R *.lfm}

procedure TfrmUploadConvertedDataLST.FormShow(Sender: TObject);
var
i,mik: integer;
st,fc:string;
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


     CheckListBox1.Items.Clear;
     assignfile(f, fn);
     reset(f);

     memo1.Visible:=false;
     mik:=0;
{f}while not EOF(f) do begin
    mik:=mik+1;
    readln(f, st);
    Memo1.Lines.Add(inttostr(mik)+#9+st);

{v}if mik=1 then begin
    fc:=trim(copy(st,17,10));
    for i:=1 to length(fc) do CheckListBox1.Items.Add(fc[i]);

    //if copy(st,1,1)='F' then CheckListBox1.Items.Add('Speed');
    //if copy(st,2,1)='A' then CheckListBox1.Items.Add('Angle');
    //if copy(st,21,1)='T' then CheckListBox1.Items.Add('Temp');
    //if copy(st,22,1)='S' then CheckListBox1.Items.Add('Salt');
    //if copy(st,22,1)='P' then CheckListBox1.Items.Add('Press');
    //if copy(st,23,1)='P' then CheckListBox1.Items.Add('Press');
{v}end;


{f}end;
    closefile(f);

   for i:=0 to CheckListBox1.Items.Count-1 do CheckListBox1.Checked[i]:=true;


    memo1.Visible:=true;
    btnUpload.Visible:=true;
end;


procedure TfrmUploadConvertedDataLST.btnUploadClick(Sender: TObject);
var
i,mik :integer;
d,m,y,h,min,sec,msec :word;

speed, dir, ucomp, vcomp, temp, salt, press, turb, oxy :real;
st: string;
temp_exist, salt_exist, press_exist: Boolean;
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
     readln(f,st);
     readln(f,st);


    mik:=0;
    memo1.Lines.Add('#  time  dir  speed  temp');
{f}while not EOF(f) do begin

    speed:=-9;
    dir:=-9;
    temp:=-9;
    salt:=-9;
    press:=-9;
    turb:=-9;
    oxy:=-9;

     mik:=mik+1;
     read(f, y, m, d, h, min);

{i}for i:=0 to CheckLIstBox1.Count-1 do begin
     if ChecklistBox1.Items.Strings[i]='F' then read(f, speed);
     if ChecklistBox1.Items.Strings[i]='A' then read(f, dir);
     if ChecklistBox1.Items.Strings[i]='U' then read(f, ucomp);
     if ChecklistBox1.Items.Strings[i]='V' then read(f, vcomp);
     if ChecklistBox1.Items.Strings[i]='T' then read(f, temp);
     if ChecklistBox1.Items.Strings[i]='S' then read(f, salt);
     if ChecklistBox1.Items.Strings[i]='P' then read(f, press);
{i}end;
                                                readln(f);

     if y>50 then y:=y+1900 else y:=y+2000;

     //if components only
{c}if (speed=-9) and (dir=-9) then begin
     speed:=sqrt(ucomp*ucomp+vcomp*vcomp);
     if (ucomp>=0) and (vcomp>=0) then dir:=arctan(ucomp/vcomp);       // 1
     if (ucomp>0)  and (vcomp<0)  then dir:=arctan(ucomp/vcomp)+180;   // 2
     if (ucomp<=0) and (vcomp<=0) then dir:=arctan(ucomp/vcomp)+180;   // 3
     if (ucomp<0)  and (vcomp>0)  then dir:=arctan(ucomp/vcomp)+360;   // 4
{c}end;


    sec:=0;
    msec:=0;
    recTime:=EncodeDateTime(y, m, d, h, min, sec, msec);

    Memo1.Lines.Add(inttostr(mik)
     +#9+datetimetostr(recTime)
     +#9+floattostr(dir)
     +#9+floattostr(speed)
     +#9+floattostr(temp)
     +#9+floattostr(salt)
     +#9+floattostr(press)
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


    frmDM.TR.Commit;


end;




end.
