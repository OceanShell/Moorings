unit dm;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, DB, sqldb, IBConnection, Variants, BufDataSet;

type

  { Tfrmdm }

  Tfrmdm = class(TDataModule)
    CDSRD: TBufDataset;
    CDScf: TBufDataset;
    CDQuery: TSQLQuery;
    dsCD: TDataSource;
    DSRD: TDataSource;
    DS: TDataSource;
    DB: TIBConnection;
    Q: TSQLQuery;
    RDQuery: TSQLQuery;
    CFQuery: TSQLQuery;
    TR: TSQLTransaction;
    Q0: TSQLQuery;
    QQ: TSQLQuery;
    ib1q1: TSQLQuery;
    ib1q2: TSQLQuery;
    ib1q3: TSQLQuery;
    dsSM: TDataSource;
    ib1q5: TSQLQuery;
    ib1q4: TSQLQuery;
    CDSCD: TBufDataSet;
    dsCF: TDataSource;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmdm: Tfrmdm;

implementation

{$R *.lfm}


end.
