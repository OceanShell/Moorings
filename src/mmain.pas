unit mmain;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, Menus, ImgList, ComCtrls, ActnList, math,
  StdCtrls, DBCtrls, Buttons, Spin, DBGrids, ExtCtrls, DateTimePicker,
  sqldb, DateUtils, IniFiles, Grids;

type
   MapDS=record
     ID:int64;
     Latitude:real;
     Longitude:real;
     x:int64;
     y:int64;
end;

type

  { Tfrmmain }

  Tfrmmain = class(TForm)
    actmap: TAction;
    actnewdb: TAction;
    actopendb: TAction;
    actsettings: TAction;
    AL: TActionList;
    applyfilteract: TAction;
    btnadd: TToolButton;
    btncancel: TToolButton;
    btnCDSCommit: TBitBtn;
    btndelete: TToolButton;
    btnMainSelection: TButton;
    btnsave: TToolButton;
    cbInstrument: TComboBox;
    cbInstrumentNum: TComboBox;
    cbMooringID: TComboBox;
    cbPI: TComboBox;
    cbProject: TComboBox;
    clearfilteract: TAction;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    dtpDateMax: TDateTimePicker;
    dtpDateMin: TDateTimePicker;
    GrapherCompositeDrawning1: TMenuItem;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    IL1: TImageList;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lbReset: TLabel;
    MenuItem1: TMenuItem;
    MM: TMainMenu;
    File1: TMenuItem;
    Import1: TMenuItem;
    N1: TMenuItem;
    N3: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    Panel1: TPanel;
    pcSelection: TPageControl;
    PlotConvertedData1: TMenuItem;
    PlotRowData1: TMenuItem;
    pmSelection1: TPopupMenu;
    sbSelection: TStatusBar;
    seIDMax: TSpinEdit;
    seIDMin: TSpinEdit;
    seLatMax: TFloatSpinEdit;
    seLatMin: TFloatSpinEdit;
    seLonMax: TFloatSpinEdit;
    seLonMin: TFloatSpinEdit;
    Splitter3: TSplitter;
    OD: TOpenDialog;
    lbTables: TListBox;
    lbParameters: TListBox;
    Settings1: TMenuItem;
    SD: TSaveDialog;
    lbSensors: TListBox;
    GFIUpload1: TMenuItem;
    ools1: TMenuItem;
    CreateListOfFiles1: TMenuItem;
    LoadHDRFiles1: TMenuItem;
    SalinityFromConductivity1: TMenuItem;
    Plot1: TMenuItem;
    Map1: TMenuItem;
    N2: TMenuItem;
    ConvertRowData1: TMenuItem;
    CreateTextReport1: TMenuItem;
    N4: TMenuItem;
    PlotTimeSeriesLSTGrapher1: TMenuItem;
    Export1: TMenuItem;
    ExportNMDC1: TMenuItem;
    StatusBar1: TStatusBar;
    tabSelectedData: TTabSheet;
    tabSelection: TTabSheet;
    ToolBar3: TToolBar;
    ToolButton1: TToolButton;
    UpdateMooringStartKAL1: TMenuItem;
    RecomputeRowSpeed1: TMenuItem;
    CreateMooringsDirectoryCatalogOnDisk1: TMenuItem;
    ExportExcelMD1: TMenuItem;
    UpdateROWDATA_ReplaceRecords: TMenuItem;
    UploadConvertedDataINN1: TMenuItem;
    UploadConvertedDataLST1: TMenuItem;
    UploadConvertedDataSeaGuard1: TMenuItem;
    UploadROWDataTextFile1: TMenuItem;
    UploadSBE37cnv1: TMenuItem;


    procedure actsettingsExecute(Sender: TObject);
    procedure btnMainSelectionClick(Sender: TObject);
    procedure btnsaveClick(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure DBGrid1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DBGrid1PrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
    procedure DBGrid1TitleClick(Column: TColumn);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    procedure FormShow(Sender: TObject);

    procedure GFIUpload1Click(Sender: TObject);
    procedure CreateListOfFiles1Click(Sender: TObject);
    procedure GrapherCompositeDrawning1Click(Sender: TObject);
    procedure lbResetClick(Sender: TObject);
    procedure LoadHDRFiles1Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure PlotConvertedData1Click(Sender: TObject);
    procedure PlotRowData1Click(Sender: TObject);
    procedure SalinityFromConductivity1Click(Sender: TObject);
    procedure actmapExecute(Sender: TObject);


    procedure applyfilteractExecute(Sender: TObject);
    procedure clearfilteractExecute(Sender: TObject);
    procedure ConvertRowData1Click(Sender: TObject);
    procedure CreateTextReport1Click(Sender: TObject);
  //  procedure actBackupExecute(Sender: TObject);
    procedure PlotTimeSeriesLSTGrapher1Click(Sender: TObject);
    procedure ExportNMDC1Click(Sender: TObject);
    procedure UpdateMooringStartKAL1Click(Sender: TObject);
    procedure RecomputeRowSpeed1Click(Sender: TObject);
    procedure CreateMooringsDirectoryCatalogOnDisk1Click(Sender: TObject);
    procedure ExportExcelMD1Click(Sender: TObject);
    procedure UpdateROWDATA_ReplaceRecordsClick(Sender: TObject);
    procedure UploadConvertedDataINN1Click(Sender: TObject);
    procedure UploadConvertedDataLST1Click(Sender: TObject);
    procedure UploadConvertedDataSeaGuard1Click(Sender: TObject);
    procedure UploadROWDataTextFile1Click(Sender: TObject);
    procedure UploadSBE37cnv1Click(Sender: TObject);

  private
    procedure OpenDatabase;
    procedure GetDropDownList(Sender: TObject);

  public
    procedure CDSNavigation;
  end;

var
  frmmain: Tfrmmain;

  //глобальные переменные
  IBName:string;

  IBCount, SCount, IDMin, IDMax: integer;
  IBYearMin,IBYearMax,IBMonthMin,IBMonthMax,IBDayMin,IBDayMax :Word;
  IBLatMin,IBLatMax,IBLonMin,IBLonMax,SLatMin,SLatMax,SLonMin,SLonMax:Real;
  IBDateMin, IBDateMax, SDateMin, SDateMax :TDateTime;

  MapDataset: array of MapDS;

  NavigationOrder:boolean=true; //Блокируем навигацию пока все модули не ответили
  OldID:integer; // флаг на запись до фильтрации

  frmmap_open:boolean;

implementation

{$R *.lfm}

uses dm, msettings, sortbufds, osmap, import_1, TextFilesList, LoadHDRFiles,
     SalinityFromConductivity, ShowRowData, ConvertRowData, CreateTextReport,
     PlotTimeSeriesLSTGrapher, ExportNMDC,
     UpdateMooringStartKAL, RecomputeRowSpeed,
     CreateMooringsDirectoryCatalogOnDisk, ExportExcel_MD,
     PlotRowData, AddParameterToROWDATA, ReplaceRecordsInROWDATA,
     PlotConvertedData, Grapher_CompositeDrawning, UploadROWDATA_TextFile,
     UploadConvertedDataLST, UploadConvertedDataINN, UploadConvertedDataSeaGuard,
     UploadSBE37_cnv;


procedure Tfrmmain.FormShow(Sender: TObject);
Var
  Ini:TIniFile;
  x, y, k:integer;
  syspath: array [0..MAX_PATH] of char;
  scripter:string;
begin

   (* Определяем глобальный путь к папке с программой *)
  GlobalPath:=ExtractFilePath(Application.ExeName);
  GlobalUnloadPath:=GlobalPath+'unload'+PathDelim;
  GlobalSupportPath:=GlobalPath+'support'+PathDelim;

  (* Создаем нужные директории *)
  if not DirectoryExists(GlobalUnloadPath) then CreateDir(GlobalUnloadPath);
  if not DirectoryExists(GlobalSupportPath) then CreateDir(GlobalSupportPath);

  (* Создаем файл с настройками *)
  IniFileName:=GetUserDir+'.moorings';

  if not DirectoryExists(GlobalUnloadPath+'currents') then CreateDir(GlobalUnloadPath+'currents');
  if not DirectoryExists(GlobalUnloadPath+'currents\grf') then CreateDir(GlobalUnloadPath+'currents\grf');

  (* Loading settings from INI file *)
  Ini := TIniFile.Create(IniFileName);
  try
    (* main form sizes *)
    Width :=Ini.ReadInteger( 'mmain', 'width',  1350);
    Height:=Ini.ReadInteger( 'mmain', 'weight', 700);

    seLatMin.Value   :=Ini.ReadFloat  ( 'mmain', 'latmin',     0);
    seLatMax.Value   :=Ini.ReadFloat  ( 'mmain', 'latmax',     0);
    seLonMin.Value   :=Ini.ReadFloat  ( 'mmain', 'lonmin',     0);
    seLonMax.Value   :=Ini.ReadFloat  ( 'mmain', 'lonmax',     0);
    seIDMin.Value    :=Ini.ReadInteger( 'mmain', 'idmin',      0);
    seIDMax.Value    :=Ini.ReadInteger( 'mmain', 'idmax',      0);

    cbMooringID.Text     :=Ini.ReadString ( 'mmain', 'mooring_id',     '');
    cbInstrument.Text    :=Ini.ReadString ( 'mmain', 'instrument',     '');
    cbInstrumentNum.Text :=Ini.ReadString ( 'mmain', 'instrument_num', '');
    cbPI.Text            :=Ini.ReadString ( 'mmain', 'pi',             '');
    cbProject.Text       :=Ini.ReadString ( 'mmain', 'project',        '');

    dtpDateMin.DateTime:=Ini.ReadDateTime('mmain', 'datemin', now);
    dtpDateMax.DateTime:=Ini.ReadDateTime('mmain', 'datemax', now);

    With DBGrid1 do begin
     Columns[0].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col00',  30);
     Columns[1].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col01',  50);
     Columns[2].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col02',  70);
     Columns[3].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col03',  70);
     Columns[4].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col04',  70);
     Columns[5].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col05',  70);
     Columns[6].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col06',  70);
     Columns[7].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col07',  70);
     Columns[8].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col08',  70);
     Columns[9].Width :=Ini.ReadInteger( 'mmain', 'DBGrid1_Col09',  70);
     Columns[10].Width:=Ini.ReadInteger( 'mmain', 'DBGrid1_Col10',  70);
     Columns[11].Width:=Ini.ReadInteger( 'mmain', 'DBGrid1_Col11',  70);
     Columns[12].Width:=Ini.ReadInteger( 'mmain', 'DBGrid1_Col12',  70);
     Columns[13].Width:=Ini.ReadInteger( 'mmain', 'DBGrid1_Col13',  70);
    End;

    With DBGrid2 do begin
      Columns[0].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col00',  70);
      Columns[1].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col01',  70);
      Columns[2].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col02',  70);
      Columns[3].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col03',  70);
      Columns[4].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col04',  70);
      Columns[5].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col05',  70);
      Columns[6].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col06',  70);
      Columns[7].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col07',  70);
      Columns[8].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col08',  70);
      Columns[9].Width :=Ini.ReadInteger( 'mmain', 'DBGrid2_Col09',  70);
      Columns[10].Width:=Ini.ReadInteger( 'mmain', 'DBGrid2_Col10',  70);
      Columns[11].Width:=Ini.ReadInteger( 'mmain', 'DBGrid2_Col11',  70);
    end;
  finally
    Ini.Free;
  end;

  (* убираем доступность пунктов меню *)
//  for k:=1 to  MM.Items.Count-1 do MM.Items[k].Enabled:=false;
    Application.ProcessMessages;


  (* задаем флаги на открытость немодальных форм *)
  frmmap_open:=false;       // карта станций

  IBName:='localhost:'+GlobalPath+'MOORINGS.FDB';
  OpenDatabase;

  cbMooringID.OnDropDown      := @GetDropDownList;
  cbInstrument.OnDropDown     := @GetDropDownList;
  cbInstrumentNum.OnDropDown  := @GetDropDownList;
  cbPI.OnDropDown             := @GetDropDownList;
  cbProject.OnDropDown        := @GetDropDownList;
end;


procedure Tfrmmain.actmapExecute(Sender: TObject);
begin
  if frmmap_open=true then frmmap.SetFocus else
     begin
        frmmap := Tfrmmap.Create(Self);
        frmmap.Show;
     end;
   frmmap.btnShowAllStationsClick(self);
   frmmap_open:=true;
end;


(*действия при открытии базы *)
procedure Tfrmmain.OpenDatabase;
Var
  cnt, k :integer;

  TRt:TSQLTransaction;
  Qt:TSQLQuery;
begin

    try
     frmdm.DB.Close(false);
     frmdm.DB.DatabaseName:=IBName;
     frmdm.DB.Open;
    except
      on E: Exception do
        if MessageDlg(E.Message, mtWarning, [mbOk], 0)=mrOk then exit;
    end;

    (* temporary transaction for main database *)
    TRt:=TSQLTransaction.Create(self);
    TRt.DataBase:=frmdm.DB;

    (* temporary query for main database *)
    Qt :=TSQLQuery.Create(self);
    Qt.Database:=frmdm.DB;
    Qt.Transaction:=TRt;

    try
      with Qt do begin
       Close;
        SQL.Clear;
        SQL.Add(' select count(ABSNUM) as StCount, ');
        SQL.Add(' min(ABSNUM) as IDMin, max(ABSNUM) as IDMax, ');
        SQL.Add(' min(M_LAT) as StLatMin, max(M_LAT) as StLatMax, ');
        SQL.Add(' min(M_LON) as StLonMin, max(M_LON) as StLonMax, ');
        SQL.Add(' min(Extract(Year from M_TIMEBEG)) as StYearMin, max(Extract(Year from M_TIMEBEG)) as StYearMax, ');
        SQL.Add(' min(Extract(Month from M_TIMEBEG)) as StMonthMin,  max(Extract(Month from M_TIMEBEG))  as StMonthMax, ');
        SQL.Add(' min(Extract(Day from M_TIMEBEG)) as StDayMin,  max(Extract(Day from M_TIMEBEG))  as StDayMax, ');
        SQL.Add(' min(M_TIMEBEG) as StDateMin, max(M_TIMEBEG) as StDateMax ');
        SQL.Add(' from MOORINGS ');
       Open;
        IBCount:=FieldByName('StCount').AsInteger;
        if IBCount>0 then begin
         IDMin     :=FieldByName('IDMin').AsInteger;
         IDMax     :=FieldByName('IDMax').AsInteger;
         IBLatMin  :=FieldByName('StLatMin').AsFloat;
         IBLatMax  :=FieldByName('StLatMax').AsFloat;
         IBLonMin  :=FieldByName('StLonMin').AsFloat;
         IBLonMax  :=FieldByName('StLonMax').AsFloat;
         IBYearMin :=FieldByName('StYearMin').AsInteger;
         IBYearMax :=FieldByName('StYearMax').AsInteger;
         IBMonthMin:=FieldByName('StMonthMin').AsInteger;
         IBMonthMax:=FieldByName('StMonthMax').AsInteger;
         IBDayMin  :=FieldByName('StDayMin').AsInteger;
         IBDayMax  :=FieldByName('StDayMax').AsInteger;
         IBDateMin :=FieldByName('StDateMin').AsDateTime;
         IBDateMax :=FieldByName('StDateMax').AsDateTime;

         with StatusBar1 do begin
           Panels[1].Text:='LtMin: ' +floattostr(IBLatMin);
           Panels[2].Text:='LtMax: ' +floattostr(IBLatMax);
           Panels[3].Text:='LnMin: ' +floattostr(IBLonMin);
           Panels[4].Text:='LnMax: ' +floattostr(IBLonMax);
           Panels[5].Text:='Min: '+datetostr(IBDateMin);
           Panels[6].Text:='Max: '+datetostr(IBDateMax);
           Panels[7].Text:='RCM#: '+inttostr(IBCount);
         end;
      end else for k:=1 to 7 do statusbar1.Panels[k].Text:='---';
    Close;
   end;

   finally
    Trt.Commit;
    Qt.Free;
    Trt.Free;
   end;

   for k:=1 to 7 do sbSelection.Panels[k].Text:='';

   lbReset.OnClick(self);

   Caption:=IBName;
  Application.ProcessMessages;
end;


procedure Tfrmmain.btnMainSelectionClick(Sender: TObject);
Var
  Ini:TIniFile;
  k, ID: integer;
  lat1, lon1:real;
  dat1:TDateTime;
  items_enabled:boolean;
  yy, mn, dd:word;
begin

   if frmdm.TR.Active=true then frmdm.TR.Commit;

   if (dtpDateMin.DateTime>dtpDateMax.DateTime)then begin
     showmessage('First date exceeds the last one');
     exit;
   end;

   with frmdm.Q do begin
     Close;
     sql.Clear;
     SQL.Add(' SELECT ABSNUM, M_RCMNUM, M_ID, M_QFLAG, M_TIMEBEG, M_TIMEEND, ');
     SQL.Add(' M_LAT, M_LON, M_RCMDEPTH, M_RCMTIMEINT, M_BOTTOMDEPTH, ');
     SQL.Add(' M_SENSORS, M_TEMPCHANNEL, M_REC_ROW, M_REC_CUR,  ');
     SQL.Add(' M_RCMTYPE, M_REGION, M_PLACE, M_PI, M_PROJECTNAME, M_ARCHIVENAME, ');
     SQL.Add(' M_ARCHIVEREFNUM, M_SOURCEFILENAME,M_CALIBRATIONSHEET, M_DIRCORRECTION ');
     SQL.Add(' FROM MOORINGS WHERE ');
     SQL.Add(' ABSNUM BETWEEN :IDMin  AND :IDMax ');
     SQL.Add(' AND M_LAT     BETWEEN :SMLatMin  AND :SMLatMax ');
     SQL.Add(' AND M_LON     BETWEEN :SMLonMin  AND :SMLonMax ');
     SQL.Add(' AND M_TIMEBEG BETWEEN :SMBEG AND :SMEND ');

     //mooring ABSNUM
     if cbMooringID.Text<>'' then SQL.Add(' AND M_ID='+QuotedStr(cbMooringID.Text));
     //instrument type
     if cbInstrument.Text<>'' then SQL.Add(' AND M_RCMTYPE='+QuotedStr(cbInstrument.Text));
     //instrument number
     if cbInstrumentNum.Text<>'' then SQL.Add(' AND M_RCMNUM='+QuotedStr(cbInstrumentNum.Text));
     //PI
     if cbPI.Text<>'' then SQL.Add(' AND M_PI='+QuotedStr(cbPI.Text));
     //Project
     if cbProject.Text<>'' then SQL.Add(' AND M_PROJECTNAME='+QuotedStr(cbProject.Text));

     SQL.Add(' ORDER BY M_TIMEBEG, M_RCMDEPTH ' );
     ParamByName('IDMin').AsInteger:=seIDMin.Value;
     ParamByName('IDMax').AsInteger:=seIDMax.Value;
     ParamByName('smLatMin').AsFloat:=seLatMin.Value;
     ParamByName('smLatMax').AsFloat:=seLatMax.Value;
     ParamByName('smLonMin').AsFloat:=seLonMin.Value;
     ParamByName('smLonMax').AsFloat:=seLonMax.Value;
     ParamByName('smBEG').AsDateTime:=dtpDateMin.DateTime;
     ParamByName('smEnd').AsDateTime:=dtpDateMax.DateTime;

     Open;
   end;

   try
    frmdm.Q.DisableControls;

    SLatMin:=90;  SLatMax:=-90;
    SLonMin:=180; SLonMax:=-180;

    SDateMin:=Now;
    SDateMax:=EncodeDate(1, 1, 1);

    SetLength(MapDataset, IBCount);
    k:=-1;

    frmdm.Q.First;
    while not frmdm.Q.EOF do begin
      inc(k);
      ID  :=frmdm.Q.FieldByName('ABSNUM').Value;
      lat1:=frmdm.Q.FieldByName('M_LAT').AsFloat;
      lon1:=frmdm.Q.FieldByName('M_LON').AsFloat;
      dat1:=frmdm.Q.FieldByName('M_TIMEBEG').AsDateTime;

      SLatMin :=min(SLatMin, lat1);
      SLatMax :=max(SLatMax, lat1);
      SLonMin :=min(SLonMin, lon1);
      SLonMax :=max(SLonMax, lon1);

      if CompareDate(dat1, SDateMin)<0 then SDateMin:=dat1;
      if CompareDate(dat1, SDateMax)>0 then SDateMax:=dat1;

      MapDataset[k].ID:=ID;
      MapDataset[k].Latitude :=lat1;
      MapDataset[k].Longitude:=lon1;
     frmdm.Q.Next;
    end;
    SetLength(MapDataset, k);

    frmdm.Q.First;
    SCount:=frmdm.Q.RecordCount;
     if SCount>0 then begin
       with sbSelection do begin
         Panels[0].Text:='Selection:';
         Panels[1].Text:='LtMin: ' +floattostr(SLatMin);
         Panels[2].Text:='LtMax: ' +floattostr(SLatMax);
         Panels[3].Text:='LnMin: ' +floattostr(SLonMin);
         Panels[4].Text:='LnMax: ' +floattostr(SLonMax);
         Panels[5].Text:='Min: '   +datetostr(SDateMin);
         Panels[6].Text:='Max: '   +datetostr(SDateMax);
         Panels[7].Text:='RCM#: '  +inttostr(SCount);
       end;
     end else for k:=1 to 7 do sbSelection.Panels[k].Text:='---';

    (* if there are selected station enabling some menu items *)
    if SCount>0 then items_enabled:=true else items_enabled:=false;

  finally
     frmdm.Q.EnableControls;
  end;


  Ini := TIniFile.Create(IniFileName);
   try
    Ini.WriteFloat   ( 'mmain', 'latmin',   seLatMin.Value);
    Ini.WriteFloat   ( 'mmain', 'latmax',   seLatMax.Value);
    Ini.WriteFloat   ( 'mmain', 'lonmin',   seLonMin.Value);
    Ini.WriteFloat   ( 'mmain', 'lonmax',   seLonMax.Value);
    Ini.WriteInteger ( 'mmain', 'idmin',    seIDMin.Value);
    Ini.WriteInteger ( 'mmain', 'idmax',    seIDMax.Value);
    Ini.WriteString  ( 'mmain', 'mooring_id',    cbMooringID.Text);
    Ini.WriteString  ( 'mmain', 'instrument',     cbInstrument.Text);
    Ini.WriteString  ( 'mmain', 'instrument_num', cbInstrumentNum.Text);
    Ini.WriteString  ( 'mmain', 'pi',            cbPI.Text);
    Ini.WriteString  ( 'mmain', 'project',       cbProject.Text);
    Ini.WriteDateTime( 'mmain', 'datemin',  dtpDateMin.DateTime);
    Ini.WriteDateTime( 'mmain', 'datemax',  dtpDateMax.DateTime);
   finally
     Ini.Free;
   end;



    //dbGridEh1.DataSource:=frmDM.CDSQuery;
  // for k:=0 to DBGridEh1.Columns.Count-1 do DBGridEh1.Columns[k].Title.TitleButton:=true;
 //  for k:=0 to DBGridEh2.Columns.Count-1 do DBGridEh2.Columns[k].Title.TitleButton:=true;


  frmmain.actmap.Enabled:=true;
   // rbtSelectByID.Checked:=false;

end;

procedure Tfrmmain.btnsaveClick(Sender: TObject);
begin
  frmdm.Q.ApplyUpdates(0);
end;

procedure Tfrmmain.DBGrid1CellClick(Column: TColumn);
begin
  CDSNavigation;
end;

procedure Tfrmmain.DBGrid1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key=VK_UP) or (key=VK_DOWN) then CDSNavigation;
end;



procedure Tfrmmain.PlotTimeSeriesLSTGrapher1Click(Sender: TObject);
begin
   frmPlotTimeSeriesLSTGrapher := TfrmPlotTimeSeriesLSTGrapher.Create(Self);
  try
   if frmPlotTimeSeriesLSTGrapher.ShowModal = mrOk then
  finally
    frmPlotTimeSeriesLSTGrapher.Free;
    frmPlotTimeSeriesLSTGrapher:= nil;
  end;

end;



procedure Tfrmmain.RecomputeRowSpeed1Click(Sender: TObject);
begin
   frmRecomputeRowSpeed := TfrmRecomputeRowSpeed.Create(Self);
  try
   if frmRecomputeRowSpeed.ShowModal = mrOk then
  finally
    frmRecomputeRowSpeed.Free;
    frmRecomputeRowSpeed:= nil;
  end;

end;



procedure Tfrmmain.CDSNavigation;
Var
ABSNUM:integer;
begin
ABSNUM:=frmDM.Q.FieldByName('ABSNUM').AsInteger;
if (ABSNUM=0) or (NavigationOrder=false) then exit;
 If NavigationOrder=true then begin
  NavigationOrder:=false; //Блокируем перемещение, пока все не завершим
   if frmmap_open=true then frmmap.ChangeID(absnum);

  NavigationOrder:=true; //Завершили, открываем доступ к навигации
 end;
end;


procedure Tfrmmain.SalinityFromConductivity1Click(Sender: TObject);
begin
   frmSalinityFromConductivity := TfrmSalinityFromConductivity.Create(Self);
  try
   if frmSalinityFromConductivity.ShowModal = mrOk then
  finally
    frmSalinityFromConductivity.Free;
    frmSalinityFromConductivity:= nil;
  end;
end;



procedure Tfrmmain.UpdateMooringStartKAL1Click(Sender: TObject);
begin
   frmUpdateMooringStartKAL := TfrmUpdateMooringStartKAL.Create(Self);
  try
   if frmUpdateMooringStartKAL.ShowModal = mrOk then
  finally
    frmUpdateMooringStartKAL.Free;
    frmUpdateMooringStartKAL:= nil;
  end;
end;


(* запуск формы настроек *)
procedure Tfrmmain.actsettingsExecute(Sender: TObject);
begin
  frmsettings := Tfrmsettings.Create(Self);
  try
   if frmsettings.ShowModal = mrOk then
  finally
    frmsettings.Free;
    frmsettings:= nil;
  end;
end;


procedure Tfrmmain.applyfilteractExecute(Sender: TObject);
Var
ABSNUM, Fl:integer;
Checked:boolean;
Filter:String;
begin
OldID:=frmDM.Q.FieldByName('ABSNUM').AsInteger;
 try
  frmDM.Q.DisableControls;
  frmDM.Q.First;
   Filter:=''; Fl:=0;
   While not frmDM.Q.Eof do begin
     ABSNUM:= frmDM.Q.FieldByName('ABSNUM').AsInteger;
     Checked:= frmDM.Q.FieldByName('STACCESSADD').AsBoolean;
      if Checked=true then begin
        Filter:=Filter+','+InttoStr(ABSNUM);
      //   showmessage(filter);
         frmDM.Q.Edit;
          frmDM.Q.FieldByName('STACCESSADD').AsBoolean:=false;
         frmDM.Q.Post;
       Fl:=1;
      end;
    frmDM.Q.Next;
   end;
   if Fl=0 then exit;
   Filter:='ABSNUM in ('+Copy(Filter, 2, Length(Filter))+')';

 //  showmessage(filter);

   frmDM.Q.Filtered:=false;
   if frmDM.Q.Filtered=true then
      frmDM.Q.Filter:=frmDM.Q.Filter+' or '+Filter else
      frmDM.Q.Filter:=Filter;
   frmDM.Q.Filtered:=true;

   if  frmmap_open=true then begin
     //frmMap.DBChart1.RefreshData;
    // frmMap.btnSelect.Down:=false;
   end;

   with frmmain.sbSelection do begin
     Panels[0].Text:='Selection:';
     Panels[1].Text:='LtMin: ' +floattostr(frmdm.Q.FieldByName('MINLAT').Value);
     Panels[2].Text:='LtMax: ' +floattostr(frmdm.Q.FieldByName('MAXLAT').Value);
     Panels[3].Text:='LnMin: ' +floattostr(frmdm.Q.FieldByName('MINLON').Value);
     Panels[4].Text:='LnMax: ' +floattostr(frmdm.Q.FieldByName('MAXLON').Value);
     Panels[5].Text:='Min: '   +datetostr(frmdm.Q.FieldByName('START').Value);
     Panels[6].Text:='Max: '   +datetostr(frmdm.Q.FieldByName('STOP').Value);
     Panels[7].Text:='RCM#: '  +inttostr(frmdm.Q.FieldByName('COUNT').Value);
   end;

 finally
  frmDM.Q.First;
  frmDM.Q.EnableControls;
 end;
end;


procedure Tfrmmain.clearfilteractExecute(Sender: TObject);
begin
frmDM.Q.Filter:='';
frmDM.Q.Filtered:=false;

 if frmmap_open=true then begin
   //frmMap.DBChart1.Series[2].Clear;
  // frmmap.DBChart1.RefreshData;
 end;

 with sbSelection do begin
   Panels[1].Text:='LtMin: ' +floattostr(IBLatMin);
   Panels[2].Text:='LtMax: ' +floattostr(IBLatMax);
   Panels[3].Text:='LnMin: ' +floattostr(IBLonMin);
   Panels[4].Text:='LnMax: ' +floattostr(IBLonMax);
   Panels[5].Text:='Min: '+datetostr(IBDateMin);
   Panels[6].Text:='Max: '+datetostr(IBDateMax);
   Panels[7].Text:='RCM#: '+inttostr(IBCount);
 end;
frmDM.Q.Locate('ABSNUM', OldID, []);
end;


procedure Tfrmmain.ConvertRowData1Click(Sender: TObject);
begin
  frmConvertRowData := TfrmConvertRowData.Create(Self);
  try
   if frmConvertRowData.ShowModal = mrOk then
  finally
    frmConvertRowData.Free;
    frmConvertRowData:= nil;
  end;

end;

procedure Tfrmmain.CreateListOfFiles1Click(Sender: TObject);
begin
  frmTextFilesList1 := TfrmTextFilesList1.Create(Self);
  try
   if frmTextFilesList1.ShowModal = mrOk then
  finally
    frmTextFilesList1.Free;
    frmTextFilesList1:= nil;
  end;

end;

procedure Tfrmmain.lbResetClick(Sender: TObject);
begin
  seLatMax.Value:=IBLatMax;
  seLatMin.Value:=IBLatMin;
  seLonMax.Value:=IBLonMax;
  seLonMin.Value:=IBLonMin;

  dtpDateMin.DateTime:=IBDateMin;
  dtpDateMax.DateTime:=IBDateMax;

  seIDMin.Value:=IDMin;
  seIDMax.Value:=IDMax;

  cbMooringID.Text:='';
  cbInstrument.Text:='';
  cbPI.Text:='';
  cbProject.Text:='';
  cbInstrumentNum.Text:='';
end;


procedure Tfrmmain.CreateMooringsDirectoryCatalogOnDisk1Click(Sender: TObject);
begin
   frmCreateMooringsDirectoryCatalogOnDisk:= TfrmCreateMooringsDirectoryCatalogOnDisk.Create(Self);
  try
   if frmCreateMooringsDirectoryCatalogOnDisk.ShowModal = mrOk then
  finally
    frmCreateMooringsDirectoryCatalogOnDisk.Free;
    frmCreateMooringsDirectoryCatalogOnDisk:= nil;
  end;

end;

procedure Tfrmmain.CreateTextReport1Click(Sender: TObject);
begin
   frmCreateTextReport:= TfrmCreateTextReport.Create(Self);
  try
   if frmCreateTextReport.ShowModal = mrOk then
  finally
    frmCreateTextReport.Free;
    frmCreateTextReport:= nil;
  end;

end;

procedure Tfrmmain.GFIUpload1Click(Sender: TObject);
begin
  frmImport1 := TfrmImport1.Create(Self);
  try
   if frmImport1.ShowModal = mrOk then
  finally
    frmImport1.Free;
    frmImport1:= nil;
  end;
end;



procedure Tfrmmain.LoadHDRFiles1Click(Sender: TObject);
begin
  frmLoadHDRFiles := TfrmLoadHDRFiles.Create(Self);
  try
   if frmLoadHDRFiles.ShowModal = mrOk then
  finally
    frmLoadHDRFiles.Free;
    frmLoadHDRFiles:= nil;
  end;

end;


procedure Tfrmmain.PlotConvertedData1Click(Sender: TObject);
begin
  if frmDM.Q.FieldByName('M_QFLAG').AsInteger>=8 then begin
     showmessage('Time series were not converted! QFLAG>=8 ');
     Exit;
  end
  else begin
     //plot time series in engineering units
     frmPlotConvertedData := TfrmPlotConvertedData.Create(Self);
   try
   if frmPlotConvertedData.ShowModal = mrOk then
   finally
     frmPlotConvertedData.Free;
     frmPlotConvertedData:= nil;
   end;
  end;
end;

procedure Tfrmmain.PlotRowData1Click(Sender: TObject);
begin
//plot current data in engeeniering units for QC
  frmPlotRowData := TfrmPlotRowData.Create(Self);
   try
   if frmPlotRowData.ShowModal = mrOk then
   finally
     frmPlotRowData.Free;
     frmPlotRowData:= nil;
   end;
end;


procedure Tfrmmain.GrapherCompositeDrawning1Click(Sender: TObject);
begin
    frmGrapher_CompositeDrawning:= TfrmGrapher_CompositeDrawning.Create(Self);
   try
   if frmGrapher_CompositeDrawning.ShowModal = mrOk then
   finally
     frmGrapher_CompositeDrawning.Free;
     frmGrapher_CompositeDrawning:= nil;
   end;
end;


procedure Tfrmmain.UploadROWDataTextFile1Click(Sender: TObject);
begin
 frmUploadROWDATA_TextFile:= TfrmUploadROWDATA_TextFile.Create(Self);
  try
    if frmUploadROWDATA_TextFile.ShowModal = mrOk then
  finally
   frmUploadROWDATA_TextFile.Free;
   frmUploadROWDATA_TextFile:= nil;
  end;
end;

procedure Tfrmmain.UpdateROWDATA_ReplaceRecordsClick(Sender: TObject);
begin
  //update current mooring instrument by adding new parameter time series
  frmReplaceRecordsInROWDATA:= TfrmReplaceRecordsInROWDATA.Create(Self);
   try
   if frmReplaceRecordsInROWDATA.ShowModal = mrOk then
   finally
     frmReplaceRecordsInROWDATA.Free;
     frmReplaceRecordsInROWDATA:= nil;
   end;
end;

procedure Tfrmmain.UploadConvertedDataINN1Click(Sender: TObject);
begin
  //upload converted data in INN format
  frmUploadConvertedDataINN:= TfrmUploadConvertedDataINN.Create(Self);
   try
   if frmUploadConvertedDataINN.ShowModal = mrOk then
   finally
     frmUploadConvertedDataINN.Free;
     frmUploadConvertedDataINN:= nil;
   end;
end;

procedure Tfrmmain.UploadConvertedDataLST1Click(Sender: TObject);
begin
 //upload converted data in LST format
  frmUploadConvertedDataLST:= TfrmUploadConvertedDataLST.Create(Self);
   try
   if frmUploadConvertedDataLST.ShowModal = mrOk then
   finally
     frmUploadConvertedDataLST.Free;
     frmUploadConvertedDataLST:= nil;
   end;
end;

procedure Tfrmmain.UploadConvertedDataSeaGuard1Click(Sender: TObject);
begin
 //upload converted data in LST format
  frmUploadConvertedDataSeaGuard:= TfrmUploadConvertedDataSeaGuard.Create(Self);
   try
   if frmUploadConvertedDataSeaGuard.ShowModal = mrOk then
   finally
     frmUploadConvertedDataSeaGuard.Free;
     frmUploadConvertedDataSeaGuard:= nil;
   end;
end;


procedure Tfrmmain.UploadSBE37cnv1Click(Sender: TObject);
begin
 frmUploadSBE37_cnv:= TfrmUploadSBE37_cnv.Create(Self);
   try
   if frmUploadSBE37_cnv.ShowModal = mrOk then
   finally
     frmUploadSBE37_cnv.Free;
     frmUploadSBE37_cnv:= nil;
   end;
end;


procedure Tfrmmain.MenuItem1Click(Sender: TObject);
begin
 //update current mooring instrument by adding new parameter time series
 frmAddParameterToROWDATA := TfrmAddParameterToROWDATA.Create(Self);
  try
    if frmAddParameterToROWDATA.ShowModal = mrOk then
  finally
   frmAddParameterToROWDATA.Free;
   frmAddParameterToROWDATA:= nil;
  end;
end;


procedure Tfrmmain.ExportExcelMD1Click(Sender: TObject);
begin
  frmExportExcel_MD:= TfrmExportExcel_MD.Create(Self);
  try
   if frmExportExcel_MD.ShowModal = mrOk then
  finally
    frmExportExcel_MD.Free;
    frmExportExcel_MD:= nil;
  end;
end;

procedure Tfrmmain.ExportNMDC1Click(Sender: TObject);
begin
  frmExportNMDC := TfrmExportNMDC.Create(Self);
  try
   if frmExportNMDC.ShowModal = mrOk then
  finally
    frmExportNMDC.Free;
    frmExportNMDC:= nil;
  end;
end;


procedure Tfrmmain.GetDropDownList(Sender: TObject);
Var
  TRt:TSQLTransaction;
  Qt:TSQLQuery;
  par: string;
begin
if Sender is TComboBox then begin
 TRt:=TSQLTransaction.Create(self);
 TRt.DataBase:=frmdm.DB;

 Qt :=TSQLQuery.Create(self);
 Qt.Database:=frmdm.DB;
 Qt.Transaction:=TRt;

 if TComboBox(Sender).Name='cbMooringID'     then par:='M_ID';
 if TComboBox(Sender).Name='cbInstrument'    then par:='M_RCMTYPE';
 if TComboBox(Sender).Name='cbInstrumentNum' then par:='M_RCMNUM';
 if TComboBox(Sender).Name='cbPI'            then par:='M_PI';
 if TComboBox(Sender).Name='cbProject'       then par:='M_PROJECTNAME';

 try
   if (Sender as TComboBox).Items.Count=0 then begin
     Qt.SQL.Text:=' select distinct '+par+' from MOORINGS ';
     Qt.Open;
    while not Qt.Eof do begin
       (Sender as TComboBox).Items.Add(Qt.Fields[0].AsString);
      Qt.Next;
    end;
    Qt.Close;
   end;
  finally
    TRt.Commit;
    Qt.Free;
    Trt.free;
  end;
end;
end;


procedure Tfrmmain.DBGrid1PrepareCanvas(sender: TObject; DataCol: Integer;
  Column: TColumn; AState: TGridDrawState);
begin
  if ((column.Index=0) and (column.Title.Caption='')) or
    (column.FieldName='ABSNUM') then begin
    TDBGrid(sender).Canvas.Brush.Color := clBtnFace;
 end;

 if (gdRowHighlight in AState) then begin
    TDBGrid(Sender).Canvas.Brush.Color := clNavy;
    TDBGrid(Sender).Canvas.Font.Color  := clYellow;
    TDBGrid(Sender).Canvas.Font.Style  := [fsBold];
 end;
end;

procedure Tfrmmain.DBGrid1TitleClick(Column: TColumn);
begin
  sortbufds.SortBufDataSet(frmdm.Q, Column.FieldName);
end;


procedure Tfrmmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Var
  Ini:TIniFile;
begin
   Ini := TIniFile.Create(IniFileName);
   try
    With DBGrid1 do begin
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col00', Columns[0].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col01', Columns[1].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col02', Columns[2].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col03', Columns[3].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col04', Columns[4].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col05', Columns[5].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col06', Columns[6].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col07', Columns[7].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col08', Columns[8].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col09', Columns[9].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col10', Columns[10].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col11', Columns[11].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col12', Columns[12].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid1_Col13', Columns[13].Width);
    end;
    With DBGrid2 do begin
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col00', Columns[0].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col01', Columns[1].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col02', Columns[2].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col03', Columns[3].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col04', Columns[4].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col05', Columns[5].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col06', Columns[6].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col07', Columns[7].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col08', Columns[8].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col09', Columns[9].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col10', Columns[10].Width);
     Ini.WriteInteger( 'mmain', 'DBGrid2_Col11', Columns[11].Width);
    end;

   finally
     Ini.Free;
   end;
end;


end.
