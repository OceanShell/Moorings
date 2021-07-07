unit PlotRowData;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, {EhLibCDS, GridsEh, DBGridEh, DBGridEhGrouping,} StdCtrls, Buttons,
  ExtCtrls, DBCtrls, {TeEngine, Series, TeeProcs, Chart, DBChart, ToolCtrlsEh,
  DBGridEhToolCtrls, DynVarsEh, DBAxisGridsEh,} MaskEdit, Menus, TASeries;

type
  TfrmPlotRowData = class(TForm)
   // DBGridEh1: TDBGridEh;
    DBNavigator1: TDBNavigator;
    btnCDSCommit: TBitBtn;
  //  DBChart1: TDBChart;
    RadioGroup1: TRadioGroup;
   // Series2: TPointSeries;
   // Series1: TLineSeries;
    CheckBox1: TCheckBox;
    Label1: TLabel;
    Panel1: TPanel;
    Label2: TLabel;
    DBEdit2: TDBEdit;
    DBEdit3: TDBEdit;
    DBEdit1: TDBEdit;
    gbTemp: TGroupBox;
    DBEdit4: TDBEdit;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    GroupBox2: TGroupBox;
    gbCond: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    DBEdit5: TDBEdit;
    DBEdit6: TDBEdit;
    DBEdit7: TDBEdit;
    DBEdit8: TDBEdit;
    gbPress: TGroupBox;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    DBEdit9: TDBEdit;
    DBEdit10: TDBEdit;
    DBEdit11: TDBEdit;
    DBEdit12: TDBEdit;
    gbDir: TGroupBox;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    DBEdit13: TDBEdit;
    DBEdit14: TDBEdit;
    DBEdit15: TDBEdit;
    DBEdit16: TDBEdit;
    gbSpeed: TGroupBox;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    DBEdit17: TDBEdit;
    DBEdit18: TDBEdit;
    DBEdit19: TDBEdit;
    DBEdit20: TDBEdit;
    gbTurb: TGroupBox;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    DBEdit21: TDBEdit;
    DBEdit22: TDBEdit;
    DBEdit23: TDBEdit;
    DBEdit24: TDBEdit;
    gbOxyg: TGroupBox;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    DBEdit25: TDBEdit;
    DBEdit26: TDBEdit;
    DBEdit27: TDBEdit;
    DBEdit28: TDBEdit;
    gbXXX: TGroupBox;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    DBEdit29: TDBEdit;
    DBEdit30: TDBEdit;
    DBEdit31: TDBEdit;
    DBEdit32: TDBEdit;
    btnApplyUpdates_cdsCF: TBitBtn;
    PopupMenu1: TPopupMenu;
    SetAsStartDate1: TMenuItem;
    SetAsStopDate1: TMenuItem;
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Label3: TLabel;
    Label36: TLabel;
    CheckBox2: TCheckBox;
    btnSetQFL_9: TBitBtn;
    btnSetQFL_0: TBitBtn;
    Label37: TLabel;
    CheckBox3: TCheckBox;
    procedure FormShow(Sender: TObject);
 //   procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCDSCommitClick(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure DBGridEh1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  //  procedure DBGridEh1CellClick(Column: TColumnEh);
    procedure DBChart1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CheckBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnApplyUpdates_cdsCFClick(Sender: TObject);
    procedure SetAsStartDate1Click(Sender: TObject);
    procedure SetAsStopDate1Click(Sender: TObject);
    procedure btnSetQFL_9Click(Sender: TObject);
    procedure btnSetQFL_0Click(Sender: TObject);
    procedure CheckBox3MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    procedure UpdateForm;
  public
    { Public declarations }
  end;

var
  frmPlotRowData: TfrmPlotRowData;
  SA :integer;

implementation

{$R *.lfm}

uses DM, SetAsStartDate, SetAsStopDate;


procedure TfrmPlotRowData.FormShow(Sender: TObject);
var
k: integer;
begin
     SA     :=frmDM.Q.FieldByName('ABSNUM').AsInteger;
     UpdateForm;
  //   for k:=0 to DBGridEh1.Columns.Count-1 do DBGridEh1.Columns[k].Title.TitleButton:=true;

     //preset coefficients  не работает
     //DBEdit13.Text:='1.5';        //DA
     //DBEdit14.Text:='0.349';      //DB
     //DBEdit17.Text:='1.5';        //SA
     //DBEdit3.Text:='-1.344e-06';  //TC
     //DBEdit4.Text:='1.937e-09';   //TD
end;



procedure TfrmPlotRowData.UpdateForm;
var
mik_QFL :integer;
sensors: string[9];
start,stop: TDateTime;
begin
    start  :=frmDM.Q.FieldByName('M_TimeBeg').AsDateTime;
    stop   :=frmDM.Q.FieldByName('M_TimeEnd').AsDateTime;
    sensors:=frmDM.Q.FieldByName('M_Sensors').AsString;

    Edit1.Text:=datetimetostr(start);
    Edit2.Text:=datetimetostr(stop);

    frmPlotRowData.Caption:=frmPlotRowData.Caption+'  absnum='+inttostr(SA)
    +' RCM#='+inttostr(frmDM.Q.FieldByName('M_RCMNUM').AsInteger);


   if sensors[2]<>'0' then gbTemp.Visible:=true;
   if sensors[3]<>'0' then gbCond.Visible:=true;
   if sensors[4]<>'0' then gbPress.Visible:=true;
   if sensors[5]<>'0' then gbDir.Visible:=true;
   if sensors[6]<>'0' then gbSpeed.Visible:=true;
   if sensors[7]<>'0' then gbTurb.Visible:=true;
   if sensors[8]<>'0' then gbOxyg.Visible:=true;
   if sensors[9]<>'0' then gbXXX.Visible:=true;


   with frmdm.RDQuery do begin
     Close;
     sql.Clear;
     SQL.Add(' SELECT * FROM ROWDATA  ');
     SQL.Add(' WHERE ');
     SQL.Add(' ABSNUM=:ABSNUM ');
     SQL.Add(' ORDER BY RD_TIME ');
     ParamByName('ABSNUM').AsInteger:=SA;
     Open;
   end;

     frmDM.CDSRD.Open;
     frmDM.RDQuery.Close;
     frmDM.TR.Commit;

  //   Series1.CheckDataSource;

   with frmdm.CFQuery do begin
     Close;
     sql.Clear;
     SQL.Add(' SELECT * FROM COEFFICIENTS  ');
     SQL.Add(' WHERE ');
     SQL.Add(' ABSNUM=:ABSNUM ');
     ParamByName('ABSNUM').AsInteger:=SA;
     Open;
   end;

     frmDM.cdsCF.Open;
     frmDM.CFQuery.Close;
     frmDM.TR.Commit;

     //count numner of QFL, filter CDS, show timeseries
     mik_QFL:=0;
     frmdm.CDSRD.Filtered:=false;
     frmdm.CDSRD.First;
     frmdm.CDSRD.DisableControls;
   while not frmdm.CDSRD.Eof do begin
     if frmdm.CDSRD.FieldByName('QFL').AsInteger=9 then mik_QFL:=mik_QFL+1;
     frmdm.CDSRD.Next;
   end;
     frmdm.CDSRD.EnableControls;
     Label1.Caption:='Number of QFL=9 is ' + inttostr(mik_QFL);
     CheckBox1.Checked:=true;

     frmDM.CDSRD.Filter:='QFL=0';
     frmdm.CDSRD.Filtered:=true;

     Application.ProcessMessages;

end;

{
procedure TfrmPlotRowData.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   frmDM.cdsRD.Active:=false;
   frmDM.cdsCF.Active:=false;
end; }



//show/hide grid boxes with parameters' coefficients
procedure TfrmPlotRowData.CheckBox3MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
sensors: string[9];
begin

    sensors:=frmDM.Q.FieldByName('M_Sensors').AsString;

   if CheckBox3.Checked=true then begin
     if sensors[2]='0' then gbTemp.Visible :=false;
     if sensors[3]='0' then gbCond.Visible :=false;
     if sensors[4]='0' then gbPress.Visible:=false;
     if sensors[5]='0' then gbDir.Visible  :=false;
     if sensors[6]='0' then gbSpeed.Visible:=false;
     if sensors[7]='0' then gbTurb.Visible :=false;
     if sensors[8]='0' then gbOxyg.Visible :=false;
     if sensors[9]='0' then gbXXX.Visible  :=false;
   end
   else begin
     gbTemp.Visible :=true;
     gbCond.Visible :=true;
     gbPress.Visible:=true;
     gbDir.Visible  :=true;
     gbSpeed.Visible:=true;
     gbTurb.Visible :=true;
     gbOxyg.Visible :=true;
     gbXXX.Visible  :=true;
   end;

end;




procedure TfrmPlotRowData.btnApplyUpdates_cdsCFClick(Sender: TObject);
begin
     frmDM.cdsCF.ApplyUpdates(0);
end;

procedure TfrmPlotRowData.btnCDSCommitClick(Sender: TObject);
begin
//showmessage('ABSNUM='+inttostr(frmDM.CDSRD.FieldByName('ABSNUM').AsInteger));
//showmessage('Time='+datetimetostr(frmDM.CDSRD.FieldByName('RD_TIME').AsDateTime));
     frmDM.cdsRD.ApplyUpdates(0);
end;



procedure TfrmPlotRowData.RadioGroup1Click(Sender: TObject);
begin
   //  series1.Clear;
   //  series2.Clear;
   //  series1.YValues.ValueSource:=frmdm.cdsRD.Fields.Fields[RadioGroup1.ItemIndex+2].FieldName;
   //  //showmessage(series1.YValues.ValueSource);

     frmDM.CDSRD.Active:=true;
end;



procedure TfrmPlotRowData.SetAsStartDate1Click(Sender: TObject);
begin
   frmSetAsStartDate := TfrmSetAsStartDate.Create(Self);
  try
   if frmSetAsStartDate.ShowModal = mrOk then
  finally
    frmSetAsStartDate.Free;
    frmSetAsStartDate:= nil;
  end;
end;



procedure TfrmPlotRowData.SetAsStopDate1Click(Sender: TObject);
begin
   frmSetAsStopDate := TfrmSetAsStopDate.Create(Self);
  try
   if frmSetAsStopDate.ShowModal = mrOk then
  finally
    frmSetAsStopDate.Free;
    frmSetAsStopDate:= nil;
  end;
end;




procedure TfrmPlotRowData.CheckBox1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   //Filter records with QFL=9?
   if CheckBox1.Checked=true then begin
     frmDM.CDSRD.Filter:='QFL=0';
     frmDM.CDSRD.Filtered:=true;
   end
   else
     frmDM.CDSRD.Filtered:=false;

   //  series1.CheckDataSource;


end;




//draw point while navigating in GRID
procedure TfrmPlotRowData.DBGridEh1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
     {series2.Clear;
   if (frmdm.cdsRD.FieldValues['RD_Time']<>null) and
      (frmdm.cdsRD.Fields.Fields[RadioGroup1.ItemIndex+2].Value<>null) then
       Series2.AddXY(frmdm.cdsRD.FieldValues['RD_Time'],
                     frmdm.cdsRD.Fields.Fields[RadioGroup1.ItemIndex+2].Value);
                     }
end;


{
//draw point on mouse click in GRID
procedure TfrmPlotRowData.DBGridEh1CellClick(Column: TColumnEh);
begin
     series2.Clear;
   if (frmdm.cdsRD.FieldValues['RD_Time']<>null) and
      (frmdm.cdsRD.Fields.Fields[RadioGroup1.ItemIndex+2].Value<>null) then
       Series2.AddXY(frmdm.cdsRD.FieldValues['RD_Time'],
                     frmdm.cdsRD.Fields.Fields[RadioGroup1.ItemIndex+2].Value);
end;
}

//draw point on mouse click in DBCHART
procedure TfrmPlotRowData.DBChart1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
Num_Clicked:int64;
LVar:array[0..1] of Variant;
begin
{     series2.Clear;
{w}with series1 do begin
     Num_Clicked:=Clicked(X,Y);
{c}if Num_Clicked<>-1 then begin
     LVar[0]:=YValues[Num_clicked];
     LVar[1]:=XValues[Num_clicked];
     DbGridEh1.DataSource.DataSet.Locate('RD_Time',LVar[1],[]);
     DBChart1.Series[1].AddXY(XValues[Num_Clicked],YValues[Num_Clicked]);
{c}end;
{w}end;  }
end;




procedure TfrmPlotRowData.btnSetQFL_9Click(Sender: TObject);
begin

   if checkbox2.Checked then
   with frmdm.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' UPDATE ROWDATA SET QFL=9  ');
     SQL.Add(' WHERE ');
     SQL.Add(' ABSNUM=:ABSNUM ');
     SQL.Add(' and (RD_TIME<:start or RD_TIME>:stop) ');
     ParamByName('ABSNUM').AsFloat:=SA;
     ParamByName('start').AsDateTime:=strtodatetime(Edit1.Text);
     ParamByName('stop').AsDateTime :=strtodatetime(Edit2.Text);
     ExecSQL;
   end
   else
   with frmdm.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' UPDATE ROWDATA SET QFL=9  ');
     SQL.Add(' WHERE ');
     SQL.Add(' ABSNUM=:ABSNUM ');
     SQL.Add(' and (RD_TIME>:start and RD_TIME<:stop) ');
     ParamByName('ABSNUM').AsFloat:=SA;
     ParamByName('start').AsDateTime:=strtodatetime(Edit1.Text);
     ParamByName('stop').AsDateTime :=strtodatetime(Edit2.Text);
     ExecSQL;
   end;
     frmdm.TR.Commit;
     frmDM.cdsRD.Active:=false;
     frmDM.cdsCF.Active:=false;
     UpdateForm;
end;


procedure TfrmPlotRowData.btnSetQFL_0Click(Sender: TObject);
begin
   with frmdm.ib1q1 do begin
     Close;
     SQL.Clear;
     SQL.Add(' UPDATE ROWDATA SET QFL=0  ');
     SQL.Add(' WHERE ');
     SQL.Add(' ABSNUM=:ABSNUM ');
     ParamByName('ABSNUM').AsFloat:=SA;
     ExecSQL;
   end;
     frmdm.TR.Commit;
     frmDM.cdsRD.Active:=false;
     frmDM.cdsCF.Active:=false;
     UpdateForm;
end;




end.
