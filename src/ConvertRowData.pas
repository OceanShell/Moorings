unit ConvertRowData;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, {DBGridEhGrouping, ToolCtrlsEh, DBGridEhToolCtrls, DynVarsEh, GridsEh,
  DBAxisGridsEh, DBGridEh,} StdCtrls, Buttons;

type
  TfrmConvertRowData = class(TForm)
   // DBGridEh1: TDBGridEh;
   // DBGridEh2: TDBGridEh;
    btnConvertAll: TBitBtn;
    Memo1: TMemo;
    btnEmptyTableCurrents: TBitBtn;
    CheckBox1: TCheckBox;
    procedure btnConvertAllClick(Sender: TObject);
    procedure btnEmptyTableCurrentsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmConvertRowData: TfrmConvertRowData;

implementation

{$R *.lfm}

uses DM, Procedures;

procedure TfrmConvertRowData.btnConvertAllClick(Sender: TObject);
var
k,mik: integer;
absnum,RCMnum,mqfl,temp_ch,RCMDepth: integer;
CH1,CH2,CH3,CH4,CH5,CH6,CH7,CH8,CH9: integer;
rd_temp,rd_cond,rd_press,rd_dir,rd_speed,rd_turb,rd_oxy,rd_xxx,rd_QFL: integer;
RecNum: integer;

temp,t24,cond,salt,press,dir,speed,turb,oxy,xxx: real;
RCMLat: real;
TA,TB,TC,TD,CA,CB,CC,CD,PA,PB,PC,PD,DA,DB,DC,DD: real;
SA,SB,SC,SD,UA,UB,UC,UD,OA,OB,OC,OD,XA,XB,XC,XD: real;

R_STP, R_ST, R_S, F, p, rt, t100 :real;

sensors: string[9];
rec_time, stop: TDateTime;

begin

     memo1.Clear;
     memo1.Visible:=true;

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

   //read row data
   with frmdm.ib1q2 do begin
     Close;
     sql.Clear;
     SQL.Add(' SELECT * FROM ROWDATA  ');
     SQL.Add(' WHERE ');
     SQL.Add(' ABSNUM=:ABSNUM ');
     SQL.Add(' ORDER BY RD_TIME ');
     Prepare;
   end;

   //insert converted data varuables(7) Qflags (6)
   //variables: angle speed temperature salinity pressure turbidity oxygen
   //flags:     current     temperature salinity pressure turbidity oxygen
   with frmDM.ib1q3 do begin
    Close;
    SQL.Clear;
    SQL.Add(' INSERT INTO CURRENTS ');
    SQL.Add(' (ABSNUM, C_TIME, C_ANGLE, C_SPEED, C_TEMP, C_SALT, C_PRESS, C_TURB, C_OXYG, ');
    SQL.Add('  C_CFL, C_TFL, C_SFL, C_PFL, C_UFL, C_OFL ) ');
    SQL.Add(' VALUES ');
    SQL.Add(' (:ABSNUM, :C_TIME, :C_ANGLE, :C_SPEED, :C_TEMP, :C_SALT, :C_PRESS, :C_TURB, :C_OXYG, ');
    SQL.Add('  :C_CFL, :C_TFL, :C_SFL, :C_PFL, :C_UFL, :C_OFL ) ');
    Prepare;
  end;
    //showmessage(frmDM.ib1q3.sql.Text);

     //delete mooring
   with frmDM.ib1q4 do begin
     Close;
     SQL.Clear;
     SQL.Add(' Delete from CURRENTS where absnum=:absnum');
     Prepare;
   end;


     frmdm.Q.DisableControls;
     frmdm.Q.First;
//{w}for k:=1 to 5 do begin
{w}while not frmdm.Q.Eof do begin

     absnum:=frmdm.Q.FieldByName('Absnum').AsInteger;
     RCMnum:=frmdm.Q.FieldByName('M_RCMnum').AsInteger;
     MQFL:=frmdm.Q.FieldByName('M_QFlag').AsInteger;
     RCMLat:=frmdm.Q.FieldByName('M_Lat').AsFloat;
     RCMDepth:=frmdm.Q.FieldByName('M_RCMDepth').AsInteger;
     sensors:=frmdm.Q.FieldByName('M_sensors').AsString;
     temp_ch:=frmdm.Q.FieldByName('M_TempChannel').AsInteger;

     Depth_to_Pressure(RCMDepth,RCMLat,0,p);


     if (checkbox1.Checked) then memo1.Lines.Add('');
     memo1.Lines.Add('### absnum='+inttostr(absnum)
     +'   RCMnum='+inttostr(RCMnum)
     +'   MQFL='+inttostr(MQFL)
     +'   channels:'+sensors
     +'   temp channel:'+inttostr(temp_ch)
     +'   RCMDepth:'+inttostr(RCMDepth)
     +'   RCMLat:'+floattostr(RCMLat)
     +'   pressure:'+floattostrF(p,ffFixed,5,1));


//delete mooring if exist
   with frmDM.ib1q4 do begin
     ParamByName('ABSNUM').AsInteger:=absnum;
     ExecSQL;
   end;

{Q}if MQFL<>9 then begin

     if (checkbox1.Checked) then begin
     memo1.Lines.Add('available sensors (channel -> variable)');
     if sensors[1]<>'0' then memo1.Lines.Add('CH1: '+sensors[1]);
     if sensors[2]<>'0' then memo1.Lines.Add('CH2: '+sensors[2]);
     if sensors[3]<>'0' then memo1.Lines.Add('CH3: '+sensors[3]);
     if sensors[4]<>'0' then memo1.Lines.Add('CH4: '+sensors[4]);
     if sensors[5]<>'0' then memo1.Lines.Add('CH5: '+sensors[5]);
     if sensors[6]<>'0' then memo1.Lines.Add('CH6: '+sensors[6]);
     if sensors[7]<>'0' then memo1.Lines.Add('CH7: '+sensors[7]);
     if sensors[8]<>'0' then memo1.Lines.Add('CH8: '+sensors[8]);
     if sensors[9]<>'0' then memo1.Lines.Add('CH9: '+sensors[9]);
     memo1.Lines.Add('...coefficients for available sensors');
     end;

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


     if (checkbox1.Checked) then begin
     if sensors[2]<>'0' then
     memo1.Lines.Add('TA='+floattostrF(TA,ffFixed,8,5)
     +#9+'TB='+floattostrF(TB,ffFixed,8,5)
     +#9+'TC='+floattostrF(TC,ffFixed,8,5)
     +#9+'TD='+floattostrF(TD,ffFixed,8,5));
     if sensors[3]<>'0' then
     memo1.Lines.Add('CA='+floattostrF(CA,ffFixed,8,5)
     +#9+'CB='+floattostrF(CB,ffFixed,8,5)
     +#9+'CC='+floattostrF(CC,ffFixed,8,5)
     +#9+'CD='+floattostrF(CD,ffFixed,8,5));
     if sensors[4]<>'0' then
     memo1.Lines.Add('PA='+floattostrF(PA,ffFixed,8,5)
     +#9+'PB='+floattostrF(PB,ffFixed,8,5)
     +#9+'PC='+floattostrF(PC,ffFixed,8,5)
     +#9+'PD='+floattostrF(PD,ffFixed,8,5));
     if sensors[5]<>'0' then
     memo1.Lines.Add('DA='+floattostrF(DA,ffFixed,8,5)
     +#9+'DB='+floattostrF(DB,ffFixed,8,5)
     +#9+'DC='+floattostrF(DC,ffFixed,8,5)
     +#9+'DD='+floattostrF(DD,ffFixed,8,5));
     if sensors[6]<>'0' then
     memo1.Lines.Add('SA='+floattostrF(SA,ffFixed,8,5)
     +#9+'SB='+floattostrF(SB,ffFixed,8,5)
     +#9+'SC='+floattostrF(SC,ffFixed,8,5)
     +#9+'SD='+floattostrF(SD,ffFixed,8,5));
     if sensors[7]<>'0' then
     memo1.Lines.Add('UA='+floattostrF(UA,ffFixed,8,5)
     +#9+'UB='+floattostrF(UB,ffFixed,8,5)
     +#9+'UC='+floattostrF(UC,ffFixed,8,5)
     +#9+'UD='+floattostrF(UD,ffFixed,8,5));
     if sensors[8]<>'0' then
     memo1.Lines.Add('OA='+floattostrF(OA,ffFixed,8,5)
     +#9+'OB='+floattostrF(OB,ffFixed,8,5)
     +#9+'OC='+floattostrF(OC,ffFixed,8,5)
     +#9+'OD='+floattostrF(OD,ffFixed,8,5));
     if sensors[9]<>'0' then
     memo1.Lines.Add('XA='+floattostrF(XA,ffFixed,8,5)
     +#9+'XB='+floattostrF(XB,ffFixed,8,5)
     +#9+'XC='+floattostrF(XC,ffFixed,8,5)
     +#9+'XD='+floattostrF(XD,ffFixed,8,5));
     end;


   with frmdm.ib1q2 do begin
     ParamByName('ABSNUM').AsFloat:=absnum;
     Open;
   end;

   if (checkbox1.Checked) then begin
     memo1.Lines.Add('Row Data with QFL<>9');
     memo1.Lines.Add('time--Temp--Cond--Press/temp--Dir--Speed--tUrb--Oxy--X--QFL');
   end;

     mik:=0;
{R}while not frmdm.ib1q2.Eof do begin
     rec_time :=frmdm.ib1q2.FieldByName('RD_TIME').AsDateTime;
     rd_temp     :=frmdm.ib1q2.FieldByName('CH2').AsInteger;  //temperature
     rd_cond     :=frmdm.ib1q2.FieldByName('CH3').AsInteger;  //conductivity
     rd_press    :=frmdm.ib1q2.FieldByName('CH4').AsInteger;  //pressure
     rd_dir      :=frmdm.ib1q2.FieldByName('CH5').AsInteger;  //direction
     rd_speed    :=frmdm.ib1q2.FieldByName('CH6').AsInteger;  //speed
     rd_turb     :=frmdm.ib1q2.FieldByName('CH7').AsInteger;  //turbidity
     rd_oxy      :=frmdm.ib1q2.FieldByName('CH8').AsInteger;  //oxygen
     rd_xxx      :=frmdm.ib1q2.FieldByName('CH9').AsInteger;   //reserved
     rd_QFL      :=frmdm.ib1q2.FieldByName('QFL').AsInteger;   //reserved

{9}if rd_QFL<>9 then begin
     mik:=mik+1;
     //show only 5 rows
     if (checkbox1.Checked) and (mik<=5) then
     memo1.Lines.Add(datetimetostr(rec_time)
     +#9+inttostr(rd_temp)
     +#9+inttostr(rd_cond)
     +#9+inttostr(rd_press)
     +#9+inttostr(rd_dir)
     +#9+inttostr(rd_speed)
     +#9+inttostr(rd_turb)
     +#9+inttostr(rd_oxy)
     +#9+inttostr(rd_xxx)
     +#9+inttostr(rd_QFL));

     //conversion
     //temperature
      if sensors[2]<>'0' then
      temp:= TA + TB*rd_temp + TC*rd_temp*rd_temp + TD*rd_temp*rd_temp*rd_temp
                         else temp:=-9;
      //conductivity
      if sensors[3]<>'0' then
      cond:= CA + CB*rd_cond + CC*rd_cond*rd_cond + CD*rd_cond*rd_cond*rd_cond
                         else cond:=-9;
      //pressure
      if sensors[4]<>'0' then
      press:= PA + PB*rd_press + PC*rd_press*rd_press + PD*rd_press*rd_press*rd_press
                         else press:=-9;
      //direction
      if sensors[5]<>'0' then
      dir:= DA + DB*rd_dir + DC*rd_dir*rd_dir + DD*rd_dir*rd_dir*rd_dir
                         else dir:=-9;
      //speed
      if sensors[6]<>'0' then
      speed:= SA + SB*rd_speed + SC*rd_speed*rd_speed + SD*rd_speed*rd_speed*rd_speed
                         else speed:=-9;
      //turbidity
      if sensors[7]<>'0' then
      turb:= UA + UB*rd_turb + UC*rd_turb*rd_turb + UD*rd_turb*rd_turb*rd_turb
                         else turb:=-9;
      //oxygen
      if sensors[7]<>'0' then
      oxy:= OA + OB*rd_oxy + OC*rd_oxy*rd_oxy + OD*rd_oxy*rd_oxy*rd_oxy
                         else oxy:=-9;
      //reserved variable
      if sensors[6]<>'0' then
      xxx:= XA + XB*rd_xxx + XC*rd_xxx*rd_xxx + XD*rd_xxx*rd_xxx*rd_xxx
                         else xxx:=-9;

      //temperature selection according prefered channel
      //t24 used in calculations
      //temp  populates field C_TEMP in CURRENTS
      //press populates field C_PRESS in CURRENTS
      //without temp cond cannot be converted

        t24:=-9;
     //if (sensors[2]<>'0') or (sensors[4]<>'0')then
     case temp_ch of
     0: showmessage('...Temperature does not exist');
     2: t24:=temp;
     4: t24:=press;
     end; {case}

     //salinity computing
    salt:=-9;
{c}if (cond<>-9) and (t24<>-9) then begin
    //conductivity -> salinity   Technical Description N159 March 1990 p.6-06
    //1. in situ cond -> conductivity ratio (cond_R)
    R_STP:= cond/42.914;

    //2. correction for effect of pressure
       //convert depth to pressure later: rcm-depth latitude m parameter pressure
       //m=0 depth to pressure   m=1 pressure to depth
       Depth_to_Pressure(RCMDepth,RCMLat,0,p);

    F:=(1.60836e-5*p - 5.4845e-10*p*p + 6.166e-15*p*p*p)/(1 + 3.0786e-2*t24 + 3.169e-4*t24*t24);
    R_ST:=R_STP/(1 + F);
   //showmessage('R_ST='+floattostr(R_ST));

    //3. correction for effect of temperature
      t100:=t24/100;
    rt := 0.6765836 + 2.005294*t100 + 1.11099*t100*t100 - 0.726684*t100*t100*t100
          + 0.13587*t100*t100*t100*t100;
    R_S:=R_ST/rt;
    //showmessage('R_S='+floattostr(R_S));

    //4. conversion to salinity
    salt:= -0.08996 + 28.8567*R_S + 12.18882*R_S*R_S - 10.61869*R_S*R_S*R_S
           + 5.98624*R_S*R_S*R_S*R_S
           - 1.32311*R_S*R_S*R_S*R_S*R_S
           + R_S*(R_S-1)*(0.0442*t24 - 0.46e-3*t24*t24 - 4e-3*R_S*t24
           + (1.25e-4 - 2.9e-6*t24)*p);
    //showmessage('salt='+floattostr(salt));

{c}end;


     //show only 5 rows
     if (checkbox1.Checked) and (mik<=5) then
     memo1.Lines.Add(datetimetostr(rec_time)
     +#9+floattostrF(t24,ffFixed,6,3)
     +#9+floattostrF(salt,ffFixed,6,3)
     +#9+floattostrF(press,ffFixed,6,3)
     +#9+floattostrF(dir,ffFixed,6,3)
     +#9+floattostrF(speed,ffFixed,6,3)
     +#9+floattostrF(turb,ffFixed,6,3)
     +#9+floattostrF(oxy,ffFixed,6,3)
     +#9+floattostrF(xxx,ffFixed,6,3));

//insert converted data onto table CURRENTS
   with frmDM.ib1q3 do begin
     ParamByName('ABSNUM').AsInteger:=absnum;
     ParamByName('C_TIME').AsDateTime:=rec_time;
     ParamByName('C_ANGLE').AsFloat:=dir;
     ParamByName('C_SPEED').AsFloat:=speed;
     ParamByName('C_TEMP').AsFloat:=temp; //prefered temperature channel
     ParamByName('C_SALT').AsFloat:=salt;
     ParamByName('C_PRESS').AsFloat:=press;//always channel 4
     ParamByName('C_TURB').AsFloat:=turb;
     ParamByName('C_OXYG').AsFloat:=oxy;

     ParamByName('C_CFL').AsInteger:=0;
     ParamByName('C_TFL').AsInteger:=0;
     ParamByName('C_SFL').AsInteger:=0;
     ParamByName('C_PFL').AsInteger:=0;
     ParamByName('C_UFL').AsInteger:=0;
     ParamByName('C_OFL').AsInteger:=0;
     ExecSQL;
   end;



{9}end; {if QFL on row data <>-9}

     frmdm.ib1q2.Next;
{R}end; {ib1q2.Eof}
     frmdm.ib1q2.Close;
     memo1.Lines.Add('...records#='+inttostr(mik));
     frmDM.TR.CommitRetaining;  //only CommirRetaining since there are prepared queries

     //update record#
   with frmDM.ib1q5 do begin
     Close;
     SQL.Clear;
     SQL.Add(' update MOORINGS set M_REC_CUR=:recnum where absnum=:absnum');
     ParamByName('ABSNUM').AsInteger:=absnum;
     ParamByName('recnum').AsInteger:=mik;
     ExecSQL;
   end;

     //update stop
   //with frmDM.ib1q5 do begin
     //Close;
     //SQL.Clear;
     //SQL.Add(' update MOORINGS set M_TIMEEND=:rec_time where absnum=:absnum');
     //ParamByName('ABSNUM').AsInteger:=absnum;
     //ParamByName('rec_time').AsDateTime:=rec_time;
     //ExecSQL;
   //end;

{Q}end; {if QF at station <>9}
     frmdm.Q.Next;
     frmDM.TR.CommitRetaining;  //only CommirRetaining since there are prepared queries
{w}end; {Q}

     frmdm.Q.First;
     frmdm.Q.EnableControls;

     frmdm.ib1q1.UnPrepare;
     frmdm.ib1q2.UnPrepare;
     frmdm.ib1q3.UnPrepare;
     frmdm.ib1q4.UnPrepare;

     memo1.Lines.Add('... conversion has compleated');


     //get and update number of records in ROWDATA
   with frmDM.ib1q5 do begin
     Close;
     SQL.Clear;
     SQL.Add(' select count(*) as RecNum from ROWDATA where absnum=:absnum ');
     ParamByName('ABSNUM').AsInteger:=absnum;
     Open;
     RecNum:=FieldByName('RecNum').AsInteger;
   end;
   with frmDM.ib1q5 do begin
     Close;
     SQL.Clear;
     SQL.Add(' update MOORINGS set M_REC_ROW=:RecNum where absnum=:absnum ');
     ParamByName('ABSNUM').AsInteger:=absnum;
     ParamByName('recnum').AsInteger:=RecNum;
     ExecSQL;
     Close;
   end;
     frmDM.TR.Commit;

     //get and update time for stop
   with frmDM.ib1q5 do begin
     Close;
     SQL.Clear;
     SQL.Add(' select max(RD_TIME) as Stop from ROWDATA where absnum=:absnum ');
     ParamByName('ABSNUM').AsInteger:=absnum;
     Open;
     Stop:=FieldByName('STOP').AsDateTime;
   end;
     //showmessage(datetimetostr(stop));
   with frmDM.ib1q5 do begin
     Close;
     SQL.Clear;
     SQL.Add(' update MOORINGS set M_TIMEEND=:STOP where absnum=:absnum ');
     ParamByName('ABSNUM').AsInteger:=absnum;
     ParamByName('STOP').AsDateTime:=Stop;
     ExecSQL;
     Close;
   end;
     frmDM.TR.Commit;



     frmDM.TR.Active:=false;
end;




procedure TfrmConvertRowData.btnEmptyTableCurrentsClick(Sender: TObject);
begin

     frmdm.TR.StartTransaction;
     showmessage('All data in table CURRENTS will be deleted');
   with frmDM.ib1q4 do begin
     Close;
     SQL.Clear;
     SQL.Add(' Delete from CURRENTS ');
     ExecSQL;
   end;
     frmdm.TR.CommitRetaining;
     frmDM.TR.Active:=false;

end;

end.
