unit Grapher_CompositeDrawning;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, Buttons, IniFiles, DateUtils;

type
  TfrmGrapher_CompositeDrawning = class(TForm)
    Memo1: TMemo;
    CheckListBox1: TCheckListBox;
    GroupBox1: TGroupBox;
    btn_CreateGrapherPlot: TBitBtn;
    btn_AllSelectedInstruments: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure btn_CreateGrapherPlotClick(Sender: TObject);
    procedure btn_AllSelectedInstrumentsClick(Sender: TObject);
  private
    { Private declarations }
    procedure CompositePlot(SinglePlot: Boolean);
  public
    { Public declarations }
  end;

var
  frmGrapher_CompositeDrawning: TfrmGrapher_CompositeDrawning;
  SA, RCM, BD, RCMD, TInt, RRow, RConv, RCM_QFL: Integer;
  RCMLat, RCMLon, MC :real;
  TStart,TStop :TDateTime;
  PI, Project, CS, RCMType, RCM_ID :string;
  sensors: string[9];

  vmin_arr,vmax_arr,vmd_arr,vsd_arr: array[1..9] of real;
  CFL_count,TFL_count,SFL_count,PFL_count,UFL_count,OFL_count,XFL_count: integer;

  RStart,RStop: TDateTime;
  f_out, script: text;


implementation

{$R *.lfm}

uses dm, msettings, mmain;


procedure TfrmGrapher_CompositeDrawning.FormShow(Sender: TObject);
var
i, vn: integer;
VarName_arr: array [1..8] of string;
begin

     memo1.Clear;

     SA      := frmDM.Q.FieldByName('ABSNUM').AsInteger;           //RCM absnum
     RCM_ID  := frmDM.Q.FieldByName('M_ID').AsString;              //mooring identificator
     RCM_QFL := frmDM.Q.FieldByName('M_QFLAG').AsInteger;          //RCM absnum
     RCM     := frmDM.Q.FieldByName('M_RCMNUM').AsInteger;         //RCM #
     RCMD    := frmDM.Q.FieldByName('M_RCMDEPTH').AsInteger;       //RCM depth
     RCMLat  := frmDM.Q.FieldByName('M_LAT').AsFloat;              //RCM latitude
     RCMLon  := frmDM.Q.FieldByName('M_LON').AsFloat;              //RCM longitude
     sensors := frmDM.Q.FieldByName('M_SENSORS').AsString;         //sensors composition
     BD      := frmDM.Q.FieldByName('M_BottomDEpth').AsInteger;    //bottom depth
     TStart  := frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;       //RCM start date and time
     TStop   := frmDM.Q.FieldByName('M_TimeEnd').AsDateTime;       //RCM end date and time
     TInt    := frmDM.Q.FieldByName('M_RCMTimeInt').AsInteger;     //RCM end date and time
     RRow    := frmDM.Q.FieldByName('M_Rec_Row').AsInteger;        //# of records row data
     RConv   := frmDM.Q.FieldByName('M_Rec_Cur').AsInteger;        //# of records converted data
     PI      := frmDM.Q.FieldByName('M_PI').AsString;              //Principal Investigator
     Project := frmDM.Q.FieldByName('M_ProjectName').AsString;    //Project name
     CS      := frmDM.Q.FieldByName('M_CalibrationSheet').AsString;//Name of pdf with calibration coefficients
     RCMType := frmDM.Q.FieldByName('M_RCMType').AsString;         //RCM type
     MC      := frmDM.Q.FieldByName('M_DirCorrection').AsFloat;    //magnetic correction for direction

     memo1.Lines.Add('...absnum  : '+#9+inttostr(SA));
     memo1.Lines.Add('...RCM#    : '+#9+inttostr(RCM));
     memo1.Lines.Add('...RCM ID  : '+#9+RCM_ID);
     memo1.Lines.Add('...sensors : '+#9+sensors);


     vn:=0;
     sensors[1]:='0';  //CH1 reference will not used
{1}for i:=1 to 9 do begin
{s}if sensors[i]<>'0' then begin
     vn:=vn+1;
     case i of
     2: varName_arr[vn]:='CH2:Temperature';
     3: varName_arr[vn]:='CH3:Salinity';
     4: if sensors[i]='P' then varName_arr[vn]:='CH4:Pressure'
                          else varName_arr[vn]:='CH4:Temperature';
     5: varName_arr[vn]:='CH5:Direction';
     6: varName_arr[vn]:='CH6:Speed';
     7: varName_arr[vn]:='CH7:Turbidity';
     8: varName_arr[vn]:='CH8:Oxygen';
     end; {case}

     CheckListBox1.Items.Add(varName_arr[vn]);

{s}end;
{1}end;

      for i:=0 to vn-1 do CheckListBox1.Checked[i]:=true;

end;





procedure TfrmGrapher_CompositeDrawning.btn_CreateGrapherPlotClick(
  Sender: TObject);
var
i,rval,mik: integer;
cval: real;
vmin,vmax,sv,sv2: double;
fn: string;
rec_time: TDateTime;
splot: boolean;
begin

     //reload sensors string
     sensors := frmDM.Q.FieldByName('M_SENSORS').AsString; //sensors composition
     sensors[1]:='0';  //CH1 reference will not used

     for i:=0 to CheckListBox1.Count-1 do
     if CheckListBox1.Checked[i]=false then sensors[i+2]:='0';

     memo1.Lines.Add('');
     memo1.Lines.Add(sensors);

     //number of flags=9 set on converted variables
     CFL_count:=0;
     TFL_count:=0;
     SFL_count:=0;
     PFL_count:=0;
     UFL_count:=0;
     OFL_count:=0;

{i}for i:=1 to 9 do begin
     vmin_arr[i]:=9999;
     vmax_arr[i]:=-9999;
     vmd_arr[i] :=0;
     vsd_arr[i] :=0;
{s}if sensors[i]<>'0' then begin

{c}case i of

2: begin //CH2: row -> converted temperature
      fn:=GlobalUnloadPath+'currents\grf\CH2_temp.dat';
      assignfile(f_out, fn);
      rewrite(f_out);
      //memo1.Lines.Add('...temp from CH2 in '+fn);

{q}if RCM_QFL<>9 then begin
      //get temperature records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as TFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_TFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        TFL_count:=FieldByName('TFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH2,C_TEMP FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_tfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH2').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_TEMP').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[2]:=vmin;
     vmax_arr[2]:=vmax;
     if mik<>0 then begin
     vmd_arr[2] :=sv/mik;
     vsd_arr[2] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[2]<>0 then vsd_arr[2]:=sqrt(abs(vsd_arr[2]));
     end;
{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH2 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH2').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;


//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Temp FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_TFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Temp').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[2]:=vmin;
     vmax_arr[2]:=vmax;
     if mik<>0 then begin
     vmd_arr[2] :=sv/mik;
     vsd_arr[2] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[2]<>0 then vsd_arr[2]:=sqrt(abs(vsd_arr[2]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;



{2}end;


3: begin //CH3: conductivity -> salinity
      fn:=GlobalUnloadPath+'currents\grf\CH3_salt.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get salinity records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as SFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_SFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        SFL_count:=FieldByName('SFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH3,C_SALT FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_sfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH3').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_SALT').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[3]:=vmin;
     vmax_arr[3]:=vmax;
     if mik<>0 then begin
     vmd_arr[3] :=sv/mik;
     vsd_arr[3] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[3]<>0 then vsd_arr[3]:=sqrt(abs(vsd_arr[3]));
     end;
{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH3 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH3').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Salt FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_SFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Salt').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[3]:=vmin;
     vmax_arr[3]:=vmax;
     if mik<>0 then begin
     vmd_arr[3] :=sv/mik;
     vsd_arr[3] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[3]<>0 then vsd_arr[3]:=sqrt(abs(vsd_arr[3]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{3}end;


4: begin //CH4: row -> converted pressure
      if sensors[i]='P' then fn:=GlobalUnloadPath+'currents\grf\CH4_press.dat'
                        else fn:=GlobalUnloadPath+'currents\grf\CH4_temp.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get pressure/temp records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as PFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_PFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        PFL_count:=FieldByName('PFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH4,C_PRESS FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_pfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH4').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_PRESS').AsFloat;

   //convert kg/m2 -> bar -> m
   if sensors[i]='P' then begin
     cval:=cval*0.98;                                 // kg/cm2 -> bar
     cval:=cval*10.19977334;                          // bar -> meter
   end;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;


     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[4]:=vmin;
     vmax_arr[4]:=vmax;
     if mik<>0 then begin
     vmd_arr[4] :=sv/mik;
     vsd_arr[4] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[4]<>0 then vsd_arr[4]:=sqrt(abs(vsd_arr[4]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH4 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH4').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Press FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_PFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Press').AsFloat;

   //new convert kg/m2 -> bar -> m
   if sensors[i]='P' then begin
     cval:=cval*0.98;                                 // kg/cm2 -> bar
     cval:=cval*10.19977334;                          // bar -> meter
   end;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[4]:=vmin;
     vmax_arr[4]:=vmax;
     if mik<>0 then begin
     vmd_arr[4] :=sv/mik;
     vsd_arr[4] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[4]<>0 then vsd_arr[4]:=sqrt(abs(vsd_arr[4]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{4}end;


5: begin //CH5: row -> converted current direction
      fn:=GlobalUnloadPath+'currents\grf\CH5_dir.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get current records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as CFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_CFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        CFL_count:=FieldByName('CFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH5,C_ANGLE FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_cfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH5').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_ANGLE').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

//showmessage(datetimetostr(rec_time)
//     +#9+inttostr(rval)
//     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[5]:=vmin;
     vmax_arr[5]:=vmax;
     if mik<>0 then begin
     vmd_arr[5] :=sv/mik;
     vsd_arr[5] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[5]<>0 then vsd_arr[5]:=sqrt(abs(vsd_arr[5]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH5 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH5').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Angle FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_CFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Angle').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[5]:=vmin;
     vmax_arr[5]:=vmax;
     if mik<>0 then begin
     vmd_arr[5] :=sv/mik;
     vsd_arr[5] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[5]<>0 then vsd_arr[5]:=sqrt(abs(vsd_arr[5]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{5}end;



6: begin //CH5: row -> converted current speed
      fn:=GlobalUnloadPath+'currents\grf\CH6_speed.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get current records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as CFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_CFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        CFL_count:=FieldByName('CFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH6,C_SPEED FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_cfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH6').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_SPEED').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[6]:=vmin;
     vmax_arr[6]:=vmax;
     if mik<>0 then begin
     vmd_arr[6] :=sv/mik;
     vsd_arr[6] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[6]<>0 then vsd_arr[6]:=sqrt(abs(vsd_arr[6]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH6 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH6').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Speed FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_CFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Speed').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[6]:=vmin;
     vmax_arr[6]:=vmax;
     if mik<>0 then begin
     vmd_arr[6] :=sv/mik;
     vsd_arr[6] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[6]<>0 then vsd_arr[6]:=sqrt(abs(vsd_arr[6]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;

{6}end;



7: begin //CH7: row -> converted turbidity
      fn:=GlobalUnloadPath+'currents\grf\CH7_turb.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get turbidity records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as UFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_UFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        UFL_count:=FieldByName('UFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH7,C_TURB FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_ufl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH7').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_TURB').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[7]:=vmin;
     vmax_arr[7]:=vmax;
     if mik<>0 then begin
     vmd_arr[7] :=sv/mik;
     vsd_arr[7] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[7]<>0 then vsd_arr[7]:=sqrt(abs(vsd_arr[7]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH7 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH7').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Turb FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_UFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Turb').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[7]:=vmin;
     vmax_arr[7]:=vmax;
     if mik<>0 then begin
     vmd_arr[7] :=sv/mik;
     vsd_arr[7] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[7]<>0 then vsd_arr[7]:=sqrt(abs(vsd_arr[7]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{7}end;


8: begin //CH8: row -> converted oxygen
      fn:=GlobalUnloadPath+'currents\grf\CH8_oxyg.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get oxygen records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as OFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_OFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        OFL_count:=FieldByName('OFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH8,C_OXYG FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.C_Ofl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH8').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_OXYG').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[8]:=vmin;
     vmax_arr[8]:=vmax;
     if mik<>0 then begin
     vmd_arr[8] :=sv/mik;
     vsd_arr[8] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[8]<>0 then vsd_arr[8]:=sqrt(abs(vsd_arr[8]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH8 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH8').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Oxyg FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_OFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Oxyg').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[8]:=vmin;
     vmax_arr[8]:=vmax;
     if mik<>0 then begin
     vmd_arr[8] :=sv/mik;
     vsd_arr[8] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[8]<>0 then vsd_arr[8]:=sqrt(abs(vsd_arr[8]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{8}end;


{c}end; {case}
{s}end; {if sensors[i]<>'0'}
{i}end; {sensors 1..9}

      splot:=true;
      CompositePLot(splot);

end;



procedure TfrmGrapher_CompositeDrawning.CompositePlot(SinglePlot: Boolean);
var
 i, flagged: integer;
 vmin,vmax,vmd,vsd,duration :real;
 tpx,tpy,RL,Rt,RR,RB :real;
 str, str_a: string;

 xpos,ypos :real;
 Ini:TIniFile;
 qchar: char;
 scripter,cmd,vn,vu,vpath:string;
 StartupInfo:  TStartupInfo;
 //ProcessInfo:  TProcessInformation;
begin

qchar:='"';

AssignFile(script, GlobalUnloadPath+'currents\grf\CompositePlot.bas');
rewrite(script);

//create script
Writeln(script, 'Sub Main');
Writeln(script, '');
Writeln(script, ' Dim GrapherApp As Object');
Writeln(script, ' Dim CompositePlot As Object');
Writeln(script, ' Dim vGraph As Object');
Writeln(script, '');

Writeln(script, ' Set GrapherApp = CreateObject("Grapher.Application") ');
//AK 20.10.2016
if SinglePlot=true then Writeln(script, ' GrapherApp.Visible = True')
                   else Writeln(script, ' GrapherApp.Visible = False');
Writeln(script, '');

Writeln(script, ' Set CompositePlot = GrapherApp.Documents.Add(grfPlotDoc) ');
Writeln(script, ' CompositePlot.PageSetup.Orientation=grfPortrait ');
Writeln(script, '');

//title line 01:RCM Composite PLot
str:='Time series composite PLot (mooring ID:'+RCM_ID+')';
str:=AnsiQuotedStr(str,qchar);

//Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,26.5,"Composite PLot") ');
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,26.5, ' +str +')' );
Writeln(script, ' txt.Font.Size=14 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');

//rectangles  left,top,right,bottom,xradius,yradius,ID
Writeln(script, ' CompositePlot.Shapes.AddRectangle(0.5, 25.6, 21, 21.1, 0.2,0.2,"RectangleTop") ');
Writeln(script, ' CompositePlot.Shapes.AddRectangle(0.5, 2.6,  21, 1.6,  0.2,0.2,"RectangleBottom") ');


//database
str:='database     :'+extractfilename(IBName);
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,25.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//absnum
str:='absnum       :'+inttostr(SA)+'  (internal QC flag='+inttostr(RCM_QFL)+')';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,25,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//RCM number & RCM Type
str:='RCM#         :'+inttostr(RCM)+'  ('+RCMType+')';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,24.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Color=grfColorRed ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//RCM depth
str:='RCM depth    :'+inttostr(RCMD);
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,24,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//bottom depth
if BD <>-9 then  str:='Bottom depth       :'+inttostr(BD)
              else str:='Bottom depth       : n/a';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(12,24,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//start
str:='start        :'+datetimetostr(TStart);
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,23.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//stop
str:='stop         :'+datetimetostr(TStop);
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,23,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//RCM time interval
str:='interval     :'+inttostr(TInt)+' min';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,22.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');

//RCM latitude
str:='latitude     :'+floattostrF(RCMLat,ffFixed,9,5);
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,22,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Color=grfColorBlue ');
Writeln(script, ' txt.Font.Bold=true ');
//RCM longitude
str:='longitude    :'+floattostrF(RCMLon,ffFixed,9,5);
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(2.5,21.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Color=grfColorBlue ');
Writeln(script, ' txt.Font.Bold=true ');


//RCM duration
     duration:=(DaySpan(TStop,TStart));
str:='duration           :'+floattostrF(duration,ffFixed,7,2)+' days';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(12,22.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');

//RCM magnetic correction
str:='magnetic correction:'+floattostrF(MC,ffFixed,7,1)+' deg. (not added)';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(12,22,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');


//records#  row data
str:='records# row data  :'+inttostr(RRow)+' (unflagged)';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(12,23.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//records#  converted data
if RConv<=0 then RConv:=0;
str:='records# converted :'+inttostr(RConv);
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(12,23,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');

//PI
if PI <>'' then str:='PI                 :'+PI
           else str:='PI                 : n/a';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(12,25.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//Project
if Project<>'' then str:='Project            :'+Project
               else str:='Project            : n/a';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(12,25,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Bold=true ');
//Calibration sheet
if CS<>'' then str:='Calibration Sheet  :'+CS
          else str:='Calibration Sheet  : n/a';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(12,21.5,' +str +')' );
Writeln(script, ' txt.Font.Size=10 ');
Writeln(script, ' txt.Font.Face="Courier New" ');
Writeln(script, ' txt.Font.Color=grfColorRed ');
Writeln(script, ' txt.Font.Bold=true ');


//bottom line 01: two time series
str:='Note. Each graph contains time series in engineering (left axis, black curve) and physical (right axis, red curve) units.';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(3,2.5,' +str +')' );
Writeln(script, ' txt.Font.Size=8 ');
Writeln(script, ' txt.Font.Face="Times New Roman" ');
Writeln(script, ' txt.Font.Bold=true ');
//bottom line 02: two time series
str:='Number of flagged values as well min, max, mean and standard deviations in physical units are shown to the right.';
str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set txt=CompositePlot.Shapes.AddText(3,2,' +str +')' );
Writeln(script, ' txt.Font.Size=8 ');
Writeln(script, ' txt.Font.Face="Times New Roman" ');
Writeln(script, ' txt.Font.Bold=true ');






//fixed plot position for variable rowdata (left axis) converted data (right axis)
//1-speed  2-direction 3-temp from CH2  4-cond/salt
//5-press or temp from CH4  6-turbidity 7-oxygen

//AK
{s}for i:=2 to 9 do begin {max 7 plots on page at fixed positions 1-ref/9-reserved}
   //change sequence: SDTSPUO speed-dir-temp-salt-press-turb-oxyg


{0}if sensors[i]<>'0' then begin

      vmin:=vmin_arr[i];
      vmax:=vmax_arr[i];
      vmd :=vmd_arr[i];
      vsd :=vsd_arr[i];
      //showmessage(floattostr(vmin)+'  '+floattostr(vmax)+'  '+floattostr(vmd)+'  '+floattostr(vsd));

   case i of
   2: begin
      vn:='Temperature';   //variable name
      vu:='(C)';  //variable units
      vpath:=GlobalUnloadPath+'\currents\grf\CH2_Temp.dat';
      xpos:=4;
      ypos:=13.5;
      flagged:=TFL_count;
      end;
   3: begin
      vn:='Conductivity';   //variable name
      vu:='(PSU)';  //variable units
      vpath:=GlobalUnloadPath+'currents\grf\CH3_Salt.dat';
      xpos:=4;
      ypos:=11;
      flagged:=SFL_count;
      end;
   4: begin
      if sensors[i]='P' then begin
      vn:='Pressure';   //variable name
      vu:='(m)';  //variable units
      vpath:=GlobalUnloadPath+'currents\grf\CH4_Press.dat';
      xpos:=4;
      ypos:=8.5;
      flagged:=PFL_count;
      end;
      if sensors[i]='T' then begin
      vn:='Temperature';   //variable name
      vu:='(C)';  //variable units
      vpath:=GlobalUnloadPath+'currents\grf\CH4_Temp.dat';
      xpos:=4;
      ypos:=8.5;
      end;
      flagged:=PFL_count;
      end;
   5: begin
      vn:='Direction';   //variable name
      vu:='(deg)';  //variable units
      vpath:=GlobalUnloadPath+'currents\grf\CH5_Dir.dat';
      xpos:=4;
      ypos:=16;
      flagged:=CFL_count;
      end;
   6: begin
      vn:='Speed';   //variable name
      vu:='(cm/s)';  //variable units
      vpath:=GlobalUnloadPath+'currents\grf\CH6_Speed.dat';
      xpos:=4;
      ypos:=18.5;
      flagged:=CFL_count;
      end;
   7: begin
      vn:='Turbidity';   //variable name
      vu:='(NTU)';  //variable units
      vpath:=GlobalUnloadPath+'currents\grf\CH7_Turb.dat';
      xpos:=4;
      ypos:=6;
      flagged:=UFL_count;
      end;
   8: begin
      vn:='Oxygen';   //variable name
      vu:='(%)';  //variable units
      vpath:=GlobalUnloadPath+'currents\grf\CH8_Oxyg.dat';
      xpos:=4;
      ypos:=3.5;
      flagged:=OFL_count;
      end;
   9: begin
      vn:='XXX';   //variable name
      vu:='(xxx)';  //variable units
      vpath:=GlobalUnloadPath+'currents\grf\CH9_XXX.dat';
      xpos:=4;
      ypos:=1;
      flagged:=XFL_count;
      end;
   end; {case}

//text: statistics min,max,md,sd
     tpx:=18;             //text position along X axis

     tpy:=yPos+1.9;         //text position along Y axis
     str:='flagged# '+inttostr(flagged);
     str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set Text_stat=CompositePlot.Shapes.AddText('+floattostr(tpx)+','+floattostr(tpy)+','+str+') ');
Writeln(script, ' Text_stat.Font.Size=8 ');

     tpy:=yPos+1.5;         //text position along Y axis
     str:='min='+floattostrF(vmin,ffFixed,6,3);
     str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set Text_stat=CompositePlot.Shapes.AddText('+floattostr(tpx)+','+floattostr(tpy)+','+str+') ');
Writeln(script, ' Text_stat.Font.Size=8 ');

     tpy:=yPos+1.1;         //text position along Y axis
     str:='max='+floattostrF(vmax,ffFixed,6,3);
     str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set Text_stat=CompositePlot.Shapes.AddText('+floattostr(tpx)+','+floattostr(tpy)+','+str+') ');
Writeln(script, ' Text_stat.Font.Size=8 ');

     tpy:=yPos+0.7;         //text position along Y axis
     str:='md='+floattostrF(vmd,ffFixed,6,3);
     str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set Text_stat=CompositePlot.Shapes.AddText('+floattostr(tpx)+','+floattostr(tpy)+','+str+') ');
Writeln(script, ' Text_stat.Font.Size=8 ');
Writeln(script, ' Text_stat.Font.Color=grfColorRed ');



     tpy:=yPos+0.3;         //text position along Y axis
     str:='sd='+floattostrF(vsd,ffFixed,6,3);
     str:=AnsiQuotedStr(str,qchar);
Writeln(script, ' Set Text_stat=CompositePlot.Shapes.AddText('+floattostr(tpx)+','+floattostr(tpy)+','+str+') ');
Writeln(script, ' Text_stat.Font.Size=8 ');

//rectangle around statistics
RL:=17.7;   //position left
RT:=yPos+2; //         top
RR:=20;     //         right
RB:=yPos;   //         bottom

Writeln(script, ' CompositePlot.Shapes.AddRectangle('
     +floattostr(RL)
     +','+floattostr(RT)
     +','+floattostr(RR)
     +','+floattostr(RB) +')');


writeln(script,'vn=',AnsiQuotedStr(vn,qchar));
writeln(script,'vu=',AnsiQuotedStr(vu,qchar));
writeln(script,'vpath=',AnsiQuotedStr(vpath,qchar));


Writeln(script, ' Set vGraph=CompositePlot.Shapes.AddLinePlotGraph(vpath,1,2,vn) ');
Writeln(script, '');

//new set color to white
if (RRow=0) then begin
Writeln(script, ' Set RowData=vGraph.Plots.Item(1) ');               //set name on plot
Writeln(script, ' RowData.line.style="Invisible" ');                 //set line invisible
end;



Writeln(script, ' CompositePlot.ReloadWorksheets ');
Writeln(script, '');

//x axis settings
Writeln(script, ' Set XAxis =vGraph.Axes.Item(1) ');
Writeln(script, ' XAxis.length=12 ');
Writeln(script, ' XAxis.xPos='+floattostr(xpos));
Writeln(script, ' XAxis.yPos='+floattostr(ypos));
Writeln(script, ' XAxis.Tickmarks.MajorLength=0.2 ');
Writeln(script, ' XAxis.Tickmarks.MinorLength=0 ');
//datetime: 4=d-mmmm-yy  6=mmm-yy  25=dd/mm/yy
Writeln(script, ' XAxis.TickLabels.MajorFormat.DateTimeFormat = 6 ');
Writeln(script, ' XAxis.TickLabels.MajorFont.size=8 ');
Writeln(script, ' XAxis.TickLabels.MajorOffset=0.05 ');
Writeln(script, '');
//Writeln(script, ' XAxis.title.text="Time" ');
//Writeln(script, ' XAxis.title.Font.color=grfColorRed ');
//limits ex: XAxis.Min=DateValue("29.09.1998 12:00:00")
//Writeln(script, '  XAxis.AutoMin=False ');
//Writeln(script, '  XAxis.AutoMax=False ');
//Writeln(script, ' XAxis.Min=DateValue('+AnsiQuotedStr(datetimetostr(MStart),qchar)+')');
//Writeln(script, ' XAxis.Max=DateValue('+AnsiQuotedStr(datetimetostr(MStop) ,qchar)+')');
//Writeln(script, '');

//y axis settings
Writeln(script, ' Set YAxis =vGraph.Axes.Item(2) ');
Writeln(script, ' YAxis.length=1.8 ');
Writeln(script, ' YAxis.xPos='+floattostr(xpos));
Writeln(script, ' YAxis.yPos='+floattostr(ypos));
Writeln(script, ' YAxis.Tickmarks.MajorLength=0.2 ');
Writeln(script, ' YAxis.Tickmarks.MinorLength=0 ');
Writeln(script, ' YAxis.TickLabels.MajorFont.size=8 ');
Writeln(script, ' YAxis.title.text= ' + AnsiQuotedStr(vn,qchar) );
//new skip labels
if (RRow=0) then
Writeln(script, ' YAxis.TickLabels.MajorOn= False ' );
Writeln(script, '');

//add new Y axis and line plot with convereted speed
Writeln(script, ' vGraph.AddAxis(grfYAxis, "Y Axis 2") ');         //new Y axis
Writeln(script, ' Set YAxis2 =vGraph.Axes.Item(3) ');              //select new axis as YAxis2 object
Writeln(script, ' YAxis2.PositionAxis(grfPositionRightTop,"X Axis 1") ');   //position to the right end of X
Writeln(script, ' YAxis2.length=1.8 ');                                     //position to the right end of X
Writeln(script, ' YAxis2.Tickmarks.MajorLength=0.2 ');
Writeln(script, ' YAxis2.Tickmarks.MinorLength=0 ');
Writeln(script, ' YAxis2.Tickmarks.MajorSide=grfTicksTopRight ');           //move ticks to the right
Writeln(script, ' YAxis2.TickLabels.MajorSide=grfTicksTopRight ');          //move lavels to the right
Writeln(script, ' YAxis2.TickLabels.MajorFont.size=8 ');                    // font
Writeln(script, ' YAxis2.title.text= ' + AnsiQuotedStr(vu,qchar) );
Writeln(script, ' YAxis2.title.Font.color=grfColorRed ');
Writeln(script, ' YAxis2.title.Side=grfAxisTitleRightTop ');

//skip converted time series if QFL on mooring =9
if RCM_QFL<>9 then begin
Writeln(script, ' vGraph.AddLinePlot(vpath,1,3, "X Axis 1", "Y Axis 2") '); //add converted data
Writeln(script, ' Set ConvertedData=vGraph.Plots.Item(2) ');               //set name on plot
Writeln(script, ' ConvertedData.line.foreColor=grfColorRed ');              //change line color to red
end;


Writeln(script, '');

{0}end;
{s}end;




Writeln(script, '');
//save grf
//Writeln(script, 'CompositePlot.SaveAs("d:\OceanShell\applications\unload\currents\grf\CompositePLot.grf")');

//export to PDF  name: absnum+RCM#
//convert absnum to string with fixed length for proper sorting
str_a:=inttostr(SA);
if length(str_a)=1 then str_a:='000'+str_a;
if length(str_a)=2 then str_a:='00'+str_a;
if length(str_a)=3 then str_a:='0'+str_a;

str:=GlobalUnloadPath+'currents\grf\' + str_a +'_RCM_'+inttostr(RCM)+'.pdf';
Writeln(script, 'CompositePlot.Export2(' +AnsiQuotedStr(str,qchar) + ',,,,"pdfv")');
//AK 20.10.2016, 21.12.2016
if SinglePlot=false then Writeln(script, 'CompositePlot.Close(grfSaveChangesNo)');

Writeln(script, '');
Writeln(script, 'End Sub');
CloseFile(script);


//run skript
 Ini := TIniFile.Create(IniFileName); // settings from file
  try
   scripter:=Ini.ReadString( 'Main', 'Grapher',  'c:\Program Files\Golden Software\Grapher 10\Scripter\Scripter.exe');
  finally
    Ini.Free;
  end;

   cmd:=Concat('"'+Scripter, '"', ' -x ', '"', GlobalUnloadPath+'currents\grf\CompositePlot.bas"');
   //memo1.Lines.Add('scripter: '+scripter);
   //memo1.Lines.Add('cmd: '+cmd);
   Fillchar(startupInfo, Sizeof(StartupInfo), #0);
   StartupInfo.cb:=Sizeof(StartupInfo);
 {  if CreateProcess(nil, Pchar(cmd), nil, nil, false, CREATE_NO_WINDOW, nil, nil,StartupInfo, ProcessInfo)
   then begin
     WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
     FileClose(ProcessInfo.hProcess); { *Converted from CloseHandle* }
   end;  }

//AK 1.11.2016
    memo1.Lines.Add('pdf created: '+str);


end;



procedure TfrmGrapher_CompositeDrawning.btn_AllSelectedInstrumentsClick(
  Sender: TObject);
var
k: integer;
i,rval,mik: integer;
cval: real;
vmin,vmax,sv,sv2: double;
fn: string;
rec_time: TDateTime;
splot: boolean;
begin

     memo1.Clear;
     //showmessage('Selected instruments#= '+inttostr(frmDM.Q.RecordCount));

     frmDM.Q.First;
{1}for k:=1 to frmDM.Q.RecordCount do begin

     SA      := frmDM.Q.FieldByName('ABSNUM').AsInteger;           //RCM absnum
     RCM_ID  := frmDM.Q.FieldByName('M_ID').AsString;              //mooring identificator
     RCM_QFL := frmDM.Q.FieldByName('M_QFLAG').AsInteger;          //RCM absnum
     RCM     := frmDM.Q.FieldByName('M_RCMNUM').AsInteger;         //RCM #
     RCMD    := frmDM.Q.FieldByName('M_RCMDEPTH').AsInteger;       //RCM depth
     RCMLat  := frmDM.Q.FieldByName('M_LAT').AsFloat;              //RCM latitude
     RCMLon  := frmDM.Q.FieldByName('M_LON').AsFloat;              //RCM longitude
     sensors := frmDM.Q.FieldByName('M_SENSORS').AsString;         //sensors composition
     BD      := frmDM.Q.FieldByName('M_BottomDEpth').AsInteger;    //bottom depth
     TStart  := frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;       //RCM start date and time
     TStop   := frmDM.Q.FieldByName('M_TimeEnd').AsDateTime;       //RCM end date and time
     TInt    := frmDM.Q.FieldByName('M_RCMTimeInt').AsInteger;     //RCM end date and time
     RRow    := frmDM.Q.FieldByName('M_Rec_Row').AsInteger;        //# of records row data
     RConv   := frmDM.Q.FieldByName('M_Rec_Cur').AsInteger;        //# of records converted data
     PI      := frmDM.Q.FieldByName('M_PI').AsString;              //Principal Investigator
     Project := frmDM.Q.FieldByName('M_ProjectName').AsString;    //Project name
     CS      := frmDM.Q.FieldByName('M_CalibrationSheet').AsString;//Name of pdf with calibration coefficients
     RCMType := frmDM.Q.FieldByName('M_RCMType').AsString;         //RCM type
     MC      := frmDM.Q.FieldByName('M_DirCorrection').AsFloat;    //magnetic correction for direction

     memo1.Lines.Add('...absnum  : '+#9+inttostr(SA));
     memo1.Lines.Add('...RCM#    : '+#9+inttostr(RCM));
     memo1.Lines.Add('...RCM ID  : '+#9+RCM_ID);
     memo1.Lines.Add('...sensors : '+#9+sensors);
     memo1.Lines.Add('');


////////////////////////////////////////////////////////
{i}for i:=1 to 9 do begin
     vmin_arr[i]:=9999;
     vmax_arr[i]:=-9999;
     vmd_arr[i] :=0;
     vsd_arr[i] :=0;
{s}if sensors[i]<>'0' then begin

{c}case i of

2: begin //CH2: row -> converted temperature
      fn:=GlobalUnloadPath+'currents\grf\CH2_temp.dat';
      assignfile(f_out, fn);
      rewrite(f_out);
      //memo1.Lines.Add('...temp from CH2 in '+fn);

{q}if RCM_QFL<>9 then begin
      //get temperature records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as TFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_TFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        TFL_count:=FieldByName('TFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH2,C_TEMP FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_tfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH2').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_TEMP').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[2]:=vmin;
     vmax_arr[2]:=vmax;
     if mik<>0 then begin
     vmd_arr[2] :=sv/mik;
     vsd_arr[2] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[2]<>0 then vsd_arr[2]:=sqrt(abs(vsd_arr[2]));
     end;
{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH2 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH2').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;


//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Temp FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_TFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Temp').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[2]:=vmin;
     vmax_arr[2]:=vmax;
     if mik<>0 then begin
     vmd_arr[2] :=sv/mik;
     vsd_arr[2] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[2]<>0 then vsd_arr[2]:=sqrt(abs(vsd_arr[2]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;
{2}end;




3: begin //CH3: conductivity -> salinity
      fn:=GlobalUnloadPath+'currents\grf\CH3_salt.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get salinity records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as SFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_SFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        SFL_count:=FieldByName('SFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH3,C_SALT FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_sfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH3').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_SALT').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[3]:=vmin;
     vmax_arr[3]:=vmax;
     if mik<>0 then begin
     vmd_arr[3] :=sv/mik;
     vsd_arr[3] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[3]<>0 then vsd_arr[3]:=sqrt(abs(vsd_arr[3]));
     end;
{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH3 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH3').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Salt FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_SFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Salt').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[3]:=vmin;
     vmax_arr[3]:=vmax;
     if mik<>0 then begin
     vmd_arr[3] :=sv/mik;
     vsd_arr[3] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[3]<>0 then vsd_arr[3]:=sqrt(abs(vsd_arr[3]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{3}end;


4: begin //CH4: row -> converted pressure
      if sensors[i]='P' then fn:=GlobalUnloadPath+'currents\grf\CH4_press.dat'
                        else fn:=GlobalUnloadPath+'currents\grf\CH4_temp.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get pressure/temp records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as PFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_PFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        PFL_count:=FieldByName('PFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH4,C_PRESS FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_pfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH4').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_PRESS').AsFloat;

   //convert kg/m2 -> bar -> m
   if sensors[i]='P' then begin
     cval:=cval*0.98;                                 // kg/cm2 -> bar
     cval:=cval*10.19977334;                          // bar -> meter
   end;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;


     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[4]:=vmin;
     vmax_arr[4]:=vmax;
     if mik<>0 then begin
     vmd_arr[4] :=sv/mik;
     vsd_arr[4] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[4]<>0 then vsd_arr[4]:=sqrt(abs(vsd_arr[4]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH4 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH4').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Press FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_PFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Press').AsFloat;

   //new convert kg/m2 -> bar -> m
   if sensors[i]='P' then begin
     cval:=cval*0.98;                                 // kg/cm2 -> bar
     cval:=cval*10.19977334;                          // bar -> meter
   end;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[4]:=vmin;
     vmax_arr[4]:=vmax;
     if mik<>0 then begin
     vmd_arr[4] :=sv/mik;
     vsd_arr[4] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[4]<>0 then vsd_arr[4]:=sqrt(abs(vsd_arr[4]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{4}end;


5: begin //CH5: row -> converted current direction
      fn:=GlobalUnloadPath+'currents\grf\CH5_dir.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get current records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as CFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_CFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        CFL_count:=FieldByName('CFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH5,C_ANGLE FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_cfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH5').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_ANGLE').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[5]:=vmin;
     vmax_arr[5]:=vmax;
     if mik<>0 then begin
     vmd_arr[5] :=sv/mik;
     vsd_arr[5] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[5]<>0 then vsd_arr[5]:=sqrt(abs(vsd_arr[5]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH5 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH5').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Angle FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_CFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Angle').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[5]:=vmin;
     vmax_arr[5]:=vmax;
     if mik<>0 then begin
     vmd_arr[5] :=sv/mik;
     vsd_arr[5] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[5]<>0 then vsd_arr[5]:=sqrt(abs(vsd_arr[5]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{5}end;



6: begin //CH5: row -> converted current speed
      fn:=GlobalUnloadPath+'currents\grf\CH6_speed.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get current records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as CFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_CFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        CFL_count:=FieldByName('CFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH6,C_SPEED FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_cfl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH6').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_SPEED').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[6]:=vmin;
     vmax_arr[6]:=vmax;
     if mik<>0 then begin
     vmd_arr[6] :=sv/mik;
     vsd_arr[6] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[6]<>0 then vsd_arr[6]:=sqrt(abs(vsd_arr[6]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH6 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH6').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Speed FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_CFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Speed').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[6]:=vmin;
     vmax_arr[6]:=vmax;
     if mik<>0 then begin
     vmd_arr[6] :=sv/mik;
     vsd_arr[6] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[6]<>0 then vsd_arr[6]:=sqrt(abs(vsd_arr[6]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;

{6}end;



7: begin //CH7: row -> converted turbidity
      fn:=GlobalUnloadPath+'currents\grf\CH7_turb.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get turbidity records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as UFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_UFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        UFL_count:=FieldByName('UFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH7,C_TURB FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.c_ufl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH7').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_TURB').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[7]:=vmin;
     vmax_arr[7]:=vmax;
     if mik<>0 then begin
     vmd_arr[7] :=sv/mik;
     vsd_arr[7] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[7]<>0 then vsd_arr[7]:=sqrt(abs(vsd_arr[7]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH7 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH7').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Turb FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_UFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Turb').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[7]:=vmin;
     vmax_arr[7]:=vmax;
     if mik<>0 then begin
     vmd_arr[7] :=sv/mik;
     vsd_arr[7] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[7]<>0 then vsd_arr[7]:=sqrt(abs(vsd_arr[7]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{7}end;


8: begin //CH8: row -> converted oxygen
      fn:=GlobalUnloadPath+'currents\grf\CH8_oxyg.dat';
      assignfile(f_out, fn);
      rewrite(f_out);

{q}if RCM_QFL<>9 then begin
      //get oxygen records number with QFL=9
      with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT count(*) as OFL_count FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (absnum=:absnum) and (C_OFL=9) ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
        OFL_count:=FieldByName('OFL_count').AsInteger;
        Close;
      end;

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH8,C_OXYG FROM ROWDATA,CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ROWDATA.absnum=:absnum) and (ROWDATA.absnum=CURRENTS.absnum) ');
        SQL.Add(' and (ROWDATA.rd_time=CURRENTS.c_time) ');
        SQL.Add(' and (ROWDATA.qfl<>9) and (CURRENTS.C_Ofl<>9) ');
        SQL.Add(' ORDER BY ROWDATA.rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH8').AsInteger;
     cval    :=frmdm.RDQuery.FieldByName('C_OXYG').AsFloat;

     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created');

     vmin_arr[8]:=vmin;
     vmax_arr[8]:=vmax;
     if mik<>0 then begin
     vmd_arr[8] :=sv/mik;
     vsd_arr[8] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[8]<>0 then vsd_arr[8]:=sqrt(abs(vsd_arr[8]));
     end;

{q}end;

{q}if RCM_QFL=9 then begin
      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT RD_TIME,CH8 FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum ');
        SQL.Add(' ORDER BY rd_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row');

{w}while not frmdm.RDQuery.Eof do begin
     rec_time:=frmdm.RDQuery.FieldByName('RD_TIME').AsDateTime;
     rval    :=frmdm.RDQuery.FieldByName('CH8').AsInteger;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval));

     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;
     memo1.Lines.Add(fn+' ...created only row data available');
{q}end;

//new converted data only
{q}if (RRow=0) and (RConv>0) then begin

      memo1.Lines.Add('rowdata#='+inttostr(RRow)+'  convdata#='+inttostr(RConv));
      rewrite(f_out);

      with frmdm.RDQuery do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT C_TIME,C_Oxyg FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' absnum=:absnum and C_OFl<>9 ');
        SQL.Add(' ORDER BY c_time ');
        ParamByName('ABSNUM').AsInteger:=SA;
        Open;
      end;
      writeln(f_out,'time'+#9+'row'+#9+'converted');

      mik:=0; vmin:=9999; vmax:=-9999; sv:=0; sv2:=0;
{w}while not frmdm.RDQuery.Eof do begin

     mik:=mik+1;
     rec_time:=frmdm.RDQuery.FieldByName('C_TIME').AsDateTime;
     rval:=-9; //fictitious number for left exis
     cval    :=frmdm.RDQuery.FieldByName('C_Oxyg').AsFloat;

     //memo1.Lines.add(datetimetostr(rec_time)+#9+inttostr(rval)+#9+floattostr(cval));
     if vmin>cval then vmin:=cval;
     if vmax<cval then vmax:=cval;
     sv :=sv +cval;
     sv2:=sv2+cval*cval;

     writeln(f_out,datetimetostr(rec_time)
     +#9+inttostr(rval)
     +#9+floattostr(cval));


     frmdm.RDQuery.Next;
{w}end;
     closefile(f_out);
     frmdm.RDQuery.Close;

     vmin_arr[8]:=vmin;
     vmax_arr[8]:=vmax;
     if mik<>0 then begin
     vmd_arr[8] :=sv/mik;
     vsd_arr[8] :=(sv2-sv*sv/mik)/mik;
     if vsd_arr[8]<>0 then vsd_arr[8]:=sqrt(abs(vsd_arr[8]));
     end;

     memo1.Lines.Add(fn+' ...created only converted data available');
{q}end;


{8}end;


{c}end; {case}
{s}end; {if sensors[i]<>'0'}
{i}end; {sensors 1..9}
////////////////////////////////////////////////////////

      splot:=false;
      CompositePLot(splot);


     frmDM.Q.Next;

{1}end;
     memo1.Lines.Add(' ...done');


end;




end.
