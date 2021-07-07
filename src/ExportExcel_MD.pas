unit ExportExcel_MD;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, {ExcelXP,} ComObj;

type
  TfrmExportExcel_MD = class(TForm)
    btnExtractMDfromDB: TBitBtn;
    Memo1: TMemo;
    procedure btnExtractMDfromDBClick(Sender: TObject);
  private
    { Private declarations }
    procedure GetRegion(M_ID:string; M_Latitude:real; var region:string; var DetailedLocation:string);
    procedure GetKeywords(sensors:string; var GCMDkeywords:string);

  public
    { Public declarations }
  end;

var
  frmExportExcel_MD: TfrmExportExcel_MD;
  path: string;

implementation

{$R *.lfm}

uses DM, msettings;

procedure TfrmExportExcel_MD.btnExtractMDfromDBClick(Sender: TObject);
var
//WorkBk : _WorkBook;
//WorkSheet : _WorkSheet;
XL: Variant;
DataFile:string; //path to the output xls file
XLTemplate:string; //path to the template

i, ind: integer;
y,m,d: word;
M_Count,idepth,idepth_min,idepth_max: integer;
m_lat,m_lon: real;
CurrentDate: TDateTime;
mstart,mstop,mstart_min,mstop_max: TDateTime;

dstr,mstr: string[2];
M_ID,Inst,PIname,region,place,sensors,sensors_all,GCMDkeywords,project: string;
ecol_A,ecol_B,ecol_C,ecol_D,ecol_E,ecol_F,ecol_G: string;
ecol_K,ecol_L,ecol_M,ecol_N,ecol_O,ecol_P,ecol_S,ecol_T: string;
ecol_Q,ecol_U,ecol_V,ecol_W,ecol_X,ecol_Y,ecol_AA,ecol_AB,ecol_AC,ecol_AD: string;
ecol_AH,ecol_AI,ecol_AJ,ecol_AL,ecol_AS,ecol_AY,ecol_AZ: string;
ecol_BB,ecol_BC,ecol_BD,ecol_BG,ecol_BI,ecol_BQ,ecol_BR: string;

begin
     path:='d:\OceanShell\applications\unload\currents\Excel\';

    DataFile:=GlobalPath+'unload\excel\ExportExcel.xls';
    XLTemplate:=GlobalPath+'support\ExportExcel_MD.xls';
    XL := CreateOleObject('Excel.Application');
    XL.WorkBooks.Add(XLTemplate);


     frmdm.TR.StartTransaction;

   //mooring composition
   with frmdm.ib1q2 do begin
     Close;
     SQL.Clear;
     SQL.Add(' select * from MOORINGS  ');
     SQL.Add(' where M_ID=:M_ID ');
     SQL.Add(' order by M_RCMDEPTH ');
     Prepare;
   end;

   //moorings identifiers
   with frmdm.ib1q1 do begin
     Close;
     sql.Clear;
     SQL.Add(' select M_ID, count(M_ID) from MOORINGS  ');
     SQL.Add(' group by M_ID ');
     Open;
   end;

     frmdm.ib1q1.First;
     ind:=2; // first string in the file (skip the header)
{w}while not frmdm.ib1q1.Eof do begin
     inc(ind); //increment for a new string

     sensors_all:='000000000';
     mstart_min:=strtodate('31.12.2050');
     mstop_max :=strtodate('01.01.1900');
     idepth_min:=9999;
     idepth_max:=0;

     M_ID:=frmdm.ib1q1.FieldByName('M_ID').AsString;
     M_Count:=frmdm.ib1q1.FieldByName('Count').AsInteger;

     //ecol_B:='GFI mooring data';  //entry_title
     ecol_B:='Physical oceanography at GFI mooring station:';  //Benjamin suggested a new title
     ecol_C:='The dataset allows quantifying temporal variability of currents (speed and direction) ';  //purpose
     ecol_C:=ecol_C+'and available variables at the fixed location and fixed depth(s) at sea. ';  //purpose
     ecol_D:='This dataset includes Geophysical Institute (GFI), University of Bergen mooring ';  //summary
     //reference
     ecol_G:='Harden, B. E., et al. (2016), Upstream Sources of the Denmark Strait Overflow: Observations from a High-Resolution Mooring Array, Deep Sea Research Part I: Oceanographic Research Papers, 112, 94–112';
     ecol_M:='Institute of Marine Research, Norwegian Marine Data Centre, Norway ';  //datacenter
     ecol_N:='Ann Kristin Østrem';  //datacenter_person
     ecol_O:='Geophysical Institute, University of Bergen  ';  //originating_institution
     ecol_S:='Unrestricted  ';  //use_constraints
     ecol_T:='Unrestricted  ';  //access_constraints
     ecol_Q:='English  ';  //language
     ecol_W:='OCEANS'; //iso_topic_category
     ecol_X:='CURRENT METERS'; //keyword
     ecol_Y:='OCEANS > OCEAN CIRCULATION > OCEAN CURRENTS,'; //gcmd_science_keywords
     ecol_AJ:='ftp'; //media
     ecol_AL:='NetCDF, text, pdf'; //format
     ecol_AS:='Complete'; //dataset_progress
     ecol_AY:='Steinar Myking, Alexander Korablev'; //dataset_creator
     ecol_AZ:='GFI mooring data'; //dataset_title
     ecol_BB:='Bergen'; //dataset_release_place
     ecol_BD:='Alexander Korablev'; //dataset_release_place
     ecol_BG:='time series'; //data_presentation_form
     ecol_BI:='ftp://ftp.nmdc.no/nmdc/UIB/Currents/moorings/'; //online_resource
     ecol_BQ:='GET DATA'; //url_type
     ecol_BR:='ftp://ftp.nmdc.no/nmdc/UIB/Currents/moorings/'; //url

     ecol_BI:=ecol_BI+M_ID+'/';
     ecol_BR:=ecol_BR+M_ID+'/';

     CurrentDate:=Date;
     DecodeDate(CurrentDate,y,m,d);
     if m<10 then mstr:='0'+inttostr(m) else mstr:=inttostr(m);
     if d<10 then dstr:='0'+inttostr(d) else dstr:=inttostr(d);
     //showmessage('m='+mstr+'  d='+dstr);
     ecol_BC:=inttostr(y)+'-'+mstr+'-'+dstr; //dataset_release_date


   //mooring composition: instrument number
   with frmdm.ib1q2 do begin
     ParamByName('M_ID').AsString:=M_ID;
     Open;
   end;
     Inst:='';
     frmdm.ib1q2.First;
{m}while not frmdm.ib1q2.Eof do begin
     Inst:=Inst+frmdm.ib1q2.FieldByName('M_RCMTYPE').AsString+':';
     Inst:=Inst+inttostr(frmdm.ib1q2.FieldByName('M_RCMNUM').AsInteger);
     Inst:=Inst+'('+inttostr(frmdm.ib1q2.FieldByName('M_RCMDEPTH').AsInteger)+'m) ';
     PIname:=frmdm.ib1q2.FieldByName('M_PI').AsString;
     sensors:=frmdm.ib1q2.FieldByName('M_SENSORS').AsString;
     project:=frmdm.ib1q2.FieldByName('M_PROJECTNAME').AsString;
     //find all sensors in mooring
     for i:=1 to 9 do
     if sensors[i]<>'0' then sensors_all[i]:=sensors[i];

     m_lat:=frmdm.ib1q2.FieldByName('M_LAT').AsFloat;
     m_lon:=frmdm.ib1q2.FieldByName('M_LON').AsFloat;

     idepth:=frmdm.ib1q2.FieldByName('M_RCMDEPTH').AsInteger;
     //inst. min and max depth
     if idepth>idepth_max then idepth_max:=idepth;
     if idepth<idepth_min then idepth_min:=idepth;

     //mooring start and stop
     mstart:=frmdm.ib1q2.FieldByName('M_TIMEBEG').AsDateTime;
     mstop:=frmdm.ib1q2.FieldByName('M_TIMEEND').AsDateTime;
     if mstart_min>mstart then mstart_min:=mstart;
     if mstop_max<mstop then mstop_max:=mstop;

     frmdm.ib1q2.Next;
{m}end;
     frmdm.ib1q2.Close;

     ecol_A:=M_ID;
     ecol_B:=ecol_B+' - '+M_ID;

     //summary
     ecol_D:=ecol_D+' '+M_ID+' data.';
     ecol_D:=ecol_D+' The mooring consists of ';
     ecol_D:=ecol_D+inttostr(M_Count)+' inst. (instrument type:instrument number(instrument depth)):';
     ecol_D:=ecol_D+Inst+'.';
     ecol_D:=ecol_D+' Metadata and raw/processed time series are presented as NetCDF, text and pdf';
     ecol_D:=ecol_D+'(plots with statistics, calibration sheets, mooring drawing) files.';

     DecodeDate(mstart_min,y,m,d);
     if m<10 then mstr:='0'+inttostr(m)  else mstr:=inttostr(m);
     if d<10 then dstr:='0'+inttostr(d)  else dstr:=inttostr(d);
     ecol_E:=inttostr(y)+'-'+mstr+'-'+dstr; //dataset_release_date

     DecodeDate(mstop_max,y,m,d);
     if m<10 then mstr:='0'+inttostr(m)  else mstr:=inttostr(m);
     if d<10 then dstr:='0'+inttostr(d)  else dstr:=inttostr(d);
     ecol_F:=inttostr(y)+'-'+mstr+'-'+dstr; //dataset_release_date

     ecol_P:=PIname;
     ecol_L:=Project;


     //U location
     GetRegion(M_ID,m_lat,region,place);
     ecol_U:=region;
     ecol_V:=place;

     //Y gcmd_science_keywords
     GetKeywords(sensors_all,GCMDkeywords);
     ecol_Y:=GCMDkeywords;

     //position: southern_latitude, northern_latitude, western_longitude, eastern_longitude
     ecol_AA:=floattostr(m_lat);
     ecol_AB:=floattostr(m_lat);
     ecol_AC:=floattostr(m_lon);
     ecol_AD:=floattostr(m_lon);

     ecol_AH:=inttostr(idepth_min);
     ecol_AI:=inttostr(idepth_max);

     ecol_AZ:=ecol_AZ+' - '+M_ID;

     memo1.Lines.Add('');
     memo1.Lines.Add(M_ID+#9+inttostr(M_Count));
     memo1.Lines.Add(' A: '+ecol_A);             //entry_id
     memo1.Lines.Add(' B: '+ecol_B);             //entry_title
     memo1.Lines.Add(' C: '+ecol_C);             //purpose
     memo1.Lines.Add(' D: '+ecol_D);             //summary
     memo1.Lines.Add(' E: '+ecol_E);             //start_date
     memo1.Lines.Add(' F: '+ecol_F);             //end_date
     memo1.Lines.Add(' G: '+ecol_G);             //reference
     memo1.Lines.Add(' L: '+ecol_L);             //project
     memo1.Lines.Add(' M: '+ecol_M);             //datacenter
     memo1.Lines.Add(' N: '+ecol_N);             //datacenter_person
     memo1.Lines.Add(' O: '+ecol_O);             //originating_institution
     memo1.Lines.Add(' P: '+ecol_P);             //originating_institution_person
     memo1.Lines.Add(' Q: '+ecol_Q);             //language
     memo1.Lines.Add(' S: '+ecol_S);             //use_constraints
     memo1.Lines.Add(' T: '+ecol_T);             //access_constraints
     memo1.Lines.Add(' U: '+ecol_U);             //location
     memo1.Lines.Add(' V: '+ecol_U);             //detailed_location
     memo1.Lines.Add(' W: '+ecol_W);             //iso_topic_category
     memo1.Lines.Add(' X: '+ecol_X);             //keyword
     memo1.Lines.Add(' Y: '+ecol_Y);             //gcmd_science_keywords

     memo1.Lines.Add('AA: '+ecol_AA);            //southern_latitude
     memo1.Lines.Add('AB: '+ecol_AB);            //northern__latitude
     memo1.Lines.Add('AC: '+ecol_AC);            //western_longitude
     memo1.Lines.Add('AD: '+ecol_AD);            //eastern_longitude
     memo1.Lines.Add('AH: '+ecol_AH);            //minimum_depth
     memo1.Lines.Add('AI: '+ecol_AI);            //maximum_depth
     memo1.Lines.Add('AJ: '+ecol_AJ);            //media
     memo1.Lines.Add('AL: '+ecol_AL);            //format
     memo1.Lines.Add('AS: '+ecol_AS);            //progress
     memo1.Lines.Add('AZ: '+ecol_AY);            //data_creator
     memo1.Lines.Add('AZ: '+ecol_AZ);            //dataset_title

     memo1.Lines.Add('BB: '+ecol_BB);            //dataset_release_place
     memo1.Lines.Add('BC: '+ecol_BC);            //dataset_release_date
     memo1.Lines.Add('BD: '+ecol_BD);            //dataset_publisher
     memo1.Lines.Add('BG: '+ecol_BG);            //data_presentation_form
     memo1.Lines.Add('BI: '+ecol_BI);            //online_resource
     memo1.Lines.Add('BQ: '+ecol_BQ);            //url_type
     memo1.Lines.Add('BR: '+ecol_BR);            //url


     Xl.Cells[ind, 1]:=ecol_A;             //entry_id
     Xl.Cells[ind, 2]:=ecol_B;             //entry_title
     Xl.Cells[ind, 3]:=ecol_C;             //purpose
     Xl.Cells[ind, 4]:=ecol_D;             //summary
     Xl.Cells[ind, 5]:=ecol_E;             //start_date
     Xl.Cells[ind, 6]:=ecol_F;             //end_date
     Xl.Cells[ind, 7]:=ecol_G;             //reference
   //Xl.Cells[ind, 8]:=ecol_H;             //metadata_name
   //Xl.Cells[ind, 9]:=ecol_I;             //metadata_version
   //Xl.Cells[ind,10]:=ecol_J;             //metadata_version
   //Xl.Cells[ind,11]:=ecol_K;             //geographical_coverage
     Xl.Cells[ind,12]:=ecol_L;             //project
     Xl.Cells[ind,13]:=ecol_M;             //datacenter
     Xl.Cells[ind,14]:=ecol_N;             //datacenter_person
     Xl.Cells[ind,15]:=ecol_O;             //originating_institution
     Xl.Cells[ind,16]:=ecol_P;             //originating_institution_person
     Xl.Cells[ind,17]:=ecol_Q;             //language
   //XL.Cells[ind,18]:=ecol_R;             //platform
     Xl.Cells[ind,19]:=ecol_S;             //use_constraints
     Xl.Cells[ind,20]:=ecol_T;             //access_constraints
     Xl.Cells[ind,21]:=ecol_U;             //location
     Xl.Cells[ind,22]:=ecol_V;             //detailed location
     Xl.Cells[ind,23]:=ecol_W;             //iso_topic_category
     Xl.Cells[ind,24]:=ecol_X;             //keyword
     Xl.Cells[ind,25]:=ecol_Y;             //gcmd_science_keywords
   //Xl.Cells[ind,26]:=ecol_Z;             //detailed_gcmd_keyword
     Xl.Cells[ind,27]:=ecol_AA;            //southern_latitude
     Xl.Cells[ind,28]:=ecol_AB;            //northern__latitude
     Xl.Cells[ind,29]:=ecol_AC;            //western_longitude
     Xl.Cells[ind,30]:=ecol_AD;            //eastern_longitude
   //Xl.Cells[ind,31]:=ecol_AE;            //projection
   //Xl.Cells[ind,32]:=ecol_AF;            //minimum_altitude
   //Xl.Cells[ind,33]:=ecol_AG;            //maximum_altitude
     Xl.Cells[ind,34]:=ecol_AH;            //minimum_depth
     Xl.Cells[ind,35]:=ecol_AI;            //maximum_depth
     Xl.Cells[ind,36]:=ecol_AJ;            //media
   //Xl.Cells[ind,37]:=ecol_AK;            //size
     Xl.Cells[ind,38]:=ecol_AL;            //format
    (* numbers 39-51 *)
     Xl.Cells[ind,45]:=ecol_AS;            //dataset_title
     Xl.Cells[ind,51]:=ecol_AY;            //dataset_creator
     Xl.Cells[ind,52]:=ecol_AZ;            //dataset_title
   //Xl.Cells[ind,53]:=ecol_BA;            //dataset_series_name
     Xl.Cells[ind,54]:=ecol_BB;            //dataset_release_place
     Xl.Cells[ind,55]:=ecol_BC;            //dataset_release_date
     (* numbers 56-58 *)
     Xl.Cells[ind,56]:=ecol_BD;            //dataset_publisher
     Xl.Cells[ind,59]:=ecol_BG;            //data_presentation_form
   //Xl.Cells[ind,60]:=ecol_BA;            //dataset_series_name
     Xl.Cells[ind,61]:=ecol_BI;            //online_resource
     (* numbers 62-68 *)
     Xl.Cells[ind,69]:=ecol_BQ;            //url_type
     Xl.Cells[ind,70]:=ecol_BR;            //url

     frmdm.ib1q1.Next;
{w}end;


  //  XL.ActiveWorkBook.SaveAs(DataFile,xlNormal,'','',false,false, xlNoChange,emptyParam,emptyParam,emptyParam,emptyParam,1);
    XL.Quit;  //Save results and quit Excel

     memo1.Lines.Add('Moorings count='+inttostr(frmdm.ib1q1.RecordCount));

     frmdm.ib1q2.UnPrepare;
     frmdm.ib1q1.Close;
     frmdm.TR.Active:=false;

end;



procedure TfrmExportExcel_MD.GetRegion(M_ID:string; M_Latitude:real; var region:string; var DetailedLocation:string);
var
RID,place: string;
begin

     RID:=copy(M_ID,1,3); //region ID

                       region:='';
                       place:='';
     if RID='ANT' then region:='Ocean>Southern Ocean>Weddell Sea';
     if RID='AO_' then region:='Ocean>Arctic Ocean';
     if RID='BSO' then begin
                       region:='Ocean>Arctic Ocean>Barents Sea';
                       place :='Barents Sea Opening';
                       end;

     if RID='BS_' then region:='Ocean>Arctic Ocean>Barents Sea';

     if RID='DS_' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place :='Denmark Strait';
                       end;

     if RID='FBC' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place :='Faroe Bank Channel';
                       end;

     if (RID='FJ_') and (M_Latitude<=66.56222) then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place :='Fjord';
                       end;

     if (RID='FJ_') and (M_Latitude >66.56222) then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place :='Fjord';
                       end;

     if RID='FR_' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place :='Faroe Islands';
                       end;

     if RID='FSC' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place :='Faroe Shetland Channel';
                       end;

     if RID='FS_' then begin
                       region:='Ocean>Arctic Ocean';
                       place:='Fram Strait';
                       end;

     if RID='GS_' then begin
                       region:='Ocean>Arctic Ocean';
                       place:='Greenland Sea';
                       end;

     if RID='IO_' then region:='Ocean>Indian Ocean';

     if RID='JM_' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place :='Jan Mayen';
                       end;

     if RID='KF_' then begin
                       region:='Ocean>Arctic Ocean';
                       place:='Kongsfjorden Svalbard';
                       end;

     if RID='LOF' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place:='Lofoten';
                       end;

     if RID='MD_' then region:='Ocean>Atlantic Ocean>Mediterranean Sea';

     if RID='MR_' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place:='Mohns Ridge';
                       end;

     if (RID='NS_') and (M_Latitude>60.35)  then region:='Ocean>Atlantic Ocean>North Atlantic Ocean>Norwegian Sea';
     if (RID='NS_') and (M_Latitude<=60.35) then region:='Ocean>Atlantic Ocean>North Atlantic Ocean>North Sea';
     if (RID='NTA') and (M_Latitude>60.35)  then region:='Ocean>Atlantic Ocean>North Atlantic Ocean>Norwegian Sea';
     if (RID='NTA') and (M_Latitude<=60.35) then region:='Ocean>Atlantic Ocean>North Atlantic Ocean>North Sea';
     if (RID='NTS') and (M_Latitude>60.35)  then region:='Ocean>Atlantic Ocean>North Atlantic Ocean>Norwegian Sea';
     if (RID='NTS') and (M_Latitude<=60.35) then region:='Ocean>Atlantic Ocean>North Atlantic Ocean>North Sea';


     //if RID='NTA' then region:='Ocean>Atlantic Ocean>North Sea';
     //if RID='NTS' then region:='Ocean>Atlantic Ocean>North Sea Sections';

     if RID='SKA' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean>North Sea';
                       place:='Skagerrak';
                       end;

     if RID='SO_' then region:='Ocean>Southern Ocean';

     if RID='SV_' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place:='Svalbard';
                       end;


     if RID='SVI' then begin
                       region:='Ocean>Atlantic Ocean>North Atlantic Ocean';
                       place:='Svinoy';
                       end;

     if RID='YP_' then begin
                       region:='Ocean>Arctic Ocean';
                       place :='Yarmak Plato';
                       end;

     DetailedLocation:=place;


end;




procedure TfrmExportExcel_MD.GetKeywords(sensors:string; var GCMDkeywords:string);
var
kw: string;
begin

     kw:='EARTH SCIENCE>OCEANS>OCEAN CIRCULATION>OCEAN CURRENTS';
     //sensors RTCPDSUO0
     if copy(sensors,2,1)='T' then kw:=kw+', EARTH SCIENCE>OCEANS>OCEAN TEMPERATURE>WATER TEMPERATURE';
     if copy(sensors,3,1)='C' then kw:=kw+', EARTH SCIENCE>OCEANS>SALINITY/DENSITY>SALINITY';
     if copy(sensors,4,1)='P' then kw:=kw+', EARTH SCIENCE>OCEANS>OCEAN PRESSURE>WATER PRESSURE';
     if copy(sensors,7,1)='U' then kw:=kw+', EARTH SCIENCE>OCEANS>OCEAN OPTICS>TURBIDITY';
     if copy(sensors,8,1)='O' then kw:=kw+', EARTH SCIENCE>OCEANS>OCEAN CHEMISTRY>OXYGEN';

     GCMDkeywords:=kw;

end;



end.
