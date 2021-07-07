unit SetAsStopDate;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmSetAsStopDate = class(TForm)
    btnSetStopDate: TBitBtn;
    Label1: TLabel;
    procedure btnSetStopDateClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSetAsStopDate: TfrmSetAsStopDate;

implementation

{$R *.lfm}

uses DM, PlotRowData;

procedure TfrmSetAsStopDate.FormShow(Sender: TObject);
begin
     label1.Caption:=datetimetostr(frmDM.CDSRD.FieldByName('RD_Time').AsDateTime);
end;


procedure TfrmSetAsStopDate.btnSetStopDateClick(Sender: TObject);
begin
    //showmessage(datetimetostr(frmDM.CDSRD.FieldByName('RD_Time').AsDateTime));
     frmPlotRowData.Edit2.Text:=datetimetostr(frmDM.CDSRD.FieldByName('RD_Time').AsDateTime);
     frmSetAsStopDate.Close;
end;


end.
