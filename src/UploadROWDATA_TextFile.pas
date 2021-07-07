//UPLOAD ROW MOORINGS DATA IN TEXT FORMAT
//STEP1 - MD MANUAL TYPING
//STEP2 - DOWNLOAD

//STEP1
//FILL MD IN THE DATABASE (INCLUDING: VARIABLE - CHANNEL COMPOSITION AND PATH TO FILE WITH ROWDATA)

//STEP2
//EDIT COLUMN NUMBER IN FILE AND VARIABLE COMPOSITION IN THE MODULE FORM
//READING FORMAT DEPENDS ON LINE LENGTH (AUTOMATIC ALGORITHM IF NOT - MODIFY CODE)


unit UploadROWDATA_TextFile;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TfrmUploadROWDATA_TextFile = class(TForm)
    Label2: TLabel;
    RadioGroup1: TRadioGroup;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label3: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Memo2: TMemo;
    btnUpload: TBitBtn;
    Memo1: TMemo;
    Label4: TLabel;
    Label5: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
  private
    { Private declarations }
    procedure PopulateROWDATA_SDF(fn_dat: string; absnum: integer;
      RStart: TDateTime; RTimeInt: integer; var RStop: TDateTime;
      var RRecNum: integer);
    procedure PopulateROWDATA_ARC(fn_dat: string; absnum: integer;
      RStart: TDateTime; RTimeInt: integer; var RStop: TDateTime;
      var RRecNum: integer);
  public
    { Public declarations }
end;

var
  frmUploadROWDATA_TextFile: TfrmUploadROWDATA_TextFile;
  RCMAbsnum: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;

implementation

uses dm;

{$R *.lfm}


procedure TfrmUploadROWDATA_TextFile.FormShow(Sender: TObject);
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

     if ((extractfileext(fn))='.ark') or ((extractfileext(fn))='.ARK') then
     RadioGroup1.ItemIndex:=1;

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

    RadioGroup1.Visible:=true;
    GroupBox1.Visible:=true;


end;





procedure TfrmUploadROWDATA_TextFile.btnUploadClick(Sender: TObject);
var
RecNum: Integer;
Stop: TDateTime;
begin

     //frmDM.TR1.StartTransaction;
  with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' DELETE FROM ROWDATA WHERE ABSNUM=:ABSNUM ');
     ParamByName('ABSNUM').AsInteger:=RCMAbsnum;
     ExecSQL;
     Close;
  end;
     frmDM.TR.Commit;

     if RadioGroup1.ItemIndex=0 then
     PopulateROWDATA_SDF(fn, RCMAbsnum, Start, TimeInt, Stop, RecNum);

     if RadioGroup1.ItemIndex=1 then
     PopulateROWDATA_ARC(fn,RCMAbsnum, Start, TimeInt, Stop, RecNum);

end;


procedure TfrmUploadROWDATA_TextFile.PopulateROWDATA_SDF(fn_dat: string; absnum: integer;
  RStart: TDateTime; RTimeInt: integer; var RStop: TDateTime;
  var RRecNum: integer);
var
  mik,ColNum,i,p,fll: integer;
  buf: char;
  SC,st,st1: string; //sensors composition
  val_arr: array[1..9] of integer;
  //par_arr: array[1..9] of char;
  //par_comp: string;

  rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed: integer;
  //rd_turb, rd_oxy, rd_x: integer;

  mt: TDateTime;

begin

   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO ROWDATA ');
     SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, QFL) ');
     SQL.Add(' VALUES ');
     SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :QFL) ');
     Prepare;
   end;

     ColNum:=strtoint(Edit1.Text);
     SC:=trim(Edit2.Text);

     memo1.Lines.Clear;
     memo1.Lines.Add('');
     memo1.Lines.Add('absnum: '+inttostr(absnum));
     memo1.Lines.Add('start: '+datetimetostr(RStart));
     memo1.Lines.Add('interval: '+inttostr(RTimeInt));
     memo1.Lines.Add('sensors : '+SC);

     assignfile(f, fn);
     reset(f);

     //memo1.Visible:=false;
     mik:=0;
     mt := RStart;
     fll:=0;    //first line length
{f}while not EOF(f) do begin

   rd_ref  :=-9;
   rd_temp :=-9;
   rd_cond :=-9;
   rd_press:=-9;
   rd_dir  :=-9;
   rd_speed:=-9;

    readln(f, st);
    if mik=0 then begin
     fll:=length(TrimRight(st));
     Memo1.Lines.Add('First Line Length= '+inttostr(fll));
    end;

    //Memo1.Lines.Add(inttostr(mik)+#9+st);

    st1:='';
   for i:=1 to ColNum do begin
    val_arr[i]:=-9;


// !!! SDF DAT files have a different format
//29SYMBOLS:0007 0006 0007 0003 0017 0000
//34SYMBOLS:0321  0777  0000  0052  0989  0000
//36SYMBOLS:  0321  0777  0000  0052  0989  0000
//36SYMBOLS:  0003  0098  0000  1023  0887  0000


    if fll=29 then p:=1+5*(i-1); //29
    if fll=34 then p:=1+6*(i-1); //34
    if fll>=36 then p:=3+6*(i-1); //36

    //showmessage((copy(st,p,4)));
   if (copy(st,p,4))<>'' then val_arr[i]:=strtoint(copy(st,p,4))
                         else val_arr[i]:=1023;

    st1:=st1+'  '+inttostr(val_arr[i]);

     buf:=SC[i];
   case buf of
   'R': rd_ref  :=val_arr[i];
   'T': rd_temp :=val_arr[i];
   'C': rd_cond :=val_arr[i];
   'P': rd_press:=val_arr[i];
   'D': rd_dir  :=val_arr[i];
   'S': rd_speed:=val_arr[i];
   end;{case}

   end;

{7}if rd_ref<>7 then begin  //skip records marked 0007 time not counted
    mik:=mik+1;

    //if mik > 1 then mt := RStart+(RTimeInt*(mik-1))/1440;
    //Memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt)+#9+st1);

    if mik > 1 then mt := RStart+(RTimeInt*(mik-1))/1440;
    Memo1.Lines.Add(inttostr(mik)+#9+inttostr(fll)+#9+datetimetostr(mt)+#9+st1);

   with frmDM.ib1q1 do begin
      ParamByName('ABSNUM').AsInteger := Absnum; //current absnum
      ParamByName('RD_Time').AsDateTime := mt;
      ParamByName('CH1').AsInteger := rd_ref;
      ParamByName('CH2').AsInteger := rd_temp;
      ParamByName('CH3').AsInteger := rd_cond;
      ParamByName('CH4').AsInteger := rd_press;
      ParamByName('CH5').AsInteger := rd_dir;
      ParamByName('CH6').AsInteger := rd_speed;
      ParamByName('QFL').AsInteger := 0;
      ExecSQL;
   end;

{7}end;


{f}end;
    closefile(f);
    //memo1.Visible:=true;

     RStop := mt;
     RRecNum := mik;

     frmDM.TR.Commit;
     frmDM.ib1q1.UnPrepare;

   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO COEFFICIENTS ');
     SQL.Add(' (ABSNUM) values (:ABSNUM) ');
     ParamByName('ABSNUM').AsInteger := Absnum; //current absnum
     ExecSQL;
   end;
     frmDM.TR.Commit;

   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO TIMESERIESCORRECTION ');
     SQL.Add(' (ABSNUM) values (:ABSNUM) ');
     ParamByName('ABSNUM').AsInteger := Absnum; //current absnum
     ExecSQL;
   end;
     frmDM.TR.Commit;


end;



procedure TfrmUploadROWDATA_TextFile.PopulateROWDATA_ARC(fn_dat: string; absnum: integer;
  RStart: TDateTime; RTimeInt: integer; var RStop: TDateTime;
  var RRecNum: integer);
var
  mik,ColNum,i,p: integer;
  buf: char;
  SC,st,st1: string; //sensors composition
  val_arr: array[1..9] of integer;
  //par_arr: array[1..9] of char;
  //par_comp: string;

  rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed: integer;
  //rd_turb, rd_oxy, rd_x: integer;

  mt: TDateTime;

begin

   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO ROWDATA ');
     SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, QFL) ');
     SQL.Add(' VALUES ');
     SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :QFL) ');
     Prepare;
   end;

     ColNum:=strtoint(Edit1.Text);
     SC:=trim(Edit2.Text);

     memo1.Lines.Clear;
     memo1.Lines.Add('');
     memo1.Lines.Add('absnum: '+inttostr(absnum));
     memo1.Lines.Add('start: '+datetimetostr(RStart));
     memo1.Lines.Add('interval: '+inttostr(RTimeInt));
     memo1.Lines.Add('sensors : '+SC);

     assignfile(f, fn);
     reset(f);

     //memo1.Visible:=false;
     mik:=0;
     mt := RStart;

   // SKIP lines with MD
   for i:=1 to 12 do readln(f);

{f}while not EOF(f) do begin

   rd_ref  :=-9;
   rd_temp :=-9;
   rd_cond :=-9;
   rd_press:=-9;
   rd_dir  :=-9;
   rd_speed:=-9;

    readln(f, st);
    //Memo1.Lines.Add(inttostr(mik)+#9+st);

{s}if st <>'' then begin

    st1:='';
   for i:=1 to ColNum do begin
    val_arr[i]:=-9;
    p:=3+6*(i-1); //column position

   if (copy(st,p,4))<>'' then val_arr[i]:=strtoint(copy(st,p,4))
                         else val_arr[i]:=1023;

    st1:=st1+'  '+inttostr(val_arr[i]);

     buf:=SC[i];
   case buf of
   'R': rd_ref  :=val_arr[i];
   'T': rd_temp :=val_arr[i];
   'C': rd_cond :=val_arr[i];
   'P': rd_press:=val_arr[i];
   'D': rd_dir  :=val_arr[i];
   'S': rd_speed:=val_arr[i];
   end;{case}

   end;

{7}if rd_ref<>7 then begin  //skip records marked 0007 time not counted
    mik:=mik+1;

    if mik > 1 then mt := RStart+(RTimeInt*(mik-1))/1440;
    Memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt)+#9+st1);

   with frmDM.ib1q1 do begin
      ParamByName('ABSNUM').AsInteger := Absnum; //current absnum
      ParamByName('RD_Time').AsDateTime := mt;
      ParamByName('CH1').AsInteger := rd_ref;
      ParamByName('CH2').AsInteger := rd_temp;
      ParamByName('CH3').AsInteger := rd_cond;
      ParamByName('CH4').AsInteger := rd_press;
      ParamByName('CH5').AsInteger := rd_dir;
      ParamByName('CH6').AsInteger := rd_speed;
      ParamByName('QFL').AsInteger := 0;
      ExecSQL;
   end;

{s}end;
{7}end;


{f}end;
    closefile(f);
    //memo1.Visible:=true;

     RStop := mt;
     RRecNum := mik;

     frmDM.TR.Commit;
     frmDM.ib1q1.UnPrepare;

   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO COEFFICIENTS ');
     SQL.Add(' (ABSNUM) values (:ABSNUM) ');
     ParamByName('ABSNUM').AsInteger := Absnum; //current absnum
     ExecSQL;
   end;
     frmDM.TR.Commit;

   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO TIMESERIESCORRECTION ');
     SQL.Add(' (ABSNUM) values (:ABSNUM) ');
     ParamByName('ABSNUM').AsInteger := Absnum; //current absnum
     ExecSQL;
   end;
     frmDM.TR.Commit;


end;




end.
