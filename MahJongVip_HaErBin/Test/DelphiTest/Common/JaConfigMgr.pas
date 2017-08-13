unit JaConfigMgr;

interface

uses
  Windows, SysUtils, Classes, IniFiles, Registry, JaContainers;

type

{ Classes }

  TCustomConfigMgr = class;
  TConfigIO = class;
  TIniConfigIO = class;
  TRegConfigIO = class;
  TJaMemIniFile = class;

{ TCustomConfigMgr }

  TCustomConfigMgr = class(TObject)
  private
    FSections: TStrHashTable;       // <Section, TPropertyList>
  private
    function FindPropList(const Section: string): TPropertyList;
    function AddSection(const Section: string): TPropertyList;
    procedure Load(IO: TConfigIO);
    procedure Save(IO: TConfigIO); overload;
    procedure Save(var BinStr: string); overload;
  protected
    function GetString(const Section, Key: string; const Default: string): string;
    function GetInteger(const Section, Key: string; Default: Integer): Integer;
    function GetBoolean(const Section, Key: string; const Default: Boolean): Boolean;
    function GetVariant(const Section, Key: string; const Default: Variant): Variant;
    
    procedure SetString(const Section, Key, Value: string);
    procedure SetInteger(const Section, Key: string; Value: Integer);
    procedure SetBoolean(const Section, Key: string; Value: Boolean);
    procedure SetVariant(const Section, Key: string; const Value: Variant);

    procedure DeleteSection(const Section: string);

    procedure LoadFromIniFile(const FileName: string);
    procedure SaveToIniFile(const FileName: string);
    procedure LoadFromStr(const BinStr: string);
    procedure SaveToStr(var BinStr: string);
    procedure LoadFromRegistry(RootKey: HKEY; const Path: string);
    procedure SaveToRegistry(RootKey: HKEY; const Path: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

{ TConfigIO }

  TConfigIO = class(TObject)
  public
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    procedure GetSectionList(List: TStrings); virtual; abstract;
    procedure GetKeyList(const Section: string; List: TStrings); virtual; abstract;
    function Read(const Section, Key: string; const Default: string): string; virtual; abstract;
    procedure Write(const Section, Key, Value: string); virtual; abstract;
    procedure DeleteSection(const Section: string); virtual; abstract;
  end;

{ TIniConfigIO }

  TIniConfigIO = class(TConfigIO)
  private
    FFileName: string;
    FIniFile: TIniFile;
  public
    constructor Create(const FileName: string);
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure GetSectionList(List: TStrings); override;
    procedure GetKeyList(const Section: string; List: TStrings); override;
    function Read(const Section, Key: string; const Default: string): string; override;
    procedure Write(const Section, Key, Value: string); override;
    procedure DeleteSection(const Section: string); override;
  end;

{ TMemIniConfigIO }

  TMemIniConfigIO = class(TConfigIO)
  private
    FBinStr: string;
    FIniFile: TJaMemIniFile;
  public
    constructor Create(const BinStr: string);
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure GetSectionList(List: TStrings); override;
    procedure GetKeyList(const Section: string; List: TStrings); override;
    function Read(const Section, Key: string; const Default: string): string; override;
    procedure Write(const Section, Key, Value: string); override;
    procedure DeleteSection(const Section: string); override;
  end;

{ TRegConfigIO }

  TRegConfigIO = class(TConfigIO)
  private
    FRootKey: HKEY;
    FPath: string;
    FRegistry: TRegistry;
  public
    constructor Create(RootKey: HKEY; const Path: string);
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure GetSectionList(List: TStrings); override;
    procedure GetKeyList(const Section: string; List: TStrings); override;
    function Read(const Section, Key: string; const Default: string): string; override;
    procedure Write(const Section, Key, Value: string); override;
    procedure DeleteSection(const Section: string); override;
  end;

  { TJcHashedStringList - 哈西表(为MemIni访问Protected方式调用) }

  TJcHashedStringList = class(THashedStringList)
  protected
    procedure Changed; override;
  end;

  { TJaMemIniFile - 内存ini文件 }
  
  TJaMemIniFile = class(TCustomIniFile)
  private
    FSections: TJcHashedStringList;
    
    function GetCaseSensitive: Boolean;
    procedure SetCaseSensitive(Value: Boolean);
    
    function AddSection(const ASection: string): TStrings;
    procedure LoadValues(const AStream: TStream);
  public
    constructor Create(const AStream: TStream);
    constructor CreateFromStr(const AString: string);
    destructor Destroy; override;

    procedure Clear;
    procedure UpdateFile; override;
    
    procedure DeleteKey(const ASection, AIdent: String); override;
    procedure EraseSection(const ASection: string); override;
    
    procedure GetStrings(AList: TStrings);
    procedure SetStrings(AList: TStrings);

    procedure ReadSection(const ASection: string; AStrings: TStrings); override;
    procedure ReadSections(AStrings: TStrings); override;
    procedure ReadSectionValues(const ASection: string; AStrings: TStrings); override;

    function ReadString(const ASection, AIdent, ADefault: string): string; override;
    procedure WriteString(const ASection, AIdent, AValue: String); override;
  public
    property CaseSensitive: Boolean read GetCaseSensitive write SetCaseSensitive;
  end;

implementation

{ TCustomConfigMgr }

constructor TCustomConfigMgr.Create;
begin
  inherited;
  FSections := TStrHashTable.Create(256, False);
end;

destructor TCustomConfigMgr.Destroy;
begin
  Clear;
  FSections.Free;
  inherited;
end;

procedure TCustomConfigMgr.Clear;
var
  HashItems: TStrHashItems;
  I: Integer;
begin
  FSections.GetItems(HashItems);
  for I := 0 to Length(HashItems) - 1 do
    TPropertyList(HashItems[I].Value).Free;
  FSections.Clear;
end;

function TCustomConfigMgr.FindPropList(const Section: string): TPropertyList;
begin
  if not FSections.GetValue(Section, Integer(Result)) then
    Result := nil;
end;

function TCustomConfigMgr.AddSection(const Section: string): TPropertyList;
begin
  Result := FindPropList(Section);
  if Result = nil then
  begin
    Result := TPropertyList.Create;
    FSections.Add(Section, Integer(Result));
  end;
end;

procedure TCustomConfigMgr.Load(IO: TConfigIO);
var
  SectionList, KeyList: TStringList;
  SecIndex, KeyIndex: Integer;
  Section, Key, Value: string;
begin
  SectionList := TStringList.Create;
  KeyList := TStringList.Create;
  try
    Clear;
    IO.BeginUpdate;
    try
      IO.GetSectionList(SectionList);
      for SecIndex := 0 to SectionList.Count - 1 do
      begin
        Section := SectionList[SecIndex];
        KeyList.Clear;
        IO.GetKeyList(Section, KeyList);
        for KeyIndex := 0 to KeyList.Count - 1 do
        begin
          Key := KeyList[KeyIndex];
          Value := IO.Read(Section, Key, '');
          SetString(Section, Key, Value);
        end;
      end;
    finally
      IO.EndUpdate;
    end;
  finally
    SectionList.Free;
    KeyList.Free;
  end;
end;

procedure TCustomConfigMgr.Save(IO: TConfigIO);
var
  HashItems: TStrHashItems;
  PropList: TPropertyList;
  SecIndex, KeyIndex: Integer;
  Section, Key, Value: string;
begin
  IO.BeginUpdate;
  try
    FSections.GetItems(HashItems);
    for SecIndex := 0 to Length(HashItems) - 1 do
    begin
      Section := HashItems[SecIndex].Key;
      IO.DeleteSection(Section);
      PropList := TPropertyList(HashItems[SecIndex].Value);
      for KeyIndex := 0 to PropList.Count - 1 do
      begin
        Key := PropList.Items[KeyIndex].Name;
        Value := PropList.Items[KeyIndex].Value;
        IO.Write(Section, Key, Value);
      end;
    end;
  finally
    IO.EndUpdate;
  end;
end;

function TCustomConfigMgr.GetString(const Section, Key: string;
  const Default: string): string;
var
  PropList: TPropertyList;
begin
  PropList := FindPropList(Section);
  if (PropList = nil) or not PropList.GetValue(Key, Result) then
    Result := Default;
end;

function TCustomConfigMgr.GetInteger(const Section, Key: string;
  Default: Integer): Integer;
var
  PropList: TPropertyList;
  ValueStr: string;
begin
  PropList := FindPropList(Section);
  if (PropList <> nil) and PropList.GetValue(Key, ValueStr) then
    Result := StrToIntDef(ValueStr, Default)
  else
    Result := Default;
end;

function TCustomConfigMgr.GetBoolean(const Section, Key: string;
  const Default: Boolean): Boolean;
var
  PropList: TPropertyList;
  ValueStr: string;
begin
  PropList := FindPropList(Section);
  if (PropList <> nil) and PropList.GetValue(Key, ValueStr) then
    Result := StrToBoolDef(ValueStr, Default)
  else
    Result := Default;
end;

function TCustomConfigMgr.GetVariant(const Section, Key: string;
  const Default: Variant): Variant;
var
  PropList: TPropertyList;
  ValueStr: string;
begin
  PropList := FindPropList(Section);
  if (PropList <> nil) and PropList.GetValue(Key, ValueStr) then
    Result := ValueStr
  else
    Result := Default;
end;

procedure TCustomConfigMgr.SetString(const Section, Key, Value: string);
var
  PropList: TPropertyList;
begin
  PropList := AddSection(Section);
  PropList.Add(Key, Value);
end;

procedure TCustomConfigMgr.SetInteger(const Section, Key: string; Value: Integer);
var
  PropList: TPropertyList;
begin
  PropList := AddSection(Section);
  PropList.Add(Key, IntToStr(Value));
end;

procedure TCustomConfigMgr.SetBoolean(const Section, Key: string; Value: Boolean);
var
  PropList: TPropertyList;
begin
  PropList := AddSection(Section);
  PropList.Add(Key, BoolToStr(Value, True));
end;

procedure TCustomConfigMgr.SetVariant(const Section, Key: string; const Value: Variant);
var
  PropList: TPropertyList;
begin
  PropList := AddSection(Section);
  PropList.Add(Key, Value);
end;

procedure TCustomConfigMgr.DeleteSection(const Section: string);
begin
  FindPropList(Section).Free;
  FSections.Remove(Section);
end;

procedure TCustomConfigMgr.LoadFromIniFile(const FileName: string);
var
  IO: TIniConfigIO;
begin
  IO := TIniConfigIO.Create(FileName);
  try
    Load(IO);
  finally
    IO.Free;
  end;
end;

procedure TCustomConfigMgr.Save(var BinStr: string);
var
  HashItems: TStrHashItems;
  PropList: TPropertyList;
  SecIndex, KeyIndex: Integer;
  Section, Key, Value: string;
  LStrList: TStringList;
begin
  LStrList := TStringList.Create;
  try
    FSections.GetItems(HashItems);
    for SecIndex := 0 to Length(HashItems) - 1 do
    begin
      Section := HashItems[SecIndex].Key;
      LStrList.Add('[' + Section + ']');

      PropList := TPropertyList(HashItems[SecIndex].Value);
      for KeyIndex := 0 to PropList.Count - 1 do
      begin
        Key := PropList.Items[KeyIndex].Name;
        Value := PropList.Items[KeyIndex].Value;

        LStrList.Add(Key + LStrList.NameValueSeparator + Value);
      end;
      
      LStrList.Add('');
    end;

    BinStr := LStrList.Text;
  finally
    LStrList.Free;
  end;
end;

procedure TCustomConfigMgr.SaveToIniFile(const FileName: string);
var
  IO: TIniConfigIO;
begin
  IO := TIniConfigIO.Create(FileName);
  try
    Save(IO);
  finally
    IO.Free;
  end;
end;

procedure TCustomConfigMgr.LoadFromRegistry(RootKey: HKEY; const Path: string);
var
  IO: TRegConfigIO;
begin
  IO := TRegConfigIO.Create(RootKey, Path);
  try
    Load(IO);
  finally
    IO.Free;
  end;
end;

procedure TCustomConfigMgr.LoadFromStr(const BinStr: string);
var
  IO: TMemIniConfigIO;
begin
  IO := TMemIniConfigIO.Create(BinStr);
  try
    Load(IO);
  finally
    IO.Free;
  end;
end;

procedure TCustomConfigMgr.SaveToRegistry(RootKey: HKEY; const Path: string);
var
  IO: TRegConfigIO;
begin
  IO := TRegConfigIO.Create(RootKey, Path);
  try
    Save(IO);
  finally
    IO.Free;
  end;
end;

procedure TCustomConfigMgr.SaveToStr(var BinStr: string);
begin
  Save(BinStr);
end;

{ TConfigIO }

procedure TConfigIO.BeginUpdate;
begin
  // nothing
end;

procedure TConfigIO.EndUpdate;
begin
  // nothing
end;

{ TIniConfigIO }

constructor TIniConfigIO.Create(const FileName: string);
begin
  inherited Create;
  FFileName := FileName;
end;

procedure TIniConfigIO.BeginUpdate;
begin
  FIniFile := TIniFile.Create(FFileName);
end;

procedure TIniConfigIO.EndUpdate;
begin
  FIniFile.Free;
end;

procedure TIniConfigIO.GetSectionList(List: TStrings);
begin
  FIniFile.ReadSections(List);
end;

procedure TIniConfigIO.GetKeyList(const Section: string; List: TStrings);
begin
  FIniFile.ReadSection(Section, List);
end;

function TIniConfigIO.Read(const Section, Key: string; const Default: string): string;
begin
  Result := FIniFile.ReadString(Section, Key, Default);
end;

procedure TIniConfigIO.Write(const Section, Key, Value: string);
begin
  FIniFile.WriteString(Section, Key, Value);
end;

procedure TIniConfigIO.DeleteSection(const Section: string);
begin
  FIniFile.EraseSection(Section);
end;

{ TMemIniConfigIO }

constructor TMemIniConfigIO.Create(const BinStr: string);
begin
  inherited Create;
  FBinStr := BinStr;
end;

procedure TMemIniConfigIO.BeginUpdate;
begin
  FIniFile := TJaMemIniFile.CreateFromStr(FBinStr);
end;

procedure TMemIniConfigIO.EndUpdate;
begin
  FIniFile.Free;
end;

procedure TMemIniConfigIO.GetSectionList(List: TStrings);
begin
  FIniFile.ReadSections(List);
end;

procedure TMemIniConfigIO.GetKeyList(const Section: string; List: TStrings);
begin
  FIniFile.ReadSection(Section, List);
end;

function TMemIniConfigIO.Read(const Section, Key: string; const Default: string): string;
begin
  Result := FIniFile.ReadString(Section, Key, Default);
end;

procedure TMemIniConfigIO.Write(const Section, Key, Value: string);
begin
  FIniFile.WriteString(Section, Key, Value);
end;

procedure TMemIniConfigIO.DeleteSection(const Section: string);
begin
  FIniFile.EraseSection(Section);
end;

{ TRegConfigIO }

constructor TRegConfigIO.Create(RootKey: HKEY; const Path: string);
begin
  inherited Create;
  FRootKey := RootKey;
  FPath := Path;
  if Copy(FPath, Length(FPath), 1) <> '\' then
    FPath := FPath + '\';
end;

procedure TRegConfigIO.BeginUpdate;
begin
  FRegistry := TRegistry.Create;
  FRegistry.RootKey := FRootKey;
end;

procedure TRegConfigIO.EndUpdate;
begin
  FRegistry.Free;
end;

procedure TRegConfigIO.GetSectionList(List: TStrings);
begin
  List.Clear;
  if FRegistry.OpenKey(FPath, False) then
    FRegistry.GetKeyNames(List);
end;

procedure TRegConfigIO.GetKeyList(const Section: string; List: TStrings);
begin
  List.Clear;
  if FRegistry.OpenKey(FPath + Section, False) then
    FRegistry.GetValueNames(List);
end;

function TRegConfigIO.Read(const Section, Key: string; const Default: string): string;
begin
  if FRegistry.OpenKey(FPath + Section, False) then
    Result := FRegistry.ReadString(Key)
  else
    Result := Default;
end;

procedure TRegConfigIO.Write(const Section, Key, Value: string);
begin
  if FRegistry.OpenKey(FPath + Section, True) then
    FRegistry.WriteString(Key, Value);
end;

procedure TRegConfigIO.DeleteSection(const Section: string);
begin
  if FRegistry.OpenKey(FPath, False) then
    FRegistry.DeleteKey(Section);
end;


{ TJcHashedStringList }

procedure TJcHashedStringList.Changed;
begin
  inherited;
end;

{ TJaMemIniFile }

constructor TJaMemIniFile.Create(const AStream: TStream);
begin
  inherited Create('');

  FSections := TJcHashedStringList.Create;
  LoadValues(AStream);
end;

destructor TJaMemIniFile.Destroy;
begin
  if FSections <> nil then
    Clear;
  FSections.Free;
  
  inherited Destroy;
end;

function TJaMemIniFile.AddSection(const ASection: string): TStrings;
begin
  Result := THashedStringList.Create;
  try
    THashedStringList(Result).CaseSensitive := CaseSensitive;
    FSections.AddObject(ASection, Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure TJaMemIniFile.Clear;
var
  I: Integer;
begin
  for I := 0 to FSections.Count - 1 do
    TObject(FSections.Objects[I]).Free;
    
  FSections.Clear;
end;

constructor TJaMemIniFile.CreateFromStr(const AString: string);
var
  LStream: TMemoryStream;
begin
  inherited Create('');

  LStream := TMemoryStream.Create;
  try
    LStream.Position := 0;
    if Length(AString) > 0 then
      LStream.WriteBuffer(AString[1], Length(AString));

    FSections := TJcHashedStringList.Create;
    LoadValues(LStream);
  finally
    FreeAndNil(LStream);
  end;
end;

procedure TJaMemIniFile.DeleteKey(const ASection, AIdent: String);
var
  LSectionIndex: Integer;
  LNameIndex: Integer;
  LStrings: TStrings;
begin
  LSectionIndex := FSections.IndexOf(ASection);
  
  if LSectionIndex >= 0 then
  begin
    LStrings := TStrings(FSections.Objects[LSectionIndex]);
    LNameIndex := LStrings.IndexOfName(AIdent);
    if LNameIndex >= 0 then
      LStrings.Delete(LNameIndex);
  end;
end;

procedure TJaMemIniFile.EraseSection(const ASection: string);
var
  LIndex: Integer;
begin
  LIndex := FSections.IndexOf(ASection);
  
  if LIndex >= 0 then
  begin
    TStrings(FSections.Objects[LIndex]).Free;
    FSections.Delete(LIndex);
  end;
end;

function TJaMemIniFile.GetCaseSensitive: Boolean;
begin
  Result := FSections.CaseSensitive;
end;

procedure TJaMemIniFile.GetStrings(AList: TStrings);
var
  I, J: Integer;
  LStrings: TStrings;
begin
  AList.BeginUpdate;
  try
    for I := 0 to FSections.Count - 1 do
    begin
      AList.Add('[' + FSections[I] + ']');
      LStrings := TStrings(FSections.Objects[I]);
      
      for J := 0 to LStrings.Count - 1 do
        AList.Add(LStrings[J]);
        
      AList.Add('');
    end;
  finally
    AList.EndUpdate;
  end;
end;

procedure TJaMemIniFile.LoadValues(const AStream: TStream);
var
  LStrList: TStringList;
  LOldPos: Int64;
begin
  if Assigned(AStream) then
  begin
    LOldPos := AStream.Position;
    LStrList := TStringList.Create;
    try
      AStream.Position := 0;
      LStrList.LoadFromStream(AStream);
      SetStrings(LStrList);
    finally
      LStrList.Free;
      AStream.Position := LOldPos;
    end;
  end
  else
    Clear;
end;

procedure TJaMemIniFile.ReadSection(const ASection: string;
  AStrings: TStrings);
var
  I: Integer;
  LSectionIndex: Integer;
  LSectionStrings: TStrings;
begin
  AStrings.BeginUpdate;
  try
    AStrings.Clear;
    LSectionIndex := FSections.IndexOf(ASection);
    
    if LSectionIndex >= 0 then
    begin
      LSectionStrings := TStrings(FSections.Objects[LSectionIndex]);
      
      for I := 0 to LSectionStrings.Count - 1 do
        AStrings.Add(LSectionStrings.Names[I]);
    end;
  finally
    AStrings.EndUpdate;
  end;
end;

procedure TJaMemIniFile.ReadSections(AStrings: TStrings);
begin
  AStrings.Assign(FSections);
end;

procedure TJaMemIniFile.ReadSectionValues(const ASection: string;
  AStrings: TStrings);
var
  LSectionIndex: Integer;
begin
  AStrings.BeginUpdate;
  try
    AStrings.Clear;
    LSectionIndex := FSections.IndexOf(ASection);
    
    if LSectionIndex >= 0 then
      AStrings.Assign(TStrings(FSections.Objects[LSectionIndex]));
  finally
    AStrings.EndUpdate;
  end;
end;

function TJaMemIniFile.ReadString(const ASection, AIdent,
  ADefault: string): string;
var
  LIndex: Integer;
  LStrings: TStrings;
begin
  LIndex := FSections.IndexOf(ASection);
  
  if LIndex >= 0 then
  begin
    LStrings := TStrings(FSections.Objects[LIndex]);
    LIndex := LStrings.IndexOfName(AIdent);
    
    if LIndex >= 0 then
    begin
      Result := Copy(LStrings[LIndex], Length(AIdent) + 2, Maxint);
      Exit;
    end;
  end;
  
  Result := ADefault;
end;

procedure TJaMemIniFile.SetCaseSensitive(Value: Boolean);
var
  I: Integer;
  LHashList: TJcHashedStringList;
begin
  if Value <> FSections.CaseSensitive then
  begin
    FSections.CaseSensitive := Value;
    
    for I := 0 to FSections.Count - 1 do
    begin
      LHashList := TJcHashedStringList(FSections.Objects[I]);
      LHashList.CaseSensitive := Value;
      LHashList.Changed;
    end;

    TJcHashedStringList(FSections).Changed;
  end;
end;

procedure TJaMemIniFile.SetStrings(AList: TStrings);
var
  I: Integer;
  LPos: Integer;
  LStr: string;
  LStrings: TStrings;
begin
  Clear;
  LStrings := nil;
  
  for I := 0 to AList.Count - 1 do
  begin
    LStr := Trim(AList[I]);
    
    if (LStr <> '') and (LStr[1] <> ';') then
    begin
      if (LStr[1] = '[') and (LStr[Length(LStr)] = ']') then
      begin
        Delete(LStr, 1, 1);
        SetLength(LStr, Length(LStr)-1);
        LStrings := AddSection(Trim(LStr));
      end else
      begin
        if LStrings <> nil then
        begin
          LPos := Pos('=', LStr);
          if LPos > 0 then // remove spaces before and after '='
            LStrings.Add(Trim(Copy(LStr, 1, LPos - 1)) + '=' + Trim(Copy(LStr, LPos + 1, MaxInt)))
          else
            LStrings.Add(LStr);
        end;
      end;
    end;
  end;
end;

procedure TJaMemIniFile.UpdateFile;
begin

end;

procedure TJaMemIniFile.WriteString(const ASection, AIdent, AValue: String);
var
  LIndex: Integer;
  LStr: string;
  LStrings: TStrings;
begin
  LIndex := FSections.IndexOf(ASection);
  if LIndex >= 0 then
    LStrings := TStrings(FSections.Objects[LIndex])
  else
    LStrings := AddSection(ASection);
    
  LStr := AIdent + '=' + AValue;
  LIndex := LStrings.IndexOfName(AIdent);
  
  if LIndex >= 0 then
    LStrings[LIndex] := LStr
  else
    LStrings.Add(LStr);
end;

end.
