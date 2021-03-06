unit osmap_kml;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLIntf, Dialogs, mmain, msettings, dm;

  procedure ExportKML_;


implementation


procedure ExportKML_;
Var
f_out:text;
ID:Integer;
datafile, descr, coord, sep: string;
Lat1, Lon1 :real;
Dat1:TDateTime;
begin
 if not DirectoryExists(GlobalUnloadPath+'kml'+PathDelim) then
    CreateDir(GlobalUnloadPath+'kml'+PathDelim);

 DataFile:=GlobalUnloadPath+'kml'+PathDelim+'stations.kml';

 try
  AssignFile(f_out, DataFile); rewrite(f_out);

  Writeln(f_out, '<?xml version="1.0" encoding="UTF-8"?>');
  Writeln(f_out, '<kml xmlns="http://earth.google.com/kml/2.2">');
  Writeln(f_out, ' <Document>');
  Writeln(f_out, '   <Style id="hideLabel">');
  Writeln(f_out, '    <BalloonStyle>');
  Writeln(f_out, '      <text><![CDATA[');
  Writeln(f_out, '      <p><b>ID=<font color="red">$[name]</b></font></p>]]>');
  Writeln(f_out, '       $[description]');
  Writeln(f_out, '       </text>');
  Writeln(f_out, '    </BalloonStyle>');
  Writeln(f_out, '    <IconStyle>');
  Writeln(f_out, '      <color>#FF0000FF</color>');
  Writeln(f_out, '      <scale>0.5</scale>');
  Writeln(f_out, '      <Icon><href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href></Icon>');
  Writeln(f_out, '    </IconStyle>');
  Writeln(f_out, '    <LabelStyle>');
  Writeln(f_out, '     <scale>0</scale>');
  Writeln(f_out, '    </LabelStyle>');
  Writeln(f_out, '   </Style>');

  sep:=' &lt;br/&gt;';

  try
  frmdm.Q.DisableControls;
  frmdm.Q.First;
  while not frmdm.Q.EOF do begin
     ID  :=frmdm.Q.FieldByName('ABSNUM').AsInteger;
     lat1:=frmdm.Q.FieldByName('M_LAT').AsFloat;
     lon1:=frmdm.Q.FieldByName('M_LON').AsFloat;
     dat1:=frmdm.Q.FieldByName('M_TIMEBEG').AsDateTime;

       descr:='Latitude = '  +FloattostrF(Lat1, fffixed, 8, 5) +sep+
              'Longitude = ' +FloattostrF(Lon1, fffixed, 9, 5) +sep+
              'StartDate = ' +DateTimeToStr(dat1);

       coord:=Floattostr(Lon1)+', '+Floattostr(Lat1);

       Writeln(f_out, '   <Placemark>');
       Writeln(f_out, '    <name>'+inttostr(ID)+'</name>');
       Writeln(f_out, '    <styleUrl>#hideLabel</styleUrl>');
       Writeln(f_out, '    <description>'+descr+'</description>');
       Writeln(f_out, '     <Point>');
       Writeln(f_out, '      <coordinates>'+coord+', 0</coordinates>');
       Writeln(f_out, '     </Point>');
       Writeln(f_out, '   </Placemark>');

     frmdm.Q.Next;
  end;
  finally
   frmdm.Q.EnableControls;
  end;

 Finally
  Writeln(f_out, ' </Document>');
  Writeln(f_out, '</kml>');
  Closefile(f_out);
  OpenDocument(DataFile);
 end;
end;

end.

