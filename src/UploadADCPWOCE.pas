//ADCP RCM data upload in WOCE format
//default value -999
//separate bins uploaded as diffrent instruments

unit UploadADCPWOCE;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, {DBClient,} DB;

type
  TfrmADCPWOCE = class(TForm)
    OpenDialog1: TOpenDialog;
    btnOpen: TBitBtn;
    Memo1: TMemo;
    btnCreateCDS: TBitBtn;
    btn_Upload: TBitBtn;
    procedure btnOpenClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCreateCDSClick(Sender: TObject);
    procedure btn_UploadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmADCPWOCE: TfrmADCPWOCE;
  RCMNum,BD,RCMDepth,TimeInt: integer;
  Lat,Lon,deg,min,DirCorrection: real;
  TimeBeg,TimeEnd,mt: TDateTime;
  M_ID: string;

  bin_step,bin_total,FirstEnsemble,lines: integer;

  fn_dir,fn_spd: string;
  f_dir,f_spd: text;
  cdsDataCreated: boolean;
  cdsData: TClientDataset;


implementation

{$R *.lfm}

uses DM;

procedure TfrmADCPWOCE.FormShow(Sender: TObject);
begin
     cdsDataCreated:=false;
end;



procedure TfrmADCPWOCE.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    if cdsDataCreated=true then begin
     cdsData.EmptyDataSet;
     cdsData.Free;
     cdsDataCreated:=false;
    end;
end;




procedure TfrmADCPWOCE.btnOpenClick(Sender: TObject);
var
k,mik: integer;
M_RCMNum,M_Lat,M_Lon,M_BottomDepth,M_RCMDepth,M_TimeBeg,M_TimeEnd,M_RCMTimeInt,M_DirCorrection : string;
lines_dir,lines_spd: integer;
mt: TDateTime;
st: string;
Lat_sign,Lon_sign: string;
d_str,m_str,y_str,hh_str,mm_str,time_str: string;

begin

    OpenDialog1.InitialDir:='d:\data\Currents\GFI\ADCP\ModifiedWOCEFormat\';

  if OpenDialog1.Execute then
     fn_dir:=OpenDialog1.FileName
   else begin
     showmessage('File not selected!');
     Exit;
   end;

     fn_spd:=ChangeFileExt(fn_dir,'.spd');
     memo1.Lines.Add('file with direction: '+fn_dir);
     memo1.Lines.Add('file with speed    : '+fn_spd);
     M_ID:=ExtractFileName(fn_dir);
     M_ID:=copy(M_ID,1,8);

     assignfile(f_dir,fn_dir);
     reset(f_dir);

   //get metadata
{w}for k:=1 to 16 do begin
     readln(f_dir, st);
     memo1.Lines.Add(inttostr(k)+#9+st);

     if k=2  then M_RCMNum       :=trim(copy(st,16,6));
     if k=4  then M_Lat          :=trim(copy(st,10,10));
     if k=4  then Lat_Sign       :=trim(copy(st,21,1));
     if k=5  then M_Lon          :=trim(copy(st,11,9));
     if k=5  then Lon_Sign       :=trim(copy(st,21,1));
     if k=6  then M_BottomDepth  :=trim(copy(st,14,5));
     if k=8  then M_RCMDepth     :=trim(copy(st,27,5)); //actually not instrument depth but first bin mean depth
     if k=12 then M_TimeBeg      :=trim(copy(st,24,17));
     if k=14 then M_TimeEnd      :=trim(copy(st,23,18));
     if k=15 then M_RCMTimeInt   :=trim(copy(st,31,5));
     if k=16 then M_DirCorrection:=trim(copy(st,46,5));


     if k=9  then bin_step     :=strtoint(trim(copy(st,12,4)));
     if k=10 then bin_total    :=strtoint(trim(copy(st,16,4)));
     if k=11 then FirstEnsemble:=strtoint(trim(copy(st,26,7)));




{w}end;
     closefile(f_dir);

     //TimeBeg [of first ensemble:] 1997 06 16 15 40
     y_str:=trim(copy(M_TimeBeg,1,4));
     m_str:=trim(copy(M_TimeBeg,6,2));
     d_str:=trim(copy(M_TimeBeg,9,2));
     hh_str:=trim(copy(M_TimeBeg,12,2));
     mm_str:=trim(copy(M_TimeBeg,15,2));
     time_str:=d_str+'.'+m_str+'.'+y_str+' '+hh_str+':'+mm_str+':'+'00';
     memo1.Lines.Add('Start [string]:'+time_str);
     TimeBeg:=strtodatetime(time_str);
     //TimeEnd [of first ensemble:] 1997 06 16 15 40
     y_str:=trim(copy(M_TimeEnd,1,4));
     m_str:=trim(copy(M_TimeEnd,6,2));
     d_str:=trim(copy(M_TimeEnd,9,2));
     hh_str:=trim(copy(M_TimeEnd,12,2));
     mm_str:=trim(copy(M_TimeEnd,15,2));
     time_str:=d_str+'.'+m_str+'.'+y_str+' '+hh_str+':'+mm_str+':'+'00';
     memo1.Lines.Add('Stop [string]:'+time_str);
     TimeEnd:=strtodatetime(time_str);



     memo1.Lines.Add('');
     memo1.Lines.Add('M_ID            :'+M_ID);
     memo1.Lines.Add('M_RCMNum        :'+M_RCMNum);
     memo1.Lines.Add('M_Lat           :'+M_Lat+Lat_Sign);
     memo1.Lines.Add('M_Lon           :'+M_Lon+Lon_Sign);
     memo1.Lines.Add('M_BottomDepth   :'+M_BottomDepth);
     memo1.Lines.Add('M_RCMDepth      :'+M_RCMDepth);
     memo1.Lines.Add('M_TimeBeg       :'+M_TimeBeg);
     memo1.Lines.Add('M_TimeEnd       :'+M_TimeEnd);
     memo1.Lines.Add('M_RCMTimeInt    :'+M_RCMTimeInt);
     memo1.Lines.Add('M_DirCorrection :'+M_DirCorrection);


     RCMNum       :=strtoint(M_RCMNum);
     RCMDepth     :=strtoint(M_RCMDepth);
     BD           :=strtoint(M_BottomDepth);
     TimeInt      :=strtoint(M_RCMTimeInt);
     DirCorrection:=strtofloat(M_DirCorrection);
     //Lat 61 24.980 N
     deg:=strtofloat(copy(M_Lat,1,2));
     min:=strtofloat(copy(M_Lat,4,6));
     lat:=deg+min/60;
     if Lat_sign='S' then lat:=-lat;
     //Lon 08 16.980 W
     deg:=strtofloat(copy(M_Lon,1,2));
     min:=strtofloat(copy(M_Lon,4,6));
     lon:=deg+min/60;
     if Lon_sign='W' then lon:=-lon;

     memo1.Lines.Add('');
     memo1.Lines.Add('RCMNum        :'+inttostr(RCMNum));
     memo1.Lines.Add('BD            :'+inttostr(BD));
     memo1.Lines.Add('TimeInt       :'+inttostr(TimeInt));
     memo1.Lines.Add('DirCorrection :'+floattostr(DirCorrection));
     memo1.Lines.Add('Lat           :'+floattostr(Lat));
     memo1.Lines.Add('Lon           :'+floattostr(Lon));
     memo1.Lines.Add('Start         :'+datetimetostr(TimeBeg));
     memo1.Lines.Add('Stop          :'+datetimetostr(TimeEnd));

     memo1.Lines.Add('');
     memo1.Lines.Add('RCMDepth      :'+inttostr(RCMDepth));
     memo1.Lines.Add('bin_step      :'+inttostr(bin_step));
     memo1.Lines.Add('bin_total     :'+inttostr(bin_total));

   //control dir
     reset(f_dir);
     mik:=0;
{w}while not EOF(f_dir)do begin
     readln(f_dir, st);
     mik:=mik+1;
{i}if mik>=24 then begin //data starts from line 24

     mt:=TimeBeg+(TimeInt*(mik-24))/1440; //measurement time
     //memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt)+#9+st);
     //memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt));

{i}end;
{w}end;
     closefile(f_dir);
     lines_dir:=mik;

   //control spd
     assignfile(f_spd,fn_spd);
     reset(f_spd);
     mik:=0;
{w}while not EOF(f_spd)do begin
     readln(f_spd, st);
     mik:=mik+1;
{i}if mik>=24 then begin //data starts from line 24

     mt:=TimeBeg+(TimeInt*(mik-24))/1440; //measurement time
     //memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt)+#9+st);
     //memo1.Lines.Add(inttostr(mik)+#9+datetimetostr(mt));

{i}end;
{w}end;
     closefile(f_spd);
     lines_spd:=mik;

     if lines_dir=lines_spd then lines:=lines_dir
     else begin
       showmessage('Number of lines in dir and spd files is different');
       Exit;
     end;

     lines:=lines-1;  //last line seems to be without data
     memo1.Lines.Add('lines dir/spd: '+inttostr(lines));

end;



procedure TfrmADCPWOCE.btnCreateCDSClick(Sender: TObject);
var
i,k: integer;
bin_depth,ensD,ensS: integer;
col_name: string;

dir_arr,spd_arr: array[1..100] of integer;
begin


//create cdsData: ensemble, direction[1..bin_count], speed[1..bin_count]]
{i}if cdsDataCreated=false  then begin
     cdsData:=TClientDataSet.Create(nil);

{w}with cdsData.FieldDefs do begin

     Add('ensemble',ftInteger,0,true);

{d} for i:=1 to bin_total do begin
     bin_depth:=RCMDEpth-bin_step*(i-1); //up looking ADCP
     col_name:='d'+inttostr(bin_depth);
     Add(col_name,ftInteger,0,true);
{d}end;
{s} for i:=1 to bin_total do begin
     bin_depth:=RCMDEpth-bin_step*(i-1); //up looking ADCP
     col_name:='s'+inttostr(bin_depth);
     Add(col_name,ftInteger,0,true);
{s}end;

{w}end;
    cdsData.CreateDataSet;
    cdsData.LogChanges:=false;
    cdsDataCreated:=true;
{i}end;


//populate cdsData from two text files
     assignfile(f_dir,fn_dir);
     reset(f_dir);
     assignfile(f_spd,fn_spd);
     reset(f_spd);

//{w}while not EOF(f_dir)do begin
{w}for k:=1 to lines do begin
     readln(f_dir);
     readln(f_spd);
{m}if k>=23 then begin //data starts from line 24

     read(f_dir,ensD); //showmessage('ensD='+inttostr(ensD));
     for i:=1 to bin_total do read(f_dir,dir_arr[i]);
     //readln(f_dir);

     read(f_spd,ensS);  //showmessage('ensS='+inttostr(ensS));
     for i:=1 to bin_total do read(f_spd,spd_arr[i]);
     //readln(f_spd);

     mt:=TimeBeg+(TimeInt*(k-24))/1440; //measurement time
     //memo1.Lines.Add(inttostr(k)+#9+datetimetostr(mt)+#9+inttostr(ensD)+'->'+inttostr(ensS));

     //populate
{a}if ensD=ensS then begin
     cdsData.Append;
     cdsData.FieldByName('ensemble').AsInteger:=ensD;
   for i:=1 to bin_total do begin
     bin_depth:=RCMDEpth-bin_step*(i-1); //up looking ADCP
     col_name:='d'+inttostr(bin_depth);
     cdsData.FieldByName(col_name).AsInteger:=dir_arr[i];
   end;
   for i:=1 to bin_total do begin
     bin_depth:=RCMDEpth-bin_step*(i-1); //up looking ADCP
     col_name:='s'+inttostr(bin_depth);
     cdsData.FieldByName(col_name).AsInteger:=spd_arr[i];
   end;
     cdsData.Post;
{a}end;

{m}end;
{w}end;
     closefile(f_dir);
     closefile(f_spd);

     memo1.Lines.Add('');
     memo1.Lines.Add('Records in cdsData:'+inttostr(cdsData.RecordCount));
     memo1.Lines.Add('...done');

end;



procedure TfrmADCPWOCE.btn_UploadClick(Sender: TObject);
var
mik: integer;
m,ens,absnum,bin_depth,QFL: integer;
dir,spd: real;
begin


  with frmDM.ib1q2 do begin
    Close;
    SQL.Clear;
    SQL.Add(' INSERT INTO MOORINGS ');
    SQL.Add(' (ABSNUM, M_RCMNUM, M_ID, M_TIMEBEG, M_TIMEEND, M_LAT, M_LON, M_RCMDEPTH,  ');
    SQL.Add(' M_RCMTIMEINT, M_BOTTOMDEPTH, M_REC_ROW, M_REC_CUR,');
    SQL.Add(' M_RCMTYPE, M_REGION, M_PLACE, M_PI, M_PROJECTNAME,  ');
    SQL.Add(' M_ARCHIVENAME, M_ARCHIVEREFNUM, M_SOURCEFILENAME, M_CALIBRATIONSHEET, ');
    SQL.Add(' M_QFLAG, M_SENSORS, M_TEMPCHANNEL, M_DIRCORRECTION) ');
    SQL.Add(' VALUES ');
    SQL.Add(' (:ABSNUM, :M_RCMNUM, :M_ID, :M_TIMEBEG, :M_TIMEEND, :M_LAT, :M_LON, :M_RCMDEPTH,  ');
    SQL.Add(' :M_RCMTIMEINT, :M_BOTTOMDEPTH, :M_REC_ROW, :M_REC_CUR, ');
    SQL.Add(' :M_RCMTYPE, :M_REGION, :M_PLACE, :M_PI, :M_PROJECTNAME,  ');
    SQL.Add(' :M_ARCHIVENAME, :M_ARCHIVEREFNUM, :M_SOURCEFILENAME, :M_CALIBRATIONSHEET, ');
    SQL.Add(' :M_QFLAG, :M_SENSORS, :M_TEMPCHANNEL, :M_DIRCORRECTION) ');
    Prepare;
  end;


   with frmDM.ib1q3 do begin
     Close;
     SQL.Clear;
     SQL.Add(' insert into CURRENTS ');
     SQL.Add(' (ABSNUM, C_TIME, C_ANGLE, C_SPEED, C_CFL) ');
     SQL.Add(' values ');
     SQL.Add(' (:ABSNUM, :C_TIME, :C_ANGLE, :C_SPEED, :C_CFL) ');
     Prepare;
   end;


     memo1.Lines.Add('');

{m}for m:=0 to bin_total-1 do begin  //bin_total = number of depth levels
     cdsData.First;

     bin_depth:=RCMDEpth-bin_step*m; //up looking ADCP

   //get last absnum
   with frmDM.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' select gen_id(gen_absnum,0) from RDB$DataBase ');
     Open;
     absnum:=Fields[0].AsInteger;
     absnum:=absnum+1;
     Close;
   end;


     //showmessage(cdsData.Fields.Fields[0].Text);
     //showmessage(cdsData.Fields[0].DisplayName);
     //showmessage(cdsData.Fields[0].DisplayText);
     //showmessage(cdsData.Fields[0].FullName);

     memo1.Lines.Add('');
     memo1.Lines.Add('absnum='+inttostr(absnum));
     memo1.Lines.Add(cdsData.FieldDefs.Items[0].Name
                 +#9+cdsData.FieldDefs.Items[m+1].Name
                 +#9+cdsData.FieldDefs.Items[m+1+bin_total].Name);

   with frmDM.ib1q2 do begin
     ParamByName('ABSNUM').AsInteger:=absnum;
     ParamByName('M_RCMNUM').AsInteger:=RCMNUM;
     ParamByName('M_RCMDEPTH').AsInteger:=bin_depth; //central depth in a bin
     ParamByName('M_RCMTIMEINT').AsInteger:=TimeInt;
     ParamByName('M_BOTTOMDEPTH').AsInteger:=BD;
     ParamByName('M_QFLAG').AsInteger:=0;
     ParamByName('M_TEMPCHANNEL').AsInteger:=-9;
     ParamByName('M_REC_ROW').AsInteger:=0;
     ParamByName('M_REC_CUR').AsInteger:=cdsData.RecordCount;
     ParamByName('M_ARCHIVEREFNUM').AsInteger:=0;

     ParamByName('M_TIMEBEG').AsDateTime:=TimeBeg;
     ParamByName('M_TIMEEND').AsDateTime:=TimeEnd;

     ParamByName('M_LAT').AsFloat:=Lat;
     ParamByName('M_LON').AsFloat:=Lon;
     ParamByName('M_DIRCORRECTION').AsFloat:=DirCorrection;

     ParamByName('M_ID').AsString:=M_ID;  //10 characters
     ParamByName('M_RCMTYPE').AsString:='ADCP RDI75';      //10 characters
     ParamByName('M_REGION').AsString:='North Atlantic';   //20 characters
     ParamByName('M_PLACE').AsString:='Faroe Bank';        //20 characters
     ParamByName('M_PI').AsString:='Svein Osterhus';       //20 characters
     ParamByName('M_ARCHIVENAME').AsString:='GFI';         //40 characters
     ParamByName('M_SOURCEFILENAME').AsString:=fn_dir;     //160 characters
     ParamByName('M_SENSORS').AsString:='0000DS000';       //9 characters

     ExecSQL;
    end;
     frmDM.TR1.Commit;


     mik:=0;
{w}while not cdsData.Eof do begin
     mik:=mik+1;
     ens:=cdsData.Fields.Fields[0].AsInteger;
     dir:=cdsData.Fields.Fields[m+1].AsInteger;  //directions have been corrected
     spd:=cdsData.Fields.Fields[m+1+bin_total].AsInteger;

     if spd<>-999 then
     spd:=spd/10;  // mm/s -> cm/s

     if dir<>-999 then begin
     dir:=dir-DirCorrection;  //make direction uncorrected as all in DB
     if dir>360 then dir:=dir-360;
     if dir<0   then dir:=dir+360;
     end;

     QFL:=0;
     if (spd=-999) or (dir=-999) then QFL:=9;

     mt:=TimeBeg+(TimeInt*(mik-1))/1440; //measurement time

     //if m=bin_total-1 then
     //memo1.Lines.Add(inttostr(ens)+#9+datetimetostr(mt)+#9+floattostr(dir)+#9+floattostr(spd));

   with frmDM.ib1q3 do begin
     ParamByName('ABSNUM').AsInteger:=absnum;
     ParamByName('C_TIME').AsDateTime:=mt;
     ParamByName('C_ANGLE').AsFloat:=dir;
     ParamByName('C_SPEED').AsFloat:=spd;
     ParamByName('C_CFL').AsInteger:=QFL;
     ExecSQL;
   end;

     cdsData.Next;
{w}end;
     frmDM.TR1.Commit;
{m}end;

     frmDM.ib1q2.UnPrepare;
     frmDM.ib1q3.UnPrepare;

     memo1.Lines.Add('');
     memo1.Lines.Add('...upload to DB compleated');

end;





end.
