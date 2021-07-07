unit msettings;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IniFiles, ExtCtrls, ComCtrls;

type

  { Tfrmsettings }

  Tfrmsettings = class(TForm)
    btnGrapherPath: TButton;
    btnGEBCOPath: TButton;
    btnOk: TButton;
    btnSurferPath: TButton;
    eGrapherPath: TEdit;
    eGEBCOPath: TEdit;
    eSurferPath: TEdit;
    gbAuxiliaryPrograms: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    OD: TOpenDialog;

    procedure FormShow(Sender: TObject);
    procedure btnSurferPathClick(Sender: TObject);
    procedure btnGrapherPathClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmsettings: Tfrmsettings;
  GlobalPath, GlobalUnloadPath, GlobalSupportPath, IniFileName: string; // path to the settings

implementation

{$R *.lfm}

procedure Tfrmsettings.FormShow(Sender: TObject);
Var
 Ini:TIniFile;
 SurferDefault, GrapherDefault, GEBCODefault:string;
begin

 Ini := TIniFile.Create(IniFileName);

 SurferDefault :='c:\Program Files\Golden Software\Surfer 13\Scripter\Scripter.exe';
 GrapherDefault:='c:\Program Files\Golden Software\Grapher 11\Scripter\Scripter.exe';
 GEBCODefault :=GlobalPath+'support'+PathDelim+'bathymetry'+PathDelim+'GEBCO_2020.nc';

 Ini := TIniFile.Create(IniFileName);
  try
   eSurferPath.Text  :=Ini.ReadString  ( 'main', 'SurferPath',   SurferDefault);
   eGrapherPath.Text :=Ini.ReadString  ( 'main', 'GrapherPath',  GrapherDefault);
   eGEBCOPath.Text   :=Ini.ReadString  ( 'main', 'GEBCOPath',    GEBCODefault);
  finally
    Ini.Free;
  end;

   if FileExists(eSurferPath.Text)  then eSurferPath.Font.Color:=clGreen  else eSurferPath.Font.Color:=clRed;
   if FileExists(eGrapherPath.Text) then eGrapherPath.Font.Color:=clGreen else eGrapherPath.Font.Color:=clRed;
   if FileExists(eGEBCOPath.Text)   then eGEBCOPath.Font.Color:=clGreen   else eGEBCOPath.Font.Color:=clRed;
end;



procedure Tfrmsettings.btnSurferPathClick(Sender: TObject);
begin
  OD.Filter:='Scripter.exe|Scripter.exe';
  if OD.Execute then eSurferPath.Text:= OD.FileName;
end;

procedure Tfrmsettings.btnGrapherPathClick(Sender: TObject);
begin
  OD.Filter:='Scripter.exe|Scripter.exe';
  if OD.Execute then eGrapherPath.Text:= OD.FileName;
end;

procedure Tfrmsettings.btnOkClick(Sender: TObject);
Var
 Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
  try
    Ini.WriteString  ( 'main', 'SurferPath',  eSurferPath.Text);
    Ini.WriteString  ( 'main', 'GrapherPath', eGrapherPath.Text);
    Ini.WriteString  ( 'main', 'GEBCOPath',   eGEBCOPath.Text);
  finally
    ini.Free;
  end;
 Close;
end;


end.
