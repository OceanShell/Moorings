unit TextFilesList;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, FileCtrl, ExtCtrls, DB, BufDataset;

type
  TfrmTextFilesList1 = class(TForm)
    Memo1: TMemo;
    btnStart: TBitBtn;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Edit2: TEdit;
    Label3: TLabel;
    Edit3: TEdit;
    Panel1: TPanel;
    btnCheckDup: TBitBtn;
    ListBox1: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnCheckDupClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ffind(SearchDir:string);

    { Public declarations }
  end;

var
  frmTextFilesList1: TfrmTextFilesList1;
  fi,fo:text;
  count:integer;

  cdsFDup:TBufDataSet; //cds with files duplicates
  cdsCreated:boolean=false;

  SearchExt :string='.LST';
  SearchExt1:string='.lst';

implementation

{$R *.lfm}


procedure TfrmTextFilesList1.FormCreate(Sender: TObject);
begin
    Memo1.Clear;
end;




procedure TfrmTextFilesList1.btnStartClick(Sender: TObject);
var
i:integer;
SearchDir :string;
begin
   memo1.Clear;
   count:=0;

   SearchDir:=trim(Edit1.Text);
   SearchExt:=trim(Edit2.Text);
   SearchExt1:=trim(Edit3.Text);
   //showmessage('Search Directoty:  '+SearchDir);
   //showmessage('SearchExt:  '+SearchExt+'  '+SearchExt1);
   //ffind('c:\data\Currents\GFI\');

{c}if cdsCreated=false then begin
    cdsFDup:=TBufDataSet.Create(nil);
   with cdsFDup.FieldDefs do begin
    Add('FName',ftString,40,false);
    Add('FSize',ftInteger,0,false);
   end;
    cdsFDup.CreateDataSet;
    //cdsFDup.LogChanges:=false;
    cdsCreated:=true;
{c}end;

   ffind(SearchDir);

end;


Procedure TfrmTextFilesList1.ffind(SearchDir:string);
var
res :integer;
FRec :TSearchRec;
begin

//showmessage('Search Directoty:'+SearchDir+'   SearchExt:'+SearchExt);
Application.ProcessMessages;

    {TSearchRec = record
	  Time: Integer;
	  Size: Int64;
	  Attr: Integer;  1 2 4 8 16 32 64 71
	  Name: TFileName;
	  ExcludeAttr: Integer;
	  FindHandle: Cardinal;
	  FindData: _WIN32_FIND_DATAW;
    end;}

    res:=FindFirst(SearchDir+'*.*',faAnyFile,FRec); //ищем первый файл
    //Memo1.Lines.Add('FRec.Attr='+inttostr(FRec.Attr));
    //showmessage('FRec.Name='+FRec.Name);
    //showmessage('FRec.Size='+inttostr(FRec.Size));

    res:=findNext(FRec);//ищем следующий файл
    //Memo1.Lines.Add('search for: '+DirPath+'*.*');
    //Memo1.Lines.Add(Sea.Name);//добавляем имя файла
    //Memo1.Lines.Add(ExtractFileExt(Sea.Name));

{w}While res=0 do begin
   if (FRec.Attr=faDirectory) and ((FRec.Name='.')or(FRec.Name='..')) then begin
    Res:=FindNext(FRec);
    if (ExtractFileExt(FRec.Name)=SearchExt) or (ExtractFileExt(FRec.Name)=SearchExt1)
     then begin
       count:= count+1;
       Memo1.Lines.Add('#'+inttostr(count));
       Memo1.Lines.Add(SearchDir+FRec.Name);
       //populate cdsFDup
       with cdsFDup do begin
        Append;
        FieldByName('FName').AsString:=FRec.Name;
        FieldByName('FSize').AsInteger:=FRec.Size;
        Post;
       end;
    end;
    Continue;
   end;

   //if a directory found looking inside
   if (FRec.Attr=faDirectory) then begin
    ffind(SearchDir+FRec.Name+'\');//рекурсивно вызываем нашу процедуру
    Res:=FindNext(FRec);
    if (ExtractFileExt(FRec.Name)=SearchExt) or (ExtractFileExt(FRec.Name)=SearchExt1)
    then begin
       count:=count+1;
       Memo1.Lines.Add('#'+inttostr(count));
       Memo1.Lines.Add(SearchDir+FRec.Name);
       //populate cdsFDup
       with cdsFDup do begin
        Append;
        FieldByName('FName').AsString:=FRec.Name;
        FieldByName('FSize').AsInteger:=FRec.Size;
        Post;
       end;
    end;
    Continue;//продолжаем цикл
   end;

    Res:=FindNext(FRec);//ищем след. файл
    if (ExtractFileExt(FRec.Name)=SearchExt) or (ExtractFileExt(FRec.Name)=SearchExt1)
    then begin
       count:=count+1;
       Memo1.Lines.Add('#'+inttostr(count));
       Memo1.Lines.Add(SearchDir+FRec.Name);
       //populate cdsFDup
       with cdsFDup do begin
        Append;
        FieldByName('FName').AsString:=FRec.Name;
        FieldByName('FSize').AsInteger:=FRec.Size;
        Post;
       end;
    end;

{w}end;

    FindClose(FRec);//освобождаем пересенную поиска
end;


procedure TfrmTextFilesList1.btnCheckDupClick(Sender: TObject);
var
mik,k1,k2,dup,fsize:integer;
fname:string;
begin

{
вот пример кода - создание listbox, добавление в него файла и убийство в конце
можно задать listbox1.Parent:=имя формы - так лучше будет, чем self

procedure TForm1.Button1Click(Sender: TObject);
var FRec:TSearchrec;
ListBox1:TListBox;
begin
listbox1:=Tlistbox.Create(Self);
try
listbox1.Visible:=false;
listbox1.Sorted:=True;
listbox1.Parent := Self;
ris:=findfirst('c:\*.*',faAnyFile,FRec);
while ris=0 do begin
listbox1.Items.Add(frec.name);
ris:=findnext(FRec);
end;
findclose(Frec);
finally
listbox1.free;
end;
end}

    if cdsCreated=false then begin
     showmessage ('Compleate the search first!');
     Exit;
    end;

   //populate listbox1
     memo1.Clear;
     mik:=0;
     cdsFDup.First;
{w}while not cdsFDup.Eof do begin
     mik:=mik+1;
     fname:=cdsFDup.FieldByName('FName').AsString;
     ListBox1.Items.Add(fname); //add fnames into listbox
     memo1.Lines.Add('#'+inttostr(mik)+#9+fname);
     cdsFdup.Next;
{w}end;
     Application.ProcessMessages;

   //find duplicates: external loop-listbox1, internal-cdsFDup
     memo1.Clear;
     mik:=0;
     dup:=0;
     cdsFDup.First;
{L}for k1:=0 to ListBox1.Count-1 do begin
     mik:=mik+1;
     fname:=ListBox1.Items.Strings[k1];

     cdsFDup.Filter:='Fname='+QuotedStr(fname);

     //showmessage('filter='+cdsFDup.Filter);
     cdsFDup.Filtered:=true;
     //showmessage('count='+inttostr(cdsFDup.RecordCount));

{f}if cdsFDup.RecordCount>1 then begin
     dup:=dup+1;
     memo1.Lines.Add('');
     memo1.Lines.Add('dup='+inttostr(dup));
{c}for k2:=1 to cdsFDup.RecordCount do begin
     fsize:=cdsFDup.FieldByName('fsize').AsInteger;
     memo1.Lines.Add(inttostr(k2)+' '+fname+#9+inttostr(fsize)+' byte');
     cdsFdup.Next;
{c}end;
     //clean duplicates in cds
     cdsFDup.Filtered:=false;
     cdsFDup.First;
{d}while not cdsFDup.Eof do begin
      if cdsFDup.FieldByName('fname').AsString=fname then cdsFDup.Delete;
      cdsFDup.Next;
{d}end;
{f}end;


{L}end;

     // cdsFDup.EmptyDataSet;
      cdsFDup.Free;
      cdsCreated:=false;

end;




end.
