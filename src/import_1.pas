unit import_1;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DateUtils, ComObj, DB, BufDataset;

type
  TfrmImport1 = class(TForm)
    btnLoad: TButton;
    btnOpenDownloadFile: TBitBtn;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;

    procedure btnLoadClick(Sender: TObject);
    procedure btnOpenDownloadFileClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    { Private declarations }
    procedure read_hdr(fn: string; var RN: integer; var RLat, RLon: real;
      var RDepth, RInt: integer; var RStart: TDateTime;
      var ta1, ta2, tb1, tb2, tc, td, ca1, ca2, cb1, cb2, cc, cd, pa1, pa2,
      pb1, pb2, pc, pd, da1, da2, db1, db2, dc, dd, sa1, sa2, sb1, sb2, sc,
      sd: real);

    procedure GetCoeff(st: string; var cf1, cf2, cf3, cf4, cf5, cf6: real);
    procedure PopulateROWDATA_Table(fn_hdr: string; absnum: integer;
      RStart: TDateTime; RTimeInt: integer; var RStop: TDateTime;
      var RRecNum: integer);

    procedure GetMDFromExcel(ARN, RDepth: integer; RStart: TDateTime;
      var Region, Place, Project, PI, Archive, RCMType: string;
      BotDepth: integer);

    procedure Create_cdsCatalog;

  public
    { Public declarations }
  end;

var
  frmImport1: TfrmImport1;
  pathDownload: string = 'c:\data\Currents\gfi';
  fn: string;
  cdsCatalog:TBufDataSet;
  cdsCreated:boolean=false;
  f, f_hdr, f_dat: text;

implementation

uses dm;
{$R *.lfm}


procedure TfrmImport1.FormClose(Sender: TObject; var Action: TCloseAction);
begin

    if cdsCreated=true then begin
     // cdsCatalog.EmptyDataSet;
      cdsCatalog.Free;
    end;

end;



procedure TfrmImport1.Create_cdsCatalog;
var
  c, mik: integer;
  y, m, d, h, min, s, ms: word;
  xls_id, xls_ARN, RCMDepthCatalog, BottomDepthCatalog: integer;
  xls_reg, xls_start, xls_stop, xls_PI, xls_pos, xls_Project, xls_ArchiveName: string;
  xls_BotDepth, xls_rigg, xls_InstN, xls_InstDepth, xls_Year, xls_Place: string;
  XL: Variant;
  DateIsValid: boolean;
  date_xls, date_hdr: TDateTime;
begin

{c}if cdsCreated=false then begin
    cdsCatalog:=TBufDataSet.Create(nil);
   with cdsCatalog.FieldDefs do begin
    Add('C_ARN',ftInteger,0,false);
    Add('C_ID',ftInteger,0,false);
    Add('C_RCMStart',ftDate,0,false);
    Add('C_RCMDepth',ftInteger,0,false);
    Add('C_Region',ftString,20,false);
    Add('C_Place',ftString,20,false);
    Add('C_Project',ftString,40,false);
    Add('C_PI',ftString,20,false);
    Add('C_Archive',ftString,40,false);
    Add('C_Rigg',ftString,10,false);
    Add('C_BottomDepth',ftInteger,0,false);
   end;
    cdsCatalog.CreateDataSet;
   // cdsCatalog.LogChanges:=false;
    cdsCreated:=true;
{c}end;

  Memo1.Lines.Add('populate cdsCATALOG ...');

  XL := CreateOleObject('Excel.Application');
  XL.WorkBooks.Add('c:\data\Currents\GFI\strømdata.xlsx'); // имя файла

  mik := 0; // number of moorings found
  c := 2; // счетчик строк
{x}repeat
{1}if trim(vartostr(XL.Cells[c, 1])) <> '' then begin // если первая строчка не пустая
    xls_id := XL.Cells[c, 1];           //Int
    xls_reg := XL.Cells[c, 2];
    xls_ARN := XL.Cells[c, 3];          //Int
    xls_start := trim(XL.Cells[c, 4]);
    xls_stop := XL.Cells[c, 5];
    xls_PI := XL.Cells[c, 6];
    xls_pos := XL.Cells[c, 7];
    xls_Project := XL.Cells[c, 8];
    xls_ArchiveName := XL.Cells[c, 9];
    xls_BotDepth := XL.Cells[c, 10];
    xls_rigg := XL.Cells[c, 11];
    xls_InstN := XL.Cells[c, 12];
    xls_InstDepth := XL.Cells[c, 13];   //Int
    xls_Year := XL.Cells[c, 14];
    xls_Place := XL.Cells[c, 15];

                                RCMDepthCatalog   :=-9;
                                BottomDepthCatalog:=-9;
    if xls_InstDepth <> '' then RCMDepthCatalog   := strtoint(xls_InstDepth);
    if xls_BotDepth  <> '' then BottomDepthCatalog:= strtoint(xls_BotDepth);

    // date conversion
    if (length(xls_start)=6) or (length(xls_start)=8) then DateIsValid := true
                                                      else DateIsValid := false;

{d}if DateIsValid=true then begin
        // 1. convert date from catalog to date format
{6}if length(xls_start)=6 then begin
     y:= strtoint(copy(xls_start,1,2));
     if y>30 then y:=1900+y else y:=2000+y;
     m:=strtoint(copy(xls_start,3,2));
     d:=strtoint(copy(xls_start,5,2));
     date_xls:= EncodeDate(y,m,d);
{6}end;
{8}if length(xls_start)=8 then begin
    y := strtoint(copy(xls_start, 1, 4));
    m := strtoint(copy(xls_start, 5, 2));
    d := strtoint(copy(xls_start, 7, 2));
    date_xls:=EncodeDate(y,m,d);
{8}end;
{d}end;

    mik:=mik+1;

    //Memo1.Lines.Add('');
    //Memo1.Lines.Add('ID         : ' + inttostr(xls_id));
    //Memo1.Lines.Add('Region     : ' + xls_reg);
    //Memo1.Lines.Add('ArchiveRef : ' + inttostr(xls_ARN));
    //Memo1.Lines.Add('Start      : ' + xls_start);
    //Memo1.Lines.Add('Stop       : ' + xls_stop);
    //Memo1.Lines.Add('PI         : ' + xls_PI);
    //Memo1.Lines.Add('pos        : ' + xls_pos);
    //Memo1.Lines.Add('Project    : ' + xls_Project);
    //Memo1.Lines.Add('ArchiveName: ' + xls_ArchiveName);
    //Memo1.Lines.Add('BotDepth   : ' + xls_BotDepth);
    //Memo1.Lines.Add('rigg       : ' + xls_rigg);
    //Memo1.Lines.Add('InstN      : ' + xls_InstN);
    //Memo1.Lines.Add('InstDepth  : ' + xls_InstDepth);
    //Memo1.Lines.Add('Year       : ' + xls_Year);
    //Memo1.Lines.Add('Place      : ' + xls_Place);

   with cdsCatalog do begin
    Append;
    FieldByName('C_ARN').AsInteger:=xls_ARN;
    FieldByName('C_ID').AsInteger:=xls_id;
    FieldByName('C_RCMStart').AsDateTime:=date_xls;
    FieldByName('C_RCMDepth').AsInteger:=RCMDepthCatalog;
    FieldByName('C_Region').AsString:=xls_reg;
    FieldByName('C_Place').AsString:=xls_place;
    FieldByName('C_Project').AsString:=xls_project;
    FieldByName('C_PI').AsString:=xls_PI;
    FieldByName('C_Archive').AsString:=xls_ArchiveName;
    FieldByName('C_Rigg').AsString:=xls_rigg;
    FieldByName('C_BottomDepth').AsInteger:=BottomDepthCatalog;

    Post;
   end;

    inc(c);

{1}end;
{x}until trim(vartostr(XL.Cells[c,1]))= '';

    XL.Quit; // закрываем Эксель
    Memo1.Lines.Add('Number of moorings in catalog: '+inttostr(mik));
end;




procedure TfrmImport1.btnOpenDownloadFileClick(Sender: TObject);
var
  mik: integer;
  HDRNum: integer;
  st, CalSheet, fn_hdr: string;
  sensors: string[6];
  TCh: string[2];
  sym: char;

  RN, RDepth, RInt: integer;
  RLat, RLon: real;
  RStart: TDateTime;
  ta1, ta2, tb1, tb2, tc, td, ca1, ca2, cb1, cb2, cc, cd, pa1, pa2, pb1, pb2,
    pc, pd: real;
  da1, da2, db1, db2, dc, dd, sa1, sa2, sb1, sb2, sc, sd: real;
  RCF: real;

begin

  Memo1.Clear;

  OpenDialog1.InitialDir := pathDownload;
  if OpenDialog1.Execute then
  begin
    fn := OpenDialog1.FileName;
    Memo1.Lines.Add('download file: ' + fn);
    Memo1.Lines.Add('');
  end;

  assignfile(f, fn);
  reset(f);

  sym := ' ';
  mik := 0;
  { f } while not EOF(f) do
  begin
    readln(f, st); // 1
    if st <> '' then
      sym := st[1]
    else
      sym := ' ';
    { # } if sym = '#' then
    begin
      mik := mik + 1;
      HDRNum := strtoint(trim(copy(st, 2, length(st))));
      readln(f, fn_hdr); // 2 path
      readln(f, sensors); // 3 sensors
      readln(f, TCh); // 4 temperature channel
      readln(f, CalSheet); // calibration sheet .pdf

      Memo1.Lines.Add(inttostr(mik) + '  HDRNum=' + inttostr(HDRNum));
      Memo1.Lines.Add(fn_hdr);
      Memo1.Lines.Add(sensors + '  ' + TCh + '  ' + CalSheet + '.pdf');

      read_hdr(fn_hdr, RN, RLat, RLon, RDepth, RInt, RStart, ta1, ta2, tb1,
        tb2, tc, td, ca1, ca2, cb1, cb2, cc, cd, pa1, pa2, pb1, pb2, pc, pd,
        da1, da2, db1, db2, dc, dd, sa1, sa2, sb1, sb2, sc, sd);

      Memo1.Lines.Add('RCM# ' + inttostr(RN) + '  Lat=' + floattostrF(RLat,
          ffFixed, 12, 5) + '  Lon=' + floattostrF(RLon, ffFixed, 12,
          5) + '  Depth=' + floattostr(RDepth) + '  Int=' + floattostr(RInt)
          + '  Start=' + datetimetostr(RStart));

      Memo1.Lines.Add('temp :' + #9 + floattostr(ta1) + #9 + floattostr(ta2)
          + #9 + floattostr(tb1) + #9 + floattostr(tb2) + #9 + floattostr(tc)
          + #9 + floattostr(td));
      Memo1.Lines.Add('cond :' + #9 + floattostr(ca1) + #9 + floattostr(ca2)
          + #9 + floattostr(cb1) + #9 + floattostr(cb2) + #9 + floattostr(cc)
          + #9 + floattostr(cd));
      Memo1.Lines.Add('pres :' + #9 + floattostr(pa1) + #9 + floattostr(pa2)
          + #9 + floattostr(pb1) + #9 + floattostr(pb2) + #9 + floattostr(pc)
          + #9 + floattostr(pd));
      Memo1.Lines.Add('dir  :' + #9 + floattostr(da1) + #9 + floattostr(da2)
          + #9 + floattostr(db1) + #9 + floattostr(db2) + #9 + floattostr(dc)
          + #9 + floattostr(dd));
      Memo1.Lines.Add('speed:' + #9 + floattostr(sa1) + #9 + floattostr(sa2)
          + #9 + floattostr(sb1) + #9 + floattostr(sb2) + #9 + floattostr(sc)
          + #9 + floattostr(sd));

      RCF := sb1 * RInt * 60 / 42; // rotor counter factor
      Memo1.Lines.Add('RCF  :' + #9 + floattostrF(RCF, ffFixed, 12, 2));

      { # } end;

    { f } end;
  closefile(f);

  btnLoad.Visible := true;

end;


procedure TfrmImport1.read_hdr(fn: string; var RN: integer;
  var RLat, RLon: real; var RDepth, RInt: integer; var RStart: TDateTime;
  var ta1, ta2, tb1, tb2, tc, td, ca1, ca2, cb1, cb2, cc, cd, pa1, pa2, pb1,
  pb2, pc, pd, da1, da2, db1, db2, dc, dd, sa1, sa2, sb1, sb2, sc, sd: real);
var
  i: integer;
  st, pos, time_start, recFL: string;

  p1, p2, ARN: integer;
  my, mm, md, mh, mmin, ms, mms: word;
  lat, lon, lat_deg, lat_min, lon_deg, lon_min: real;
  lt_sym, ln_sym: char;
  lt_st, ln_st, p_deg, p_min: string;
  mtime_beg: TDateTime;

begin

  assignfile(f_hdr, fn);
  reset(f_hdr);

  // read hdr
  { h } for i := 1 to 12 do
  begin
    case i of
      1:
        begin // instrument number
          readln(f_hdr, st);
          RN := strtoint(trim(copy(st, 1, 20)));
        end;
      2:
        begin // position
          readln(f_hdr, st);
          pos := trim(copy(st, 1, 20));
        end;
      3:
        begin // instrument depth
          readln(f_hdr, st);
          RDepth := strtoint(trim(copy(st, 1, 20)));
        end;
      4:
        begin // sampling interval
          readln(f_hdr, st);
          RInt := strtoint(trim(copy(st, 1, 20)));
        end;
      5:
        begin // time start
          readln(f_hdr, st);
          time_start := trim(copy(st, 1, 20));
        end;
      6:
        begin // record number first and last
          readln(f_hdr, st);
          recFL := trim(copy(st, 1, 20));
        end;
      7:
        begin // temp coefficients
          readln(f_hdr, st);
          GetCoeff(st, ta1, ta2, tb1, tb2, tc, td);
          // memo1.Lines.Add('... temp coef ... ok')
        end;
      8:
        begin // cond coefficients
          readln(f_hdr, st);
          GetCoeff(st, ca1, ca2, cb1, cb2, cc, cd);
          // memo1.Lines.Add('... cond coef ... ok')
        end;
      9:
        begin // press/temp coefficients
          readln(f_hdr, st);
          GetCoeff(st, pa1, pa2, pb1, pb2, pc, pd);
          // memo1.Lines.Add('... press/temp coef ... ok')
        end;
      10:
        begin // direction coefficients
          readln(f_hdr, st);
          GetCoeff(st, da1, da2, db1, db2, dc, dd);
          // memo1.Lines.Add('... dir coef ... ok')
        end;
      11:
        begin // speed coefficients
          readln(f_hdr, st);
          GetCoeff(st, sa1, sa2, sb1, sb2, sc, sd);
          // memo1.Lines.Add('... speed coef ... ok')
        end;

    end; { case }
    { h } end;
  closefile(f_hdr);

//showmessage(pos);
  // convert coordinataes START assume that lat the first lon the second
{i}for i:=1 to length(pos) do begin
     if (pos[i]='N') or (pos[i]='S') or (pos[i]='n') or (pos[i]='s')
     then begin
       p1:=i; lt_sym:=pos[i];
     end;
     if (pos[i]='E') or (pos[i]='W')or (pos[i]='e') or (pos[i]='w')
     then begin
       p2:=i; ln_sym:=pos[i];
     end;
{i}end;
//showmessage('p1 p2 '+ inttostr(p1)+'   '+inttostr(p2));

  // if latitude symbol at the first position
  { 1 } if p1 = 1 then
  begin

    // showmessage('string length for position: '+inttostr(length(st)));
    // if (length(st) <> 13) and (length(st) <> 15) then showmessage('New format position');

    lt_st := copy(pos, 2, p2 - 2); // 5 symbols
//showmessage('lt_st '+lt_st);
    p_deg := copy(lt_st, 1, 2);
    p_min := copy(lt_st, 3, length(lt_st));
    lat_deg := strtofloat(p_deg);
    lat_min := strtofloat(p_min);
    if length(p_min)=3 then  lat_min := lat_min / 10; // add decimals
    if length(p_min)=4 then  lat_min := lat_min / 100;
    if length(p_min)=5 then  lat_min := lat_min / 1000;
    lat_min := lat_min / 60; // convert min to deg
    lat := lat_deg + lat_min;
    if (lt_sym='S') or (lt_sym='s') then lat:=-lat;

    RLat := lat;
//showmessage('RLat='+floattostr(RLat));

    ln_st := copy(pos, p2 + 1, length(st) - p2); // 6 symbols
//showmessage('ln_st '+ln_st);
    p_deg := copy(ln_st, 1, 3); // 3 symbols
    p_min := copy(ln_st, 4, length(ln_st));
    lon_deg := strtofloat(p_deg);
    lon_min := strtofloat(p_min);
    if length(p_min)=3 then lon_min := lon_min / 10; // add decimals
    if length(p_min)=4 then lon_min := lon_min / 100;
    if length(p_min)=5 then lon_min := lon_min / 1000;
    lon_min := lon_min / 60; // convert min to deg
    lon := lon_deg + lon_min;
    if (ln_sym='W') or (ln_sym='w') then lon:=-lon;

    RLon := lon;
    // showmessage('RLon='+floattostr(RLon));

    { 1 } end;

  // if not starts from latitude simbol
  { 2 } if p1 <> 1 then
  begin

    if (length(pos) <> 11) or (length(pos) <> 12) then
      showmessage('New format position');

    lt_st := copy(pos, 1, p1 - 1);
//showmessage('lt_st '+lt_st);
    if length(lt_st) = 4 then
    begin // if deg and min
      p_deg := copy(lt_st, 1, 2);
      p_min := copy(lt_st, 3, 2);
    end;

    lat_deg := strtofloat(p_deg);
    lat_min := strtofloat(p_min);
    lat_min := lat_min / 60; // convert min to deg
    lat := lat_deg + lat_min;
    if (lt_sym='S') or (lt_sym='s') then lat:=-lat;

    RLat := lat;
//showmessage('RLat='+floattostr(RLat));

    ln_st := copy(pos, p1 + 1, p2 - p1 - 1);
//showmessage('ln_st '+ln_st);
    if length(ln_st) = 5 then
    begin // if deg and min
      p_deg := copy(ln_st, 1, 3);
      p_min := copy(ln_st, 4, 2);
    end;

    if length(ln_st) = 6 then
    begin // if deg and min
      p_deg := copy(ln_st, 1, 3);
      p_min := copy(ln_st, 4, 3);
    end;

    lon_deg := strtofloat(p_deg);
    lon_min := strtofloat(p_min);
    lon_min := lon_min / 60; // convert min to deg
    lon := lon_deg + lon_min;
     if (ln_sym='W') or (ln_sym='w') then lon:=-lon;

    RLon := lon;
//showmessage('RLon='+floattostr(RLon));

    { 2 } end;
  // convert coordinataes END assume that lat the first lon the second

  // convert time start START
  if length(time_start) <> 14 then
    showmessage('... time wrong format');
  my := strtoint(copy(time_start, 1, 2));
  if my < 20 then
    my := my + 2000
  else
    my := my + 1900;
  mm := strtoint(copy(time_start, 4, 2));
  md := strtoint(copy(time_start, 7, 2));
  mh := strtoint(copy(time_start, 10, 2));
  mmin := strtoint(copy(time_start, 13, 2));
  ms := 0;
  mms := 0;

  mtime_beg := EncodeDateTime(my, mm, md, mh, mmin, ms, mms);

  RStart := mtime_beg;

  // convert time start END

end;

procedure TfrmImport1.GetCoeff(st: string; var cf1, cf2, cf3, cf4, cf5,
  cf6: real);
var
  i, mik: integer;
  s1, s2: char;
  v: array [1 .. 100] of integer;
begin

  // showmessage(st);
  st := trim(st);
  st := st + ' ';
  i := 1;
  v[1] := 1;
  mik := 1;
  for i := 1 to length(st) do
  begin
    s1 := st[i];
    s2 := st[i + 1];
    if (s1 <> ' ') and (s2 = ' ') then
    begin
      mik := mik + 1;
      v[mik] := i;
    end;
    if (s1 = ' ') and (s2 <> ' ') then
    begin
      mik := mik + 1;
      v[mik] := i + 1;
    end;
  end;

  // for i:=1 to 14 do showmessage(inttostr(i)+'   '+inttostr(v[i]));
  // showmessage(copy(st,1,v[2]));
  // showmessage(copy(st,v[3],v[4]-v[3]+1));
  // showmessage(copy(st,v[5],v[6]-v[5]+1));
  // showmessage(copy(st,v[7],v[8]-v[7]+1));
  // showmessage(copy(st,v[9],v[10]-v[9]+1));
  // showmessage(copy(st,v[11],v[12]-v[11]+1));

  cf1 := strtofloat(copy(st, 1, v[2]));

  cf2 := strtofloat(copy(st, v[3], v[4] - v[3] + 1));
  cf3 := strtofloat(copy(st, v[5], v[6] - v[5] + 1));
  cf4 := strtofloat(copy(st, v[7], v[8] - v[7] + 1));
  cf5 := strtofloat(copy(st, v[9], v[10] - v[9] + 1));
  cf6 := strtofloat(copy(st, v[11], v[12] - v[11] + 1));

end;

(* Пример конвертора *)
procedure TfrmImport1.btnLoadClick(Sender: TObject);
Var
  mik, ARN: integer;
  HDRNum, absnum, absnum_max, RRecNum, BotDepth: integer;
  st, CalSheet, fn_hdr: string;
  Region, Place, Project, PI, Archive, RCMType: string;
  sensors: string[6];
  TCh: string[2];
  sym: char;

  RN, RDepth, RInt: integer;
  RLat, RLon: real;
  RStart, RStop: TDateTime;
  ta1, ta2, tb1, tb2, tc, td, ca1, ca2, cb1, cb2, cc, cd, pa1, pa2, pb1, pb2,
    pc, pd: real;
  da1, da2, db1, db2, dc, dd, sa1, sa2, sb1, sb2, sc, sd: real;
  RCF: real;

  dw_start :TDateTime;
begin


  with frmDM.ib1q1 do begin
    Close;
    SQL.Clear;
    SQL.Add(' SELECT MAX(ABSNUM) as ABSNUM_MAX from MOORINGS ');
    Open;
    absnum_max:=frmDM.ib1q1.FieldByName('ABSNUM_MAX').AsInteger;
    Close;
  end;

  with frmDM.ib1q1 do
  begin
    Close;
    SQL.Clear;
    SQL.Add(' INSERT INTO MOORINGS ');
    SQL.Add(' (ABSNUM, M_RCMNUM, M_TIMEBEG, M_TIMEEND, M_LAT, M_LON, M_RCMDEPTH,  ');
    SQL.Add(' M_RCMTIMEINT, M_BOTTOMDEPTH, ');
    SQL.Add(' M_RCMTYPE, M_REGION, M_PLACE, M_PI, M_PROJECTNAME,  ');
    SQL.Add(' M_ARCHIVENAME, M_ARCHIVEREFNUM, M_SOURCEFILENAME, M_CALIBRATIONSHEET, ');
    SQL.Add(' M_ARCHIVENAME, M_ARCHIVEREFNUM, M_SOURCEFILENAME, M_CALIBRATIONSHEET, ');
    SQL.Add(' M_QFLAG, M_SENSORS, M_TEMPCHANNEL) ');
    SQL.Add(' VALUES ');
    SQL.Add(' (:ABSNUM, :M_RCMNUM, :M_TIMEBEG, :M_TIMEEND, :M_LAT, :M_LON, :M_RCMDEPTH,  ');
    SQL.Add(' :M_RCMTIMEINT, :M_BOTTOMDEPTH, ');
    SQL.Add(' :M_RCMTYPE, :M_REGION, :M_PLACE, :M_PI, :M_PROJECTNAME,  ');
    SQL.Add(' :M_ARCHIVENAME, :M_ARCHIVEREFNUM, :M_SOURCEFILENAME, :M_CALIBRATIONSHEET, ');
    SQL.Add(' :M_ARCHIVENAME, :M_ARCHIVEREFNUM, :M_SOURCEFILENAME, :M_CALIBRATIONSHEET, ');
    SQL.Add(' :M_QFLAG, :M_SENSORS, :M_TEMPCHANNEL) ');
    Prepare;
  end;

  with frmDM.ib1q2 do
  begin
    Close;
    SQL.Clear;
    SQL.Add(' INSERT INTO COEFFICIENTS ');
    SQL.Add(' (ABSNUM, TA, TB, TC, TD, CA, CB, CC, CD, PA, PB, PC, PD, ');
    SQL.Add(' DA, DB, DC, DD, SA, SB, SC, SD) ');
    SQL.Add(' VALUES ');
    SQL.Add(' (:ABSNUM, :TA, :TB, :TC, :TD, :CA, :CB, :CC, :CD, :PA, :PB, :PC, :PD, ');
    SQL.Add(' :DA, :DB, :DC, :DD, :SA, :SB, :SC, :SD) ');
    Prepare;
  end;


  Memo1.Clear;
  Memo1.Lines.Add('download file: ' + fn);
  dw_start:=now;
  Memo1.Lines.Add('downloading started at: ' + datetimetostr(now));
  Memo1.Lines.Add('');
  reset(f);

  Create_cdsCATALOG;

  // frmDM.TR1.StartTransaction;

    sym:=' ';
    mik:=0;
{f}while not EOF(f) do begin
    readln(f, st); // 1
    if st<>'' then sym:=st[1] else sym:= ' ';
{#}if sym='#' then begin
    Memo1.Lines.Add('');
    mik := mik + 1;
    HDRNum := strtoint(trim(copy(st, 2, length(st))));
    readln(f, fn_hdr); // 2 path
    readln(f, sensors); // 3 sensors
    readln(f, TCh); // 4 temperature channel
    readln(f, CalSheet); // calibration sheet .pdf

    Memo1.Lines.Add(inttostr(mik) + '  HDRNum=' + inttostr(HDRNum));
    Memo1.Lines.Add(fn_hdr);
    Memo1.Lines.Add(sensors + '  ' + TCh + '  ' + CalSheet + '.pdf');

    read_hdr(fn_hdr, RN, RLat, RLon, RDepth, RInt, RStart, ta1, ta2, tb1,
      tb2, tc, td, ca1, ca2, cb1, cb2, cc, cd, pa1, pa2, pb1, pb2, pc, pd,
      da1, da2, db1, db2, dc, dd, sa1, sa2, sb1, sb2, sc, sd);

    Memo1.Lines.Add('RCM# ' + inttostr(RN) + '  Lat=' + floattostrF(RLat,
          ffFixed, 12, 5) + '  Lon=' + floattostrF(RLon, ffFixed, 12,
          5) + '  Depth=' + floattostr(RDepth));

      Memo1.Lines.Add('temp :' + #9 + floattostr(ta1) + #9 + floattostr(ta2)
          + #9 + floattostr(tb1) + #9 + floattostr(tb2) + #9 + floattostr(tc)
          + #9 + floattostr(td));
      Memo1.Lines.Add('cond :' + #9 + floattostr(ca1) + #9 + floattostr(ca2)
          + #9 + floattostr(cb1) + #9 + floattostr(cb2) + #9 + floattostr(cc)
          + #9 + floattostr(cd));
      Memo1.Lines.Add('pres :' + #9 + floattostr(pa1) + #9 + floattostr(pa2)
          + #9 + floattostr(pb1) + #9 + floattostr(pb2) + #9 + floattostr(pc)
          + #9 + floattostr(pd));
      Memo1.Lines.Add('dir  :' + #9 + floattostr(da1) + #9 + floattostr(da2)
          + #9 + floattostr(db1) + #9 + floattostr(db2) + #9 + floattostr(dc)
          + #9 + floattostr(dd));
      Memo1.Lines.Add('speed:' + #9 + floattostr(sa1) + #9 + floattostr(sa2)
          + #9 + floattostr(sb1) + #9 + floattostr(sb2) + #9 + floattostr(sc)
          + #9 + floattostr(sd));

      RCF := sb1 * RInt * 60 / 42; // rotor counter factor
      Memo1.Lines.Add('RCF  :' + #9 + floattostrF(RCF, ffFixed, 12, 2));

      // GET METADATA FROM CATALOG AND UPDATE TABLE MOORINGS
      ARN := strtoint(trim(copy(fn_hdr, 45, 3))); // Archive Reference Number
      // showmessage('ARN ->'+inttostr(ARN)+'  RDepth ->'+inttostr(RDepth)+'  RStart ->'+datetimetostr(RStart));
      //GetMDFromExcel(ARN, RDepth, RStart, Region, Place, Project, PI, Archive,
      //  RCMType, BotDepth);


    if
    cdsCatalog.Locate('C_ARN;C_RCMStart;C_RCMDepth',VarArrayOf([ARN,RStart,RDepth]),[])=true
    then begin
    Region:=cdsCatalog.FieldByName('C_Region').AsString;
    Place:=cdsCatalog.FieldByName('C_Place').AsString;
    Project:=cdsCatalog.FieldByName('C_Project').AsString;
    PI:=cdsCatalog.FieldByName('C_PI').AsString;
    Archive:=cdsCatalog.FieldByName('C_Archive').AsString;
    RCMType:=cdsCatalog.FieldByName('C_Rigg').AsString;
    BotDepth:=cdsCatalog.FieldByName('C_BottomDepth').AsInteger;
    end
    else begin
    Region:='';
    Place:='';
    Project:='';
    PI:='';
    Archive:='';
    RCMType:='';
    BotDepth:=-9;
    end;

    absnum := mik+absnum_max;

   with frmDM.ib1q1 do begin
    ParamByName('ABSNUM').AsInteger := absnum;
    ParamByName('M_RCMNUM').AsInteger := RN;
    ParamByName('M_TIMEBEG').AsDateTime := RStart;
    ParamByName('M_TIMEEND').AsDateTime := RStart;
    ParamByName('M_LAT').AsFloat := RLat;
    ParamByName('M_LON').AsFloat := RLon;
    ParamByName('M_RCMDEPTH').AsInteger := RDepth;
    ParamByName('M_RCMTIMEINT').AsInteger := RInt;
    ParamByName('M_BOTTOMDEPTH').AsInteger := BotDepth;
    ParamByName('M_SENSORS').AsString := sensors;
    if TCh = 't4' then ParamByName('M_TEMPCHANNEL').AsInteger := 4
                  else ParamByName('M_TEMPCHANNEL').AsInteger := 2;
    ParamByName('M_RCMTYPE').AsString := RCMType;
    ParamByName('M_REGION').AsString := Region;
    ParamByName('M_PLACE').AsString := Place;
    ParamByName('M_PI').AsString := PI;
    ParamByName('M_PROJECTNAME').AsString := Project;
    ParamByName('M_ARCHIVENAME').AsString := Archive;
    ParamByName('M_ARCHIVEREFNUM').AsInteger := ARN;
    ParamByName('M_SOURCEFILENAME').AsString := fn_hdr;
    if CalSheet <> 'UNKNOWN' then ParamByName('M_CALIBRATIONSHEET').AsString := CalSheet + '.pdf'
                             else ParamByName('M_CALIBRATIONSHEET').AsString := '';
    ParamByName('M_QFLAG').AsInteger := 0;
    ExecSQL;
   end;
    frmDM.TR.Commit;

      // UPLOAD COEFFICIENTS
      //!!! ONLY sum A+a is stored not A and separately
      with frmDM.ib1q2 do
      begin
        ParamByName('ABSNUM').AsInteger := absnum;
        ParamByName('TA').AsFloat := ta1+ta2;  //added 23.01.2014
        ParamByName('TB').AsFloat := tb1+tb2;
        ParamByName('TC').AsFloat := tc;
        ParamByName('TD').AsFloat := td;
        ParamByName('CA').AsFloat := ca1+ca2;
        ParamByName('CB').AsFloat := cb1+cb2;
        ParamByName('CC').AsFloat := cc;
        ParamByName('CD').AsFloat := cd;
        ParamByName('PA').AsFloat := pa1+pa2;
        ParamByName('PB').AsFloat := pb1+pb2;
        ParamByName('PC').AsFloat := pc;
        ParamByName('PD').AsFloat := pd;
        ParamByName('DA').AsFloat := da1+da2;
        ParamByName('DB').AsFloat := db1+db2;
        ParamByName('DC').AsFloat := dc;
        ParamByName('DD').AsFloat := dd;
        ParamByName('SA').AsFloat := sa1+sa2;
        ParamByName('SB').AsFloat := sb1+sb2;
        ParamByName('SC').AsFloat := sc;
        ParamByName('SD').AsFloat := sd;
        ExecSQL;
      end;
      frmDM.TR.Commit;

      // UPLOAD ROWDATA
      PopulateROWDATA_Table(fn_hdr, absnum, RStart, RInt, RStop, RRecNum);

      // RECORD INFO
      Memo1.Lines.Add('record start :' + #9 + datetimetostr(RStart));
      Memo1.Lines.Add('record stop  :' + #9 + datetimetostr(RStop));
      Memo1.Lines.Add('Time interval:' + #9 + inttostr(RInt) + ' min');
      Memo1.Lines.Add('Records #    :' + #9 + inttostr(RRecNum));
      Memo1.Lines.Add('Durations    :' + #9 + floattostrF(DaySpan(RStop,
            RStart), ffFixed, 6, 2) + ' days');

      // UPDATE Record STOP TIME AND NUMBER OF RECORDS
    with frmDM.ib1q4 do begin
        Close;
        SQL.Clear;
        SQL.Add(' UPDATE MOORINGS SET M_TIMEEND=:RSTOP, M_REC_ROW=:RRECNUM ');
        SQL.Add(' WHERE ABSNUM=:ABSNUM ');
        ParamByName('ABSNUM').AsInteger := absnum;
        ParamByName('RSTOP').AsDateTime := RStop;
        ParamByName('RRecNum').AsInteger := RRecNum;
        ExecSQL;
    end;
      frmDM.TR.Commit;
      //showmessage('UPDATE absnum='+inttostr(absnum)+'  start='+datetimetostr(RStop))

{#}end;
{f}end;
    closefile(f);

  // frmDM.TR1.Commit;
  Memo1.Lines.Add('');
  Memo1.Lines.Add('... DOWNLOAD COMPLEATED');
  Memo1.Lines.Add('time start : ' + datetimetostr(dw_start));
  Memo1.Lines.Add('time finish: ' + datetimetostr(now));

end;




procedure TfrmImport1.PopulateROWDATA_Table(fn_hdr: string; absnum: integer;
  RStart: TDateTime; RTimeInt: integer; var RStop: TDateTime;
  var RRecNum: integer);
var
  mik: integer;
  rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed: integer;
  fn_dat: string;
  mt: TDateTime;

begin

  with frmDM.ib1q3 do begin
    Close;
    SQL.Clear;
    SQL.Add(' INSERT INTO ROWDATA ');
    SQL.Add(' (ABSNUM, RD_TIME, CH1, CH2, CH3, CH4, CH5, CH6, QFL) ');
    SQL.Add(' VALUES ');
    SQL.Add(' (:ABSNUM, :RD_TIME, :CH1, :CH2, :CH3, :CH4, :CH5, :CH6, :QFL) ');
    Prepare;
  end;

    fn_dat := ChangeFileExt(fn_hdr, '.dat');
    assignfile(f_dat, fn_dat);
    reset(f_dat);

    mik := 0;
    mt := RStart;
{w}while not EOF(f_dat) do begin

    readln(f_dat, rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed);

{7}if rd_ref<>7 then begin  //skip records marked 0007 time not counted

    mik:=mik+1;

    //incMinute does not work in same cases -> overflow
    //if mik > 1 then mt := IncMinute(mt, RTimeInt);
    if mik > 1 then mt := RStart+(RTimeInt*(mik-1))/1440;

   with frmDM.ib1q3 do begin
      ParamByName('ABSNUM').AsInteger := absnum;
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
    closefile(f_dat);

  RStop := mt;
  RRecNum := mik;

end;





procedure TfrmImport1.GetMDFromExcel(ARN, RDepth: integer; RStart: TDateTime;
  var Region, Place, Project, PI, Archive, RCMType: string; BotDepth: integer);
var
  c, mik: integer;
  y, m, d, h, min, s, ms: word;
  xls_id, xls_ARN, RCMDepthCatalog: integer;
  xls_reg, xls_start, xls_stop, xls_PI, xls_pos, xls_Project,
    xls_ArchiveName: string;
  xls_BotDepth, xls_rigg, xls_InstN, xls_InstDepth, xls_Year, xls_Place: string;
  XL: Variant;
  DateIsValid: boolean;
  date_xls, date_hdr: TDateTime;
begin
  // showmessage('ARN ->'+inttostr(ARN)+'  RDepth ->'+inttostr(RDepth)+'  RStart ->'+datetimetostr(RStart));

  Region := '';
  Place := '';
  Project := '';
  PI := '';
  Archive := '';
  RCMType := '';
  BotDepth := -9;

  // showmessage('ARN='+'  '+inttostr(ARN));
  // memo1.Lines.Add('');
  Memo1.Lines.Add('searching of the mooring CATALOG ...');

  XL := CreateOleObject('Excel.Application');
  XL.WorkBooks.Add('c:\data\Currents\GFI\strømdata.xlsx'); // имя файла

  mik := 0; // number of moorings found
  c := 2; // счетчик строк
  { x } repeat
    { 1 } if trim(vartostr(XL.Cells[c, 1])) <> '' then
    begin // если первая строчка не пустая
      xls_id := XL.Cells[c, 1];
      xls_reg := XL.Cells[c, 2];
      xls_ARN := XL.Cells[c, 3];
      xls_start := trim(XL.Cells[c, 4]);
      xls_stop := XL.Cells[c, 5];
      xls_PI := XL.Cells[c, 6];
      xls_pos := XL.Cells[c, 7];
      xls_Project := XL.Cells[c, 8];
      xls_ArchiveName := XL.Cells[c, 9];
      xls_BotDepth := XL.Cells[c, 10];
      xls_rigg := XL.Cells[c, 11];
      xls_InstN := XL.Cells[c, 12];
      xls_InstDepth := XL.Cells[c, 13];
      xls_Year := XL.Cells[c, 14];
      xls_Place := XL.Cells[c, 15];

      if xls_InstDepth <> '' then
        RCMDepthCatalog := strtoint(xls_InstDepth); // RCM depth catalog

      // compare date from .hdr and date from catalog
      date_xls := strtodate('10.03.1960');
      date_xls := strtodate('12.02.1997');
      if (length(xls_start) = 6) or (length(xls_start) = 8) then
        DateIsValid := true
      else
        DateIsValid := false;

      // memo1.lines.add(inttostr(xls_ID)+#9+xls_start);

      { d } if DateIsValid = true then
      begin
        // 1. convert date from catalog to date format
        if length(xls_start) = 6 then
        begin
          y := strtoint(copy(xls_start, 1, 2));
          if y > 30 then
            y := 1900 + y
          else
            y := 2000 + y;
          m := strtoint(copy(xls_start, 3, 2));
          d := strtoint(copy(xls_start, 5, 2));
          date_xls := EncodeDate(y, m, d);
        end;
        if length(xls_start) = 8 then
        begin
          y := strtoint(copy(xls_start, 1, 4));
          m := strtoint(copy(xls_start, 5, 2));
          d := strtoint(copy(xls_start, 7, 2));
          date_xls := EncodeDate(y, m, d);
        end;
        { d } end;

      // 2. extract date from converted datatime - only date should be compared
      DecodeDateTime(RStart, y, m, d, h, min, s, ms);
      date_hdr := EncodeDate(y, m, d);

      // search in CATALOG by archive number   RCM depth   Start date

      { A } if (xls_ARN = ARN) and (RCMDepthCatalog = RDepth) and
        (date_xls = date_hdr) then
      begin

        mik := mik + 1;

        Memo1.Lines.Add('');
        Memo1.Lines.Add('ID         : ' + inttostr(xls_id));
        Memo1.Lines.Add('Region     : ' + xls_reg);
        Memo1.Lines.Add('ArchiveRef : ' + inttostr(xls_ARN));
        Memo1.Lines.Add('Start      : ' + xls_start);
        Memo1.Lines.Add('Stop       : ' + xls_stop);
        Memo1.Lines.Add('PI         : ' + xls_PI);
        Memo1.Lines.Add('pos        : ' + xls_pos);
        Memo1.Lines.Add('Project    : ' + xls_Project);
        Memo1.Lines.Add('ArchiveName: ' + xls_ArchiveName);
        Memo1.Lines.Add('BotDepth   : ' + xls_BotDepth);
        Memo1.Lines.Add('rigg       : ' + xls_rigg);
        Memo1.Lines.Add('InstN      : ' + xls_InstN);
        Memo1.Lines.Add('InstDepth  : ' + xls_InstDepth);
        Memo1.Lines.Add('Year       : ' + xls_Year);
        Memo1.Lines.Add('Place      : ' + xls_Place);

        Region := xls_reg;
        Place := xls_Place;
        Project := xls_Project;
        PI := xls_PI;
        Archive := xls_ArchiveName;
        RCMType := xls_rigg;
        if xls_BotDepth <> '' then
          BotDepth := strtoint(xls_BotDepth)
        else
          BotDepth := -9;

        { A } end;

      inc(c); // берем следующую строчку
      { 1 } end;
    { x } until trim(vartostr(XL.Cells[c, 1])) = '';

  XL.Quit; // закрываем Эксель

  Memo1.Lines.Add('Number of moorings found in catalog (ARN, start, depth): '+inttostr(mik));

end;

end.
