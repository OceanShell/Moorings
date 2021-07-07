unit SetAsStartDate;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmSetAsStartDate = class(TForm)
    btnSetStartDate: TBitBtn;
    Label1: TLabel;
    procedure btnSetStartDateClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSetAsStartDate: TfrmSetAsStartDate;

implementation

{$R *.lfm}

uses DM, PlotRowData;


procedure TfrmSetAsStartDate.FormShow(Sender: TObject);
begin
     label1.Caption:=datetimetostr(frmDM.CDSRD.FieldByName('RD_Time').AsDateTime);
end;


procedure TfrmSetAsStartDate.btnSetStartDateClick(Sender: TObject);
begin
     //showmessage(datetimetostr(frmDM.CDSRD.FieldByName('RD_Time').AsDateTime));
     frmPlotRowData.Edit1.Text:=datetimetostr(frmDM.CDSRD.FieldByName('RD_Time').AsDateTime);
     frmSetAsStartDate.Close;
     //frmSetAsStartDate.Free;
end;


end.
