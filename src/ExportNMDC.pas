unit ExportNMDC;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, {DBGridEhGrouping, ToolCtrlsEh, DBGridEhToolCtrls, DynVarsEh,}
  StdCtrls, Buttons, {GridsEh, DBAxisGridsEh, DBGridEh,} DateUtils{, EhLibVCL};

type
  TfrmExportNMDC = class(TForm)
  //  DBGridEh1: TDBGridEh;
  //  DBGridEh2: TDBGridEh;
    Memo1: TMemo;
    btnExportSelected: TBitBtn;
    CheckBox1: TCheckBox;
    procedure btnExportSelectedClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmExportNMDC: TfrmExportNMDC;
  f_out,f1_out: text;

implementation

{$R *.lfm}

uses DM, mmain, msettings;

procedure TfrmExportNMDC.btnExportSelectedClick(Sender: TObject);
var
k,mik,i,sn: integer;
absnum,RCMnum,mqfl,temp_ch,RCMDepth,TInt,BD,recR,recC: integer;
CH1,CH2,CH3,CH4,CH5,CH6,CH7,CH8,CH9,QFL_R :integer;
Cfl,Tfl,Sfl,Pfl,Ufl,Ofl :integer;
apply_angle,apply_speed,apply_temp,apply_salt,apply_press,apply_turb,apply_oxyg :integer;


RCMLat,RCMLon,duration,MC: real;
dir,dirMC,speed,temp,salt,press,turb,oxyg :real;
TA,TB,TC,TD,CA,CB,CC,CD,PA,PB,PC,PD,DA,DB,DC,DD: real;
SA,SB,SC,SD,UA,UB,UC,UD,OA,OB,OC,OD,XA,XB,XC,XD: real;
cf_angle,cf_speed,cf_temp,cf_salt,cf_press,cf_turb,cf_oxyg :real;



sensors: string[9];
M_ID,RCMTYpe,PI,Project,Region,Place,CS,SourceFile,time_str,par :string;
fn,fn1,str: string;

start,stop,Time_R,Time_C: TDateTime;
begin

     //frmdm.TR1.StartTransaction; //one mooring will be replaced in framework of transaction

     frmdm.Q.DisableControls;
     frmdm.Q.First;

{w}while not frmdm.Q.Eof do begin

     absnum   :=frmdm.Q.FieldByName('Absnum').AsInteger;
     M_ID     :=frmDM.Q.FieldByName('M_ID').AsString;      //mooring identificator
     RCMnum   :=frmdm.Q.FieldByName('M_RCMnum').AsInteger;
     MQFL     :=frmdm.Q.FieldByName('M_QFlag').AsInteger;
     RCMDepth :=frmdm.Q.FieldByName('M_RCMDepth').AsInteger;
     sensors  :=frmdm.Q.FieldByName('M_sensors').AsString;
     temp_ch  :=frmdm.Q.FieldByName('M_TempChannel').AsInteger;
     TInt     :=frmDM.Q.FieldByName('M_RCMTimeInt').AsInteger;
     BD       :=frmDM.Q.FieldByName('M_BottomDepth').AsInteger;
     RecR     :=frmDM.Q.FieldByName('M_Rec_ROW').AsInteger;
     RecC     :=frmDM.Q.FieldByName('M_Rec_CUR').AsInteger;

     RCMLat:=frmdm.Q.FieldByName('M_Lat').AsFloat;
     RCMLon:=frmdm.Q.FieldByName('M_Lon').AsFloat;
     MC    :=frmdm.Q.FieldByName('M_DirCorrection').AsFloat;

     start:=frmdm.Q.FieldByName('M_TimeBeg').AsDateTime;
     stop :=frmdm.Q.FieldByName('M_TimeEnd').AsDateTime;
     duration:=(DaySpan(Stop,Start));

     RCMType   := frmDM.Q.FieldByName('M_RCMType').AsString;
     PI        := frmDM.Q.FieldByName('M_PI').AsString;
     Project   := frmDM.Q.FieldByName('M_ProjectName').AsString;
     CS        := frmDM.Q.FieldByName('M_CalibrationSheet').AsString;
     Place     := frmDM.Q.FieldByName('M_Place').AsString;
     Region    := frmDM.Q.FieldByName('M_Region').AsString;
     SourceFile:= frmDM.Q.FieldByName('M_SourceFileName').AsString;


     //file name: absnum + RCMnum
     str:=inttostr(absnum);
     if length(str)=1 then str:='000'+str;
     if length(str)=2 then str:='00' +str;
     if length(str)=3 then str:='0'  +str;

     fn :=GlobalPath+'unload\currents\txt\' + str + '_RCM_'+inttostr(RCMNum) + '.txt' ;
     fn1:=GlobalPath+'unload\currents\txt\' + str + '_RCM_'+inttostr(RCMNum) + '_QC.txt' ;

     if (checkbox1.Checked) then memo1.Lines.Add('');
     memo1.Lines.Add('### absnum='+inttostr(absnum)
     +'   RCMnum='+inttostr(RCMnum)
     +'   MQFL='+inttostr(MQFL)
     +'   channels:'+sensors
     +'   temp channel:'+inttostr(temp_ch)
     +'   RCMDepth:'+inttostr(RCMDepth)
     +'   RCMLat:'+floattostr(RCMLat)
     +'   RCMLon:'+floattostr(RCMLon));

     memo1.Lines.Add('        file name: '+fn);

     //output
     //..............................................................
     assignfile(f_out, fn);
     rewrite(f_out);
     assignfile(f1_out, fn1);
     rewrite(f1_out);



writeln(f_out,'//Geophysical Institute (GFI), University of Bergen (UiB)');
writeln(f_out,'//The file contains measurements made by Recording Current Mooring (RCM) or Seabird instrument and');
writeln(f_out,'//consists of six sections');
writeln(f_out,'//');
writeln(f_out,'//1. METADATA:   information about RCM');
writeln(f_out,'//');

writeln(f_out,'//2. CONVERSION COEFFICIENTS:   variables’ conversion coefficients from the closest calibration sheet (if');
writeln(f_out,'//available) or from .hdr file (if calibration sheet is not available). Default coefficients were used');
writeln(f_out,'//at some RCMs.');
writeln(f_out,'//conversion equation:  A + B*val +  C*val*val + D*val*val*val   ,where ‘val’-is a variable value');
writeln(f_out,'//in engineering unit, A,B,C,D - conversion coefficients');
writeln(f_out,'//');

writeln(f_out,'//3. ROWDATA:   variables in engineering units from RCM channels');
writeln(f_out,'//Channels abbriviation: Refence number (Ref), Temperature (Temp), Conductivity (Cond), Pressure (Press),');
writeln(f_out,'//Current direction (Dir), Current speed (Speed), Turbidity (Turb), Oxygen (Oxyg)');
writeln(f_out,'//Last column (QFL) contains QC flags changed to SeaDataNet standard');
writeln(f_out,'//Note: channel 4 can contain either pressure or temperature values');
writeln(f_out,'//');

writeln(f_out,'//4. CONVERTED DATA:   variables converted from engineering into physical units');
writeln(f_out,'//variables units : Temperature (deg. C),  Salinity(PSU),  Pressure/Temperature (m/deg.C),');
writeln(f_out,'//Current direction (deg),  Current speed(cm/s),  Turbidity (NTU), Oxygen (%)');
writeln(f_out,'//variables flags name convection: Temperature (TFL), Salinity (SFL), Current direction or speed');
writeln(f_out,'//(CFL), Pressure (PFL), Turbidity (UFL), Oxygen (OFL)');
writeln(f_out,'//Current direction was corrected by adding magnetic correction');
writeln(f_out,'//');

writeln(f_out,'//5. CORRECTION COEFFICIENTS: coefficients for time series correction  ');
writeln(f_out,'//defined only for RCM with salinity time series against available CTD profiles ');
writeln(f_out,'//in current version coefficient defined only for temperature and salinity below 100 m ');
writeln(f_out,'//');

writeln(f_out,'//6. CORRECTED DATA: converted data with applied correction coefficients  ');
writeln(f_out,'//if were defined (coefficient<>0) and apply parameters set to apply (=1)) ');
writeln(f_out,'//corrected data also available in separate file ');
writeln(f_out,'//');

writeln(f_out,'//IMPORTANT:   current version of time series passed three stages of quality control');
writeln(f_out,'//The first stage  – seting of QC flags on ROWDATA (all variables are affected)');
writeln(f_out,'//The second stage – seting of QC flags on converted individual variables');
writeln(f_out,'//The third stage - temp and salt time series correction (where was possible) against');
writeln(f_out,'//CTD data');
writeln(f_out,'//');
writeln(f_out,'//');
writeln(f_out,'//The file was created  by the ‘CURRENTS’ application developed by Alexander Korablev,');
writeln(f_out,'//Geophysical Institute, University of Bergen');

writeln(f_out,'//file creation date:'+datetimetostr(now));
writeln(f_out);


writeln(f1_out,'//Geophysical Institute (GFI), University of Bergen (UiB)');
writeln(f1_out,'//The file contains quality controlled measurements made by Recording Current Mooring (RCM) or Seabird instrument and');
writeln(f1_out,'//consists of two sections');
writeln(f1_out,'//');
writeln(f1_out,'//1. METADATA:   information about RCM');
writeln(f1_out,'//');

writeln(f1_out,'//2. CONVERTED, QUALITY CONTROLLED AND CORRECTED DATA: converted data with applied correction coefficients and magnetic correction ');
writeln(f1_out,'//');
writeln(f1_out,'//variables units : Temperature (deg. C),  Salinity(PSU),  Pressure/Temperature (m/deg.C),');
writeln(f1_out,'//Current direction (deg),  Current speed(cm/s),  Turbidity (NTU), Oxygen (%)');
writeln(f1_out,'//variables flags name convection: Temperature (TFL), Salinity (SFL), Current direction or speed');
writeln(f1_out,'//(CFL), Pressure (PFL), Turbidity (UFL), Oxygen (OFL)');
writeln(f1_out,'//');
writeln(f1_out,'//SeaDataNet quality control flags:  ');
writeln(f1_out,'//     0 -  no quality control  ');
writeln(f1_out,'//     1 -  good value  ');
writeln(f1_out,'//     2 -  probably good value  ');
writeln(f1_out,'//     3 -  probably bad value  ');
writeln(f1_out,'//     4 -  bad value  ');
writeln(f1_out,'//     5 -  changed value  ');
writeln(f1_out,'//     6 -  value below detection ');
writeln(f1_out,'//     7 -  value in excess ');
writeln(f1_out,'//     8 -  interpolated value ');
writeln(f1_out,'//     9 -  missing value ');
writeln(f1_out,'//     A -  value phenomenon uncertain');
writeln(f1_out,'//');
writeln(f1_out,'//The file was created  by the ‘CURRENTS’ application developed by Alexander Korablev,');
writeln(f1_out,'//Geophysical Institute, University of Bergen');
writeln(f1_out,'//');
writeln(f1_out,'//!!! see details of the RCM data processing in the compleate text file');
writeln(f1_out,'//');
writeln(f1_out,'//file creation date:'+datetimetostr(now));
writeln(f1_out);


//METADATA
     sn:=30; //symbols number reserved for metadata before description
     writeln(f_out,'###METADATA');
     writeln(f1_out,'###METADATA');

     //database name
     str:=extractfilename(IBName);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//database name');
     writeln(f1_out,str + '//database name');

     //mooring ID
     str:=M_ID;
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//mooring ID');
     writeln(f1_out,str + '//mooring ID');

     //database number
     str:=inttostr(absnum);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM unique number in database');
     writeln(f1_out,str + '//RCM unique number in database');

     //RCM QC flag
     //change to SeaDataNet style

     if  MQFL=0 then MQFL:=1; //good
     if  MQFL=5 then MQFL:=3; //probably bad
     if  (MQFL=8) or (MQFL=9) then MQFL:=4; //bad

     str:=inttostr(MQFL);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM quality control flag');
     writeln(f1_out,str + '//RCM quality control flag');

     //RCM type
     str:=RCMType;
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM type');
     writeln(f1_out,str + '//RCM type');

     //RCM number
     str:=inttostr(RCMNum);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM number');
     writeln(f1_out,str + '//RCM number');

     //RCM position lat
     str:=floattostr(RCMLat);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM position latitude (deg)');
     writeln(f1_out,str + '//RCM position latitude (deg)');

     //RCM position lon
     str:=floattostr(RCMLon);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM position longitude (deg)');
     writeln(f1_out,str + '//RCM position longitude (deg)');

     //RCM depth
     str:=inttostr(RCMDepth);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM depth (m)');
     writeln(f1_out,str + '//RCM depth (m)');

     //RCM start time
     str:=datetimetostr(start);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM start time');
     writeln(f1_out,str + '//RCM start time');

     //RCM stop time
     str:=datetimetostr(stop);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM stop time');
     writeln(f1_out,str + '//RCM stop time');

     //RCM time interval
     str:=inttostr(TInt);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM time interval (min)');
     writeln(f1_out,str + '//RCM time interval (min)');

     //time series duration
     str:=floattostrF(duration,ffFixed,10,2);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//time series duration (days)');
     writeln(f1_out,str + '//time series duration (days)');

     //number of records ROWDATA
     str:=inttostr(RecR);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//number of records (unflagged ROWDATA)');
     writeln(f1_out,str + '//number of records (unflagged ROWDATA)');

     //number of records Converted DATA
     str:=inttostr(RecC);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//number of records (unflagged Converted Data)');
     writeln(f1_out,str + '//number of records (unflagged Converted Data)');

     //RCM available channels
     str:=sensors;
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//RCM Channels: 1.Ref 2.Temp 3.Cond 4.Dir 5.Speed 6.Press/Temp 7.tUrb 8.Oxyg 9.Reserved   without measurements: 0');
     writeln(f1_out,str + '//RCM Channels: 1.Ref 2.Temp 3.Cond 4.Dir 5.Speed 6.Press/Temp 7.tUrb 8.Oxyg 9.Reserved   without measurements: 0');

     //RCM temperature sensor used for salinity conversion from salinity
     str:=inttostr(temp_ch);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//temperature channel for conductivity conversion');
     writeln(f1_out,str + '//temperature channel for conductivity conversion');

     //Bottom depth
     str:=inttostr(BD);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//Bottom depth (m) missing value: -9');
     writeln(f1_out,str + '//Bottom depth (m) missing value: -9');

     //Region
     str:=Region;
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//Region');
     writeln(f1_out,str + '//Region');

     //Place
     str:=Place;
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//Place');
     writeln(f1_out,str + '//Place');

     //Pl
     str:=PI;
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//Principal Investigator');
     writeln(f1_out,str + '//Principal Investigator');

     //Project
     str:=Project;
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//Project name');
     writeln(f1_out,str + '//Project name');

     //Calibration sheet with conversion coefficients
     str:=CS;
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//Calibration sheet with conversion coefficients');
     writeln(f1_out,str + '//Calibration sheet with conversion coefficients');

     //Source file name from archive
     str:=extractfilename(SourceFile);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//source file name from GFI archive');
     writeln(f1_out,str + '//source file name from GFI archive');

     //Magnitic correction
     str:=floattostr(MC);
     if length(str)<sn then for i:=length(str) to sn do str:=str+' ';
     writeln(f_out,str + '//magnetic correction from www.ngdc.noaa.gov/geomag-web/');
     writeln(f1_out,str + '//magnetic correction from www.ngdc.noaa.gov/geomag-web/');


//COEFFICIENTS
       writeln(f_out);
       writeln(f_out);
       writeln(f_out,'###COEFFICIENTS ');
       //writeln(f_out,'//conversion equation:  A + B*val +  C*val*val + D*val*val*val    val-a variable value');

     with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT * FROM COEFFICIENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ABSNUM=:absnum) ');
        ParamByName('ABSNUM').AsInteger:=absnum;
        Open;

        TA:=FieldByName('TA').AsFloat;
        TB:=FieldByName('TB').AsFloat;
        TC:=FieldByName('TC').AsFloat;
        TD:=FieldByName('TD').AsFloat;

        CA:=FieldByName('CA').AsFloat;
        CB:=FieldByName('CB').AsFloat;
        CC:=FieldByName('CC').AsFloat;
        CD:=FieldByName('CD').AsFloat;

        PA:=FieldByName('PA').AsFloat;
        PB:=FieldByName('PB').AsFloat;
        PC:=FieldByName('PC').AsFloat;
        PD:=FieldByName('PD').AsFloat;

        DA:=FieldByName('DA').AsFloat;
        DB:=FieldByName('DB').AsFloat;
        DC:=FieldByName('DC').AsFloat;
        DD:=FieldByName('DD').AsFloat;

        SA:=FieldByName('SA').AsFloat;
        SB:=FieldByName('SB').AsFloat;
        SC:=FieldByName('SC').AsFloat;
        SD:=FieldByName('SD').AsFloat;

        UA:=FieldByName('UA').AsFloat;
        UB:=FieldByName('UB').AsFloat;
        UC:=FieldByName('UC').AsFloat;
        UD:=FieldByName('UD').AsFloat;

        OA:=FieldByName('OA').AsFloat;
        OB:=FieldByName('OB').AsFloat;
        OC:=FieldByName('OC').AsFloat;
        OD:=FieldByName('OD').AsFloat;

        XA:=FieldByName('XA').AsFloat;
        XB:=FieldByName('XB').AsFloat;
        XC:=FieldByName('XC').AsFloat;
        XD:=FieldByName('XD').AsFloat;

        Close;
     end;

    if sensors[2]<>'0' then begin       //CH2 Temp
      writeln(f_out,'Temperature');
      writeln(f_out,'A=',floattostrF(TA,ffFixed,10,5));
      writeln(f_out,'B=',floattostrF(TB,ffFixed,10,5));
      writeln(f_out,'C=',floattostrF(TC,ffExponent,5,2));
      writeln(f_out,'D=',floattostrF(TD,ffExponent,5,2));
    end;

    if sensors[3]<>'0' then begin       //CH3 Cond
      writeln(f_out,'Conductivity');
      writeln(f_out,'A=',floattostrF(CA,ffFixed,10,5));
      writeln(f_out,'B=',floattostrF(CB,ffFixed,10,5));
      writeln(f_out,'C=',floattostrF(CC,ffExponent,5,2));
      writeln(f_out,'D=',floattostrF(CD,ffExponent,5,2));
    end;

    if sensors[4]<>'0' then begin       //CH4 Press/Temp
      writeln(f_out,'Pressure/Temperature');
      writeln(f_out,'A=',floattostrF(PA,ffFixed,10,5));
      writeln(f_out,'B=',floattostrF(PB,ffFixed,10,5));
      writeln(f_out,'C=',floattostrF(PC,ffExponent,5,2));
      writeln(f_out,'D=',floattostrF(PD,ffExponent,5,2));
    end;

    if sensors[5]<>'0' then begin       //CH5 Current Direction
      writeln(f_out,'Current direction');
      writeln(f_out,'A=',floattostrF(DA,ffFixed,10,5));
      writeln(f_out,'B=',floattostrF(DB,ffFixed,10,5));
      writeln(f_out,'C=',floattostrF(DC,ffExponent,5,2));
      writeln(f_out,'D=',floattostrF(DD,ffExponent,5,2));
    end;

    if sensors[6]<>'0' then begin       //CH6 Current Speed
      writeln(f_out,'Current speed');
      writeln(f_out,'A=',floattostrF(SA,ffFixed,10,5));
      writeln(f_out,'B=',floattostrF(SB,ffFixed,10,5));
      writeln(f_out,'C=',floattostrF(SC,ffExponent,5,2));
      writeln(f_out,'D=',floattostrF(SD,ffExponent,5,2));
    end;

    if sensors[7]<>'0' then begin       //CH7 Turbidity
      writeln(f_out,'Turbidity');
      writeln(f_out,'A=',floattostrF(UA,ffFixed,10,5));
      writeln(f_out,'B=',floattostrF(UB,ffFixed,10,5));
      writeln(f_out,'C=',floattostrF(UC,ffExponent,5,2));
      writeln(f_out,'D=',floattostrF(UD,ffExponent,5,2));
    end;

    if sensors[8]<>'0' then begin       //CH8 Oxygen
      writeln(f_out,'Oxygen');
      writeln(f_out,'A=',floattostrF(OA,ffFixed,10,5));
      writeln(f_out,'B=',floattostrF(OB,ffFixed,10,5));
      writeln(f_out,'C=',floattostrF(OC,ffExponent,5,2));
      writeln(f_out,'D=',floattostrF(OD,ffExponent,5,2));
    end;

    if sensors[9]<>'0' then begin       //CH9 Reserved
      writeln(f_out,'Reserved');
      writeln(f_out,'A=',floattostrF(XA,ffFixed,10,5));
      writeln(f_out,'B=',floattostrF(XB,ffFixed,10,5));
      writeln(f_out,'C=',floattostrF(XC,ffExponent,5,2));
      writeln(f_out,'D=',floattostrF(XD,ffExponent,5,2));
    end;


//ROWDATA
     writeln(f_out);
     writeln(f_out);
     writeln(f_out,'###ROWDATA');
     str:=' Date        Time'+#9;
   for i:=1 to 9 do begin
   if sensors[i]<>'0' then begin
     case sensors[i] of
     'R': par:='Ref';
     'T': par:='Temp';
     'C': par:='Cond';
     'P': par:='Press';
     'D': par:='Dir';
     'S': par:='Speed';
     'U': par:='Turb';
     'O': par:='Oxyg';
     end;
     str:=str+par+#9;
   end;
   end;
     str:=str+'QFL';
     writeln(f_out,str);

     with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT * FROM ROWDATA  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ABSNUM=:absnum) ');
        SQL.Add(' order by RD_TIME ');
        ParamByName('ABSNUM').AsInteger:=absnum;
        Open;
     end;

{r}while not frmdm.ib1q1.Eof do begin
    Time_R:= frmdm.ib1q1.FieldByName('RD_Time').AsDateTime;
    CH1   := frmdm.ib1q1.FieldByName('CH1').AsInteger;
    CH2   := frmdm.ib1q1.FieldByName('CH2').AsInteger;
    CH3   := frmdm.ib1q1.FieldByName('CH3').AsInteger;
    CH4   := frmdm.ib1q1.FieldByName('CH4').AsInteger;
    CH5   := frmdm.ib1q1.FieldByName('CH5').AsInteger;
    CH6   := frmdm.ib1q1.FieldByName('CH6').AsInteger;
    CH7   := frmdm.ib1q1.FieldByName('CH7').AsInteger;
    CH8   := frmdm.ib1q1.FieldByName('CH8').AsInteger;
    CH9   := frmdm.ib1q1.FieldByName('CH9').AsInteger;
    QFL_R := frmdm.ib1q1.FieldByName('QFL').AsInteger;

    //qfl change to SeaDataNet
    if qfl_r=0 then qfl_r:=2; //probably good value
    if qfl_r=9 then qfl_r:=4; //bad value

    //showmessage(timetostr(time_r));
    if timetostr(time_r)='00:00:00' then time_str:=datetostr(time_r)+' 00:00:00'
                                    else time_str:=datetimetostr(time_r);
    //showmessage(time_str);

                            write(f_out,time_str);
                            write(f_out,#9,inttostr(CH1));
    if sensors[2]<>'0' then write(f_out,#9,inttostr(CH2));
    if sensors[3]<>'0' then write(f_out,#9,inttostr(CH3));
    if sensors[4]<>'0' then write(f_out,#9,inttostr(CH4));
    if sensors[5]<>'0' then write(f_out,#9,inttostr(CH5));
    if sensors[6]<>'0' then write(f_out,#9,inttostr(CH6));
    if sensors[7]<>'0' then write(f_out,#9,inttostr(CH7));
    if sensors[8]<>'0' then write(f_out,#9,inttostr(CH8));
    if sensors[9]<>'0' then write(f_out,#9,inttostr(CH9));
                            write(f_out,#9,inttostr(qfl_r));
                            writeln(f_out);

     frmdm.ib1q1.Next;
{r}end;
     frmdm.ib1q1.Close;


//CONVERTED DATA
     writeln(f_out);
     writeln(f_out);
     writeln(f_out,'###CONVERTED DATA');
     //writeln(f_out,'                     //Temp(deg.C)  Salt(PSU)  Press/Temp(m/deg.C)  Dir(deg)  Speed(cm/s)  tUrbidity(NTU) Oxygen(%) ');
     //writeln(f_out,'          QC flags:  //TFL          SFL        PFL                  CFL       CFL           UFL           OFL  ');
     str:=' Date        Time'+#9;
   for i:=2 to 9 do begin
   if sensors[i]<>'0' then begin
     case sensors[i] of
     'T': par:='Temp';
     'C': par:='Salt';
     'P': par:='Press';
     'D': par:='Dir';
     'S': par:='Speed';
     'U': par:='Turb';
     'O': par:='Oxyg';
     end;
     str:=str+par+#9;
   end;
   end;

   for i:=2 to 9 do begin
   if sensors[i]<>'0' then begin
     case sensors[i] of
     'T': par:='T';
     'C': par:='S';
     'P': par:='P';
     'D': par:='C';    //one flag
     'S': par:='C';    //for direction and speed
     'U': par:='U';
     'O': par:='O';
     end;
     str:=str+par+'FL'+#9;
   end;
   end;

     writeln(f_out,str);

     with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT * FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ABSNUM=:absnum) ');
        SQL.Add(' order by C_TIME ');
        ParamByName('ABSNUM').AsInteger:=absnum;
        Open;
     end;

{r}while not frmdm.ib1q1.Eof do begin
    Time_C:= frmdm.ib1q1.FieldByName('C_Time').AsDateTime;
    dir   := frmdm.ib1q1.FieldByName('C_ANGLE').AsFloat;

    dirMC:=dir+MC; //add magnetic correction
    if dirMC>360 then dirMC:=dirMC-360;
    if dirMC<0   then dirMC:=dirMC+360;

    speed := frmdm.ib1q1.FieldByName('C_SPEED').AsFloat;
    temp  := frmdm.ib1q1.FieldByName('C_TEMP').AsFloat;
    salt  := frmdm.ib1q1.FieldByName('C_SALT').AsFloat;
    press := frmdm.ib1q1.FieldByName('C_PRESS').AsFloat;
    turb  := frmdm.ib1q1.FieldByName('C_TURB').AsFloat;
    oxyg  := frmdm.ib1q1.FieldByName('C_OXYG').AsFloat;

    Cfl   := frmdm.ib1q1.FieldByName('C_CFL').AsInteger;
    Tfl   := frmdm.ib1q1.FieldByName('C_TFL').AsInteger;
    Sfl   := frmdm.ib1q1.FieldByName('C_SFL').AsInteger;
    Pfl   := frmdm.ib1q1.FieldByName('C_PFL').AsInteger;
    Ufl   := frmdm.ib1q1.FieldByName('C_UFL').AsInteger;
    Ofl   := frmdm.ib1q1.FieldByName('C_OFL').AsInteger;

    //qfl change to SeaDataNet
    if cfl=0 then cfl:=2; //probably good value
    if cfl=5 then cfl:=3; //probably bad value
    if cfl=9 then cfl:=4; //bad value

    if tfl=0 then tfl:=2; //probably good value
    if tfl=5 then tfl:=3; //probably bad value
    if tfl=9 then tfl:=4; //bad value

    if sfl=0 then sfl:=2; //probably good value
    if sfl=5 then sfl:=3; //probably bad value
    if sfl=9 then sfl:=4; //bad value

    if pfl=0 then pfl:=2; //probably good value
    if pfl=5 then pfl:=3; //probably bad value
    if pfl=9 then pfl:=4; //bad value

    if ufl=0 then ufl:=2; //probably good value
    if ufl=5 then ufl:=3; //probably bad value
    if ufl=9 then ufl:=4; //bad value

    if ofl=0 then ofl:=2; //probably good value
    if ofl=5 then ofl:=3; //probably bad value
    if ofl=9 then ofl:=4; //bad value



    //showmessage(timetostr(time_r));
    if timetostr(time_c)='00:00:00' then time_str:=datetostr(time_c)+' 00:00:00'
                                    else time_str:=datetimetostr(time_c);
    //showmessage(time_str);

                            write(f_out,time_str);
    if sensors[2]<>'0' then write(f_out,#9,floattostrF(temp,ffFixed,7,3));
    if sensors[3]<>'0' then write(f_out,#9,floattostrF(salt,ffFixed,7,3));
    if sensors[4]<>'0' then write(f_out,#9,floattostrF(press,ffFixed,7,3));
    if sensors[5]<>'0' then write(f_out,#9,floattostrF(dirMC,ffFixed,7,1));
    if sensors[6]<>'0' then write(f_out,#9,floattostrF(speed,ffFixed,7,2));
    if sensors[7]<>'0' then write(f_out,#9,floattostrF(turb,ffFixed,7,3));
    if sensors[8]<>'0' then write(f_out,#9,floattostrF(oxyg,ffFixed,7,1));

    if sensors[2]<>'0' then write(f_out,#9,inttostr(Tfl));
    if sensors[3]<>'0' then write(f_out,#9,inttostr(Sfl));
    if sensors[4]<>'0' then write(f_out,#9,inttostr(Pfl));
    if sensors[5]<>'0' then write(f_out,#9,inttostr(Cfl));  //one flag for
    if sensors[6]<>'0' then write(f_out,#9,inttostr(Cfl));  //direction and speed
    if sensors[7]<>'0' then write(f_out,#9,inttostr(Ufl));
    if sensors[8]<>'0' then write(f_out,#9,inttostr(Ofl));
                            writeln(f_out);

     frmdm.ib1q1.Next;
{r}end;
     frmdm.ib1q1.Close;




//5. CORRECTION COEFFICIENTS

       writeln(f_out);
       writeln(f_out);
       writeln(f_out,'###CORRECTION COEFFICIENTS ');

        cf_angle:=0;
        cf_speed:=0;
        cf_temp :=0;
        cf_salt :=0;
        cf_press:=0;
        cf_turb :=0;
        cf_oxyg :=0;

        Apply_angle:=0;
        Apply_speed:=0;
        Apply_temp :=0;
        Apply_salt :=0;
        Apply_press:=0;
        Apply_turb :=0;
        Apply_oxyg :=0;


     with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT * FROM TIMESERIESCORRECTION  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ABSNUM=:absnum) ');
        ParamByName('ABSNUM').AsInteger:=absnum;
        Open;

        cf_angle:=FieldByName('Angle_kf').AsFloat;
        cf_speed:=FieldByName('Angle_kf').AsFloat;
        cf_temp :=FieldByName('Temp_kf').AsFloat;
        cf_salt :=FieldByName('Salt_kf').AsFloat;
        cf_press:=FieldByName('Press_kf').AsFloat;
        cf_turb :=FieldByName('Turb_kf').AsFloat;
        cf_oxyg :=FieldByName('Oxyg_kf').AsFloat;

        Apply_angle:=FieldByName('Angle_apply').AsInteger;
        Apply_speed:=FieldByName('Speed_apply').AsInteger;
        Apply_temp :=FieldByName('Temp_apply').AsInteger;
        Apply_salt :=FieldByName('Salt_apply').AsInteger;
        Apply_press:=FieldByName('Press_apply').AsInteger;
        Apply_turb :=FieldByName('Turb_apply').AsInteger;
        Apply_oxyg :=FieldByName('Oxyg_apply').AsInteger;


        Close;
     end;

      writeln(f_out,inttostr(Apply_angle),'     ',floattostrF(cf_angle,ffFixed,8,3),'     Apply/coefficient for Current angle');
      writeln(f_out,inttostr(Apply_speed),'     ',floattostrF(cf_speed,ffFixed,8,3),'     Apply/coefficient for Current speed');
      writeln(f_out,inttostr(Apply_temp ),'     ',floattostrF(cf_temp ,ffFixed,8,3),'     Apply/coefficient for Temperature');
      writeln(f_out,inttostr(Apply_salt ),'     ',floattostrF(cf_salt ,ffFixed,8,3),'     Apply/coefficient for Salinity');
      writeln(f_out,inttostr(Apply_press),'     ',floattostrF(cf_press,ffFixed,8,3),'     Apply/coefficient for Pressure/Temperature');
      writeln(f_out,inttostr(Apply_turb ),'     ',floattostrF(cf_turb ,ffFixed,8,3),'     Apply/coefficient for Turbidity');
      writeln(f_out,inttostr(Apply_oxyg ),'     ',floattostrF(cf_oxyg ,ffFixed,8,3),'     Apply/coefficient for Oxygen');


//6. CORRECTED DATA
     writeln(f_out);
     writeln(f_out);
     writeln(f_out,'###CORRECTED DATA');
     writeln(f1_out);
     writeln(f1_out);
     writeln(f1_out,'###CONVERTED, QUALITY CONTROLLED, CORRECTED DATA');
     //writeln(f_out,'                     //Temp(deg.C)  Salt(PSU)  Press/Temp(m/deg.C)  Dir(deg)  Speed(cm/s)  tUrbidity(NTU) Oxygen(%) ');
     //writeln(f_out,'          QC flags:  //TFL          SFL        PFL                  CFL       CFL           UFL           OFL  ');
     str:=' Date        Time'+#9;
   for i:=2 to 9 do begin
   if sensors[i]<>'0' then begin
     case sensors[i] of
     'T': par:='Temp';
     'C': par:='Salt';
     'P': par:='Press';
     'D': par:='Dir';
     'S': par:='Speed';
     'U': par:='Turb';
     'O': par:='Oxyg';
     end;
     str:=str+par+#9;
   end;
   end;

   for i:=2 to 9 do begin
   if sensors[i]<>'0' then begin
     case sensors[i] of
     'T': par:='T';
     'C': par:='S';
     'P': par:='P';
     'D': par:='C';    //one flag
     'S': par:='C';    //for direction and speed
     'U': par:='U';
     'O': par:='O';
     end;
     str:=str+par+'FL'+#9;
   end;
   end;

     writeln(f_out,str);
     writeln(f1_out,str);

     with frmdm.ib1q1 do begin
        Close;
        sql.Clear;
        SQL.Add(' SELECT * FROM CURRENTS  ');
        SQL.Add(' WHERE ');
        SQL.Add(' (ABSNUM=:absnum) ');
        SQL.Add(' order by C_TIME ');
        ParamByName('ABSNUM').AsInteger:=absnum;
        Open;
     end;

{r}while not frmdm.ib1q1.Eof do begin
    Time_C:= frmdm.ib1q1.FieldByName('C_Time').AsDateTime;
    dir   := frmdm.ib1q1.FieldByName('C_ANGLE').AsFloat;

    dirMC:=dir+MC; //add magnetic correction
    if dirMC>360 then dirMC:=dirMC-360;
    if dirMC<0   then dirMC:=dirMC+360;

    speed := frmdm.ib1q1.FieldByName('C_SPEED').AsFloat;
    temp  := frmdm.ib1q1.FieldByName('C_TEMP').AsFloat;
    salt  := frmdm.ib1q1.FieldByName('C_SALT').AsFloat;
    press := frmdm.ib1q1.FieldByName('C_PRESS').AsFloat;
    turb  := frmdm.ib1q1.FieldByName('C_TURB').AsFloat;
    oxyg  := frmdm.ib1q1.FieldByName('C_OXYG').AsFloat;

    Cfl   := frmdm.ib1q1.FieldByName('C_CFL').AsInteger;
    Tfl   := frmdm.ib1q1.FieldByName('C_TFL').AsInteger;
    Sfl   := frmdm.ib1q1.FieldByName('C_SFL').AsInteger;
    Pfl   := frmdm.ib1q1.FieldByName('C_PFL').AsInteger;
    Ufl   := frmdm.ib1q1.FieldByName('C_UFL').AsInteger;
    Ofl   := frmdm.ib1q1.FieldByName('C_OFL').AsInteger;


    //qfl change to SeaDataNet
    if cfl=0 then cfl:=1; //good value
    if cfl=5 then cfl:=3; //probably bad value
    if cfl=9 then cfl:=4; //bad value

    if tfl=0 then tfl:=1; //good value
    if tfl=5 then tfl:=3; //probably bad value
    if tfl=9 then tfl:=4; //bad value

    if sfl=0 then sfl:=1; //good value
    if sfl=5 then sfl:=3; //probably bad value
    if sfl=9 then sfl:=4; //bad value

    if pfl=0 then pfl:=1; //good value
    if pfl=5 then pfl:=3; //probably bad value
    if pfl=9 then pfl:=4; //bad value

    if ufl=0 then ufl:=1; //good value
    if ufl=5 then ufl:=3; //probably bad value
    if ufl=9 then ufl:=4; //bad value

    if ofl=0 then ofl:=1; //good value
    if ofl=5 then ofl:=3; //probably bad value
    if ofl=9 then ofl:=4; //bad value


    //correction  and set QFL=5 (changed value)
    if apply_speed=1 then begin speed:=speed+cf_speed; cfl:=5; end;
    if apply_temp =1 then begin temp :=temp +cf_temp;  tfl:=5; end;
    if apply_salt =1 then begin salt :=salt +cf_salt; sfl:=5; end;
    if apply_press=1 then begin press:=press+cf_press; pfl:=5; end;
    if apply_turb= 1 then begin turb :=turb +cf_turb; ufl:=5; end;
    if apply_oxyg= 1 then begin oxyg :=oxyg +cf_oxyg; ofl:=5; end;




    //showmessage(timetostr(time_r));
    if timetostr(time_c)='00:00:00' then time_str:=datetostr(time_c)+' 00:00:00'
                                    else time_str:=datetimetostr(time_c);
    //showmessage(time_str);

                            write(f_out,time_str);
    if sensors[2]<>'0' then write(f_out,#9,floattostrF(temp,ffFixed,7,3));
    if sensors[3]<>'0' then write(f_out,#9,floattostrF(salt,ffFixed,7,3));
    if sensors[4]<>'0' then write(f_out,#9,floattostrF(press,ffFixed,7,3));
    if sensors[5]<>'0' then write(f_out,#9,floattostrF(dirMC,ffFixed,7,1));
    if sensors[6]<>'0' then write(f_out,#9,floattostrF(speed,ffFixed,7,2));
    if sensors[7]<>'0' then write(f_out,#9,floattostrF(turb,ffFixed,7,3));
    if sensors[8]<>'0' then write(f_out,#9,floattostrF(oxyg,ffFixed,7,1));

    if sensors[2]<>'0' then write(f_out,#9,inttostr(Tfl));
    if sensors[3]<>'0' then write(f_out,#9,inttostr(Sfl));
    if sensors[4]<>'0' then write(f_out,#9,inttostr(Pfl));
    if sensors[5]<>'0' then write(f_out,#9,inttostr(Cfl));  //one flag for
    if sensors[6]<>'0' then write(f_out,#9,inttostr(Cfl));  //direction and speed
    if sensors[7]<>'0' then write(f_out,#9,inttostr(Ufl));
    if sensors[8]<>'0' then write(f_out,#9,inttostr(Ofl));
                            writeln(f_out);

                            write(f1_out,time_str);
    if sensors[2]<>'0' then write(f1_out,#9,floattostrF(temp,ffFixed,7,3));
    if sensors[3]<>'0' then write(f1_out,#9,floattostrF(salt,ffFixed,7,3));
    if sensors[4]<>'0' then write(f1_out,#9,floattostrF(press,ffFixed,7,3));
    if sensors[5]<>'0' then write(f1_out,#9,floattostrF(dirMC,ffFixed,7,1));
    if sensors[6]<>'0' then write(f1_out,#9,floattostrF(speed,ffFixed,7,2));
    if sensors[7]<>'0' then write(f1_out,#9,floattostrF(turb,ffFixed,7,3));
    if sensors[8]<>'0' then write(f1_out,#9,floattostrF(oxyg,ffFixed,7,1));

    if sensors[2]<>'0' then write(f1_out,#9,inttostr(Tfl));
    if sensors[3]<>'0' then write(f1_out,#9,inttostr(Sfl));
    if sensors[4]<>'0' then write(f1_out,#9,inttostr(Pfl));
    if sensors[5]<>'0' then write(f1_out,#9,inttostr(Cfl));  //one flag for
    if sensors[6]<>'0' then write(f1_out,#9,inttostr(Cfl));  //direction and speed
    if sensors[7]<>'0' then write(f1_out,#9,inttostr(Ufl));
    if sensors[8]<>'0' then write(f1_out,#9,inttostr(Ofl));
                            writeln(f1_out);


     frmdm.ib1q1.Next;
{r}end;
     frmdm.ib1q1.Close;



//..............................................................

     closefile(f_out);
     closefile(f1_out);

     Application.ProcessMessages;

     frmdm.Q.Next;
{w}end; {Q}

     frmdm.Q.First;
     frmdm.Q.EnableControls;

     //frmDM.TR1.Active:=false;
     memo1.Visible:=true;
     memo1.Lines.Add('...done');


end;

end.
