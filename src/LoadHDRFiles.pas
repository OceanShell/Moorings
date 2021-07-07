unit LoadHDRFiles;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, BufDataset, StdCtrls, Buttons, ExtCtrls;

type
  TfrmLoadHDRFiles = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    btnStart: TBitBtn;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Memo1: TMemo;
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    procedure ffind(SearchDir:string);
    procedure HDR(HDRFileName:string; HDRFileSize:integer);
  public
    { Public declarations }
  end;

var
  frmLoadHDRFiles: TfrmLoadHDRFiles;
  fi,fo:text;
  count:integer;

  cdsHDR:TBufDataSet; //cds with files duplicates
  cdsCreated:boolean=false;

  SearchExt :string='.HDR';
  SearchExt1:string='.hdr';

implementation

{$R *.lfm}

procedure TfrmLoadHDRFiles.FormCreate(Sender: TObject);
begin
    Memo1.Clear;
end;


procedure TfrmLoadHDRFiles.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    if cdsCreated=true then begin
      //cdsHDR.EmptyDataSet;
      cdsHDR.Free;
    end;
end;



procedure TfrmLoadHDRFiles.btnStartClick(Sender: TObject);
var
i:integer;
SearchDir :string;
begin
   memo1.Clear;
   count:=0;

   SearchDir:=trim(Edit1.Text);
   SearchExt:=trim(Edit2.Text);
   SearchExt1:=trim(Edit3.Text);

{c}if cdsCreated=false then begin
    cdsHDR:=TBufDataSet.Create(nil);
   with cdsHDR.FieldDefs do begin
    Add('FName',ftString,256,false);
    Add('FSize',ftinteger,0,false);
   end;
    cdsHDR.CreateDataSet;
  //  cdsHDR.LogChanges:=false;
    cdsCreated:=true;
{c}end;

   ffind(SearchDir);

end;


Procedure TfrmLoadHDRFiles.ffind(SearchDir:string);
var
res, fsize :integer;
fname :string;
FRec :TSearchRec;
begin

//showmessage('Search Directoty:'+SearchDir+'   SearchExt:'+SearchExt);
Application.ProcessMessages;


    res:=FindFirst(SearchDir+'*.*',faAnyFile,FRec); //ищем первый файл
    res:=findNext(FRec);//ищем следующий файл

{w}While res=0 do begin
{d}if (FRec.Attr=faDirectory) and ((FRec.Name='.')or(FRec.Name='..')) then begin
    Res:=FindNext(FRec);
   if (ExtractFileExt(FRec.Name)=SearchExt) or (ExtractFileExt(FRec.Name)=SearchExt1)
{e}then begin
       count:= count+1;
       fname:=SearchDir+FRec.Name;
       fsize:=FRec.Size;
       Memo1.Lines.Add('#'+inttostr(count));
       Memo1.Lines.Add(fname);
       Memo1.Lines.Add(inttostr(fsize)+' byte');
       HDR(fname,fsize); //hdr file analysis

{e}end;
    Continue;
{d}end;

   //if a directory found looking inside
{d}if (FRec.Attr=faDirectory) then begin
    ffind(SearchDir+FRec.Name+'\');//рекурсивно вызываем нашу процедуру
    Res:=FindNext(FRec);
    if (ExtractFileExt(FRec.Name)=SearchExt) or (ExtractFileExt(FRec.Name)=SearchExt1)
{e}then begin
       count:=count+1;
       fname:=SearchDir+FRec.Name;
       fsize:=FRec.Size;
       Memo1.Lines.Add('#'+inttostr(count));
       Memo1.Lines.Add(fname);
       Memo1.Lines.Add(inttostr(fsize)+' byte');
       HDR(fname,fsize); //hdr file analysis
{e}end;

    Continue;//продолжаем цикл
{d}end;

    Res:=FindNext(FRec);//ищем след. файл
    if (ExtractFileExt(FRec.Name)=SearchExt) or (ExtractFileExt(FRec.Name)=SearchExt1)
{e}then begin
       count:=count+1;
       fname:=SearchDir+FRec.Name;
       fsize:=FRec.Size;
       Memo1.Lines.Add('#'+inttostr(count));
       Memo1.Lines.Add(fname);
       Memo1.Lines.Add(inttostr(fsize)+' byte');
       HDR(fname,fsize); //hdr file analysis
{e}end;

{w}end;

    FindClose(FRec);//освобождаем переменную поиска
end;



Procedure TfrmLoadHDRFiles.HDR(HDRFileName:string; HDRFileSize:integer);
begin

    //showmessage(HDRFileName+'  size='+inttostr(hdrfilesize));

       // Open hdr file here
       //populate cdsHDR if a new mooring
       with cdsHDR do begin
        Append;
        FieldByName('FName').AsString:=hdrfilename;
        FieldByName('FSize').AsInteger:=hdrfilesize;
        Post;
       end;



end;




end.
