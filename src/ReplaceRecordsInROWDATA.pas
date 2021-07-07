unit ReplaceRecordsInROWDATA;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TfrmReplaceRecordsInROWDATA = class(TForm)
    btnSourceFile: TBitBtn;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    Label2: TLabel;
    RadioGroup1: TRadioGroup;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Edit1: TEdit;
    Label3: TLabel;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Memo2: TMemo;
    btnReplace: TBitBtn;
    procedure btnSourceFileClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnReplaceClick(Sender: TObject);
  private
    { Private declarations }
    procedure PopulateROWDATA_Table(fn_dat: string; absnum: integer;
      RStart: TDateTime; RTimeInt: integer; var RStop: TDateTime;
      var RRecNum: integer);
  public
    { Public declarations }
  end;

var
  frmReplaceRecordsInROWDATA: TfrmReplaceRecordsInROWDATA;
  RCMAbsnum: integer;  // current RCM absnum
  Start: TDateTime; //instrument start time
  TimeInt:integer;  //recording interval in minutes
  fn :string;
  f: text;


implementation

uses dm;

{$R *.lfm}

procedure TfrmReplaceRecordsInROWDATA.FormShow(Sender: TObject);
begin

    RCMAbsnum:=frmDM.Q.FieldByName('ABSNUM').AsInteger;
    frmReplaceRecordsInROWDATA.Caption:=frmReplaceRecordsInROWDATA.Caption+'  absnum='+inttostr(RCMAbsnum)
    +' RCM#='+inttostr(frmDM.Q.FieldByName('M_RCMNUM').AsInteger);

    Start  :=frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;
    TimeInt:=frmDM.Q.FieldByName('M_RCMTimeInt').AsInteger;
end;




procedure TfrmReplaceRecordsInROWDATA.btnSourceFileClick(Sender: TObject);
var
mik: integer;
st: string;
begin

     OpenDialog1.InitialDir:='c:\data\Currents\GFI\STROMDATAARKIV-301-400\391-ark-Svalbard-sept-2013\I1-inn-2013\RCM-9\';
   if OpenDialog1.Execute then
     begin
     fn := OpenDialog1.FileName;
   end;

     //RCM7 ex
     //fn:='c:\data\Currents\GFI\STROMDATAARKIV-301-400\385-faeroyene-2012-2013\S2\11633.dat';

     //RCM9 ex
     //fn:='c:\data\Currents\GFI\STROMDATAARKIV-301-400\310-ark-Faeroe\310b\195\195MA01.RAW';

     Memo1.Lines.Add('source file: ' + fn);
     Memo1.Lines.Add('start: '+datetimetostr(Start));
     Memo1.Lines.Add('interval [min]: '+inttostr(TimeInt));
     Memo1.Lines.Add('');

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
    memo1.Visible:=true;

end;


procedure TfrmReplaceRecordsInROWDATA.btnReplaceClick(Sender: TObject);
var
RecNum: Integer;
Stop: TDateTime;
begin

     frmDM.TR.StartTransaction;
  with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' DELETE FROM ROWDATA WHERE ABSNUM=:ABSNUM ');
     ParamByName('ABSNUM').AsInteger:=RCMAbsnum;
     ExecSQL;
     Close;
  end;
     frmDM.TR.Commit;

     PopulateROWDATA_Table(fn, RCMAbsnum, Start, TimeInt, Stop, RecNum);

  //add empty row into COEFFICIENTS
  with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO COEFFICIENTS(ABSNUM) VALUES (:ABSNUM) ');
     ParamByName('ABSNUM').AsInteger:=RCMAbsnum;
     ExecSQL;
     Close;
  end;
     frmDM.TR.Commit;


end;




procedure TfrmReplaceRecordsInROWDATA.PopulateROWDATA_Table(fn_dat: string; absnum: integer;
  RStart: TDateTime; RTimeInt: integer; var RStop: TDateTime;
  var RRecNum: integer);
var
  k,mik,ColNum: integer;
  buf: char;
  SC: string; //sensors composition
  val_arr: array[1..9] of integer;
  par_arr: array[1..9] of char;
  par_comp: string;

  rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed, rd_turb, rd_oxy, rd_x: integer;
  mt: TDateTime;

begin

     memo1.Lines.Clear;
     memo1.Lines.Add('');
     memo1.Lines.Add('__absnum: '+inttostr(absnum));
     memo1.Lines.Add('___start: '+datetimetostr(RStart));
     memo1.Lines.Add('interval: '+inttostr(RTimeInt));

   case RadioGroup1.ItemIndex of
   0: begin
       ColNum:=strtoint(Edit1.Text);
       SC:=trim(Edit2.Text);
      end;
   1: begin
       ColNum:=strtoint(Edit3.Text);
       SC:=trim(Edit4.Text);
      end;
   end; {case}

     //string
     par_arr[1]:='R';
     par_arr[2]:='T';
     par_arr[3]:='C';
     par_arr[4]:='P';
     par_arr[5]:='D';
     par_arr[6]:='S';
     par_arr[7]:='U';
     par_arr[8]:='O';
     par_arr[9]:='X';

     par_comp:='#  time';
     for k:=1 to ColNum do par_comp:=par_comp+'  '+par_arr[k];

     frmDM.TR.StartTransaction;

//6 fixed channels
{0}if RadioGroup1.ItemIndex=0 then begin

   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO ROWDATA ');
     SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, QFL) ');
     SQL.Add(' VALUES ');
     SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :QFL) ');
     Prepare;
   end;

     assignfile(f, fn_dat);
     reset(f);

     memo1.Lines.Add(par_comp);
     mik := 0;
     mt := RStart;
{w}while not EOF(f) do begin
{c}for k:=1 to ColNum do begin
     read(f,val_arr[k]);
     buf:=SC[k];
   case buf of
   'R': rd_ref  :=val_arr[k];
   'T': rd_temp :=val_arr[k];
   'C': rd_cond :=val_arr[k];
   'P': rd_press:=val_arr[k];
   'D': rd_dir  :=val_arr[k];
   'S': rd_speed:=val_arr[k];
   end;{case}
{c}end;
     readln(f);

{7}if rd_ref<>7 then begin  //skip records marked 0007 time not counted
    mik:=mik+1;


    //incMinute does not work in same cases -> overflow
    //if mik > 1 then mt := IncMinute(mt, RTimeInt);
    if mik > 1 then mt := RStart+(RTimeInt*(mik-1))/1440;

     memo1.Lines.Add(inttostr(mik)
     +#9+datetimetostr(mt)
     +#9+inttostr(rd_ref)
     +#9+inttostr(rd_temp)
     +#9+inttostr(rd_cond)
     +#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)
     +#9+inttostr(rd_speed));

     Application.ProcessMessages;

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
{w}end;
    closefile(f);

     RStop := mt;
     RRecNum := mik;

     frmDM.ib1q1.UnPrepare;

{0}end;



//variable number of channels

{1}if RadioGroup1.ItemIndex=1 then begin

   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' INSERT INTO ROWDATA ');

     case ColNum of
     5: SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, QFL) ');
     6: SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, QFL) ');
     7: SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, CH7, QFL) ');
     8: SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, CH7, CH8, QFL) ');
     9: SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, CH7, CH8, CH9, QFL) ');
     end;

     SQL.Add(' VALUES ');

     case ColNum of
     5: SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :QFL) ');
     6: SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :QFL) ');
     7: SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :CH7, :QFL) ');
     8: SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :CH7, :CH8, :QFL) ');
     9: SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :CH7, :CH8, :CH9, :QFL) ');
     end;

     Prepare;
   end;

     assignfile(f, fn_dat);
     reset(f);

     rd_turb:=-9;
     rd_oxy:=-9;
     rd_x:=-9;
     rd_cond:=-9;
     rd_temp:=-9;

     memo1.Lines.Add(par_comp);
     mik := 0;
     mt := RStart;
{w}while not EOF(f) do begin

     read(f, rd_ref);

{7}if rd_ref<>7 then begin  //skip records marked 0007 time not counted

    mik:=mik+1;
    val_arr[1]:=rd_ref;

{c}for k:=2 to ColNum do begin
     read(f,val_arr[k]);
     buf:=SC[k];
   case buf of
   'T': rd_temp :=val_arr[k];
   'C': rd_cond :=val_arr[k];
   'P': rd_press:=val_arr[k];
   'D': rd_dir  :=val_arr[k];
   'S': rd_speed:=val_arr[k];
   'U': rd_turb :=val_arr[k]; //turbidity
   'O': rd_oxy  :=val_arr[k]; //oxygen
   end;{case}
{c}end;

    //incMinute does not work in same cases -> overflow
    //if mik > 1 then mt := IncMinute(mt, RTimeInt);
     if mik > 1 then mt := RStart+(RTimeInt*(mik-1))/1440;

   case ColNum of
   6: memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt)+#9+inttostr(rd_ref)
     +#9+inttostr(rd_temp)+#9+inttostr(rd_cond)+#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)+#9+inttostr(rd_speed));
   7: memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt)+#9+inttostr(rd_ref)
     +#9+inttostr(rd_temp)+#9+inttostr(rd_cond)+#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)+#9+inttostr(rd_speed)+#9+inttostr(rd_turb));
   8: memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt)+#9+inttostr(rd_ref)
     +#9+inttostr(rd_temp)+#9+inttostr(rd_cond)+#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)+#9+inttostr(rd_speed)+#9+inttostr(rd_turb)
     +#9+inttostr(rd_oxy));
   9: memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt)+#9+inttostr(rd_ref)
     +#9+inttostr(rd_temp)+#9+inttostr(rd_cond)+#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)+#9+inttostr(rd_speed)+#9+inttostr(rd_turb)
     +#9+inttostr(rd_oxy)+#9+inttostr(rd_x));
   end; {case}

     {memo1.Lines.Add(inttostr(mik)
     +#9+datetimetostr(mt)
     +#9+inttostr(rd_ref)
     +#9+inttostr(rd_temp)
     +#9+inttostr(rd_cond)
     +#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)
     +#9+inttostr(rd_speed)
     +#9+inttostr(rd_turb)
     +#9+inttostr(rd_oxy)
     +#9+inttostr(rd_x));}

     Application.ProcessMessages;

   with frmDM.ib1q1 do begin
      ParamByName('ABSNUM').AsInteger := Absnum;
      ParamByName('RD_Time').AsDateTime := mt;
      ParamByName('CH1').AsInteger := rd_ref;
      ParamByName('CH2').AsInteger := rd_temp;
      ParamByName('CH3').AsInteger := rd_cond;
      ParamByName('CH4').AsInteger := rd_press;
      ParamByName('CH5').AsInteger := rd_dir;
      ParamByName('CH6').AsInteger := rd_speed;

      if colNum=7 then
      ParamByName('CH7').AsInteger := rd_turb;

      if colNum=8 then begin
      ParamByName('CH7').AsInteger := rd_turb;
      ParamByName('CH8').AsInteger := rd_oxy;
      end;

      if colNum=9 then begin
      ParamByName('CH7').AsInteger := rd_turb;
      ParamByName('CH8').AsInteger := rd_oxy;
      ParamByName('CH9').AsInteger := rd_x;
      end;

      ParamByName('QFL').AsInteger := 0;

      ExecSQL;
   end;

{7}end;

     readln(f);
{w}end;
    closefile(f);

     RStop := mt;
     RRecNum := mik;

     showmessage('Stop: '+datetimetostr(Rstop)+'   Records: '+inttostr(RRecNum));
     showmessage(frmDM.ib1q1.Sql.Text);

     frmDM.ib1q1.UnPrepare;

{1}end;

     frmDM.TR.Commit;


end;




end.
