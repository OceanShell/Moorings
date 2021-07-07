unit PlotConvertedData;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DBCtrls, ExtCtrls, DBGrids, TASeries, TAGraph,
  TATools, DateUtils;

type

  { TfrmPlotConvertedData }

  TfrmPlotConvertedData = class(TForm)
    btnCDSCommit: TBitBtn;
    Chart1: TChart;
    ChartToolset1: TChartToolset;
    Series1: TLineSeries;
    chkActivateQFL: TCheckBox;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
  //  DBChart1: TDBChart;
  //  Series1: TLineSeries;
  //  Series2: TPointSeries;
    RadioGroup1: TRadioGroup;
    Label3: TLabel;

    procedure Chart1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure chkActivateQFLChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCDSCommitClick(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure chkActivateQFLMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DBGridEh1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  //  procedure DBGridEh1CellClick(Column: TColumnEh);
    procedure DBChart1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DBGridEh1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    procedure GetStatistics(fld:integer);
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
begin

  // frmDM.TR1.StartTransaction;

  SA := frmDM.Q.FieldByName('ABSNUM').AsInteger;
  sensors := frmDM.Q.FieldByName('M_SENSORS').AsString;
  mc := frmDM.Q.FieldByName('M_DIRCORRECTION').AsFloat;
  label5.Caption:='magnetic correction='+floattostr(mc);

  frmPlotConvertedData.Caption := frmPlotConvertedData.Caption + '  ID=' +
    inttostr(SA) + '  RCM#=' + inttostr(frmDM.Q.FieldByName('M_RCMNUM')
      .AsInteger) + '  sensors:' + sensors;

   //mooring duration row data stop-start
   RStart:=frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;
   RStop :=frmDM.Q.FieldByName('M_TimeEnd').AsDateTime;
   label5.Caption:='the total duration of mooring [stop - start]='+
   floattostrF(DaySpan(RStop,RStart),ffFixed, 6, 2)+ ' days';


   {DbChart1.Title.Caption:='RCM depth='
     +inttostr(frmDM.Q.FieldByName('M_RCMDepth').AsInteger)+' m'; }

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
    if chkActivateQFL.Checked=true then
      sql.Add(' AND C_CFL<>9');
    sql.Add(' ORDER BY C_TIME ');
    ParamByName('ID').Value := SA;
    Open;
    Last;
    First;
  end;

 //  showmessage('here3');

  DBGrid1.ReadOnly:=chkActivateQFL.Checked;


   //compute mean direction
     mik:=0;
     mean:=0;

     series1.Clear;
     frmdm.CDQuery.DisableControls;
     frmDM.CDQuery.First;
{w}while not frmDM.CDQuery.Eof do begin
     if frmDM.CDQuery.FieldByName('C_CFL').AsInteger <> 9 then begin
      mik:=mik+1;
      mean:=mean+frmDM.CDQuery.FieldByName('C_ANGLE').AsFloat;
     end;

     series1.AddXY(frmDM.CDQuery.FieldValues['C_Time'],
                   frmDM.CDQuery.Fields.Fields[RadioGroup1.ItemIndex + 2].Value);

     frmDM.CDQuery.Next;
{w}end;
     frmDM.CDQuery.First;
     frmdm.CDQuery.EnableControls;

     if mik<>0 then mean:=mean/mik;
                    mean_corr:=mean+mc;  //corrected mean

     //showmessage('rec#='+inttostr(mik)+'  mean='+floattostr(mean));

     Label4.Caption:='mean='+floattostrF(mean,ffFixed,10,3)
                     +' ('+floattostrF(mean_corr,ffFixed,10,3)+')';


 { for k := 0 to DBGridEh1.Columns.Count - 1 do
    DBGridEh1.Columns[k].Title.TitleButton := true;   }


  //   Series1.CheckDataSource;
 //    Application.ProcessMessages; }
end;


procedure TfrmPlotConvertedData.chkActivateQFLChange(Sender: TObject);
begin
  ChangeID;
end;

procedure TfrmPlotConvertedData.Chart1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin

end;


{
procedure TfrmPlotConvertedData.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  frmDM.cdsCD.Active := false;
  frmDM.TR1.Active := false;
end;
}




procedure TfrmPlotConvertedData.btnCDSCommitClick(Sender: TObject);
begin
  frmDM.cdsCD.ApplyUpdates(0);
end;

procedure TfrmPlotConvertedData.RadioGroup1Click(Sender: TObject);
begin
  ChangeID;
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

     frmDM.cdsCD.Filtered := false;
     frmDM.cdsCD.First;
     frmdm.CDSCD.DisableControls;
{w}while not frmDM.cdsCD.Eof do begin

     if frmDM.cdsCD.FieldByName(QFLName).AsInteger = 9 then QFL9:=QFL9+1

     else begin
      mik:=mik+1;
      mean:=mean+frmDM.cdsCD.FieldByName(fldName).AsFloat;
     end;

     frmDM.cdsCD.Next;
{w}end;
     frmdm.cdsCD.EnableControls;

     if mik<>0 then mean:=mean/mik;
     //showmessage(QFLName+'  mik='+inttostr(mik)+'  mean='+floattostr(mean));

     Label1.Caption := 'Number of ' + copy(QFLName,3,3) + '=9 is ' + inttostr(QFL9);
     chkActivateQFL.Checked := true;

     Label4.Caption:='mean='+floattostrF(mean,ffFixed,10,3);

{D}  if fld=0 then begin
       mean_corr:=mean+mc;
       Label4.Caption:='mean='+floattostrF(mean,ffFixed,10,3)
                       +' ('+floattostrF(mean_corr,ffFixed,10,3)+')';
{D}  end;

     sensors := frmDM.Q.FieldByName('M_SENSORS').AsString;

     //convert pressure to bar / meter
{P}if (fld=4) and (sensors[4]='P') then begin
     mean_b:=mean*0.98;             // kg/cm2 -> bar
     mean_m:=mean_b*10.19977334;    // bar -> meter

     Label4.Caption:='mean='
     +floattostrF(mean,ffFixed,10,3)  +' kg/cm2'+'   '
     +floattostrF(mean_b,ffFixed,10,3)+' bar'   +'   '
     +floattostrF(mean_m,ffFixed,10,3)+' m';
{P}end;

{P}if (fld=4) and (sensors[4]='T') then
   Label4.Caption:='mean='+floattostrF(mean,ffFixed,10,3)  +' deg C';

{O}if (fld=6) then
   Label4.Caption:='mean='+floattostrF(mean,ffFixed,10,3)  +' ml/l';


     frmDM.cdsCD.Filter := QFLName+'=0'; //showmessage(frmDM.cdsCD.Filter);
     frmDM.cdsCD.Filtered := true;
end;



procedure TfrmPlotConvertedData.chkActivateQFLMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  fldn: Integer;
begin

  fldn := RadioGroup1.ItemIndex;
  // showmessage('variable index='+inttostr(fldn));

  // Filter records with QFL=9
  if chkActivateQFL.Checked = true then
  begin
    case fldn of
      0, 1: frmDM.cdsCD.Filter := 'C_CFL=0';
      2:    frmDM.cdsCD.Filter := 'C_TFL=0';
      3:    frmDM.cdsCD.Filter := 'C_SFL=0';
      4:    frmDM.cdsCD.Filter := 'C_PFL=0';
      5:    frmDM.cdsCD.Filter := 'C_UFL=0';
      6:    frmDM.cdsCD.Filter := 'C_OFL=0';
    end; { case }
    frmDM.cdsCD.Filtered := true;
  end
  else
    frmDM.cdsCD.Filtered := false;
  //  Series1.CheckDataSource;
end;




procedure TfrmPlotConvertedData.DBGridEh1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  {Series2.Clear;
  if (frmDM.cdsCD.FieldValues['C_Time'] <> null) and
    (frmDM.cdsCD.Fields.Fields[RadioGroup1.ItemIndex + 2].Value <> null) then
    Series2.AddXY(frmDM.cdsCD.FieldValues['C_Time'],
      frmDM.cdsCD.Fields.Fields[RadioGroup1.ItemIndex + 2].Value);
      }
end;


{
procedure TfrmPlotConvertedData.DBGridEh1CellClick(Column: TColumnEh);
begin
  Series2.Clear;
  if (frmDM.cdsCD.FieldValues['C_Time'] <> null) and
    (frmDM.cdsCD.Fields.Fields[RadioGroup1.ItemIndex + 2].Value <> null) then
    Series2.AddXY(frmDM.cdsCD.FieldValues['C_Time'],
      frmDM.cdsCD.Fields.Fields[RadioGroup1.ItemIndex + 2].Value);
end;

}

// draw point on mouse click in DBCHART
procedure TfrmPlotConvertedData.DBChart1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Num_Clicked: int64;
  LVar: array [0 .. 1] of Variant;
begin
  {Series2.Clear;
  { w } with Series1 do
  begin
    Num_Clicked := Clicked(X, Y);
    { c } if Num_Clicked <> -1 then
    begin
      LVar[0] := YValues[Num_Clicked];
      LVar[1] := XValues[Num_Clicked];
      DBGridEh1.DataSource.DataSet.Locate('C_Time', LVar[1], []);
      DBChart1.Series[1].AddXY(XValues[Num_Clicked], YValues[Num_Clicked]);
      { c } end;
    { w } end;   }
end;

procedure TfrmPlotConvertedData.DBGridEh1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
uf: string; //update field
begin

{r}if Button=mbRight then begin
   //  uf:=DBGridEh1.SelectedField.FieldName;

{c}if MessageDlg('Set QFL on variable ' + uf +'?',
     mtConfirmation,
     [mbyes, mbno], 0, mbYes)= mrYes then begin

     //1. select flag from frmSEtFlag
     frmSetFlag:= TfrmSetFlag.Create(Self);
   try
     if frmSetFlag.ShowModal = mrOk then
   finally
     frmSetFlag.Free;
     frmSetFlag := nil;
   end;
     showmessage('QFL='+inttostr(QFL));

     //2. update DB and reopen cds
   with frmdm.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' UPDATE CURRENTS SET ' + uf + '=:QFL  ');
     SQL.Add(' WHERE ');
     SQL.Add(' ABSNUM=:ID ');
     ParamByName('ID').AsFloat:=SA;
     ParamByName('QFL').AsInteger:=QFL;
     ExecSQL;
   end;
     showmessage(frmdm.ib1q1.sql.Text);

     frmdm.TR.Commit;
     frmDM.cdsCD.Active:=false;
     frmDM.cdsCD.Open;

{c}end
   else
     exit;

{r}end;

end;

end.
