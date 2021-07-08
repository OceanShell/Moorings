unit PlotConvertedData;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DBCtrls, ExtCtrls, DBGrids, ComCtrls, TASeries,
  TAGraph, TATools, DateUtils, StrUtils, TACustomSeries, TAGeometry,
  TAChartUtils, TAIntervalSources, Grids, Menus, Types;

type

  { TfrmPlotConvertedData }

  TfrmPlotConvertedData = class(TForm)
    btnCDSCommit: TBitBtn;
    Chart1: TChart;
    SetFlagEntireColumn: TMenuItem;
    PM: TPopupMenu;
    Series2: TLineSeries;
    ChartToolset1: TChartToolset;
    ZMWT: TZoomMouseWheelTool;
    ZDT: TZoomDragTool;
    DPHT: TDataPointHintTool;
    DPCT: TDataPointClickTool;
    DTI: TDateTimeIntervalChartSource;
    RadioGroup1: TRadioGroup;
    Series1: TLineSeries;
    chkActivateQFL: TCheckBox;
    DBGrid1: TDBGrid;
    Panel1: TPanel;
    Panel2: TPanel;
    Label3: TLabel;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;

    procedure Chart1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure chkActivateQFLChange(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure DBGrid1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DBGrid1PrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
    procedure DPCTPointClick(ATool: TChartTool; APoint: TPoint);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCDSCommitClick(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure DBChart1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SetFlagEntireColumnClick(Sender: TObject);
  private
    { Private declarations }
    procedure GetStatistics(fld:integer);
    procedure GridNavigation;
  public
    { Public declarations }
    procedure ChangeID;
  end;

var
  frmPlotConvertedData: TfrmPlotConvertedData;
  SA: Integer;
  QFL: integer;
  mc: real;  //magnetic correction

implementation

{$R *.lfm}

uses DM, SetFlag;

procedure TfrmPlotConvertedData.FormShow(Sender: TObject);
begin
 ChangeID;
end;

procedure TfrmPlotConvertedData.ChangeID;
var
  k, mik, mik_QFL: Integer;
  mean,mean_corr: real;
  sensors: string[9];
  RStart,RStop: TDateTime;
  x:TDateTime;
  y:Real;
begin

  // frmDM.TR1.StartTransaction;

  SA := frmDM.Q.FieldByName('ABSNUM').AsInteger;
  sensors := frmDM.Q.FieldByName('M_SENSORS').AsString;
  mc := frmDM.Q.FieldByName('M_DIRCORRECTION').AsFloat;

  //label5.Caption:='magnetic correction='+floattostr(mc);

  Caption:='Converted data: ID=' +inttostr(SA) +
           '  RCM#=' + inttostr(frmDM.Q.FieldByName('M_RCMNUM').AsInteger) +
           '  sensors:' + sensors;

   //mooring duration row data stop-start
   RStart:=frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;
   RStop :=frmDM.Q.FieldByName('M_TimeEnd').AsDateTime;

   StatusBar1.Panels[0].Text:=
   'Total duration of mooring [stop - start]: '+
   floattostrF(DaySpan(RStop,RStart),ffFixed, 6, 2)+' days';

  // rename RadioGroup and DbEhLib columns according to variables composition
  // CH2 temp or press
  if sensors[2] = '0' then
    RadioGroup1.Items.Strings[2] := '-----';
    TRadioButton(RadioGroup1.Controls[2]).Enabled := False;

  if sensors[2] = 'T' then
  begin
    RadioGroup1.Items.Strings[2] := 'Temperature';
    RadioGroup1.Items.Strings[8] := 'TFL';
    TRadioButton(RadioGroup1.Controls[2]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[8]).Enabled := True;

    DBGrid1.Columns[4].Title.Caption := 'Temp';
    DBGrid1.Columns[10].Title.Caption := 'TFL';
  end;

  if sensors[2] = 'P' then
  begin
    RadioGroup1.Items.Strings[2] := 'Pressure';
    RadioGroup1.Items.Strings[8] := 'PFL';
    TRadioButton(RadioGroup1.Controls[2]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[8]).Enabled := True;

    DBGrid1.Columns[4].Title.Caption := 'Press';
    DBGrid1.Columns[10].Title.Caption := 'PFL';
  end;
  // --------------------------------------------------------------
  // CH3 salt
  if sensors[3] = '0' then
  begin
    RadioGroup1.Items.Strings[3] := '-----';
    RadioGroup1.Items.Strings[9] := '-----';
    TRadioButton(RadioGroup1.Controls[3]).Enabled := False;
    TRadioButton(RadioGroup1.Controls[9]).Enabled := False;

    DBGrid1.Columns[5].Title.Caption := '----';
    DBGrid1.Columns[11].Title.Caption := '----';
  end
  else
  begin
    RadioGroup1.Items.Strings[3] := 'Salinity';
    RadioGroup1.Items.Strings[9] := 'SFL';
    TRadioButton(RadioGroup1.Controls[3]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[9]).Enabled := True;

    DBGrid1.Columns[5].Title.Caption := 'Salt';
    DBGrid1.Columns[11].Title.Caption := 'SFL';
  end;
  // --------------------------------------------------------------
  // CH4 press or temp
  if sensors[4] = '0' then
  begin
    RadioGroup1.Items.Strings[4] := '-----';
    RadioGroup1.Items.Strings[10] := '-----';
    TRadioButton(RadioGroup1.Controls[4]).Enabled := False;
    TRadioButton(RadioGroup1.Controls[10]).Enabled := False;
    DBGrid1.Columns[6].Title.Caption := '----';
    DBGrid1.Columns[12].Title.Caption := '----';
  end;

  if sensors[4] = 'P' then
  begin
    RadioGroup1.Items.Strings[4] := 'Pressure';
    RadioGroup1.Items.Strings[10] := 'PFL';
    TRadioButton(RadioGroup1.Controls[4]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[10]).Enabled := True;

    DBGrid1.Columns[6].Title.Caption := 'Press';
    DBGrid1.Columns[12].Title.Caption := 'PFL';
  end;

  if sensors[4] = 'T' then
  begin
    RadioGroup1.Items.Strings[4] := 'Temperature';
    RadioGroup1.Items.Strings[10] := 'TFL';
    TRadioButton(RadioGroup1.Controls[4]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[10]).Enabled := True;

    DBGrid1.Columns[6].Title.Caption := 'Temp';
    DBGrid1.Columns[12].Title.Caption := 'TFL';
  end;
  // --------------------------------------------------------------
  // CH5 curent dir  ALLWAYS EXIST
  if sensors[5] = '0' then
  begin
    RadioGroup1.Items.Strings[0] := '-----';
    RadioGroup1.Items.Strings[7] := '-----';
    TRadioButton(RadioGroup1.Controls[0]).Enabled := False;
    TRadioButton(RadioGroup1.Controls[7]).Enabled := False;
  end
  else
  begin
    RadioGroup1.Items.Strings[0] := 'Direction';
    RadioGroup1.Items.Strings[7] := 'CFL';
    TRadioButton(RadioGroup1.Controls[0]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[7]).Enabled := True;

    DBGrid1.Columns[2].Title.Caption := 'Dir';
    DBGrid1.Columns[9].Title.Caption := 'CFL';
  end;
  // --------------------------------------------------------------
  // CH6 current speed should ALLWAYS EXIST
  if sensors[6] = '0' then
  begin
    RadioGroup1.Items.Strings[1] := '-----';
    RadioGroup1.Items.Strings[7] := '-----';
    TRadioButton(RadioGroup1.Controls[1]).Enabled := False;
    TRadioButton(RadioGroup1.Controls[7]).Enabled := False;
  end
  else
  begin
    RadioGroup1.Items.Strings[1] := 'Speed';
    RadioGroup1.Items.Strings[7] := 'CFL';
    TRadioButton(RadioGroup1.Controls[1]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[7]).Enabled := True;

    DBGrid1.Columns[3].Title.Caption := 'Speed';
    DBGrid1.Columns[9].Title.Caption := 'CFL';
  end;
  // --------------------------------------------------------------
  // CH7 turbidity
  if sensors[7] = '0' then
  begin
    RadioGroup1.Items.Strings[5] := '-----';
    RadioGroup1.Items.Strings[11] := '-----';
    TRadioButton(RadioGroup1.Controls[5]).Enabled := False;
    TRadioButton(RadioGroup1.Controls[11]).Enabled := False;

    DBGrid1.Columns[7].Title.Caption := '----';
    DBGrid1.Columns[13].Title.Caption := '----';
  end
  else
  begin
    RadioGroup1.Items.Strings[5] := 'Turbidity';
    RadioGroup1.Items.Strings[11] := 'UFL';
    TRadioButton(RadioGroup1.Controls[5]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[11]).Enabled := True;

    DBGrid1.Columns[7].Title.Caption := 'Turb';
    DBGrid1.Columns[13].Title.Caption := 'UFL';
  end;
  // --------------------------------------------------------------
  // CH8 oxygen
  if sensors[8] = '0' then
  begin
    RadioGroup1.Items.Strings[6] := '-----';
    RadioGroup1.Items.Strings[12] := '-----';
    TRadioButton(RadioGroup1.Controls[6]).Enabled := False;
    TRadioButton(RadioGroup1.Controls[12]).Enabled := False;

    DBGrid1.Columns[8].Title.Caption := '----';
    DBGrid1.Columns[14].Title.Caption := '----';
  end
  else
  begin
    RadioGroup1.Items.Strings[6] := 'Oxygen';
    RadioGroup1.Items.Strings[12] := 'OFL';
    TRadioButton(RadioGroup1.Controls[6]).Enabled := True;
    TRadioButton(RadioGroup1.Controls[12]).Enabled := True;

    DBGrid1.Columns[8].Title.Caption := 'Oxyg';
    DBGrid1.Columns[14].Title.Caption := 'OFL';
  end;
  // --------------------------------------------------------------

//  showmessage('here');

  // CD - Converted data
  with frmDM.CDquery do begin
    Close;
    sql.Clear;
    sql.Add(' SELECT * FROM CURRENTS  ');
    sql.Add(' WHERE ');
    sql.Add(' ABSNUM=:ID ');
    sql.Add(' ORDER BY C_TIME ');
    ParamByName('ID').Value := SA;
    Open;
  end;

  GetStatistics(RadioGroup1.ItemIndex);
end;


procedure TfrmPlotConvertedData.chkActivateQFLChange(Sender: TObject);
Var
  fldn: Integer;
begin

  fldn := RadioGroup1.ItemIndex;
  // showmessage('variable index='+inttostr(fldn));

  // Filter records with QFL=9
  if chkActivateQFL.Checked = false then begin
    case fldn of
      0, 1: frmdm.CDQuery.Filter := 'C_CFL=0';
      2:    frmdm.CDQuery.Filter := 'C_TFL=0';
      3:    frmdm.CDQuery.Filter := 'C_SFL=0';
      4:    frmdm.CDQuery.Filter := 'C_PFL=0';
      5:    frmdm.CDQuery.Filter := 'C_UFL=0';
      6:    frmdm.CDQuery.Filter := 'C_OFL=0';
    end; { case }
    frmdm.CDQuery.Filtered := true;
   // showmessage(frmdm.CDQuery.Filter);
  end else
    frmdm.CDQuery.Filtered := false;

  DBGrid1.ReadOnly:=NOT chkActivateQFL.Checked;

 GetStatistics(fldn);
end;

procedure TfrmPlotConvertedData.GridNavigation;
begin
Series2.Clear;
if (frmDM.CDQuery.FieldValues['C_Time'] <> null) and
  (frmDM.CDQuery.Fields.Fields[RadioGroup1.ItemIndex + 2].Value <> null) then
  Series2.AddXY(frmDM.CDQuery.FieldByName('C_Time').AsDateTime,
    frmDM.CDQuery.Fields.Fields[RadioGroup1.ItemIndex + 2].Value);
end;

procedure TfrmPlotConvertedData.DBGrid1CellClick(Column: TColumn);
begin
  GridNavigation;
end;

procedure TfrmPlotConvertedData.DBGrid1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key=VK_UP) or (key=VK_DOWN) then GridNavigation;
end;

procedure TfrmPlotConvertedData.DBGrid1PrepareCanvas(sender: TObject;
  DataCol: Integer; Column: TColumn; AState: TGridDrawState);
begin
 if (column.FieldName='ABSNUM') or (column.FieldName='C_TIME') then begin
    TDBGrid(sender).Canvas.Brush.Color := clBtnFace;
 end;

 if (gdRowHighlight in AState) then begin
    TDBGrid(Sender).Canvas.Brush.Color := clNavy;
    TDBGrid(Sender).Canvas.Font.Color  := clYellow;
    TDBGrid(Sender).Canvas.Font.Style  := [fsBold];
 end;
end;

procedure TfrmPlotConvertedData.DPCTPointClick(ATool: TChartTool; APoint: TPoint
  );
Var
 tool: TDataPointClicktool;
 series: TLineSeries;
begin
  tool := ATool as TDataPointClickTool;
  if tool.Series is TLineSeries then begin
    series := TLineSeries(tool.Series);

    if (tool.PointIndex<>-1) then begin
        frmdm.CDQuery.Locate('C_TIME', series.XValue[tool.PointIndex], []);

        Series2.Clear;
        Series2.AddXY(frmDM.CDQuery.FieldValues['C_Time'],
          frmDM.CDQuery.Fields.Fields[RadioGroup1.ItemIndex + 2].Value);
    end;
  end;
end;

procedure TfrmPlotConvertedData.FormResize(Sender: TObject);
Var
  k:integer;
begin
  for k:=2 to DBGrid1.Columns.Count-1 do begin
    DBGrid1.Columns[k].Width:=round((DBGrid1.Width-290)/13);
  end;
end;

procedure TfrmPlotConvertedData.Chart1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
 params: TNearestPointParams;
 res1: TNearestPointResults;
 found1: Boolean;
 x1,y1: String;
begin
 params.FDistFunc := @PointDistX;
 params.FPoint := Point(X, Y);
 params.FRadius := 8;
 params.FTargets := [nptPoint];

 found1 := Series1.GetNearestPoint(params, res1);
 x1 := DateTimeToStr(res1.FValue.X);//Chart1.XImageToGraph(X);
 y1 := VarToStr(res1.FValue.Y);

 Chart1.Title.Text.Clear;
 Chart1.Title.Text.Add('Date: '+x1+'; '+
   Radiogroup1.Items.Strings[RadioGroup1.ItemIndex]+': '+y1);

end;


procedure TfrmPlotConvertedData.btnCDSCommitClick(Sender: TObject);
begin
  frmDM.CDQuery.ApplyUpdates(0);
  frmdm.TR.CommitRetaining;
end;

procedure TfrmPlotConvertedData.RadioGroup1Click(Sender: TObject);
begin
  ChangeID;
end;

procedure TfrmPlotConvertedData.DBChart1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

end;

procedure TfrmPlotConvertedData.GetStatistics(fld:integer);
var
QFL9,mik: integer;
mean,mean_corr,mean_b,mean_m: real;
QFlName,fldName: string;
sensors: string[9];
begin

    case fld of
      0:    begin QFlName:='C_CFL'; fldName:='C_ANGLE'; end;
      1:    begin QFlName:='C_CFL'; fldName:='C_SPEED'; end;
      2:    begin QFlName:='C_TFL'; fldName:='C_TEMP';  end;
      3:    begin QFlName:='C_SFL'; fldName:='C_SALT';  end;
      4:    begin QFlName:='C_PFL'; fldName:='C_PRESS'; end;
      5:    begin QFlName:='C_UFL'; fldName:='C_TURB';  end;
      6:    begin QFlName:='C_OFL'; fldName:='C_OXYG';  end;
    end; { case }


     QFL9:=0;
     mik:=0;
     mean:=0;

   Series1.Clear;
   Series2.Clear;
   frmdm.CDQuery.DisableControls;
   frmDM.CDQuery.First;
   while not frmDM.CDQuery.Eof do begin

     if frmDM.CDQuery.FieldByName(QFLName).AsInteger = 9 then QFL9:=QFL9+1

     else begin
      mik:=mik+1;
      mean:=mean+frmDM.CDQuery.FieldByName(fldName).AsFloat;
     end;

        series1.AddXY(frmDM.CDQuery.FieldValues['C_TIME'],
                   frmDM.CDQuery.Fields.Fields[RadioGroup1.ItemIndex + 2].Value);


     frmDM.CDQuery.Next;
   end;
   frmDM.CDQuery.First;
   frmdm.CDQuery.EnableControls;

     if mik<>0 then mean:=mean/mik;

     StatusBar1.Panels[1].Text:='mean='+floattostrF(mean,ffFixed,10,3);

{D}  if fld=0 then begin
       mean_corr:=mean+mc;
       StatusBar1.Panels[1].Text:='mean='+floattostrF(mean,ffFixed,10,3)
                       +' ('+floattostrF(mean_corr,ffFixed,10,3)+')';
{D}  end;

     sensors := frmDM.Q.FieldByName('M_SENSORS').AsString;

     //convert pressure to bar / meter
{P}if (fld=4) and (sensors[4]='P') then begin
     mean_b:=mean*0.98;             // kg/cm2 -> bar
     mean_m:=mean_b*10.19977334;    // bar -> meter

     StatusBar1.Panels[1].Text:='mean='
     +floattostrF(mean,ffFixed,10,3)  +' kg/cm2'+'   '
     +floattostrF(mean_b,ffFixed,10,3)+' bar'   +'   '
     +floattostrF(mean_m,ffFixed,10,3)+' m';
{P}end;

{P}if (fld=4) and (sensors[4]='T') then
    StatusBar1.Panels[1].Text:='mean='+floattostrF(mean,ffFixed,10,3)  +' deg C';

{O}if (fld=6) then
   StatusBar1.Panels[1].Text:='mean='+floattostrF(mean,ffFixed,10,3)  +' ml/l';
end;


procedure TfrmPlotConvertedData.SetFlagEntireColumnClick(Sender: TObject);
var
uf: string; //update field
begin

 uf:=DBGrid1.SelectedField.FieldName;

 if MessageDlg('Set QFL on ' + uf +'?', mtConfirmation, [mbyes, mbno], 0)= mrNo then exit;

     //1. select flag from frmSEtFlag
  frmSetFlag:= TfrmSetFlag.Create(Self);
   try
     if frmSetFlag.ShowModal = mrOk then
   finally
     frmSetFlag.Free;
     frmSetFlag := nil;
   end;

   if QFL<0 then exit;

   showmessage('QFL='+inttostr(QFL));

   frmdm.CDQuery.DisableControls;
   frmDM.CDQuery.First;
   while not frmDM.CDQuery.Eof do begin
     frmDM.CDQuery.Edit;
     frmDM.CDQuery.FieldByName(uf).Value:=QFL;
     frmDM.CDQuery.Post;
     frmDM.CDQuery.Next;
   end;
   frmDM.CDQuery.First;
   frmdm.CDQuery.EnableControls;

   frmDM.CDQuery.ApplyUpdates(0);

end;

end.
