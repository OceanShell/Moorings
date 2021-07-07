unit CreateTextReport;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmCreateTextReport = class(TForm)
    btnCreateReport: TBitBtn;
    Memo1: TMemo;
    procedure FormShow(Sender: TObject);
    procedure btnCreateReportClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCreateTextReport: TfrmCreateTextReport;

implementation

{$R *.lfm}

uses DM, mmain;

procedure TfrmCreateTextReport.FormShow(Sender: TObject);
begin
     memo1.Clear;
     showmessage('Database have to be connected, moorings selected and properly sorted');
end;


procedure TfrmCreateTextReport.btnCreateReportClick(Sender: TObject);
var
absnum,RCMnum,QFlag,TCh,RCMDepth,RCMTimeInt,BottomDepth,RDCount,CDCount: integer;
ArchiveNum: Integer;
RCMLat,RCMLon: real;
RCMType: string[10];
sensors: string[9];
Region,Place,PrInv,Project,Archive,SourceFile,CalibrationSheet: string;

TA,TB,TC,TD,CA,CB,CC,CD,PA,PB,PC,PD,DA,DB,DC,DD: real;
SA,SB,SC,SD,UA,UB,UC,UD,OA,OB,OC,OD,XA,XB,XC,XD: real;

RDTimeBeg,RDTimeEnd: TdateTime;
begin


     frmdm.TR.StartTransaction; //one mooring will be replaced in framework of transaction

   //read coefficients
   with frmdm.ib1q1 do begin
     Close;
     sql.Clear;
     SQL.Add(' SELECT * FROM COEFFICIENTS  ');
     SQL.Add(' WHERE ');
     SQL.Add(' ABSNUM=:ABSNUM ');
     Prepare;
   end;

     memo1.Lines.Add('Database: '+IBName);
     memo1.Lines.Add('');
     memo1.Lines.Add('RCM channels abbreviation');
     memo1.Lines.Add('0: sensor not installed or conversion coefficients are missing');
     memo1.Lines.Add('R: Reference');
     memo1.Lines.Add('T: Temperature');
     memo1.Lines.Add('C: Conductivity');
     memo1.Lines.Add('P: Pressure');
     memo1.Lines.Add('D: Current Direction');
     memo1.Lines.Add('S: Current Speed');
     memo1.Lines.Add('U: tUrbidity');
     memo1.Lines.Add('O: Oxygen');


     frmdm.Q.DisableControls;
     frmdm.Q.First;
{w}while not frmdm.Q.Eof do begin

     absnum:=frmdm.Q.FieldByName('Absnum').AsInteger;
     RCMnum:=frmdm.Q.FieldByName('M_RCMnum').AsInteger;
     QFlag:=frmdm.Q.FieldByName('M_QFlag').AsInteger;

     RDTimeBeg:=frmdm.Q.FieldByName('M_TimeBeg').AsDateTime;
     RDTimeEnd:=frmdm.Q.FieldByName('M_TimeEnd').AsDateTime;

     RCMLat:=frmdm.Q.FieldByName('M_Lat').AsFloat;
     RCMLon:=frmdm.Q.FieldByName('M_Lon').AsFloat;
     RCMDepth:=frmdm.Q.FieldByName('M_RCMDepth').AsInteger;
     RCMTimeInt:=frmdm.Q.FieldByName('M_RCMTimeInt').AsInteger;
     BottomDepth:=frmdm.Q.FieldByName('M_BottomDepth').AsInteger;

     sensors:=frmdm.Q.FieldByName('M_sensors').AsString;
     TCh:=frmdm.Q.FieldByName('M_TempChannel').AsInteger;

     RDCount:=frmdm.Q.FieldByName('M_Rec_Row').AsInteger; //number of rowdata records
     CDCount:=frmdm.Q.FieldByName('M_Rec_Cur').AsInteger; //number of converted records

     RCMType:=frmdm.Q.FieldByName('M_RCMType').AsString;

     Region:=frmdm.Q.FieldByName('M_Region').AsString;
     Place:=frmdm.Q.FieldByName('M_Place').AsString;
     PrInv:=frmdm.Q.FieldByName('M_PI').AsString;
     Project:=frmdm.Q.FieldByName('M_ProjectName').AsString;
     Archive:=frmdm.Q.FieldByName('M_ArchiveName').AsString;
     ArchiveNum:=frmdm.Q.FieldByName('M_ArchiveRefNum').AsInteger;
     SourceFile:=frmdm.Q.FieldByName('M_SourceFileName').AsString;
     CalibrationSheet:=frmdm.Q.FieldByName('M_CalibrationSheet').AsString;

     memo1.Lines.Add('');
     memo1.Lines.Add(' .................... metadata'
     +'  absnum='+inttostr(absnum)
     +'  RCMType='+RCMType);

     memo1.Lines.Add('RCM# '+inttostr(RCMnum)
     +'   QFL='+inttostr(QFLag)
     +'   lat='+floattostr(RCMLat)
     +'   lon='+floattostr(RCMLon)
     +'   RCMDepth:'+inttostr(RCMDepth)+' m'
     +'   RCMTimeInt:'+inttostr(RCMTimeInt)+' min');

     memo1.Lines.Add('time series start [row data]: '+datetimetostr(RDTimeBeg));
     memo1.Lines.Add('time series stop  [row data]: '+datetimetostr(RDTimeEnd));
     memo1.Lines.Add('channels: '+sensors + '   Preferred temperature channel: '+inttostr(TCh));
     memo1.Lines.Add('records# [rowdata]       : '+inttostr(RDCount));
     memo1.Lines.Add('records# [converted data]: '+inttostr(CDCount));
     memo1.Lines.Add('Region          : '+Region);
     memo1.Lines.Add('Place           : '+Place);
     memo1.Lines.Add('PrInv           : '+PrInv);
     memo1.Lines.Add('Project         : '+Project);
     memo1.Lines.Add('Archive         : '+Archive);
     memo1.Lines.Add('ArchiveRefNum   : '+inttostr(ArchiveNum));
     memo1.Lines.Add('SourceFile      : '+SourceFile);
     memo1.Lines.Add('CalibrationSheet: '+CalibrationSheet);

   //transformation coefficients
   with frmdm.ib1q1 do begin
     ParamByName('ABSNUM').AsFloat:=absnum;
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

     memo1.Lines.Add('...coefficients (A,B,C,D) applied for conversion from engineering to physical units for available variables');
     if sensors[2]<>'0' then
     memo1.Lines.Add('TA='+floattostrF(TA,ffGeneral,8,5)
     +#9+'TB='+floattostrF(TB,ffGeneral,8,5)
     +#9+'TC='+floattostrF(TC,ffGeneral,8,5)
     +#9+'TD='+floattostrF(TD,ffGeneral,8,5));

     if sensors[3]<>'0' then
     memo1.Lines.Add('CA='+floattostrF(CA,ffGeneral,8,5)
     +#9+'CB='+floattostrF(CB,ffGeneral,8,5)
     +#9+'CC='+floattostrF(CC,ffGeneral,8,5)
     +#9+'CD='+floattostrF(CD,ffGeneral,8,5));
     if sensors[4]<>'0' then
     memo1.Lines.Add('PA='+floattostrF(PA,ffGeneral,8,5)
     +#9+'PB='+floattostrF(PB,ffGeneral,8,5)
     +#9+'PC='+floattostrF(PC,ffGeneral,8,5)
     +#9+'PD='+floattostrF(PD,ffGeneral,8,5));
     if sensors[5]<>'0' then
     memo1.Lines.Add('DA='+floattostrF(DA,ffGeneral,8,5)
     +#9+'DB='+floattostrF(DB,ffGeneral,8,5)
     +#9+'DC='+floattostrF(DC,ffGeneral,8,5)
     +#9+'DD='+floattostrF(DD,ffGeneral,8,5));
     if sensors[6]<>'0' then
     memo1.Lines.Add('SA='+floattostrF(SA,ffGeneral,8,5)
     +#9+'SB='+floattostrF(SB,ffGeneral,8,5)
     +#9+'SC='+floattostrF(SC,ffGeneral,8,5)
     +#9+'SD='+floattostrF(SD,ffGeneral,8,5));
     if sensors[7]<>'0' then
     memo1.Lines.Add('UA='+floattostrF(UA,ffGeneral,8,5)
     +#9+'UB='+floattostrF(UB,ffGeneral,8,5)
     +#9+'UC='+floattostrF(UC,ffGeneral,8,5)
     +#9+'UD='+floattostrF(UD,ffGeneral,8,5));
     if sensors[8]<>'0' then
     memo1.Lines.Add('OA='+floattostrF(OA,ffGeneral,8,5)
     +#9+'OB='+floattostrF(OB,ffGeneral,8,5)
     +#9+'OC='+floattostrF(OC,ffGeneral,8,5)
     +#9+'OD='+floattostrF(OD,ffGeneral,8,5));
     if sensors[9]<>'0' then
     memo1.Lines.Add('XA='+floattostrF(XA,ffGeneral,8,5)
     +#9+'XB='+floattostrF(XB,ffGeneral,8,5)
     +#9+'XC='+floattostrF(XC,ffGeneral,8,5)
     +#9+'XD='+floattostrF(XD,ffGeneral,8,5));


     frmdm.Q.Next;
{w}end; {Q}

     frmdm.Q.First;
     frmdm.Q.EnableControls;

     frmdm.ib1q1.UnPrepare;
     frmdm.TR.Active:=false;

end;




end.
