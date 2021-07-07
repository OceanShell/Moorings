unit CreateMooringsDirectoryCatalogOnDisk;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, FileCtrl;

type

  { TfrmCreateMooringsDirectoryCatalogOnDisk }

  TfrmCreateMooringsDirectoryCatalogOnDisk = class(TForm)
    btnCreate: TBitBtn;
    ListBox1: TListBox;
    Memo1: TMemo;
    GroupBox1: TGroupBox;
    btn_nc: TBitBtn;
    btnAddDrawings: TBitBtn;

    //DirectoryListBox1: TDirectoryListBox;
    procedure btnCreateClick(Sender: TObject);
    procedure btn_ncClick(Sender: TObject);
    procedure btnAddDrawingsClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCreateMooringsDirectoryCatalogOnDisk: TfrmCreateMooringsDirectoryCatalogOnDisk;
  path,path_source,path_target: string;

implementation

{$R *.lfm}

uses DM;


procedure TfrmCreateMooringsDirectoryCatalogOnDisk.FormShow(Sender: TObject);
begin
   //  DirectoryListBox1.Directory:='d:\data\Currents\datasets\moorings\';
   //  DirectoryListBox1.OpenCurrent;
end;



procedure TfrmCreateMooringsDirectoryCatalogOnDisk.btnCreateClick(
  Sender: TObject);
var
M_Count: integer;
M_ID, M_Folder: string;
begin
     //path:='d:\OceanShell\applications\unload\currents\moorings catalog\';
     path:='d:\data\Currents\datasets\moorings\';

     frmdm.TR.StartTransaction;

   //moorings identifiers
   with frmdm.ib1q1 do begin
     Close;
     sql.Clear;
     SQL.Add(' select M_ID, count(M_ID) from MOORINGS  ');
     SQL.Add(' group by M_ID ');
     Open;
   end;


     frmdm.ib1q1.First;
{w}while not frmdm.ib1q1.Eof do begin
     M_ID:=frmdm.ib1q1.FieldByName('M_ID').AsString;
     M_Count:=frmdm.ib1q1.FieldByName('Count').AsInteger;

     memo1.Lines.Add(M_ID+#9+inttostr(M_Count));

     M_Folder:=path+M_ID+'\';
     if not DirectoryExists(M_Folder) then CreateDir(M_Folder);

     frmdm.ib1q1.Next;
{w}end;

     memo1.Lines.Add('Moorings count='+inttostr(frmdm.ib1q1.RecordCount));

     frmdm.ib1q1.Close;
     frmdm.TR.Active:=false;

end;


procedure TfrmCreateMooringsDirectoryCatalogOnDisk.btn_ncClick(Sender: TObject);
var
M_Count,absnum,k: integer;
M_ID, path_mooring, f_source, f_target: string;
absnum_str: string;
searchResult : TSearchRec;

begin
     //path:='d:\OceanShell\applications\unload\currents\moorings catalog\';
     path_source:='d:\data\Currents\datasets\nc\';
     path_target:='d:\data\Currents\datasets\moorings\';

     frmdm.TR.StartTransaction;

   //extract instruments by moorings' identifiers
   with frmdm.ib1q2 do begin
     Close;
     sql.Clear;
     SQL.Add(' select ABSNUM from MOORINGS  ');
     SQL.Add(' where M_ID=:M_ID ');
     Prepare;
   end;


   //moorings identifiers
   with frmdm.ib1q1 do begin
     Close;
     sql.Clear;
     SQL.Add(' select M_ID, count(M_ID) from MOORINGS  ');
     SQL.Add(' group by M_ID ');
     Open;
   end;


     frmdm.ib1q1.First;
{1}while not frmdm.ib1q1.Eof do begin  //moorings
     M_ID:=frmdm.ib1q1.FieldByName('M_ID').AsString;
     M_Count:=frmdm.ib1q1.FieldByName('Count').AsInteger;
     memo1.Lines.Add(M_ID+#9+inttostr(M_Count));

     path_mooring:=path_target+M_ID+'\';

   with frmdm.ib1q2 do begin
     ParamByName('M_ID').AsString:=M_ID;
     Open;
   end;

{2}while not frmdm.ib1q2.Eof do begin   //instruments
     absnum:=frmdm.ib1q2.FieldByName('absnum').AsInteger;
     absnum_str:=inttostr(absnum);

     if length(absnum_str)=1 then absnum_str:='000'+absnum_str;
     if length(absnum_str)=2 then absnum_str:='00'+absnum_str;
     if length(absnum_str)=3 then absnum_str:='0'+absnum_str;
     // IMPORTANT !!! other wise should be file name
     absnum_str:=absnum_str+'*'; //search by absnum only
     memo1.Lines.Add(#9+inttostr(absnum)+'  ->'+absnum_str);

{3}for k:=1 to 4 do begin //four different directories to search
   case k of
   1: path_source:='d:\data\Currents\datasets\nc\';
   2: path_source:='d:\data\Currents\datasets\pdf\';
   3: path_source:='d:\data\Currents\datasets\txt_full\';
   4: path_source:='d:\data\Currents\datasets\txt_short\';
   end; {case}

     ChDir(path_source);

{f}if FindFirst(absnum_str, faAnyFile, searchResult) = 0 then begin
   repeat
     f_source:= searchResult.Name;
     //memo1.Lines.Add('File source = '+f_source);
   until FindNext(searchResult) <> 0;

     f_source:=path_source+f_source;  //full path to source file
     f_target:=path_mooring+ExtractFileName(f_source);
     memo1.Lines.Add(f_source+' -> '+f_target);

     FindClose(searchResult); // Must free up

    /// CopyFile(PChar(f_source),PChar(f_target),false); //file will be replaced
     // Т.к. параметр не принимает стандартного строкового значения String,
     // необходимо сделать приведение типа к PChar.



{f}end;
{3}end;



     frmdm.ib1q2.Next;
{2}end;
     frmdm.ib1q2.Close;

     frmdm.ib1q1.Next;
{1}end;
     frmdm.ib1q2.UnPrepare;

     memo1.Lines.Add('Moorings count='+inttostr(frmdm.ib1q1.RecordCount));
     frmdm.ib1q1.Close;
     frmdm.TR.Active:=false;

end;



procedure TfrmCreateMooringsDirectoryCatalogOnDisk.btnAddDrawingsClick(
  Sender: TObject);
var
k: integer;
m_dir, f_source, f_target,fn: string;
searchResult : TSearchRec;
begin

     memo1.Clear;
     path_source:='d:\data\Currents\datasets\pdf_drawing\';
     path_target:='d:\data\Currents\datasets\moorings\';


   //indexes does not work properly negative should be up from current directory
{d}for k:=5 to ListBox1.Count-1 do begin

     m_dir:=trim(ListBox1.Items.Strings[k]);
     fn:=trim(ListBox1.Items.Strings[k])+'*'; //all files containing directory name
     memo1.Lines.Add(inttostr(k)+#9+m_dir);

     ChDir(path_source);
     Application.ProcessMessages;

{f}if FindFirst(fn, faAnyFile, searchResult) = 0 then begin
   repeat
     f_source:= searchResult.Name;
   until FindNext(searchResult) <> 0;

     f_source:=path_source+f_source;  //full path to source file
     f_target:=path_target+m_dir+'\'+ExtractFileName(f_source);
     memo1.Lines.Add(f_source+' -> '+f_target);

     FindClose(searchResult); // Must free up

     //CopyFile(PChar(f_source),PChar(f_target),false); //file will be replaced
     // Т.к. параметр не принимает стандартного строкового значения String,
     // необходимо сделать приведение типа к PChar.



{f}end;




{d}end;

end;



end.
