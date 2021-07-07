unit SalinityFromConductivity;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Grids, DateUtils, ComObj{, ExcelXP};

type
  TfrmSalinityFromConductivity = class(TForm)
    btnOpenHDRFile: TBitBtn;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    StringGrid1: TStringGrid;
    StringGrid2: TStringGrid;
    Label1: TLabel;
    Label2: TLabel;
    btnConvert: TBitBtn;
    CheckBox1: TCheckBox;
    StringGrid3: TStringGrid;
    btnConvertRowData: TBitBtn;
    Label3: TLabel;
    Label4: TLabel;
    StringGrid4: TStringGrid;
    Label5: TLabel;
    RadioGroup1: TRadioGroup;
    Memo2: TMemo;
    CheckBox2: TCheckBox;
    Label6: TLabel;
    procedure btnOpenHDRFileClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnConvertClick(Sender: TObject);
    procedure btnConvertRowDataClick(Sender: TObject);
  private
    procedure GetCoeff(st:string; var cf1,cf2,cf3,cf4,cf5,cf6:real);
    procedure GetMDFromExcel(ARN:integer);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSalinityFromConductivity: TfrmSalinityFromConductivity;
  fname_hdr, fname_dat, fname_lst :string;
  f_hdr, f_dat, f_lst :text;

implementation

{$R *.lfm}

uses procedures;


procedure TfrmSalinityFromConductivity.FormShow(Sender: TObject);
begin
    memo1.Clear;
    memo2.Clear;
    with StringGrid1 do begin
     ColCount:=8;
     RowCount:=7;
     cells[0,0]:='Ch';
     cells[1,0]:='Parameter';
     cells[2,0]:='A';
     cells[3,0]:='a';
     cells[4,0]:='B';
     cells[5,0]:='b';
     cells[6,0]:='C';
     cells[7,0]:='D';
     cells[8,0]:='unit';

     cells[0,1]:='1';
     cells[0,2]:='2';
     cells[0,3]:='3';
     cells[0,4]:='4';
     cells[0,5]:='5';
     cells[0,6]:='6';

     cells[1,1]:='Ref';
     cells[1,2]:='Temp (deg C)';
     cells[1,3]:='Cond (mmho/cm)';
     cells[1,4]:='Press(MPa)/Temp';
     cells[1,5]:='Dir (deg)';
     cells[1,6]:='Speed (cm/sec)';

     ColWidths[0]:=50;
     ColWidths[1]:=100;

    end;

    with StringGrid2 do begin
     ColCount:=2;
     RowCount:=7;
     cells[0,0]:='Parameter';
     cells[0,1]:='RCM #';
     cells[0,2]:='Position';
     cells[0,3]:='RCM depth (m) ';
     cells[0,4]:='Time Int (min)';
     cells[0,5]:='Time start';
     cells[0,6]:='Rec First/Last';

     cells[1,0]:='value';
    end;

    //converted values
   with StringGrid3 do begin
     ColCount:=7;
     RowCount:=2;
     cells[0,0]:='RCM#';
     cells[1,0]:='Latitude';
     cells[2,0]:='Longitude';
     cells[3,0]:='RCM depth';
     cells[4,0]:='Time int';
     cells[5,0]:='Time start';
     cells[6,0]:='Archive Ref#';
   end;

    //catalog
   with StringGrid4 do begin
     ColCount:=15;
     RowCount:=2;
     cells[0,0]:='ID#';
     cells[1,0]:='Region';
     cells[2,0]:='ARN';
     cells[3,0]:='Start';
     cells[4,0]:='Stop';
     cells[5,0]:='PI';
     cells[6,0]:='Position';
     cells[7,0]:='Project';
     cells[8,0]:='Archive';
     cells[9,0]:='BDep';
     cells[10,0]:='Rigg';
     cells[11,0]:='RNum';
     cells[12,0]:='RDep';
     cells[13,0]:='Year';
     cells[14,0]:='Place';
   end;

   StringGrid4.ColWidths[0]:=30;
   StringGrid4.ColWidths[2]:=30;
   StringGrid4.ColWidths[5]:=100;
   StringGrid4.ColWidths[6]:=150;
   StringGrid4.ColWidths[7]:=100;
   StringGrid4.ColWidths[8]:=120;
   StringGrid4.ColWidths[9]:=40;
   StringGrid4.ColWidths[11]:=40;
   StringGrid4.ColWidths[12]:=45;
   StringGrid4.ColWidths[13]:=30;
   StringGrid4.ColWidths[14]:=100;

end;



procedure TfrmSalinityFromConductivity.GetCoeff(st:string; var cf1,cf2,cf3,cf4,cf5,cf6:real);
var
i, mik :integer;
s1, s2 :char;
v :array[1..100] of integer;
begin

//showmessage(st);
    st:=trim(st); st:=st+' ';
    i:=1;
    v[1]:=1;
    mik:=1;
   for i:=1 to length(st) do begin
    s1:=st[i];
    s2:=st[i+1];
    if (s1<>' ') and (s2=' ') then begin mik:=mik+1; v[mik]:=i;  end;
    if (s1=' ') and (s2<>' ') then begin mik:=mik+1; v[mik]:=i+1; end;
   end;

//for i:=1 to 14 do showmessage(inttostr(i)+'   '+inttostr(v[i]));
//showmessage(copy(st,1,v[2]));
//showmessage(copy(st,v[3],v[4]-v[3]+1));
//showmessage(copy(st,v[5],v[6]-v[5]+1));
//showmessage(copy(st,v[7],v[8]-v[7]+1));
//showmessage(copy(st,v[9],v[10]-v[9]+1));
//showmessage(copy(st,v[11],v[12]-v[11]+1));

    cf1:= strtofloat(copy(st,1,v[2]));

    cf2:= strtofloat(copy(st,v[3],v[4]-v[3]+1));
    cf3:= strtofloat(copy(st,v[5],v[6]-v[5]+1));
    cf4:= strtofloat(copy(st,v[7],v[8]-v[7]+1));
    cf5:= strtofloat(copy(st,v[9],v[10]-v[9]+1));
    cf6:= strtofloat(copy(st,v[11],v[12]-v[11]+1));


end;



procedure TfrmSalinityFromConductivity.btnOpenHDRFileClick(Sender: TObject);
var
i, mik :integer;
RCM_num, RCM_depth, time_int :integer;
rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed :integer;  //row data in engineearing units

temp_a1,temp_a2,temp_b1,temp_b2,temp_c,temp_d :real;
cond_a1,cond_a2,cond_b1,cond_b2,cond_c,cond_d :real;
press_a1,press_a2,press_b1,press_b2,press_c,press_d :real;
dir_a1,dir_a2,dir_b1,dir_b2,dir_c,dir_d :real;
speed_a1,speed_a2,speed_b1,speed_b2,speed_c,speed_d :real;

sym:char;
st, time_start, recFL :string;
pos :string[20];
begin

    memo1.Clear;
    memo2.Clear;

    label1.Visible:=false;
    label2.Visible:=false;
    label3.Visible:=false;
    label4.Visible:=false;
    label5.Visible:=false;

    stringgrid1.Visible:=false;
    stringgrid2.Visible:=false;
    stringgrid3.Visible:=false;
    stringgrid4.Visible:=false;

    btnConvert.Visible:=false;
    btnConvertRowData.Visible:=false;

    Radiogroup1.Visible:=false;

    OpenDialog1.InitialDir:='d:\data\Currents\GFI\';
    if OpenDialog1.Execute then
     fname_hdr:=OpenDialog1.FileName
     else begin
     showmessage('File not selected!');
     Exit;
     end;


    // position 11 symbols
    //fname_hdr:='c:\data\Currents\GFI\STROMDATAARKIV-100-001\003-ark-Weddellhavet\Weddell-1978-c\03149.hdr';
    //fname_hdr:='c:\data\Currents\GFI\STROMDATAARKIV-100-001\003-ark-Weddellhavet\Weddell-1978-c\03148.hdr';

    // position 13 symbols
    //fname_hdr:='c:\data\Currents\GFI\STROMDATAARKIV-100-001\007-ark-Feie-Shetland\3150.hdr';

    // position 15 symbols
    //fname_hdr:='c:\data\Currents\GFI\STROMDATAARKIV-100-001\004-ark-Egeroy\Egerøy3\2015.hdr';

    fname_dat:=ChangeFileExt(fname_hdr, '.dat');
    fname_lst:=ChangeFileExt(fname_hdr, '.lst');

    if fileexists(fname_dat)=false then showmessage(fname_dat+' does not exist!');
    if fileexists(fname_lst)=false then showmessage(fname_lst+' does not exist!');


    memo1.Lines.Add(fname_hdr);
    memo1.Lines.Add(fname_dat);
    memo2.Lines.Add(extractfilename(fname_lst));

    assignfile(f_hdr, fname_hdr);
    reset(f_hdr);
    assignfile(f_dat, fname_dat);
    reset(f_dat);

   if fileexists(fname_lst)=true then begin
    assignfile(f_lst, fname_lst);
    reset(f_lst);
   end;

    //show first two lines from .dat
                      memo1.Lines.Add('//first two lines from .dat file  (ref temp cond press/temp dir speed)');
    readln(f_dat,st); memo1.Lines.Add(st);
    readln(f_dat,st); memo1.Lines.Add(st);
    closefile(f_dat);

{L}if CheckBox2.Checked then begin

   if fileexists(fname_lst)=true then begin
    readln(f_lst,st);   //two lines with MD
    memo2.Lines.Add(trim(st));
    readln(f_lst,st);
    memo2.Lines.Add(#9+trim(st));
   end;

    mik:=0;
{e}if fileexists(fname_lst)=true then begin
//{w}while not EOF(f_lst) do begin
   for i:=1 to 50 do begin
    mik:=mik+1;
    readln(f_lst,st);
    memo2.Lines.Add(inttostr(mik)+#9+trim(st));
{w}end;
    closefile(f_lst);
{e}end;
{L}end;


    //read hdr
{h}for i:=1 to 12 do begin
   case i of
   1: begin // instrument number
       readln(f_hdr,st);
       RCM_num  :=strtoint(trim(copy(st,1,20)));
      end;
   2: begin //position
       readln(f_hdr,st);
       pos:=trim(copy(st,1,20));
      end;
   3: begin //instrument depth
       readln(f_hdr,st);
       RCM_depth:=strtoint(trim(copy(st,1,20)));
      end;
   4: begin //sampling interval
       readln(f_hdr,st);
       time_int:=strtoint(trim(copy(st,1,20)));
      end;
   5: begin //time start
       readln(f_hdr,st);
       time_start:=trim(copy(st,1,20));
      end;
   6: begin //record number first and last
       readln(f_hdr,st);
       recFL:=trim(copy(st,1,20));
      end;
   7: begin //temp coefficients
       readln(f_hdr,st);
       GetCoeff(st,temp_a1,temp_a2,temp_b1,temp_b2,temp_c,temp_d);
       memo1.Lines.Add('... temp coef ... ok')
      end;
   8: begin //cond coefficients
       readln(f_hdr,st);
       GetCoeff(st,cond_a1,cond_a2,cond_b1,cond_b2,cond_c,cond_d);
       memo1.Lines.Add('... cond coef ... ok')
      end;
   9: begin //press coefficients
       readln(f_hdr,st);
       GetCoeff(st,press_a1,press_a2,press_b1,press_b2,press_c,press_d);
       memo1.Lines.Add('... press/temp coef ... ok')
      end;
   10: begin //direction coefficients
       readln(f_hdr,st);
       GetCoeff(st,dir_a1,dir_a2,dir_b1,dir_b2,dir_c,dir_d);
       memo1.Lines.Add('... dir coef ... ok')
      end;
   11: begin //speed coefficients
       readln(f_hdr,st);
       GetCoeff(st,speed_a1,speed_a2,speed_b1,speed_b2,speed_c,speed_d);
       memo1.Lines.Add('... speed coef ... ok')
      end;

   end; {case}
{h}end;
    closefile(f_hdr);



{G2}with StringGrid2 do begin
     cells[1,1]:=inttostr(RCM_num);
     cells[1,2]:=pos;
     cells[1,3]:=inttostr(RCM_depth);
     cells[1,4]:=inttostr(time_int);
     cells[1,5]:=time_start;
     cells[1,6]:=recFL;
{G1}end;

//showmessage('temp_a1='+floattostr(temp_a1));
      //coefficients
{G1}with StringGrid1 do begin
     //temp
     cells[2,2]:=floattostr(temp_a1);
     cells[3,2]:=floattostr(temp_a2);
     cells[4,2]:=floattostr(temp_b1);
     cells[5,2]:=floattostr(temp_b2);
     cells[6,2]:=floattostr(temp_c);
     cells[7,2]:=floattostr(temp_d);
     //cond
     cells[2,3]:=floattostr(cond_a1);
     cells[3,3]:=floattostr(cond_a2);
     cells[4,3]:=floattostr(cond_b1);
     cells[5,3]:=floattostr(cond_b2);
     cells[6,3]:=floattostr(cond_c);
     cells[7,3]:=floattostr(cond_d);
     //press
     cells[2,4]:=floattostr(press_a1);
     cells[3,4]:=floattostr(press_a2);
     cells[4,4]:=floattostr(press_b1);
     cells[5,4]:=floattostr(press_b2);
     cells[6,4]:=floattostr(press_c);
     cells[7,4]:=floattostr(press_d);
     //current direction
     cells[2,5]:=floattostr(dir_a1);
     cells[3,5]:=floattostr(dir_a2);
     cells[4,5]:=floattostr(dir_b1);
     cells[5,5]:=floattostr(dir_b2);
     cells[6,5]:=floattostr(dir_c);
     cells[7,5]:=floattostr(dir_d);
     //current speed
     cells[2,6]:=floattostr(speed_a1);
     cells[3,6]:=floattostr(speed_a2);
     cells[4,6]:=floattostr(speed_b1);
     cells[5,6]:=floattostr(speed_b2);
     cells[6,6]:=floattostr(speed_c);
     cells[7,6]:=floattostr(speed_d);

{G1}end;


    //read row data from .dat should be allways six columns
{c}if CheckBox1.Checked=true then begin

    reset(f_dat);
    mik:=0;
{w}while not EOF(f_dat)do begin
    readln(f_dat, rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed);
    mik:=mik+1;
    memo1.Lines.Add(inttostr(mik)
     +#9+inttostr(rd_ref)
     +#9+inttostr(rd_temp)
     +#9+inttostr(rd_cond)
     +#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)
     +#9+inttostr(rd_speed));
{w}end;
    closefile(f_dat);
{c}end;



    label1.Visible:=true;
    label2.Visible:=true;
    btnConvert.Visible:=true;
    StringGrid1.Visible:=true;
    StringGrid2.Visible:=true;
    if CheckBox1.Checked=true then Memo1.Visible:=true;
    label6.Visible:=false;


end;


procedure TfrmSalinityFromConductivity.btnConvertClick(Sender: TObject);
var
i, p1, p2, ARN :integer;
my, mm, md, mh, mmin, ms, mms :word;
lat, lon, lat_deg, lat_min, lon_deg, lon_min:real;
lt_sym, ln_sym:char;
st, lt_st, ln_st, p_deg, p_min :string;
mtime_beg :TDateTime;
begin

//convert RCM #
    st:=trim(StringGrid2.Cells[1,1]);
    StringGrid3.Cells[0,1]:=st;

//convert coordinataes  assume that lat the first lon the second
    st:=trim(StringGrid2.Cells[1,2]);
    for i:=1 to length(st) do begin
     if (st[i]='N') or (st[i]='S') or (st[i]='n') or (st[i]='s') then begin
       p1:=i; lt_sym:=st[i];
     end;
     if (st[i]='E') or (st[i]='W')or (st[i]='e') or (st[i]='w') then begin
       p2:=i; ln_sym:=st[i];
     end;
    end;
    //showmessage('p1 p2 '+ inttostr(p1)+'   '+inttostr(p2));

    //if latitude symbol at the first position
{1}if p1=1 then begin

    //showmessage('string length for position: '+inttostr(length(st)));
    //if (length(st) <> 13) and (length(st) <> 15) then showmessage('New format position');
    //  ex.3 N6249335E00417415    Position (15 character)
     lt_st:=copy(st,2, p2-2); //5 symbols
     //showmessage('lt_st '+lt_st);
      p_deg:=copy(lt_st,1,2);
      p_min:=copy(lt_st,3,length(lt_st));
     lat_deg:=strtofloat(p_deg);
     lat_min:=strtofloat(p_min);
     if length(p_min)=3 then lat_min:=lat_min/10;  //add decimals
     if length(p_min)=4 then lat_min:=lat_min/100;
     if length(p_min)=5 then lat_min:=lat_min/1000;
     lat_min:=Lat_min/60; //convert min to deg
     lat:=lat_deg+lat_min;
     if (lt_sym='S') or (lt_sym='s') then lat:=-lat;

     ln_st:=copy(st,p2+1,length(st)-p2);  //6 symbols
     //showmessage('ln_st '+ln_st);
      p_deg:=copy(ln_st,1,3); //3 symbols
      p_min:=copy(ln_st,4,length(ln_st));
     lon_deg:=strtofloat(p_deg);
     lon_min:=strtofloat(p_min);
     if length(p_min)=3 then lon_min:=lon_min/10;  //add decimals
     if length(p_min)=4 then lon_min:=lon_min/100;
     if length(p_min)=5 then lon_min:=lon_min/1000;
     lon_min:=Lon_min/60; //convert min to deg
     lon:=lon_deg+lon_min;
     if (ln_sym='W') or (ln_sym='w') then lon:=-lon;

{1}end;

    //if not starts from latitude simbol
{2}if p1<>1 then begin

    if length(st)<> 11 then  showmessage('New format position');

     lt_st:=copy(st,1, p1-1);
     //showmessage('lt_st '+lt_st);
     if length(lt_st) = 4 then begin //if deg and min
      p_deg:=copy(lt_st,1,2);
      p_min:=copy(lt_st,3,2);
     end;

     lat_deg:=strtofloat(p_deg);
     lat_min:=strtofloat(p_min);
     lat_min:=Lat_min/60; //convert min to deg
     lat:=lat_deg+lat_min;
     if (lt_sym='S') or (lt_sym='s') then lat:=-lat;

     ln_st:=copy(st,p1+1,p2-p1-1);
     //showmessage('ln_st '+ln_st);
     if length(ln_st) = 5 then begin //if deg and min
      p_deg:=copy(ln_st,1,3);
      p_min:=copy(ln_st,4,2);
     end;

     lon_deg:=strtofloat(p_deg);
     lon_min:=strtofloat(p_min);
     lon_min:=lon_min/60; //convert min to deg
     lon:=lon_deg+lon_min;
     if (ln_sym='W') or (ln_sym='w') then lon:=-lon;
{2}end;


    StringGrid3.Cells[1,1]:=FloatToStrF(lat,fffixed,8,5);
    StringGrid3.Cells[2,1]:=FloatToStrF(lon,fffixed,9,5);


//convert RCM depth
    st:=trim(StringGrid2.Cells[1,3]);
    StringGrid3.Cells[3,1]:=st;


//convert time start
    st:=trim(StringGrid2.Cells[1,5]);
    //showmessage('time: '+st);
    //showmessage('length: '+inttostr(length(st)));
    if length(st)<>14 then showmessage('... time wrong format');
    my:=strtoint(copy(st,1,2));
    if my<20 then my:=my+2000 else my:=my+1900;
    mm:=strtoint(copy(st,4,2));
    md:=strtoint(copy(st,7,2));
    mh:=strtoint(copy(st,10,2));
    mmin:=strtoint(copy(st,13,2));
    ms:=0;
    mms:=0;

    mtime_beg := EncodeDateTime(my,mm,md,mh,mmin,ms,mms);
    StringGrid3.Cells[5,1]:=DateTimeToStr(mtime_beg);

    StringGrid3.Visible:=true;


//convert time interval currents sampling
    StringGrid3.Cells[4,1]:=trim(StringGrid2.Cells[1,4]);



//convert Archive Reference number link to xls file
// ex fname_hdr:='c:\data\Currents\GFI\STROMDATAARKIV-100-001\007-ark-Feie-Shetland\3150.hdr';

    st:= trim(copy(fname_dat,45,3)); //ALWAYS 3-digits position in the file name
    ARN:=strtoint(st);               //Archive Reference Number
    StringGrid3.Cells[6,1]:=inttostr(ARN);

    GetMDFromExcel(ARN);

    btnConvertRowData.Visible:=true;
    Radiogroup1.Visible:=true;

end;


procedure TfrmSalinityFromConductivity.GetMDFromExcel(ARN:integer);
var
c, mik :integer;
y, m, d, h, min, s, ms :word;
xls_id, xls_ARN, d1, d2 :integer;
xls_reg, xls_start, xls_stop, xls_PI, xls_pos, xls_Project, xls_ArchiveName :string;
xls_BotDepth, xls_rigg, xls_InstN, xls_InstDepth, xls_Year, xls_Place :string;
XL: Variant;
FoundInCatalog, DateIsValid :boolean;
date_xls, date_hdr :TDateTime;
begin

    //showmessage('ARN='+'  '+inttostr(ARN));
    FoundInCatalog:=false;
    memo1.Lines.Add('');
    memo1.Lines.Add('searching of the mooring CATALOG ...');

 XL := CreateOleObject('Excel.Application');
 XL.WorkBooks.Add('d:\data\Currents\GFI\strømdata.xlsx'); //имя файла

    mik:=0; //number of moorings found
    c:=2;   //счетчик строк
{x}repeat
{1}if trim(vartostr(Xl.Cells[c,1]))<>'' then begin //если первая строчка не пустая
     xls_id           :=Xl.Cells[c,1];
     xls_reg          :=Xl.Cells[c,2];
     xls_ARN          :=Xl.Cells[c,3];
     xls_start        :=trim(Xl.Cells[c,4]);
     xls_stop         :=Xl.Cells[c,5];
     xls_PI           :=Xl.Cells[c,6];
     xls_pos          :=Xl.Cells[c,7];
     xls_Project      :=Xl.Cells[c,8];
     xls_ArchiveName  :=Xl.Cells[c,9];
     xls_BotDepth     :=Xl.Cells[c,10];
     xls_rigg         :=Xl.Cells[c,11];
     xls_InstN        :=Xl.Cells[c,12];
     xls_InstDepth    :=Xl.Cells[c,13];
     xls_Year         :=Xl.Cells[c,14];
     xls_Place        :=Xl.Cells[c,15];

     if xls_InstDepth<>'' then d1:=strtoint(xls_InstDepth);         //RCM depth catalog
                               d2:=strtoint(StringGrid3.Cells[3,1]);//RCM depth conv from .hdr
//if (xls_ARN=ARN) then showmessage (inttostr(d1)+' -> '+inttostr(d2));


    //compare date from .hdr and date from catalog
    date_xls:=strtodate('10.03.1960');
    date_xls:=strtodate('12.02.1997');
    if (length(xls_start)=6) or (length(xls_start)=8) then DateIsValid:=true
                                                      else DateIsValid:=false;

    //memo1.lines.add(inttostr(xls_ID)+#9+xls_start);

{d}if DateIsValid=true then begin
    //1. convert date from catalog to date format
    if length(xls_start)=6 then begin
     y:=strtoint(copy(xls_start,1,2));  if y>30 then y:=1900+y else y:=2000+y;
     m:=strtoint(copy(xls_start,3,2));
     d:=strtoint(copy(xls_start,5,2));
     date_xls:=EncodeDate(y,m,d);
    end;
    if length(xls_start)=8 then begin
     y:=strtoint(copy(xls_start,1,4));
     m:=strtoint(copy(xls_start,5,2));
     d:=strtoint(copy(xls_start,7,2));
     date_xls:=EncodeDate(y,m,d);
    end;
    //2. extract date from converted datatime
    DecodeDateTime(StrToDateTime(StringGrid3.Cells[5,1]),y,m,d,h,min,s,ms);
    date_hdr:=EncodeDate(y,m,d);
    //memo1.Lines.Add(inttostr(c)+#9+inttostr(xls_id)+#9+datetostr(date_xls)+'   '+datetostr(date_hdr));
{d}end;


    //search in CATALOG by archive number   RCM depth   Start date
{A}if (xls_ARN=ARN) and (d1=d2) and (date_xls=date_hdr) then begin

    mik:=mik+1;

    memo1.Lines.Add('');
    memo1.Lines.Add('ID         : '+inttostr(xls_id));
    memo1.Lines.Add('Region     : '+xls_reg);
    memo1.Lines.Add('ArchiveRef : '+inttostr(xls_ARN));
    memo1.Lines.Add('Start      : '+xls_start);
    memo1.Lines.Add('Stop       : '+xls_stop);
    memo1.Lines.Add('PI         : '+xls_PI);
    memo1.Lines.Add('pos        : '+xls_pos);
    memo1.Lines.Add('Project    : '+xls_Project);
    memo1.Lines.Add('ArchiveName: '+xls_ArchiveName);
    memo1.Lines.Add('BotDepth   : '+xls_BotDepth);
    memo1.Lines.Add('rigg       : '+xls_rigg);
    memo1.Lines.Add('InstN      : '+xls_InstN);
    memo1.Lines.Add('InstDepth  : '+xls_InstDepth);
    memo1.Lines.Add('Year       : '+xls_Year);
    memo1.Lines.Add('Place      : '+xls_Place);

    StringGrid4.Cells[0,1]:=inttostr(xls_id);
    StringGrid4.Cells[1,1]:=xls_reg;
    StringGrid4.Cells[2,1]:=inttostr(xls_ARN);
    StringGrid4.Cells[3,1]:=xls_start;
    StringGrid4.Cells[4,1]:=xls_stop;
    StringGrid4.Cells[5,1]:=xls_PI;
    StringGrid4.Cells[6,1]:=xls_pos;
    StringGrid4.Cells[7,1]:=xls_Project;
    StringGrid4.Cells[8,1]:=xls_ArchiveName;
    StringGrid4.Cells[9,1]:=xls_BotDepth;
    StringGrid4.Cells[10,1]:=xls_rigg;
    StringGrid4.Cells[11,1]:=xls_InstN;
    StringGrid4.Cells[12,1]:=xls_InstDepth;
    StringGrid4.Cells[13,1]:=xls_Year;
    StringGrid4.Cells[14,1]:=xls_Place;

    label4.Visible:=true;
    label5.Visible:=true;
    StringGrid4.Visible:=true;

    FoundInCatalog:=true;
{A}end;

    inc(c); // берем следующую строчку
{1}end;
{x}until trim(vartostr(Xl.Cells[c,1]))='';

    XL.Quit; //закрываем Эксель

    if FoundInCatalog=false then memo1.Lines.Add('... Mooring is not found in CATALOG');

    Label6.Visible:=true;
    Label6.Caption:='Number of moorings found in catalog (RCM num, start, depth): '+inttostr(mik);

end;



procedure TfrmSalinityFromConductivity.btnConvertRowDataClick(Sender: TObject);
var
i, mik :integer;
rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed :integer;
mt_inc :integer;
temp, cond, salt, press, dir, speed :real;
R_STP, R_ST, R_S, RCM_depth, F, p, rt, t100, lat, t24 :real;
st :string;
ab_nil :boolean;
mt, RStart :TDateTime;
begin


    memo1.Lines.Add('');
    memo1.Lines.Add('#           Ref#          temp        cond         p/t          dir           speed        d(m)      d(dbar)        salt          time');

    //detect conversion equestion from coefficients
    ab_nil:=true;
   for i:=2 to 6 do begin
    if strtofloat(StringGrid1.Cells[3,i])<>0 then ab_nil:=false;
    if strtofloat(StringGrid1.Cells[5,i])<>0 then ab_nil:=false;
   end;
    if ab_nil=true then label3.Caption:='val = A + B*N + C*N2 +D*N3'
                   else label3.Caption:='val = (A+a) + (B+b)*N + C*N2 +D*N3';


    label3.Visible:=true;

    reset(f_dat);
    RStart:=strtodatetime(StringGrid3.Cells[5,1]);  //time start
    mt_inc:=strtoint(StringGrid3.Cells[4,1]);   //samples interval in minutes
    mik:=0;
{w}while not EOF(f_dat)do begin
//{w}for i:=1 to 50 do begin

    readln(f_dat, rd_ref, rd_temp, rd_cond, rd_press, rd_dir, rd_speed);

{7}if rd_ref<>7 then begin  //skip records marked 0007 time not counted

    mik:=mik+1;
    mt := RStart+(mt_inc*(mik-1))/1440;


{Eq1}if ab_nil=true then begin
      temp:= strtofloat(StringGrid1.Cells[2,2])
           + strtofloat(StringGrid1.Cells[4,2])*rd_temp
           + strtofloat(StringGrid1.Cells[6,2])*rd_temp*rd_temp
           + strtofloat(StringGrid1.Cells[7,2])*rd_temp*rd_temp*rd_temp;

      if rd_cond <> 0 then
      cond:= strtofloat(StringGrid1.Cells[2,3])
           + strtofloat(StringGrid1.Cells[4,3])*rd_cond
           + strtofloat(StringGrid1.Cells[6,3])*rd_cond*rd_cond
           + strtofloat(StringGrid1.Cells[7,3])*rd_cond*rd_cond*rd_cond
                      else cond:=-9;

      if rd_press<>1023 then
      press:=strtofloat(StringGrid1.Cells[2,4])
           + strtofloat(StringGrid1.Cells[4,4])*rd_press
           + strtofloat(StringGrid1.Cells[6,4])*rd_press*rd_press
           + strtofloat(StringGrid1.Cells[7,4])*rd_press*rd_press*rd_press
                        else press:=-9;

       dir:= strtofloat(StringGrid1.Cells[2,5])
           + strtofloat(StringGrid1.Cells[4,5])*rd_dir
           + strtofloat(StringGrid1.Cells[6,5])*rd_dir*rd_dir
           + strtofloat(StringGrid1.Cells[7,5])*rd_dir*rd_dir*rd_dir;

      speed:=strtofloat(StringGrid1.Cells[2,6])
           + strtofloat(StringGrid1.Cells[4,6])*rd_speed
           + strtofloat(StringGrid1.Cells[6,6])*rd_speed*rd_speed
           + strtofloat(StringGrid1.Cells[7,6])*rd_speed*rd_speed*rd_speed;
{Eq1}end;


     // A+a B+b
{Eq2}if ab_nil=false then begin
      temp:= strtofloat(StringGrid1.Cells[2,2])  + strtofloat(StringGrid1.Cells[3,2])
           +(strtofloat(StringGrid1.Cells[4,2])  + strtofloat(StringGrid1.Cells[5,2]))*rd_temp
           + strtofloat(StringGrid1.Cells[6,2])*rd_temp*rd_temp
           + strtofloat(StringGrid1.Cells[7,2])*rd_temp*rd_temp*rd_temp;
      //showmessage('temp='+floattostr(temp));

      if rd_cond <> 0 then
      cond:= strtofloat(StringGrid1.Cells[2,3])  + strtofloat(StringGrid1.Cells[3,3])
           +(strtofloat(StringGrid1.Cells[4,3])  + strtofloat(StringGrid1.Cells[5,3]))*rd_cond
           + strtofloat(StringGrid1.Cells[6,3])*rd_cond*rd_cond
           + strtofloat(StringGrid1.Cells[7,3])*rd_cond*rd_cond*rd_cond
                      else cond:=-9;
      //showmessage('cond='+floattostr(cond));

      if rd_press<>1023 then
      press:=strtofloat(StringGrid1.Cells[2,4]) + strtofloat(StringGrid1.Cells[3,4])
           +(strtofloat(StringGrid1.Cells[4,4]) + strtofloat(StringGrid1.Cells[5,4]))*rd_press
           + strtofloat(StringGrid1.Cells[6,4])*rd_press*rd_press
           + strtofloat(StringGrid1.Cells[7,4])*rd_press*rd_press*rd_press
                        else press:=-9;
      //showmessage('press='+floattostr(press));

       dir:= strtofloat(StringGrid1.Cells[2,5]) +  strtofloat(StringGrid1.Cells[3,5])
           +(strtofloat(StringGrid1.Cells[4,5]) +  strtofloat(StringGrid1.Cells[5,5]))*rd_dir
           + strtofloat(StringGrid1.Cells[6,5])*rd_dir*rd_dir
           + strtofloat(StringGrid1.Cells[7,5])*rd_dir*rd_dir*rd_dir;
      //showmessage('dir='+floattostr(temp));

      speed:=strtofloat(StringGrid1.Cells[2,6]) + strtofloat(StringGrid1.Cells[3,6])
           +(strtofloat(StringGrid1.Cells[4,6]) + strtofloat(StringGrid1.Cells[5,6]))*rd_speed
           + strtofloat(StringGrid1.Cells[6,6])*rd_speed*rd_speed
           + strtofloat(StringGrid1.Cells[7,6])*rd_speed*rd_speed*rd_speed;
      //showmessage('speed='+floattostr(temp));

{Eq2}end;



       //temp selection for conversion
       if RadioGroup1.ItemIndex=0 then t24:=temp;
       if RadioGroup1.ItemIndex=1 then t24:=press;

    salt:=-9;
{c}if cond<>-9 then begin
    //conductivity -> salinity   Technical Description N159 March 1990 p.6-06
    //1. in situ cond -> conductivity ratio (cond_R)
    R_STP:= cond/42.914;

    //2. correction for effect of pressure
    RCM_depth:=strtofloat(StringGrid3.Cells[3,1]);
    lat:=strtofloat(StringGrid3.Cells[1,1]);
       //convert depth to pressure later: rcm-depth latitude m parameter pressure
       //m=0 depth to pressure   m=1 pressure to depth
       Depth_to_Pressure(RCM_depth,lat,0,p);

    F:=(1.60836e-5*p - 5.4845e-10*p*p + 6.166e-15*p*p*p)/(1 + 3.0786e-2*t24 + 3.169e-4*t24*t24);
    R_ST:=R_STP/(1 + F);

    //3. correction for effect of temperature
      t100:=t24/100;
    rt := 0.6765836 + 2.005294*t100
          + 1.11099*t100*t100
          - 0.726684*t100*t100*t100
          + 0.13587*t100*t100*t100*t100;
    R_S:=R_ST/rt;

    //4. conversion to salinity
    salt:= -0.08996 + 28.8567*R_S + 12.18882*R_S*R_S - 10.61869*R_S*R_S*R_S
           + 5.98624*R_S*R_S*R_S*R_S
           - 1.32311*R_S*R_S*R_S*R_S*R_S
           + R_S*(R_S-1)*(0.0442*t24 - 0.46e-3*t24*t24 - 4e-3*R_S*t24
           + (1.25e-4 - 2.9e-6*t24)*p);
{c}end;

    //.dat
    memo1.Lines.Add(inttostr(mik) +' .dat'
     +#9+inttostr(rd_ref)
     +#9+inttostr(rd_temp)
     +#9+inttostr(rd_cond)
     +#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)
     +#9+inttostr(rd_speed));
    //converted
    memo1.Lines.Add(inttostr(mik) +' conv'
     +#9+inttostr(rd_ref)
     +#9+floattostrF(temp,ffFixed,6,3)
     +#9+floattostrF(cond,ffFixed,6,3)
     +#9+floattostrF(press,ffFixed,6,3)
     +#9+floattostrF(dir,ffFixed,6,1)
     +#9+floattostrF(speed,ffFixed,6,2)
     +#9+floattostrF(RCM_depth,ffFixed,6,1)
     +#9+floattostrF(p,ffFixed,6,1)
     +#9+floattostrF(salt,ffFixed,6,3)
     +#9+datetimetostr(mt)
     );

{7}end;
{w}end;

    closefile(f_dat);

end;




end.
