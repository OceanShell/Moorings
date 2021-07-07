unit PlotTimeSeriesLSTGrapher;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DateUtils, IniFiles;

type
  TfrmPlotTimeSeriesLSTGrapher = class(TForm)
    btnOpenLSTFile: TBitBtn;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    RadioGroup1: TRadioGroup;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Label1: TLabel;
    btnCreateGrapherPlot: TBitBtn;
    CheckBox3: TCheckBox;
    procedure btnOpenLSTFileClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCreateGrapherPlotClick(Sender: TObject);
  private
    { Private declarations }
    procedure RunGrapher_TimeSeries;
  public
    { Public declarations }
  end;

var
  frmPlotTimeSeriesLSTGrapher: TfrmPlotTimeSeriesLSTGrapher;
  cf: integer; //column number in file
  Mstart,Mstop: TDateTime;
  f_lst, f_out, script: text;

implementation

{$R *.lfm}

uses msettings;


procedure TfrmPlotTimeSeriesLSTGrapher.FormShow(Sender: TObject);
begin
     memo1.Clear;
end;




procedure TfrmPlotTimeSeriesLSTGrapher.btnOpenLSTFileClick(Sender: TObject);
var
i,col: integer;
fn_lst,st,coln,vn,fn: string; //coln- column name
buf: char;
begin

     memo1.Clear;
     RadioGroup1.Items.Clear;

     //showmessage('Global path: '+GlobalPath);
     OpenDialog1.InitialDir:='d:\data\Currents\GFI\';
   if OpenDialog1.Execute then
     fn_lst:=OpenDialog1.FileName
   else begin
     showmessage('File not selected!');
     Exit;
   end;

     assignfile(f_lst, fn_lst);
     reset(f_lst);

     //output
     fn:=GlobalPath+'\unload\currents\grf\TimeSeries.dat';
     assignfile(f_out, fn);
     memo1.Lines.Add('file: '+fn+'  was created');


     //1st line
     //%M09465 N= 3259 FAUVTS      DT=  60 T=9810 4-16 2 Z= 480 PS=N62486E004156
     readln(f_lst,st);
     memo1.Lines.Add(trim(st));
     //2nd line
     //%Y MM DD hh mm    F       A       U       V       T       S
     readln(f_lst,st);
     memo1.Lines.Add(trim(st));
     closefile(f_lst);

     coln:='';
{i}for i:=1 to length(st) do begin
     buf:=st[i];
     if buf<>' ' then coln:=coln+buf;
{i}end;
     memo1.Lines.Add('string without blanks: '+coln);

     col:=5;    //variable column number in file
     cf:=length(coln)-10; //column number in file
     memo1.Lines.Add('# of columns with variables: '+inttostr(cf));

   for i:=11 to length(coln) do begin
     col:=col+1;
     memo1.Lines.Add(inttostr(i)+'column#='+inttostr(col)+#9+coln[i]);

      vn:=coln[i]; //variable name
     case coln[i] of
     'F': vn:='Current speed (cm/s)';
     'A': vn:='Current direction (gr)';
     'U': vn:='Current U component (gr)';
     'V': vn:='Current V component (gr)';
     'T': vn:='Temperature (C)';
     'S': vn:='Salinity';
     'P': vn:='Pressure (kg/cm2)';
     end;

     RadioGroup1.Items.Add(vn);
   end;
     RadioGroup1.ItemIndex:=0;

     RadioGroup1.Visible:=true;
     CheckBox1.Visible:=true;
     CheckBox2.Visible:=true;
     Label1.Visible:=true;

end;





procedure TfrmPlotTimeSeriesLSTGrapher.btnCreateGrapherPlotClick(
  Sender: TObject);
var
i,sc,mik: integer;
y,m,d,h,mm: word;
v: real;
rt: TDateTime;
begin
     //five reserved columns: year, month, day, hour, minute
     sc:=RadioGroup1.ItemIndex+1; //selected variable's column
     //showmessage('selected colum:'+inttostr(sc));

   if CheckBox1.Checked then begin
     //fn:=GlobalPath+'\unload\currents\grf\TimeSeries.dat';
     //assignfile(f_out, fn);
     rewrite(f_out);
     writeln(f_out,'time'+#9+'value');
   end;


     reset(f_lst);
     readln(f_lst);
     readln(f_lst);

     if CheckBox3.Checked=true then memo1.Visible:=true else memo1.Visible:=false;
     v:=-9;
     mik:=0;
{w}while not EOF(f_lst) do begin
     mik:=mik+1;
     read(f_lst,y,m,d,h,mm);
     for i:=1 to sc do read(f_lst,v);
     readln(f_lst);

     if y>60 then y:=y+1900 else y:=y+2000;
     rt:=EncodeDateTime(y,m,d,h,mm,0,0); //record time
     if mik=1 then Mstart:=rt;

     memo1.Lines.Add(inttostr(y)
     +#9+inttostr(m)
     +#9+inttostr(d)
     +#9+inttostr(h)
     +#9+inttostr(mm)
     +#9+datetimetostr(rt)
     +#9+floattostr(v));

   if CheckBox1.Checked then writeln(f_out,datetimetostr(rt)+#9+floattostr(v));

{w}end;
     Mstop:=rt;
     closefile(f_lst);
     memo1.Visible:=true;

    if CheckBox1.Checked then closefile(f_out);
    if CheckBox2.Checked then RunGrapher_TimeSeries;

end;



procedure TfrmPlotTimeSeriesLSTGrapher.RunGrapher_TimeSeries;
var
 Ini:TIniFile;
 qchar: char;
 scripter,cmd,pn:string;
 StartupInfo:  TStartupInfo;
// ProcessInfo:  TProcessInformation;
begin

qchar:='"';
pn:=RadioGroup1.Items.Strings[RadioGroup1.ItemIndex]; //name of selected variable

AssignFile(script, GlobalPath+'unload\currents\grf\TimeSeries.bas');
rewrite(script);
//create script
Writeln(script, 'Sub Main');
Writeln(script, '');
Writeln(script, ' Dim GrapherApp As Object');
Writeln(script, ' Dim Plot As Object');
Writeln(script, ' Dim TimeSeriesGraph As Object');
Writeln(script, '');

Writeln(script, ' Set GrapherApp = CreateObject("Grapher.Application") ');
Writeln(script, ' GrapherApp.Visible = True');
Writeln(script, '');

Writeln(script, ' Set Plot = GrapherApp.Documents.Add(grfPlotDoc) ');
Writeln(script, '');

Writeln(script, ' Set TimeSeriesGraph=Plot.Shapes.AddLinePlotGraph("d:\OceanShell\applications\unload\currents\grf\TimeSeries.dat",1,2,"TimeSeriesGraph") ');
Writeln(script, '');

Writeln(script, ' Plot.ReloadWorksheets ');
Writeln(script, '');

//x axis settings
Writeln(script, ' Set XAxis =TimeSeriesGraph.Axes.Item(1) ');
Writeln(script, ' XAxis.title.text="Time" ');
Writeln(script, ' XAxis.length=14 ');
Writeln(script, ' XAxis.title.Font.color=grfColorRed ');
//labels date/time format
//4=d-mmmm-yy  6=mmm-yy  25=dd/mm/yy  from HELP->DateTimeFormatProperty
Writeln(script, ' XAxis.TickLabels.MajorFormat.DateTimeFormat = 6 ');
Writeln(script, '');
//limits ex: XAxis.Min=DateValue("29.09.1998 12:00:00")
Writeln(script, '  XAxis.AutoMin=False ');
Writeln(script, '  XAxis.AutoMax=False ');
Writeln(script, ' XAxis.Min=DateValue('+AnsiQuotedStr(datetimetostr(MStart),qchar)+')');
Writeln(script, ' XAxis.Max=DateValue('+AnsiQuotedStr(datetimetostr(MStop) ,qchar)+')');
Writeln(script, '');

//y axis settings
Writeln(script, ' Set YAxis =TimeSeriesGraph.Axes.Item(2) ');
Writeln(script, ' Set YAxis.length=5 ');
Writeln(script, ' YAxis.title.text= ' + AnsiQuotedStr(pn,qchar) );
Writeln(script, ' YAxis.title.Font.color=grfColorRed ');

Writeln(script, '');

Writeln(script, '');
Writeln(script, 'End Sub');
CloseFile(script);

RadioGroup1.ItemIndex:=-1; //uncheck all items


//run skript
 Ini := TIniFile.Create(IniFileName); // settings from file
  try
   scripter:=Ini.ReadString( 'Main', 'Grapher',  'c:\Program Files\Golden Software\Grapher 10\Scripter\Scripter.exe');
  finally
    Ini.Free;
  end;

   cmd:=Concat('"'+Scripter, '"', ' -x ', '"', GlobalPath+'unload\currents\grf\TimeSeries.bas"');
   //memo1.Lines.Add('scripter: '+scripter);
   //memo1.Lines.Add('cmd: '+cmd);
   Fillchar(startupInfo, Sizeof(StartupInfo), #0);
   StartupInfo.cb:=Sizeof(StartupInfo);
 {  if CreateProcess(nil, Pchar(cmd), nil, nil, false, CREATE_NO_WINDOW, nil, nil,StartupInfo, ProcessInfo)
   then begin
     WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
     FileClose(ProcessInfo.hProcess); { *Converted from CloseHandle* }
   end;  }

end;



end.
