
{*************************************************************************}
{ 单元描述: 容器类单元                                                    }
{ 版    本: 1.77                                                          }
{ 修改日期: 2007-08-05                                                    }
{*************************************************************************}

unit JaContainers;

interface

uses
  Windows, Classes, SysUtils, SyncObjs;

const
  DefHashTableBuckets   = 256;     // 哈希表的默认桶数
  DefBufStreamMemDelta  = 512;     // TBufferStream.MemoryDelta 的默认值

type

{ TSyncObject - 可支持线程安全的对象基类 }

  TSyncObject = class(TObject)
  private
    FLockPtr: ^TRTLCriticalSection;
    function GetThreadSafe: Boolean;
    procedure SetThreadSafe(Value: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    function TryLock: Boolean;
    procedure Lock;
    procedure Unlock;
    property ThreadSafe: Boolean read GetThreadSafe write SetThreadSafe;
  end;

{ TCustomObjectList - TObject 列表 (存取方法被保护) }

  TCustomObjectList = class(TSyncObject)
  protected
    FItems: TList;            // TObject[]
    FOwnsObjects: Boolean;    // 元素被删除时，是否自动释放元素对象

    function GetCount: Integer;
    function GetItems(Index: Integer): TObject;
    procedure SetItems(Index: Integer; Item: TObject);
    procedure NotifyDelete(Index: Integer); virtual;
  protected
    function Add(Item: TObject; AllowDuplicate: Boolean = True): Integer;
    function Remove(Item: TObject): Integer;
    function Extract(Item: TObject): TObject; overload;
    function Extract(Index: Integer): TObject; overload;
    procedure Delete(Index: Integer);
    procedure Insert(Index: Integer; Item: TObject);
    function IndexOf(Item: TObject): Integer;
    function Exists(Item: TObject): Boolean;
    function First: TObject;
    function Last: TObject;
    procedure Clear;
    procedure FreeObjects;
    procedure Sort(CompareProc: TListSortCompare);

    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
    property Items[Index: Integer]: TObject read GetItems write SetItems; default;
    property Count: Integer read GetCount;
  public
    constructor Create; overload;
    constructor Create(ThreadSafe, OwnsObjects: Boolean); overload;
    destructor Destroy; override;
  end;

{ TObjectList - TObject 列表 }

  TObjectList = class(TCustomObjectList)
  public
    function Add(Item: TObject; AllowDuplicate: Boolean = True): Integer;
    function Remove(Item: TObject): Integer;
    function Extract(Item: TObject): TObject; overload;
    function Extract(Index: Integer): TObject; overload;
    procedure Delete(Index: Integer);
    procedure Insert(Index: Integer; Item: TObject);
    function IndexOf(Item: TObject): Integer;
    function Exists(Item: TObject): Boolean;
    function First: TObject;
    function Last: TObject;
    procedure Clear;
    procedure FreeObjects;
    procedure Sort(CompareProc: TListSortCompare);

    property OwnsObjects;
    property Items;
    property Count;
  end;

{ TIntList - Integer 整型数列表 }

  TIntList = class(TObject)
  type
    PIntArray = ^TIntArray;
    TIntArray = array[0..MaxListSize - 1] of Integer;
  private
    FList: PIntArray;
    FCount: Integer;
    FCapacity: Integer;
  protected
    function Get(Index: Integer): Integer;
    procedure Put(Index: Integer; Item: Integer);
    procedure Grow;
    procedure SetCapacity(NewCapacity: Integer);
    procedure SetCount(NewCount: Integer);
    procedure Notify(Item: Integer; Action: TListNotification); virtual;
    procedure Error(const Msg: string; Data: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    function Add(Item: Integer): Integer;
    procedure Delete(Index: Integer);
    function Remove(Item: Integer): Integer;
    function Extract(Item: Integer): Integer;
    procedure Insert(Index: Integer; Item: Integer);
    procedure Clear; virtual;
    procedure Exchange(Index1, Index2: Integer);
    procedure Move(CurIndex, NewIndex: Integer);
    function IndexOf(Item: Integer): Integer;
    function Expand: TIntList;
    function First: Integer;
    function Last: Integer;
    function Equal(List: TIntList): Boolean;
    procedure Assign(Source: TIntList);

    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: Integer read Get write Put; default;
  end;

{ TInt64List - Int64 整型数列表 }

  TInt64List = class(TObject)
  type
    PInt64Array = ^TInt64Array;
    TInt64Array = array[0..MaxListSize - 1] of Int64;
  private
    FList: PInt64Array;
    FCount: Integer;
    FCapacity: Integer;
  protected
    function Get(Index: Integer): Int64;
    procedure Put(Index: Integer; Item: Int64);
    procedure Grow;
    procedure SetCapacity(NewCapacity: Integer);
    procedure SetCount(NewCount: Integer);
    procedure Notify(Item: Int64; Action: TListNotification); virtual;
    procedure Error(const Msg: string; Data: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    function Add(Item: Int64): Integer;
    procedure Delete(Index: Integer);
    function Remove(Item: Int64): Integer;
    function Extract(Item: Int64): Int64;
    procedure Insert(Index: Integer; Item: Int64);
    procedure Clear; virtual;
    procedure Exchange(Index1, Index2: Integer);
    procedure Move(CurIndex, NewIndex: Integer);
    function IndexOf(Item: Int64): Integer;
    function Expand: TInt64List;
    function First: Int64;
    function Last: Int64;
    procedure Assign(Source: TInt64List);

    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: Int64 read Get write Put; default;
  end;

{ THashTable - 哈希表基类 }

  THashTableUpdateType = (htutAdd, htutDelete);

  THashTable = class(TSyncObject);

{ TIntHashTable - 整型数哈希表 }

  PPIntHashItem = ^PIntHashItem;
  PIntHashItem = ^TIntHashItem;
  TIntHashItem = record
    Key: Integer;
    Value: Integer;
    Next: PIntHashItem;
  end;
  TIntHashItems = array of TIntHashItem;

  TIntHashTableForEachProc = procedure(Param: Pointer; Key, Value: Integer);

  TIntHashTableUpdateEvent = procedure(Sender: TObject;
    Key, Value: Integer; Action: THashTableUpdateType) of object;

  TIntHashTable = class(THashTable)
  private
    FBuckets: array of PIntHashItem;
    FCount: Integer;
    FOnUpdate: TIntHashTableUpdateEvent;

    function GetValues(Key: Integer): Integer; 
    procedure SetValues(Key: Integer; Value: Integer);
  protected
    function HashOf(Key: Integer): Cardinal; virtual;
    function FindBucket(Key: Integer): Integer;
    function FindItem(Key: Integer): PPIntHashItem;
    procedure Resize(Buckets: Cardinal);
    procedure Notify(Key, Value: Integer; Action: THashTableUpdateType);
  public
    constructor Create(Buckets: Cardinal = DefHashTableBuckets);
    destructor Destroy; override;
    procedure Assign(Source: TIntHashTable);

    function Add(Key, Value: Integer): Boolean;
    function Remove(Key: Integer): Integer;
    procedure Clear;
    function KeyExists(Key: Integer): Boolean;
    function GetValue(Key: Integer; var Value: Integer): Boolean;
    procedure ForEach(Proc: TIntHashTableForEachProc; Param: Pointer = nil);
    procedure GetItems(var Items: TIntHashItems);

    property Count: Integer read FCount;
    property Values[Key: Integer]: Integer read GetValues write SetValues; default;
    property OnUpdate: TIntHashTableUpdateEvent read FOnUpdate write FOnUpdate;
  end;

{ TStrHashTable - 字符串哈希表 }

  PPStrHashItem = ^PStrHashItem;
  PStrHashItem = ^TStrHashItem;
  TStrHashItem = record
    Key: string;
    Value: Integer;
    Next: PStrHashItem;
  end;
  TStrHashItems = array of TStrHashItem;

  TStrHashTableForEachProc = procedure(Param: Pointer;
    const Key: string; Value: Integer);

  TStrHashTableUpdateEvent = procedure(Sender: TObject; const Key: string;
    Value: Integer; Action: THashTableUpdateType) of object;

  TStrHashTable = class(THashTable)
  private
    FBuckets: array of PStrHashItem;
    FCount: Integer;
    FCaseSensitive: Boolean;
    FOnUpdate: TStrHashTableUpdateEvent;

    function GetValues(const Key: string): Integer;
    procedure SetValues(const Key: string; Value: Integer);
    function GetKeyStr(const Key: string): string;
  protected
    function HashOf(const Key: string): Cardinal; virtual;
    function FindBucket(const Key: string): Integer;
    function FindItem(const Key: string): PPStrHashItem;
    procedure Resize(Buckets: Cardinal);
    procedure Notify(const Key: string; Value: Integer; Action: THashTableUpdateType);
  public
    constructor Create(Buckets: Cardinal = DefHashTableBuckets; CaseSensitive: Boolean = True);
    destructor Destroy; override;
    procedure Assign(Source: TStrHashTable);

    function Add(const Key: string; Value: Integer): Boolean;
    function Remove(const Key: string): Integer;
    procedure Clear;
    function KeyExists(const Key: string): Boolean;
    function GetValue(const Key: string; var Value: Integer): Boolean;
    procedure ForEach(Proc: TStrHashTableForEachProc; Param: Pointer = nil);
    procedure GetItems(var Items: TStrHashItems);

    property Count: Integer read FCount;
    property Values[const Key: string]: Integer read GetValues write SetValues; default;
    property OnUpdate: TStrHashTableUpdateEvent read FOnUpdate write FOnUpdate;
  end;

{ TIntMap - 整型排序MAP }

  TIntMapItem = record
    Key: Integer;
    Value: Integer;
  end;

  TIntMap = class(TSyncObject)
  private
    FKeyList: TIntList;
    FValueList: TIntList;

    function GetItems(Index: Integer): TIntMapItem;
    function GetCount: Integer;
    function GetValues(Key: Integer): Integer;
    procedure SetValues(Key: Integer; const Value: Integer);
    function FindKey(Key: Integer): Integer;
    function FindKeyNearest(Key: Integer; var ResultState: Integer): Integer;
    function FindInsPos(Key: Integer; var Exists: Boolean): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TIntMap);

    function Add(Key, Value: Integer): Boolean;
    function Remove(Key: Integer): Integer;
    function Delete(Index: Integer): Integer;
    procedure Clear;
    function FirstKey: Integer;
    function LastKey: Integer;
    function KeyExists(Key: Integer): Boolean;
    function IndexOf(Key: Integer): Integer;
    function Equal(IntMap: TIntMap): Boolean;
    function GetValue(Key: Integer; var Value: Integer): Boolean;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TIntMapItem read GetItems;
    property Values[Key: Integer]: Integer read GetValues write SetValues; default;
  end;

{ TInt64Map - 大整型排序MAP }

  TInt64MapItem = record
    Key: Int64;
    Value: Int64;
  end;

  TInt64Map = class(TSyncObject)
  private
    FKeyList: TInt64List;
    FValueList: TInt64List;

    function GetItems(Index: Integer): TInt64MapItem;
    function GetCount: Integer;
    function GetValues(Key: Int64): Int64;
    procedure SetValues(Key: Int64; const Value: Int64);
    function FindKey(Key: Int64): Integer;
    function FindKeyNearest(Key: Int64; var ResultState: Integer): Integer;
    function FindInsPos(Key: Int64; var Exists: Boolean): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TInt64Map);

    function Add(Key, Value: Int64): Boolean;
    function Remove(Key: Int64): Int64;
    function Delete(Index: Integer): Int64;
    procedure Clear;
    function FirstKey: Int64;
    function LastKey: Int64;
    function KeyExists(Key: Int64): Boolean;
    function IndexOf(Key: Int64): Integer;
    function GetValue(Key: Int64; var Value: Int64): Boolean;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TInt64MapItem read GetItems;
    property Values[Key: Int64]: Int64 read GetValues write SetValues; default;
  end;

{ TIntMultiMap - 整型排序MultiMap }

  TIntMMapItem = TIntMapItem;

  TIntMultiMap = class(TSyncObject)
  private
    FKeyList: TIntList;
    FValueList: TIntList;

    function GetCount: Integer;
    function GetItems(Index: Integer): TIntMMapItem;
    function FindKey(Key: Integer): Integer;
    function FindKeyNearest(Key: Integer; Lower: Boolean; var ResultState: Integer): Integer;
    function FindInsPos(Key: Integer; var Exists: Boolean): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TIntMultiMap);

    function Add(Key, Value: Integer): Integer;
    function Delete(Index: Integer): Integer;
    procedure Clear;
    function FirstKey: Integer;
    function LastKey: Integer;
    function LowerIndexOf(Key: Integer): Integer;
    function UpperIndexOf(Key: Integer): Integer;
    function LowerBound(Key: Integer): Integer;
    function UpperBound(Key: Integer): Integer;
    function KeyExists(Key: Integer): Boolean;
    function KeyCount(Key: Integer): Integer;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TIntMMapItem read GetItems;
  end;

{ TInt64MultiMap - 大整型排序MultiMap }

  TInt64MMapItem = TInt64MapItem;

  TInt64MultiMap = class(TSyncObject)
  private
    FKeyList: TInt64List;
    FValueList: TInt64List;

    function GetCount: Integer;
    function GetItems(Index: Integer): TInt64MMapItem;
    function FindKey(Key: Int64): Integer;
    function FindKeyNearest(Key: Int64; Lower: Boolean; var ResultState: Integer): Integer;
    function FindInsPos(Key: Int64; var Exists: Boolean): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TInt64MultiMap);

    function Add(Key, Value: Int64): Integer;
    function Delete(Index: Integer): Int64;
    procedure Clear;
    function FirstKey: Int64;
    function LastKey: Int64;
    function LowerIndexOf(Key: Int64): Integer;
    function UpperIndexOf(Key: Int64): Integer;
    function LowerBound(Key: Int64): Integer;
    function UpperBound(Key: Int64): Integer;
    function KeyExists(Key: Int64): Boolean;
    function KeyCount(Key: Int64): Integer;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TInt64MMapItem read GetItems;
  end;

{ TIntSet - 整型排序SET }

  TIntSet = class(TSyncObject)
  private
    FItems: TIntList;

    function GetCount: Integer;
    function GetItems(Index: Integer): Integer;
    function Find(Value: Integer): Integer;
    function FindNearest(Value: Integer; var ResultState: Integer): Integer;
    function FindInsPos(Value: Integer; var Exists: Boolean): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TIntSet);

    function Add(Value: Integer): Boolean;
    function Remove(Value: Integer): Boolean;
    function Delete(Index: Integer): Boolean;
    procedure Clear;
    function FirstValue: Integer;
    function LastValue: Integer;
    function ValueExists(Value: Integer): Boolean;
    function IndexOf(Value: Integer): Integer;
    function Equal(IntSet: TIntSet): Boolean;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: Integer read GetItems; default;
  end;

{ TInt64Set - 大整型排序SET }

  TInt64Set = class(TSyncObject)
  private
    FItems: TInt64List;

    function GetCount: Integer;
    function GetItems(Index: Integer): Int64;
    function Find(Value: Int64): Integer;
    function FindNearest(Value: Int64; var ResultState: Integer): Integer;
    function FindInsPos(Value: Int64; var Exists: Boolean): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TInt64Set);

    function Add(Value: Int64): Boolean;
    function Remove(Value: Int64): Boolean;
    function Delete(Index: Integer): Boolean;
    procedure Clear;
    function FirstValue: Int64;
    function LastValue: Int64;
    function ValueExists(Value: Int64): Boolean;
    function IndexOf(Value: Int64): Integer;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: Int64 read GetItems; default;
  end;

{ TPropertyList - 属性列表 }
{
  说明:
  1. 属性列表中的每个项目由属性名(Name)和属性值(Value)组成。
  2. 属性名不可重复，不区分大小写，且其中不可含有等号"="。属性值可为任意值。
}

  PPropertyItem = ^TPropertyItem;
  TPropertyItem = record
    Name: string;
    Value: string;
  end;

  TPropertyList = class(TSyncObject)
  private
    FItems: TList;      // PPropertyItem[]

    function GetCount: Integer;
    function GetItemPtrs(Index: Integer): PPropertyItem;
    function GetItems(Index: Integer): TPropertyItem;
    function GetValues(const Name: string): string;
    function GetPropString: string;
    procedure SetValues(const Name, Value: string);
    procedure SetPropString(const Value: string);

    procedure DoAdd(const Name, Value: string);
    property ItemPtrs[Index: Integer]: PPropertyItem read GetItemPtrs;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Assign(Source: TPropertyList);
    procedure Add(const Name, Value: string);
    function Remove(const Name: string): Boolean;
    procedure Clear;
    function IndexOf(const Name: string): Integer;
    function NameExists(const Name: string): Boolean;
    function GetValue(const Name: string; var Value: string): Boolean;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TPropertyItem read GetItems;
    property Values[const Name: string]: string read GetValues write SetValues; default;
    property PropString: string read GetPropString write SetPropString; 
  end;

{ TBufferStream - 内存流 (注: 比 TMemoryStream 节省内存) }

  TBufferStream = class(TMemoryStream)
  private
    FMemoryDelta: Integer;    // 内存增长步长 (字节数，必须是 2 的 N 次方)
    function GetMemory: PChar;
    procedure SetMemoryDelta(Value: Integer);
  protected
    function Realloc(var NewCapacity: Longint): Pointer; override;
  public
    constructor Create;
    procedure Assign(Source: TMemoryStream); overload;
    procedure Assign(const Buffer; Size: Integer); overload;

    property Memory: PChar read GetMemory;
    property MemoryDelta: Integer read FMemoryDelta write SetMemoryDelta;
  end;

{ TBufferList - 缓存列表 }

  TBufferList = class(TCustomObjectList)
  protected
    function GetItems(Index: Integer): TBufferStream;
    procedure SetItems(Index: Integer; Item: TBufferStream);
  public
    function New: TBufferStream;
    function Add(Item: TBufferStream): Integer;
    function Remove(Item: TBufferStream): Integer;
    function Extract(Item: TBufferStream): TBufferStream; overload;
    function Extract(Index: Integer): TBufferStream; overload;
    procedure Delete(Index: Integer);
    procedure Insert(Index: Integer; Item: TBufferStream);
    function IndexOf(Item: TBufferStream): Integer;
    function First: TBufferStream;
    function Last: TBufferStream;
    procedure Clear;

    property OwnsObjects;
    property Items[Index: Integer]: TBufferStream read GetItems write SetItems; default;
  end;

{ TWrapStream - 包装流(用于包装一块给定的固定内存) }

  TWrapStream = class(TStream)
  private
    FBuffer: PChar;
    FSize: Integer;
    FPosition: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Wrap(const Buffer; Count: Integer);

    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    procedure SetSize(NewSize: Longint); override;
  end;

{ TCircleStream - 固定大小循环流 }

  TCircleStream = class(TObject)
  private
    FReadPos, FWritePos: Integer;
    FSection: TCriticalSection;

    FBufStr: string;
    FBufLen: Integer;
    FMaxSize: Integer;

    procedure SeekForward(var Pos: Integer; Len: Integer);

    function GetSize: Integer;
    function GetMaxSize: Integer;
    function GetReadPtr: PChar;
    function GetWritePtr: PChar;
    function GetFirstPtr: PChar;

    property FirstPtr: PChar read GetFirstPtr;
  public
    constructor Create(AMaxSize: Integer);
    destructor Destroy; override;

    procedure InitPosition;

    function Read(var Buffer; ASize: Integer): Integer;
    function Write(const Buffer; ASize: Integer): Integer;

    procedure Lock;
    procedure UnLock;

    property MaxSize: Integer read GetMaxSize;
    property Size: Integer read GetSize;
    property ReadPtr: PChar read GetReadPtr;
    property WritePtr: PChar read GetWritePtr;
  end;

implementation

const
  SListCapacityError = 'List capacity out of bounds (%d)';
  SListCountError = 'List count out of bounds (%d)';
  SListIndexError = 'List index out of bounds (%d)';
  SPropListNameError = 'Invalid name in property list (%s)';
  SBufferStreamOutOfMemory = 'Out of memory while expanding memory stream';
  SWrapStreamCannotSetSize = 'TWrapStream.SetSize is inavailable';

{ TSyncObject }

constructor TSyncObject.Create;
begin
  inherited;
end;

destructor TSyncObject.Destroy;
begin
  SetThreadSafe(False);
  inherited;
end;

function TSyncObject.GetThreadSafe: Boolean;
begin
  Result := (FLockPtr <> nil);
end;

procedure TSyncObject.SetThreadSafe(Value: Boolean);
begin
  if Value then
  begin
    if FLockPtr = nil then
    begin
      New(FLockPtr);
      InitializeCriticalSection(FLockPtr^);
    end;
  end else
  begin
    if FLockPtr <> nil then
    begin
      DeleteCriticalSection(FLockPtr^);
      Dispose(FLockPtr);
      FLockPtr := nil;
    end;
  end;
end;

function TSyncObject.TryLock: Boolean;
begin
  if FLockPtr <> nil then
    Result := TryEnterCriticalSection(FLockPtr^)     // Win98/ME 下永远返回 False !
  else
    Result := True;
end;

procedure TSyncObject.Lock;
begin
  if FLockPtr <> nil then
    EnterCriticalSection(FLockPtr^);
end;

procedure TSyncObject.Unlock;
begin
  if FLockPtr <> nil then
    LeaveCriticalSection(FLockPtr^);
end;

{ TCustomObjectList }

constructor TCustomObjectList.Create;
begin
  Create(False, True);
end;

constructor TCustomObjectList.Create(ThreadSafe, OwnsObjects: Boolean);
begin
  inherited Create;
  FItems := TList.Create;
  Self.ThreadSafe := ThreadSafe;
  Self.OwnsObjects := OwnsObjects;
end;

destructor TCustomObjectList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited;
end;

function TCustomObjectList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TCustomObjectList.GetItems(Index: Integer): TObject;
begin
  Assert((Index >= 0) and (Index < FItems.Count));
  Result := TObject(FItems[Index]);
end;

procedure TCustomObjectList.SetItems(Index: Integer; Item: TObject);
begin
  Assert((Index >= 0) and (Index < FItems.Count));
  FItems[Index] := Item;
end;

procedure TCustomObjectList.NotifyDelete(Index: Integer);
var
  Item: TObject;
begin
  if FOwnsObjects then
  begin
    Item := FItems[Index];
    FItems[Index] := nil;   // 防止重入时同一对象被释放两遍
    Item.Free;
  end;
end;

function TCustomObjectList.Add(Item: TObject; AllowDuplicate: Boolean): Integer;
begin
  Lock;
  try
    if AllowDuplicate or (FItems.IndexOf(Item) = -1) then
      Result := FItems.Add(Item)
    else
      Result := -1;
  finally
    Unlock;
  end;
end;

function TCustomObjectList.Remove(Item: TObject): Integer;
begin
  Lock;
  try
    Result := FItems.IndexOf(Item);
    if Result >= 0 then
    begin
      NotifyDelete(Result);
      FItems.Delete(Result);
    end;
  finally
    Unlock;
  end;
end;

function TCustomObjectList.Extract(Item: TObject): TObject;
var
  I: Integer;
begin
  Lock;
  try
    Result := nil;
    I := FItems.Remove(Item);
    if I >= 0 then
      Result := Item;
  finally
    Unlock;
  end;
end;

function TCustomObjectList.Extract(Index: Integer): TObject;
begin
  Lock;
  try
    Result := nil;
    if (Index >= 0) and (Index < FItems.Count) then
    begin
      Result := TObject(FItems[Index]);
      FItems.Delete(Index);
    end;
  finally
    Unlock;
  end;
end;

procedure TCustomObjectList.Delete(Index: Integer);
begin
  Lock;
  try
    if (Index >= 0) and (Index < FItems.Count) then
    begin
      NotifyDelete(Index);
      FItems.Delete(Index);
    end;
  finally
    Unlock;
  end;
end;

procedure TCustomObjectList.Insert(Index: Integer; Item: TObject);
begin
  Lock;
  try
    FItems.Insert(Index, Item);
  finally
    Unlock;
  end;
end;

function TCustomObjectList.IndexOf(Item: TObject): Integer;
begin
  Lock;
  try
    Result := FItems.IndexOf(Item);
  finally
    Unlock;
  end;
end;

function TCustomObjectList.Exists(Item: TObject): Boolean;
begin
  Lock;
  try
    Result := (FItems.IndexOf(Item) >= 0);
  finally
    Unlock;
  end;
end;

function TCustomObjectList.First: TObject;
begin
  Lock;
  try
    Result := TObject(FItems.First);
  finally
    Unlock;
  end;
end;

function TCustomObjectList.Last: TObject;
begin
  Lock;
  try
    Result := TObject(FItems.Last);
  finally
    Unlock;
  end;
end;

procedure TCustomObjectList.Clear;
var
  I: Integer;
begin
  Lock;
  try
    for I := FItems.Count - 1 downto 0 do
      NotifyDelete(I);
    FItems.Clear;
  finally
    Unlock;
  end;
end;

procedure TCustomObjectList.FreeObjects;
var
  I: Integer;
  Item: TObject;
begin
  Lock;
  try
    for I := FItems.Count - 1 downto 0 do
    begin
      Item := TObject(FItems[I]);
      FItems[I] := nil;
      Item.Free;
    end;
  finally
    Unlock;
  end;
end;

procedure TCustomObjectList.Sort(CompareProc: TListSortCompare);
begin
  Lock;
  try
    FItems.Sort(CompareProc);
  finally
    Unlock;
  end;
end;

{ TObjectList }

function TObjectList.Add(Item: TObject; AllowDuplicate: Boolean): Integer;
begin
  Result := inherited Add(Item, AllowDuplicate);
end;

function TObjectList.Remove(Item: TObject): Integer;
begin
  Result := inherited Remove(Item);
end;

function TObjectList.Extract(Item: TObject): TObject;
begin
  Result := inherited Extract(Item);
end;

function TObjectList.Extract(Index: Integer): TObject;
begin
  Result := inherited Extract(Index);
end;

procedure TObjectList.Delete(Index: Integer);
begin
  inherited Delete(Index);
end;

procedure TObjectList.Insert(Index: Integer; Item: TObject);
begin
  inherited Insert(Index, Item);
end;

function TObjectList.IndexOf(Item: TObject): Integer;
begin
  Result := inherited IndexOf(Item);
end;

function TObjectList.Exists(Item: TObject): Boolean;
begin
  Result := inherited Exists(Item);
end;

function TObjectList.First: TObject;
begin
  Result := inherited First;
end;

function TObjectList.Last: TObject;
begin
  Result := inherited Last;
end;

procedure TObjectList.Clear;
begin
  inherited Clear;
end;

procedure TObjectList.FreeObjects;
begin
  inherited FreeObjects;
end;

procedure TObjectList.Sort(CompareProc: TListSortCompare);
begin
  inherited Sort(CompareProc);
end;

{ TIntList }

constructor TIntList.Create;
begin
  inherited;
end;

destructor TIntList.Destroy;
begin
  Clear;
  inherited;
end;

function TIntList.Get(Index: Integer): Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    Error(SListIndexError, Index);
  Result := FList^[Index];
end;

procedure TIntList.Put(Index: Integer; Item: Integer);
var
  Temp: Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    Error(SListIndexError, Index);
  if Item <> FList^[Index] then
  begin
    Temp := FList^[Index];
    FList^[Index] := Item;
    if Temp <> 0 then
      Notify(Temp, lnDeleted);
    if Item <> 0 then
      Notify(Item, lnAdded);
  end;
end;

procedure TIntList.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then
    Delta := FCapacity div 4
  else
    if FCapacity > 8 then
      Delta := 16
    else
      Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

procedure TIntList.SetCapacity(NewCapacity: Integer);
begin
  if (NewCapacity < FCount) or (NewCapacity > MaxListSize) then
    Error(SListCapacityError, NewCapacity);
  if NewCapacity <> FCapacity then
  begin
    ReallocMem(FList, NewCapacity * SizeOf(Integer));
    FCapacity := NewCapacity;
  end;
end;

procedure TIntList.SetCount(NewCount: Integer);
var
  I: Integer;
begin
  if (NewCount < 0) or (NewCount > MaxListSize) then
    Error(SListCountError, NewCount);
  if NewCount > FCapacity then
    SetCapacity(NewCount);
  if NewCount > FCount then
    FillChar(FList^[FCount], (NewCount - FCount) * SizeOf(Integer), 0)
  else
    for I := FCount - 1 downto NewCount do
      Delete(I);
  FCount := NewCount;
end;

procedure TIntList.Notify(Item: Integer; Action: TListNotification);
begin
  // nothing
end;

procedure TIntList.Error(const Msg: string; Data: Integer);
begin
  raise EListError.CreateFmt(Msg, [Data]);
end;

function TIntList.Add(Item: Integer): Integer;
begin
  Result := FCount;
  if Result = FCapacity then
    Grow;
  FList^[Result] := Item;
  Inc(FCount);
  if Item <> 0 then
    Notify(Item, lnAdded);
end;

procedure TIntList.Delete(Index: Integer);
var
  Temp: Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    Error(SListIndexError, Index);
  Temp := Items[Index];
  Dec(FCount);
  if Index < FCount then
    System.Move(FList^[Index + 1], FList^[Index],
      (FCount - Index) * SizeOf(Integer));
  if Temp <> 0 then
    Notify(Temp, lnDeleted);
end;

function TIntList.Remove(Item: Integer): Integer;
begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Delete(Result);
end;

function TIntList.Extract(Item: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  I := IndexOf(Item);
  if I >= 0 then
  begin
    Result := Item;
    FList^[I] := 0;
    Delete(I);
    Notify(Result, lnExtracted);
  end;
end;

procedure TIntList.Insert(Index: Integer; Item: Integer);
begin
  if (Index < 0) or (Index > FCount) then
    Error(SListIndexError, Index);
  if FCount = FCapacity then
    Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(Integer));
  FList^[Index] := Item;
  Inc(FCount);
  if Item <> 0 then
    Notify(Item, lnAdded);
end;

procedure TIntList.Clear;
begin
  SetCount(0);
  SetCapacity(0);
end;

procedure TIntList.Exchange(Index1, Index2: Integer);
var
  Item: Integer;
begin
  if (Index1 < 0) or (Index1 >= FCount) then
    Error(SListIndexError, Index1);
  if (Index2 < 0) or (Index2 >= FCount) then
    Error(SListIndexError, Index2);
  Item := FList^[Index1];
  FList^[Index1] := FList^[Index2];
  FList^[Index2] := Item;
end;

procedure TIntList.Move(CurIndex, NewIndex: Integer);
var
  Item: Integer;
begin
  if CurIndex <> NewIndex then
  begin
    if (NewIndex < 0) or (NewIndex >= FCount) then
      Error(SListIndexError, NewIndex);
    Item := Get(CurIndex);
    FList^[CurIndex] := 0;
    Delete(CurIndex);
    Insert(NewIndex, 0);
    FList^[NewIndex] := Item;
  end;
end;

function TIntList.IndexOf(Item: Integer): Integer;
begin
  Result := 0;
  while (Result < FCount) and (FList^[Result] <> Item) do
    Inc(Result);
  if Result = FCount then
    Result := -1;
end;

function TIntList.Expand: TIntList;
begin
  if FCount = FCapacity then
    Grow;
  Result := Self;
end;

function TIntList.First: Integer;
begin
  Result := Get(0);
end;

function TIntList.Last: Integer;
begin
  Result := Get(FCount - 1);
end;

function TIntList.Equal(List: TIntList): Boolean;
var
  I: Integer;
begin
  Result := (Count = List.Count);
  if Result then
    for I := 0 to Count - 1 do
      if Items[I] <> List.Items[I] then
      begin
        Result := False;
        Break;
      end;
end;

procedure TIntList.Assign(Source: TIntList);
var
  I: Integer;
begin
  if Source <> Self then
  begin
    Clear;
    Capacity := Source.Capacity;
    for I := 0 to Source.Count - 1 do
      Add(Source[I]);
  end;
end;

{ TInt64List }

constructor TInt64List.Create;
begin
  inherited;
end;

destructor TInt64List.Destroy;
begin
  Clear;
  inherited;
end;

function TInt64List.Get(Index: Integer): Int64;
begin
  if (Index < 0) or (Index >= FCount) then
    Error(SListIndexError, Index);
  Result := FList^[Index];
end;

procedure TInt64List.Put(Index: Integer; Item: Int64);
var
  Temp: Int64;
begin
  if (Index < 0) or (Index >= FCount) then
    Error(SListIndexError, Index);
  if Item <> FList^[Index] then
  begin
    Temp := FList^[Index];
    FList^[Index] := Item;
    if Temp <> 0 then
      Notify(Temp, lnDeleted);
    if Item <> 0 then
      Notify(Item, lnAdded);
  end;
end;

procedure TInt64List.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then
    Delta := FCapacity div 4
  else
    if FCapacity > 8 then
      Delta := 16
    else
      Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

procedure TInt64List.SetCapacity(NewCapacity: Integer);
begin
  if (NewCapacity < FCount) or (NewCapacity > MaxListSize) then
    Error(SListCapacityError, NewCapacity);
  if NewCapacity <> FCapacity then
  begin
    ReallocMem(FList, NewCapacity * SizeOf(Int64));
    FCapacity := NewCapacity;
  end;
end;

procedure TInt64List.SetCount(NewCount: Integer);
var
  I: Integer;
begin
  if (NewCount < 0) or (NewCount > MaxListSize) then
    Error(SListCountError, NewCount);
  if NewCount > FCapacity then
    SetCapacity(NewCount);
  if NewCount > FCount then
    FillChar(FList^[FCount], (NewCount - FCount) * SizeOf(Int64), 0)
  else
    for I := FCount - 1 downto NewCount do
      Delete(I);
  FCount := NewCount;
end;

procedure TInt64List.Notify(Item: Int64; Action: TListNotification);
begin
  // nothing
end;

procedure TInt64List.Error(const Msg: string; Data: Integer);
begin
  raise EListError.CreateFmt(Msg, [Data]);
end;

function TInt64List.Add(Item: Int64): Integer;
begin
  Result := FCount;
  if Result = FCapacity then
    Grow;
  FList^[Result] := Item;
  Inc(FCount);
  if Item <> 0 then
    Notify(Item, lnAdded);
end;

procedure TInt64List.Delete(Index: Integer);
var
  Temp: Int64;
begin
  if (Index < 0) or (Index >= FCount) then
    Error(SListIndexError, Index);
  Temp := Items[Index];
  Dec(FCount);
  if Index < FCount then
    System.Move(FList^[Index + 1], FList^[Index],
      (FCount - Index) * SizeOf(Int64));
  if Temp <> 0 then
    Notify(Temp, lnDeleted);
end;

function TInt64List.Remove(Item: Int64): Integer;
begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Delete(Result);
end;

function TInt64List.Extract(Item: Int64): Int64;
var
  I: Integer;
begin
  Result := 0;
  I := IndexOf(Item);
  if I >= 0 then
  begin
    Result := Item;
    FList^[I] := 0;
    Delete(I);
    Notify(Result, lnExtracted);
  end;
end;

procedure TInt64List.Insert(Index: Integer; Item: Int64);
begin
  if (Index < 0) or (Index > FCount) then
    Error(SListIndexError, Index);
  if FCount = FCapacity then
    Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(Int64));
  FList^[Index] := Item;
  Inc(FCount);
  if Item <> 0 then
    Notify(Item, lnAdded);
end;

procedure TInt64List.Clear;
begin
  SetCount(0);
  SetCapacity(0);
end;

procedure TInt64List.Exchange(Index1, Index2: Integer);
var
  Item: Int64;
begin
  if (Index1 < 0) or (Index1 >= FCount) then
    Error(SListIndexError, Index1);
  if (Index2 < 0) or (Index2 >= FCount) then
    Error(SListIndexError, Index2);
  Item := FList^[Index1];
  FList^[Index1] := FList^[Index2];
  FList^[Index2] := Item;
end;

procedure TInt64List.Move(CurIndex, NewIndex: Integer);
var
  Item: Int64;
begin
  if CurIndex <> NewIndex then
  begin
    if (NewIndex < 0) or (NewIndex >= FCount) then
      Error(SListIndexError, NewIndex);
    Item := Get(CurIndex);
    FList^[CurIndex] := 0;
    Delete(CurIndex);
    Insert(NewIndex, 0);
    FList^[NewIndex] := Item;
  end;
end;

function TInt64List.IndexOf(Item: Int64): Integer;
begin
  Result := 0;
  while (Result < FCount) and (FList^[Result] <> Item) do
    Inc(Result);
  if Result = FCount then
    Result := -1;
end;

function TInt64List.Expand: TInt64List;
begin
  if FCount = FCapacity then
    Grow;
  Result := Self;
end;

function TInt64List.First: Int64;
begin
  Result := Get(0);
end;

function TInt64List.Last: Int64;
begin
  Result := Get(FCount - 1);
end;

procedure TInt64List.Assign(Source: TInt64List);
var
  I: Integer;
begin
  if Source <> Self then
  begin
    Clear;
    Capacity := Source.Capacity;
    for I := 0 to Source.Count - 1 do
      Add(Source[I]);
  end;
end;

{ TIntHashTable }

constructor TIntHashTable.Create(Buckets: Cardinal);
begin
  inherited Create;
  if Buckets < 1 then Buckets := 1;
  SetLength(FBuckets, Buckets);
end;

destructor TIntHashTable.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TIntHashTable.Assign(Source: TIntHashTable);
var
  I: Integer;
  P, ItemPtr: PIntHashItem;
  Prev: PPIntHashItem;
begin
  Source.Lock;
  Lock;
  try
    Clear;
    FCount := Source.FCount;
    SetLength(FBuckets, Length(Source.FBuckets));
    for I := 0 to Length(FBuckets) - 1 do
    begin
      Prev := @(FBuckets[I]);
      ItemPtr := Source.FBuckets[I];
      while ItemPtr <> nil do
      begin
        New(P);
        P^ := ItemPtr^;
        Prev^ := P;
        Prev := @(P.Next);
        Notify(P^.Key, P^.Value, htutAdd);

        ItemPtr := ItemPtr.Next;
      end;
    end;
  finally
    Unlock;
    Source.Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 根据键(Key)取得键值(Value)
// 返回: 键值 (若未找到键，则返回 0)
//-----------------------------------------------------------------------------
function TIntHashTable.GetValues(Key: Integer): Integer;
var
  P: PIntHashItem;
begin
  Lock;
  try
    P := FindItem(Key)^;
    if P <> nil then
      Result := P^.Value
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 修改哈希表中的键值
//-----------------------------------------------------------------------------
procedure TIntHashTable.SetValues(Key: Integer; Value: Integer);
var
  P: PIntHashItem;
begin
  Lock;
  try
    P := FindItem(Key)^;
    if P <> nil then
      P^.Value := Value
    else
      Add(Key, Value);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 计算 Key 的哈希值
//-----------------------------------------------------------------------------
function TIntHashTable.HashOf(Key: Integer): Cardinal;
begin
  Result := Cardinal(Key);
end;

//-----------------------------------------------------------------------------
// 描述: 查找 Key 所在的 Bucket 的下标号 (0-based)
//-----------------------------------------------------------------------------
function TIntHashTable.FindBucket(Key: Integer): Integer;
begin
  Result := HashOf(Key) mod Cardinal(Length(FBuckets));
end;

//-----------------------------------------------------------------------------
// 描述: 查找 Key 所在的 HashItem
//-----------------------------------------------------------------------------
function TIntHashTable.FindItem(Key: Integer): PPIntHashItem;
var
  BucketIndex: Integer;
begin
  BucketIndex := FindBucket(Key);
  Result := @FBuckets[BucketIndex];
  while Result^ <> nil do
  begin
    if Result^.Key = Key then
      Exit
    else
      Result := @Result^.Next;
  end;
end;

procedure IntHashTableResizeProc(Param: Pointer; Key, Value: Integer);
begin
  TIntHashTable(Param).Add(Key, Value);
end;

//-----------------------------------------------------------------------------
// 描述: 改变哈希表的桶数量
//-----------------------------------------------------------------------------
procedure TIntHashTable.Resize(Buckets: Cardinal);
var
  TempTable: TIntHashTable;
  SaveEvent: TIntHashTableUpdateEvent;
begin
  TempTable := TIntHashTable.Create(Buckets);
  SaveEvent := Self.FOnUpdate;
  Self.FOnUpdate := nil;
  try
    ForEach(IntHashTableResizeProc, TempTable);
    Self.Assign(TempTable);
  finally
    Self.FOnUpdate := SaveEvent;
    TempTable.Free;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 事件通知
//-----------------------------------------------------------------------------
procedure TIntHashTable.Notify(Key: Integer; Value: Integer;
  Action: THashTableUpdateType);
begin
  if Assigned(FOnUpdate) then
    FOnUpdate(Self, Key, Value, Action);
end;

//-----------------------------------------------------------------------------
// 描述: 向哈希表中增加键
// 返回:
//   True  - 成功
//   False - 失败(重复键)
//-----------------------------------------------------------------------------
function TIntHashTable.Add(Key: Integer; Value: Integer): Boolean;
var
  BucketIndex: Integer;
  P, Item: PIntHashItem;
begin
  Lock;
  try
    P := FindItem(Key)^;
    Result := (P = nil);
    if not Result then Exit;

    if FCount >= Length(FBuckets) then
      Resize(FCount * 2);

    BucketIndex := FindBucket(Key);
    New(Item);
    Item^.Key := Key;
    Item^.Value := Value;
    Item^.Next := FBuckets[BucketIndex];
    FBuckets[BucketIndex] := Item;
    Inc(FCount);
    Notify(Key, Value, htutAdd);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除哈希表中的键
// 返回:
//   <> 0     - 被删除键的键值
//   =  0     - 失败(未找到键Key)
//-----------------------------------------------------------------------------
function TIntHashTable.Remove(Key: Integer): Integer;
var
  P: PIntHashItem;
  Prev: PPIntHashItem;
begin
  Lock;
  try
    Prev := FindItem(Key);
    P := Prev^;
    if P <> nil then
    begin
      Prev^ := P^.Next;
      Notify(Key, P^.Value, htutDelete);
      Result := P^.Value;
      Dispose(P);
      Dec(FCount);
    end else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空哈希表
//-----------------------------------------------------------------------------
procedure TIntHashTable.Clear;
var
  I: Integer;
  P, N: PIntHashItem;
begin
  Lock;
  try
    for I := 0 to Length(FBuckets) - 1 do
    begin
      P := FBuckets[I];
      while P <> nil do
      begin
        N := P^.Next;
        Notify(P^.Key, P^.Value, htutDelete);
        Dispose(P);
        P := N;
      end;
      FBuckets[I] := nil;
    end;
    FCount := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断键是否存在
//-----------------------------------------------------------------------------
function TIntHashTable.KeyExists(Key: Integer): Boolean;
var
  P: PIntHashItem;
begin
  Lock;
  try
    P := FindItem(Key)^;
    Result := (P <> nil);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 根据键(Key)取得键值(Value)
// 返回:
//   True  - 成功
//   False - 失败 (键不存在)
//-----------------------------------------------------------------------------
function TIntHashTable.GetValue(Key: Integer; var Value: Integer): Boolean;
var
  P: PIntHashItem;
begin
  Lock;
  try
    P := FindItem(Key)^;
    Result := (P <> nil);
    if Result then
      Value := P^.Value;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 遍历哈希表中各个元素
// 参数:
//   Proc  - 遍历哈希表中的每个元素时，要执行的函数
//   Param - 传递给 Proc 的第一个参数
//-----------------------------------------------------------------------------
procedure TIntHashTable.ForEach(Proc: TIntHashTableForEachProc; Param: Pointer);
var
  I: Integer;
  P, N: PIntHashItem;
begin
  Lock;
  try
    for I := 0 to Length(FBuckets) - 1 do
    begin
      P := FBuckets[I];
      while P <> nil do
      begin
        N := P^.Next;
        Proc(Param, P^.Key, P^.Value);
        P := N;
      end;
    end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 取得哈希表中的所有元素
//-----------------------------------------------------------------------------
procedure TIntHashTable.GetItems(var Items: TIntHashItems);
var
  I, Index: Integer;
  P, N: PIntHashItem;
begin
  Lock;
  try
    Index := 0;
    SetLength(Items, Count);

    for I := 0 to Length(FBuckets) - 1 do
    begin
      P := FBuckets[I];
      while P <> nil do
      begin
        N := P^.Next;
        Items[Index] := P^;
        Inc(Index);
        P := N;
      end;
    end;
  finally
    Unlock;
  end;
end;

{ TStrHashTable }

constructor TStrHashTable.Create(Buckets: Cardinal; CaseSensitive: Boolean);
begin
  inherited Create;
  if Buckets < 1 then Buckets := 1;
  SetLength(FBuckets, Buckets);
  FCaseSensitive := CaseSensitive;
end;

destructor TStrHashTable.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TStrHashTable.Assign(Source: TStrHashTable);
var
  I: Integer;
  P, ItemPtr: PStrHashItem;
  Prev: PPStrHashItem;
begin
  Source.Lock;
  Lock;
  try
    Clear;
    FCount := Source.FCount;
    FCaseSensitive := Source.FCaseSensitive;
    SetLength(FBuckets, Length(Source.FBuckets));
    for I := 0 to Length(FBuckets) - 1 do
    begin
      Prev := @(FBuckets[I]);
      ItemPtr := Source.FBuckets[I];
      while ItemPtr <> nil do
      begin
        New(P);
        P^ := ItemPtr^;
        Prev^ := P;
        Prev := @(P.Next);
        Notify(P^.Key, P^.Value, htutAdd);

        ItemPtr := ItemPtr.Next;
      end;
    end;
  finally
    Unlock;
    Source.Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 根据键(Key)取得键值(Value)
// 返回: 键值 (若未找到键，则返回 0)
//-----------------------------------------------------------------------------
function TStrHashTable.GetValues(const Key: string): Integer;
var
  P: PStrHashItem;
begin
  Lock;
  try
    P := FindItem(GetKeyStr(Key))^;
    if P <> nil then
      Result := P^.Value
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 修改哈希表中的键值
//-----------------------------------------------------------------------------
procedure TStrHashTable.SetValues(const Key: string; Value: Integer);
var
  P: PStrHashItem;
begin
  Lock;
  try
    P := FindItem(GetKeyStr(Key))^;
    if P <> nil then
      P^.Value := Value
    else
      Add(Key, Value);
  finally
    Unlock;
  end;
end;

function TStrHashTable.GetKeyStr(const Key: string): string;
begin
  if FCaseSensitive then
    Result := Key else
    Result := AnsiUpperCase(Key);
end;

//-----------------------------------------------------------------------------
// 描述: 计算 Key 的哈希值
//-----------------------------------------------------------------------------
function TStrHashTable.HashOf(const Key: string): Cardinal;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(Key) do
    Result := Result * 5 + Ord(Key[I]);
end;

//-----------------------------------------------------------------------------
// 描述: 查找 Key 所在的 Bucket 的下标号 (0-based)
//-----------------------------------------------------------------------------
function TStrHashTable.FindBucket(const Key: string): Integer;
begin
  Result := HashOf(Key) mod Cardinal(Length(FBuckets));
end;

//-----------------------------------------------------------------------------
// 描述: 查找 Key 所在的 HashItem
//-----------------------------------------------------------------------------
function TStrHashTable.FindItem(const Key: string): PPStrHashItem;

  function IsSameKey(const Key1, Key2: string): Boolean;
  begin
    if FCaseSensitive then
      Result := (Key1 = Key2)
    else
      Result := AnsiSameText(Key1, Key2);
  end;

var
  BucketIndex: Integer;
begin
  BucketIndex := FindBucket(Key);
  Result := @FBuckets[BucketIndex];
  while Result^ <> nil do
  begin
    if IsSameKey(Result^.Key, Key) then
      Exit
    else
      Result := @Result^.Next;
  end;
end;

procedure StrHashTableResizeProc(Param: Pointer; const Key: string; Value: Integer);
begin
  TStrHashTable(Param).Add(Key, Value);
end;

//-----------------------------------------------------------------------------
// 描述: 改变哈希表的桶数量
//-----------------------------------------------------------------------------
procedure TStrHashTable.Resize(Buckets: Cardinal);
var
  TempTable: TStrHashTable;
  SaveEvent: TStrHashTableUpdateEvent;
begin
  TempTable := TStrHashTable.Create(Buckets);
  SaveEvent := Self.FOnUpdate;
  Self.FOnUpdate := nil;
  try
    ForEach(StrHashTableResizeProc, TempTable);
    Self.Assign(TempTable);
  finally
    Self.FOnUpdate := SaveEvent;
    TempTable.Free;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 事件通知
//-----------------------------------------------------------------------------
procedure TStrHashTable.Notify(const Key: string; Value: Integer;
  Action: THashTableUpdateType);
begin
  if Assigned(FOnUpdate) then
    FOnUpdate(Self, Key, Value, Action);
end;

//-----------------------------------------------------------------------------
// 描述: 向哈希表中增加键
// 返回:
//   True  - 成功
//   False - 失败(重复键)
//-----------------------------------------------------------------------------
function TStrHashTable.Add(const Key: string; Value: Integer): Boolean;
var
  BucketIndex: Integer;
  P, Item: PStrHashItem;
  KeyStr: string;
begin
  Lock;
  try
    KeyStr := GetKeyStr(Key);
    P := FindItem(KeyStr)^;
    Result := (P = nil);
    if not Result then Exit;

    if FCount >= Length(FBuckets) then
      Resize(FCount * 2);

    BucketIndex := FindBucket(KeyStr);
    New(Item);
    Item^.Key := Key;
    Item^.Value := Value;
    Item^.Next := FBuckets[BucketIndex];
    FBuckets[BucketIndex] := Item;
    Inc(FCount);
    Notify(Key, Value, htutAdd);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除哈希表中的键
// 返回:
//   <> 0     - 被删除键的键值
//   =  0     - 失败(未找到键Key)
//-----------------------------------------------------------------------------
function TStrHashTable.Remove(const Key: string): Integer;
var
  P: PStrHashItem;
  Prev: PPStrHashItem;
begin
  Lock;
  try
    Prev := FindItem(GetKeyStr(Key));
    P := Prev^;
    if P <> nil then
    begin
      Prev^ := P^.Next;
      Notify(Key, P^.Value, htutDelete);
      Result := P^.Value;
      Dispose(P);
      Dec(FCount);
    end else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空哈希表
//-----------------------------------------------------------------------------
procedure TStrHashTable.Clear;
var
  I: Integer;
  P, N: PStrHashItem;
begin
  Lock;
  try
    for I := 0 to Length(FBuckets) - 1 do
    begin
      P := FBuckets[I];
      while P <> nil do
      begin
        N := P^.Next;
        Notify(P^.Key, P^.Value, htutDelete);
        Dispose(P);
        P := N;
      end;
      FBuckets[I] := nil;
    end;
    FCount := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断键是否存在
//-----------------------------------------------------------------------------
function TStrHashTable.KeyExists(const Key: string): Boolean;
var
  P: PStrHashItem;
begin
  Lock;
  try
    P := FindItem(GetKeyStr(Key))^;
    Result := (P <> nil);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 根据键(Key)取得键值(Value)
// 返回:
//   True  - 成功
//   False - 失败 (键不存在)
//-----------------------------------------------------------------------------
function TStrHashTable.GetValue(const Key: string; var Value: Integer): Boolean;
var
  P: PStrHashItem;
begin
  Lock;
  try
    P := FindItem(GetKeyStr(Key))^;
    Result := (P <> nil);
    if Result then
      Value := P^.Value;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 遍历哈希表中各个元素
// 参数:
//   Proc  - 遍历哈希表中的每个元素时，要执行的函数
//   Param - 传递给 Proc 的第一个参数
//-----------------------------------------------------------------------------
procedure TStrHashTable.ForEach(Proc: TStrHashTableForEachProc; Param: Pointer);
var
  I: Integer;
  P, N: PStrHashItem;
begin
  Lock;
  try
    for I := 0 to Length(FBuckets) - 1 do
    begin
      P := FBuckets[I];
      while P <> nil do
      begin
        N := P^.Next;
        Proc(Param, P^.Key, P^.Value);
        P := N;
      end;
    end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 取得哈希表中的所有元素
//-----------------------------------------------------------------------------
procedure TStrHashTable.GetItems(var Items: TStrHashItems);
var
  I, Index: Integer;
  P, N: PStrHashItem;
begin
  Lock;
  try
    Index := 0;
    SetLength(Items, Count);

    for I := 0 to Length(FBuckets) - 1 do
    begin
      P := FBuckets[I];
      while P <> nil do
      begin
        N := P^.Next;
        Items[Index] := P^;
        Inc(Index);
        P := N;
      end;
    end;
  finally
    Unlock;
  end;
end;

{ TIntMap }

constructor TIntMap.Create;
begin
  inherited;
  FKeyList := TIntList.Create;
  FValueList := TIntList.Create;
end;

destructor TIntMap.Destroy;
begin
  Clear;
  FKeyList.Free;
  FValueList.Free;
  inherited;
end;

procedure TIntMap.Assign(Source: TIntMap);
var
  I: Integer;
begin
  Source.Lock;
  Lock;
  try
    FKeyList.Clear;
    for I := 0 to Source.FKeyList.Count - 1 do
      FKeyList.Add(Source.FKeyList[I]);

    FValueList.Clear;
    for I := 0 to Source.FValueList.Count - 1 do
      FValueList.Add(Source.FValueList[I]);
  finally
    Unlock;
    Source.Unlock;
  end;
end;

function TIntMap.GetItems(Index: Integer): TIntMapItem;
begin
  Lock;
  try
    Assert((Index >= 0) and (Index < Count));
    Result.Key := FKeyList[Index];
    Result.Value := FValueList[Index];
  finally
    Unlock;
  end;
end;

function TIntMap.GetCount: Integer;
begin
  Lock;
  try
    Result := FKeyList.Count;
  finally
    Unlock;
  end;
end;

function TIntMap.GetValues(Key: Integer): Integer;
var
  Index: Integer;
begin
  Lock;
  try
    Index := FindKey(Key);
    if Index <> -1 then
      Result := FValueList[Index]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

procedure TIntMap.SetValues(Key: Integer; const Value: Integer);
var
  Index: Integer;
begin
  Lock;
  try
    Index := FindKey(Key);
    if Index <> -1 then
      FValueList[Index] := Value
    else
      Add(Key, Value);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找键值
// 参数:
//   Key         - 待查找的键值
// 返回:
//   Key在FKeyList中的下标号，如果没找到则返回-1
//-----------------------------------------------------------------------------
function TIntMap.FindKey(Key: Integer): Integer;
var
  ResultState: Integer;
begin
  Result := FindKeyNearest(Key, ResultState);
  if ResultState <> 0 then Result := -1;
end;

//-----------------------------------------------------------------------------
// 描述: 查找离指定键值最近的位置
// 参数:
//   Key         - 待查找的键值
//   ResultState - 存放搜索结果状态
//     0:  待查找的值 = 查找结果位置的值
//     1:  待查找的值 > 查找结果位置的值
//    -1:  待查找的值 < 查找结果位置的值
//    -2:  无记录
// 返回:
//   Key在FKeyList中的下标号，如果无记录则返回-1
//-----------------------------------------------------------------------------
function TIntMap.FindKeyNearest(Key: Integer; var ResultState: Integer): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := Count - 1;
  Result := -1;
  ResultState := -2;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    Result := Mid;
    if Key > FKeyList[Mid] then
    begin
      Lo := Mid + 1;
      ResultState := 1;
    end else if Key < FKeyList[Mid] then
    begin
      Hi := Mid - 1;
      ResultState := -1;
    end else
    begin
      ResultState := 0;
      Break;
    end;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找键的插入位置
// 参数:
//   Key    - 待插入的键
//   Exists - 返回该键是否已经存在
// 返回:
//   插入位置(0-based)
//-----------------------------------------------------------------------------
function TIntMap.FindInsPos(Key: Integer; var Exists: Boolean): Integer;
var
  ResultState: Integer;
begin
  Result := FindKeyNearest(Key, ResultState);
  if ResultState in [0, 1] then Inc(Result)
  else if ResultState = -2 then Result := 0;
  Exists := (ResultState = 0);
end;

//-----------------------------------------------------------------------------
// 描述: 向 Map 中增加键
// 返回:
//   True  - 成功
//   False - 失败(重复键)
//-----------------------------------------------------------------------------
function TIntMap.Add(Key, Value: Integer): Boolean;
var
  Exists: Boolean;
  Index: Integer;
begin
  Lock;
  try
    Result := False;
    Index := FindInsPos(Key, Exists);
    if Exists then Exit;

    FKeyList.Insert(Index, Key);
    FValueList.Insert(Index, Value);
    Result := True;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 Map 中的键
// 返回:
//   <> 0     - 被删除键的键值
//   =  0     - 失败(未找到键Key)
//-----------------------------------------------------------------------------
function TIntMap.Remove(Key: Integer): Integer;
var
  Index: Integer;
begin
  Lock;
  try
    Index := FindKey(Key);
    if Index <> -1 then
    begin
      Result := FValueList[Index];
      FKeyList.Delete(Index);
      FValueList.Delete(Index);
    end else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 Map 中的键
// 返回:
//   <> 0     - 被删除键的键值
//   =  0     - 失败(下标值超出范围)
//-----------------------------------------------------------------------------
function TIntMap.Delete(Index: Integer): Integer;
begin
  Lock;
  try
    if (Index >= 0) and (Index < Count) then
    begin
      Result := FValueList[Index];
      FKeyList.Delete(Index);
      FValueList.Delete(Index);
    end else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空 Map
//-----------------------------------------------------------------------------
procedure TIntMap.Clear;
begin
  Lock;
  try
    FKeyList.Clear;
    FValueList.Clear;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Map 中的最小键
//-----------------------------------------------------------------------------
function TIntMap.FirstKey: Integer;
begin
  Lock;
  try
    if Count > 0 then
      Result := FKeyList[0]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Map 中的最大键
//-----------------------------------------------------------------------------
function TIntMap.LastKey: Integer;
begin
  Lock;
  try
    if Count > 0 then
      Result := FKeyList[Count - 1]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断键是否存在
//-----------------------------------------------------------------------------
function TIntMap.KeyExists(Key: Integer): Boolean;
begin
  Lock;
  try
    Result := FindKey(Key) <> -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回键(Key)在 Map 中的下标号 (0-based)
//-----------------------------------------------------------------------------
function TIntMap.IndexOf(Key: Integer): Integer;
begin
  Lock;
  try
    Result := FindKey(Key);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断两个 IntMap 是否相同
//-----------------------------------------------------------------------------
function TIntMap.Equal(IntMap: TIntMap): Boolean;
begin
  Lock;
  try
    Result := (FKeyList.Equal(IntMap.FKeyList)) and
      (FValueList.Equal(IntMap.FValueList));
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 根据键(Key)取得键值(Value)
// 返回:
//   True  - 成功
//   False - 失败 (键不存在)
//-----------------------------------------------------------------------------
function TIntMap.GetValue(Key: Integer; var Value: Integer): Boolean;
var
  Index: Integer;
begin
  Lock;
  try
    Index := FindKey(Key);
    Result := (Index <> -1);
    if Result then
      Value := FValueList[Index];
  finally
    Unlock;
  end;
end;

{ TInt64Map }

constructor TInt64Map.Create;
begin
  inherited;
  FKeyList := TInt64List.Create;
  FValueList := TInt64List.Create;
end;

destructor TInt64Map.Destroy;
begin
  Clear;
  FKeyList.Free;
  FValueList.Free;
  inherited;
end;

procedure TInt64Map.Assign(Source: TInt64Map);
var
  I: Integer;
begin
  Source.Lock;
  Lock;
  try
    FKeyList.Clear;
    for I := 0 to Source.FKeyList.Count - 1 do
      FKeyList.Add(Source.FKeyList[I]);

    FValueList.Clear;
    for I := 0 to Source.FValueList.Count - 1 do
      FValueList.Add(Source.FValueList[I]);
  finally
    Unlock;
    Source.Unlock;
  end;
end;

function TInt64Map.GetItems(Index: Integer): TInt64MapItem;
begin
  Lock;
  try
    Assert((Index >= 0) and (Index < Count));
    Result.Key := FKeyList[Index];
    Result.Value := FValueList[Index];
  finally
    Unlock;
  end;
end;

function TInt64Map.GetCount: Integer;
begin
  Lock;
  try
    Result := FKeyList.Count;
  finally
    Unlock;
  end;
end;

function TInt64Map.GetValues(Key: Int64): Int64;
var
  Index: Integer;
begin
  Lock;
  try
    Index := FindKey(Key);
    if Index <> -1 then
      Result := FValueList[Index]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

procedure TInt64Map.SetValues(Key: Int64; const Value: Int64);
var
  Index: Integer;
begin
  Lock;
  try
    Index := FindKey(Key);
    if Index <> -1 then
      FValueList[Index] := Value
    else
      Add(Key, Value);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找键值
// 参数:
//   Key         - 待查找的键值
// 返回:
//   Key在FKeyList中的下标号，如果没找到则返回-1
//-----------------------------------------------------------------------------
function TInt64Map.FindKey(Key: Int64): Integer;
var
  ResultState: Integer;
begin
  Result := FindKeyNearest(Key, ResultState);
  if ResultState <> 0 then Result := -1;
end;

//-----------------------------------------------------------------------------
// 描述: 查找离指定键值最近的位置
// 参数:
//   Key         - 待查找的键值
//   ResultState - 存放搜索结果状态
//     0:  待查找的值 = 查找结果位置的值
//     1:  待查找的值 > 查找结果位置的值
//    -1:  待查找的值 < 查找结果位置的值
//    -2:  无记录
// 返回:
//   Key在FKeyList中的下标号，如果无记录则返回-1
//-----------------------------------------------------------------------------
function TInt64Map.FindKeyNearest(Key: Int64; var ResultState: Integer): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := Count - 1;
  Result := -1;
  ResultState := -2;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    Result := Mid;
    if Key > FKeyList[Mid] then
    begin
      Lo := Mid + 1;
      ResultState := 1;
    end else if Key < FKeyList[Mid] then
    begin
      Hi := Mid - 1;
      ResultState := -1;
    end else
    begin
      ResultState := 0;
      Break;
    end;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找键的插入位置
// 参数:
//   Key    - 待插入的键
//   Exists - 返回该键是否已经存在
// 返回:
//   插入位置(0-based)
//-----------------------------------------------------------------------------
function TInt64Map.FindInsPos(Key: Int64; var Exists: Boolean): Integer;
var
  ResultState: Integer;
begin
  Result := FindKeyNearest(Key, ResultState);
  if ResultState in [0, 1] then Inc(Result)
  else if ResultState = -2 then Result := 0;
  Exists := (ResultState = 0);
end;

//-----------------------------------------------------------------------------
// 描述: 向 Map 中增加键
// 返回:
//   True  - 成功
//   False - 失败(重复键)
//-----------------------------------------------------------------------------
function TInt64Map.Add(Key, Value: Int64): Boolean;
var
  Exists: Boolean;
  Index: Integer;
begin
  Lock;
  try
    Result := False;
    Index := FindInsPos(Key, Exists);
    if Exists then Exit;

    FKeyList.Insert(Index, Key);
    FValueList.Insert(Index, Value);
    Result := True;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 Map 中的键
// 返回:
//   <> 0     - 被删除键的键值
//   =  0     - 失败(未找到键Key)
//-----------------------------------------------------------------------------
function TInt64Map.Remove(Key: Int64): Int64;
var
  Index: Integer;
begin
  Lock;
  try
    Index := FindKey(Key);
    if Index <> -1 then
    begin
      Result := FValueList[Index];
      FKeyList.Delete(Index);
      FValueList.Delete(Index);
    end else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 Map 中的键
// 返回:
//   <> 0     - 被删除键的键值
//   =  0     - 失败(下标值超出范围)
//-----------------------------------------------------------------------------
function TInt64Map.Delete(Index: Integer): Int64;
begin
  Lock;
  try
    if (Index >= 0) and (Index < Count) then
    begin
      Result := FValueList[Index];
      FKeyList.Delete(Index);
      FValueList.Delete(Index);
    end else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空 Map
//-----------------------------------------------------------------------------
procedure TInt64Map.Clear;
begin
  Lock;
  try
    FKeyList.Clear;
    FValueList.Clear;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Map 中的最小键
//-----------------------------------------------------------------------------
function TInt64Map.FirstKey: Int64;
begin
  Lock;
  try
    if Count > 0 then
      Result := FKeyList[0]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Map 中的最大键
//-----------------------------------------------------------------------------
function TInt64Map.LastKey: Int64;
begin
  Lock;
  try
    if Count > 0 then
      Result := FKeyList[Count - 1]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断键是否存在
//-----------------------------------------------------------------------------
function TInt64Map.KeyExists(Key: Int64): Boolean;
begin
  Lock;
  try
    Result := FindKey(Key) <> -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回键(Key)在 Map 中的下标号 (0-based)
//-----------------------------------------------------------------------------
function TInt64Map.IndexOf(Key: Int64): Integer;
begin
  Lock;
  try
    Result := FindKey(Key);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 根据键(Key)取得键值(Value)
// 返回:
//   True  - 成功
//   False - 失败 (键不存在)
//-----------------------------------------------------------------------------
function TInt64Map.GetValue(Key: Int64; var Value: Int64): Boolean;
var
  Index: Integer;
begin
  Lock;
  try
    Index := FindKey(Key);
    Result := (Index <> -1);
    if Result then
      Value := FValueList[Index];
  finally
    Unlock;
  end;
end;

{ TIntMultiMap }

constructor TIntMultiMap.Create;
begin
  inherited;
  FKeyList := TIntList.Create;
  FValueList := TIntList.Create;
end;

destructor TIntMultiMap.Destroy;
begin
  Clear;
  FKeyList.Free;
  FValueList.Free;
  inherited;
end;

procedure TIntMultiMap.Assign(Source: TIntMultiMap);
var
  I: Integer;
begin
  Source.Lock;
  Lock;
  try
    FKeyList.Clear;
    for I := 0 to Source.FKeyList.Count - 1 do
      FKeyList.Add(Source.FKeyList[I]);

    FValueList.Clear;
    for I := 0 to Source.FValueList.Count - 1 do
      FValueList.Add(Source.FValueList[I]);
  finally
    Unlock;
    Source.Unlock;
  end;
end;

function TIntMultiMap.GetCount: Integer;
begin
  Lock;
  try
    Result := FKeyList.Count;
  finally
    Unlock;
  end;
end;

function TIntMultiMap.GetItems(Index: Integer): TIntMMapItem;
begin
  Lock;
  try
    Assert((Index >= 0) and (Index < Count));
    Result.Key := FKeyList[Index];
    Result.Value := FValueList[Index];
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找键值
// 参数:
//   Key         - 待查找的键值
// 返回:
//   Key在FKeyList中的下标号(若有重复Key，则为第一个)，如果没找到则返回-1
//-----------------------------------------------------------------------------
function TIntMultiMap.FindKey(Key: Integer): Integer;
var
  ResultState: Integer;
begin
  Result := FindKeyNearest(Key, True, ResultState);
  if ResultState <> 0 then Result := -1;
end;

//-----------------------------------------------------------------------------
// 描述: 查找离指定键值最近的位置
// 参数:
//   Key         - 待查找的键值
//   Lower       - 当找到指定键值并有重复键时，返回的位置朝哪一边对齐
//                 True:   返回第一个等于键值的元素位置
//                 False:  返回最后一个等于键值的元素位置
//   ResultState - 存放搜索结果状态
//                  0:  待查找的值 = 查找结果位置的值
//                  1:  待查找的值 > 查找结果位置的值
//                 -1:  待查找的值 < 查找结果位置的值
//                 -2:  无记录
// 返回:
//   Key在FKeyList中的下标号，如果无记录则返回-1
//-----------------------------------------------------------------------------
function TIntMultiMap.FindKeyNearest(Key: Integer; Lower: Boolean;
  var ResultState: Integer): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := Count - 1;
  Result := -1;
  ResultState := -2;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    Result := Mid;
    if Key > FKeyList[Mid] then
    begin
      Lo := Mid + 1;
      ResultState := 1;
    end else if Key < FKeyList[Mid] then
    begin
      Hi := Mid - 1;
      ResultState := -1;
    end else
    begin
      if Lower then
        while (Result > 0) and (Key = FKeyList[Result - 1]) do Dec(Result)
      else
        while (Result < Count - 1) and (Key = FKeyList[Result + 1]) do Inc(Result);
      ResultState := 0;
      Break;
    end;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找键的插入位置
// 参数:
//   Key    - 待插入的键
//   Exists - 返回该键是否已经存在
// 返回:
//   插入位置(0-based)。(若有重复键，则插在所有重复键的最后)
//-----------------------------------------------------------------------------
function TIntMultiMap.FindInsPos(Key: Integer; var Exists: Boolean): Integer;
var
  ResultState: Integer;
begin
  Result := FindKeyNearest(Key, False, ResultState);
  if ResultState in [0, 1] then Inc(Result)
  else if ResultState = -2 then Result := 0;
  Exists := (ResultState = 0);
end;

//-----------------------------------------------------------------------------
// 描述: 向 MultiMap 中增加键
// 返回: 新增的键在 MultiMap 中的下标号(0-based)。
//-----------------------------------------------------------------------------
function TIntMultiMap.Add(Key, Value: Integer): Integer;
var
  Exists: Boolean;
  Index: Integer;
begin
  Lock;
  try
    Index := FindInsPos(Key, Exists);

    FKeyList.Insert(Index, Key);
    FValueList.Insert(Index, Value);

    Result := Index;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 MultiMap 中的键
// 返回:
//   <> 0     - 被删除键的键值
//   =  0     - 失败(下标值超出范围)
//-----------------------------------------------------------------------------
function TIntMultiMap.Delete(Index: Integer): Integer;
begin
  Lock;
  try
    if (Index >= 0) and (Index < Count) then
    begin
      Result := FValueList[Index];
      FKeyList.Delete(Index);
      FValueList.Delete(Index);
    end else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空 MultiMap
//-----------------------------------------------------------------------------
procedure TIntMultiMap.Clear;
begin
  Lock;
  try
    FKeyList.Clear;
    FValueList.Clear;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 MultiMap 中的最小键
//-----------------------------------------------------------------------------
function TIntMultiMap.FirstKey: Integer;
begin
  Lock;
  try
    if Count > 0 then
      Result := FKeyList[0]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 MultiMap 中的最大键
//-----------------------------------------------------------------------------
function TIntMultiMap.LastKey: Integer;
begin
  Lock;
  try
    if Count > 0 then
      Result := FKeyList[Count - 1]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回键在 MultiMap 中的最低下标号(0-based)，若键不存在则返回-1
//-----------------------------------------------------------------------------
function TIntMultiMap.LowerIndexOf(Key: Integer): Integer;
var
  ResultState: Integer;
begin
  Lock;
  try
    Result := FindKeyNearest(Key, True, ResultState);
    if ResultState <> 0 then Result := -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回键在 MultiMap 中的最高下标号(0-based)，若键不存在则返回-1
//-----------------------------------------------------------------------------
function TIntMultiMap.UpperIndexOf(Key: Integer): Integer;
var
  ResultState: Integer;
begin
  Lock;
  try
    Result := FindKeyNearest(Key, False, ResultState);
    if ResultState <> 0 then Result := -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 [元素值 >= Key] 的第一个元素下标(0-based)
//       若无符合条件的元素则返回 -1。
//-----------------------------------------------------------------------------
function TIntMultiMap.LowerBound(Key: Integer): Integer;
var
  Index, ResultState: Integer;
begin
  Lock;
  try
    Result := -1;
    Index := FindKeyNearest(Key, True, ResultState);

    case ResultState of
      -1, 0:
        Result := Index;
      1:
        begin
          Result := Index;
          if Result < FKeyList.Count - 1 then Inc(Result);
          if FKeyList[Result] < Key then Result := -1;
        end;
    end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 [元素值 > Key] 的第一个元素下标(0-based)
//       若无符合条件的元素则返回 -1。
//-----------------------------------------------------------------------------
function TIntMultiMap.UpperBound(Key: Integer): Integer;
var
  Index, ResultState: Integer;
begin
  Lock;
  try
    Result := -1;
    Index := FindKeyNearest(Key, False, ResultState);

    case ResultState of
      -1:
        Result := Index;
      0, 1:
        begin
          Result := Index;
          if Result < FKeyList.Count - 1 then Inc(Result);
          if FKeyList[Result] <= Key then Result := -1;
        end;
    end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断键是否存在
//-----------------------------------------------------------------------------
function TIntMultiMap.KeyExists(Key: Integer): Boolean;
begin
  Lock;
  try
    Result := FindKey(Key) <> -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 MultiMap 中键(Key)的数量
//-----------------------------------------------------------------------------
function TIntMultiMap.KeyCount(Key: Integer): Integer;
var
  Index: Integer;
begin
  Lock;
  try
    Result := 0;
    Index := FindKey(Key);
    while Index >= 0 do
    begin
      if FKeyList[Index] = Key then
        Inc(Result)
      else
        Break;
      Dec(Index);
    end;
  finally
    Unlock;
  end;
end;

{ TIntMultiMap }

constructor TInt64MultiMap.Create;
begin
  inherited;
  FKeyList := TInt64List.Create;
  FValueList := TInt64List.Create;
end;

destructor TInt64MultiMap.Destroy;
begin
  Clear;
  FKeyList.Free;
  FValueList.Free;
  inherited;
end;

procedure TInt64MultiMap.Assign(Source: TInt64MultiMap);
var
  I: Integer;
begin
  Source.Lock;
  Lock;
  try
    FKeyList.Clear;
    for I := 0 to Source.FKeyList.Count - 1 do
      FKeyList.Add(Source.FKeyList[I]);

    FValueList.Clear;
    for I := 0 to Source.FValueList.Count - 1 do
      FValueList.Add(Source.FValueList[I]);
  finally
    Unlock;
    Source.Unlock;
  end;
end;

function TInt64MultiMap.GetCount: Integer;
begin
  Lock;
  try
    Result := FKeyList.Count;
  finally
    Unlock;
  end;
end;

function TInt64MultiMap.GetItems(Index: Integer): TInt64MMapItem;
begin
  Lock;
  try
    Assert((Index >= 0) and (Index < Count));
    Result.Key := FKeyList[Index];
    Result.Value := FValueList[Index];
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找键值
// 参数:
//   Key         - 待查找的键值
// 返回:
//   Key在FKeyList中的下标号(若有重复Key，则为第一个)，如果没找到则返回-1
//-----------------------------------------------------------------------------
function TInt64MultiMap.FindKey(Key: Int64): Integer;
var
  ResultState: Integer;
begin
  Result := FindKeyNearest(Key, True, ResultState);
  if ResultState <> 0 then Result := -1;
end;

//-----------------------------------------------------------------------------
// 描述: 查找离指定键值最近的位置
// 参数:
//   Key         - 待查找的键值
//   Lower       - 当找到指定键值并有重复键时，返回的位置朝哪一边对齐
//                 True:   返回第一个等于键值的元素位置
//                 False:  返回最后一个等于键值的元素位置
//   ResultState - 存放搜索结果状态
//                  0:  待查找的值 = 查找结果位置的值
//                  1:  待查找的值 > 查找结果位置的值
//                 -1:  待查找的值 < 查找结果位置的值
//                 -2:  无记录
// 返回:
//   Key在FKeyList中的下标号，如果无记录则返回-1
//-----------------------------------------------------------------------------
function TInt64MultiMap.FindKeyNearest(Key: Int64; Lower: Boolean;
  var ResultState: Integer): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := Count - 1;
  Result := -1;
  ResultState := -2;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    Result := Mid;
    if Key > FKeyList[Mid] then
    begin
      Lo := Mid + 1;
      ResultState := 1;
    end else if Key < FKeyList[Mid] then
    begin
      Hi := Mid - 1;
      ResultState := -1;
    end else
    begin
      if Lower then
        while (Result > 0) and (Key = FKeyList[Result - 1]) do Dec(Result)
      else
        while (Result < Count - 1) and (Key = FKeyList[Result + 1]) do Inc(Result);
      ResultState := 0;
      Break;
    end;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找键的插入位置
// 参数:
//   Key    - 待插入的键
//   Exists - 返回该键是否已经存在
// 返回:
//   插入位置(0-based)。(若有重复键，则插在所有重复键的最后)
//-----------------------------------------------------------------------------
function TInt64MultiMap.FindInsPos(Key: Int64; var Exists: Boolean): Integer;
var
  ResultState: Integer;
begin
  Result := FindKeyNearest(Key, False, ResultState);
  if ResultState in [0, 1] then Inc(Result)
  else if ResultState = -2 then Result := 0;
  Exists := (ResultState = 0);
end;

//-----------------------------------------------------------------------------
// 描述: 向 MultiMap 中增加键
// 返回: 新增的键在 MultiMap 中的下标号(0-based)。
//-----------------------------------------------------------------------------
function TInt64MultiMap.Add(Key, Value: Int64): Integer;
var
  Exists: Boolean;
  Index: Integer;
begin
  Lock;
  try
    Index := FindInsPos(Key, Exists);

    FKeyList.Insert(Index, Key);
    FValueList.Insert(Index, Value);

    Result := Index;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 MultiMap 中的键
// 返回:
//   <> 0     - 被删除键的键值
//   =  0     - 失败(下标值超出范围)
//-----------------------------------------------------------------------------
function TInt64MultiMap.Delete(Index: Integer): Int64;
begin
  Lock;
  try
    if (Index >= 0) and (Index < Count) then
    begin
      Result := FValueList[Index];
      FKeyList.Delete(Index);
      FValueList.Delete(Index);
    end else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空 MultiMap
//-----------------------------------------------------------------------------
procedure TInt64MultiMap.Clear;
begin
  Lock;
  try
    FKeyList.Clear;
    FValueList.Clear;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 MultiMap 中的最小键
//-----------------------------------------------------------------------------
function TInt64MultiMap.FirstKey: Int64;
begin
  Lock;
  try
    if Count > 0 then
      Result := FKeyList[0]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 MultiMap 中的最大键
//-----------------------------------------------------------------------------
function TInt64MultiMap.LastKey: Int64;
begin
  Lock;
  try
    if Count > 0 then
      Result := FKeyList[Count - 1]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回键在 MultiMap 中的最低下标号(0-based)，若键不存在则返回-1
//-----------------------------------------------------------------------------
function TInt64MultiMap.LowerIndexOf(Key: Int64): Integer;
var
  ResultState: Integer;
begin
  Lock;
  try
    Result := FindKeyNearest(Key, True, ResultState);
    if ResultState <> 0 then Result := -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回键在 MultiMap 中的最高下标号(0-based)，若键不存在则返回-1
//-----------------------------------------------------------------------------
function TInt64MultiMap.UpperIndexOf(Key: Int64): Integer;
var
  ResultState: Integer;
begin
  Lock;
  try
    Result := FindKeyNearest(Key, False, ResultState);
    if ResultState <> 0 then Result := -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 [元素值 >= Key] 的第一个元素下标(0-based)
//       若无符合条件的元素则返回 -1。
//-----------------------------------------------------------------------------
function TInt64MultiMap.LowerBound(Key: Int64): Integer;
var
  Index, ResultState: Integer;
begin
  Lock;
  try
    Result := -1;
    Index := FindKeyNearest(Key, True, ResultState);

    case ResultState of
      -1, 0:
        Result := Index;
      1:
        begin
          Result := Index;
          if Result < FKeyList.Count - 1 then Inc(Result);
          if FKeyList[Result] < Key then Result := -1;
        end;
    end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 [元素值 > Key] 的第一个元素下标(0-based)
//       若无符合条件的元素则返回 -1。
//-----------------------------------------------------------------------------
function TInt64MultiMap.UpperBound(Key: Int64): Integer;
var
  Index, ResultState: Integer;
begin
  Lock;
  try
    Result := -1;
    Index := FindKeyNearest(Key, False, ResultState);

    case ResultState of
      -1:
        Result := Index;
      0, 1:
        begin
          Result := Index;
          if Result < FKeyList.Count - 1 then Inc(Result);
          if FKeyList[Result] <= Key then Result := -1;
        end;
    end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断键是否存在
//-----------------------------------------------------------------------------
function TInt64MultiMap.KeyExists(Key: Int64): Boolean;
begin
  Lock;
  try
    Result := FindKey(Key) <> -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 MultiMap 中键(Key)的数量
//-----------------------------------------------------------------------------
function TInt64MultiMap.KeyCount(Key: Int64): Integer;
var
  Index: Integer;
begin
  Lock;
  try
    Result := 0;
    Index := FindKey(Key);
    while Index >= 0 do
    begin
      if FKeyList[Index] = Key then
        Inc(Result)
      else
        Break;
      Dec(Index);
    end;
  finally
    Unlock;
  end;
end;

{ TIntSet }

constructor TIntSet.Create;
begin
  inherited;
  FItems := TIntList.Create;
end;

destructor TIntSet.Destroy;
begin
  Clear;
  FItems.Free;
  inherited;
end;

procedure TIntSet.Assign(Source: TIntSet);
var
  I: Integer;
begin
  Source.Lock;
  Lock;
  try
    FItems.Clear;
    for I := 0 to Source.FItems.Count - 1 do
      FItems.Add(Source.FItems[I]);
  finally
    Unlock;
    Source.Unlock;
  end;
end;

function TIntSet.GetCount: Integer;
begin
  Lock;
  try
    Result := FItems.Count;
  finally
    Unlock;
  end;
end;

function TIntSet.GetItems(Index: Integer): Integer;
begin
  Lock;
  try
    Assert((Index >= 0) and (Index < Count));
    Result := FItems[Index];
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找值
// 参数:
//   Value - 待查找的值
// 返回:
//   Value 在 FItems 中的下标号，如果没找到则返回-1
//-----------------------------------------------------------------------------
function TIntSet.Find(Value: Integer): Integer;
var
  ResultState: Integer;
begin
  Result := FindNearest(Value, ResultState);
  if ResultState <> 0 then Result := -1;
end;

//-----------------------------------------------------------------------------
// 描述: 查找离指定值最近的位置
// 参数:
//   Key         - 待查找的值
//   ResultState - 存放搜索结果状态
//     0:  待查找的值 = 查找结果位置的值
//     1:  待查找的值 > 查找结果位置的值
//    -1:  待查找的值 < 查找结果位置的值
//    -2:  无记录
// 返回:
//   Value 在 FItems 中的下标号，如果无记录则返回-1
//-----------------------------------------------------------------------------
function TIntSet.FindNearest(Value: Integer;
  var ResultState: Integer): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := Count - 1;
  Result := -1;
  ResultState := -2;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    Result := Mid;
    if Value > FItems[Mid] then
    begin
      Lo := Mid + 1;
      ResultState := 1;
    end else if Value < FItems[Mid] then
    begin
      Hi := Mid - 1;
      ResultState := -1;
    end else
    begin
      ResultState := 0;
      Break;
    end;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找值的插入位置
// 参数:
//   Key    - 待插入的值
//   Exists - 返回该值是否已经存在
// 返回:
//   插入位置(0-based)
//-----------------------------------------------------------------------------
function TIntSet.FindInsPos(Value: Integer; var Exists: Boolean): Integer;
var
  ResultState: Integer;
begin
  Result := FindNearest(Value, ResultState);
  if ResultState in [0, 1] then Inc(Result)
  else if ResultState = -2 then Result := 0;
  Exists := (ResultState = 0);
end;

//-----------------------------------------------------------------------------
// 描述: 向 Set 中增加值
// 返回:
//   True  - 成功
//   False - 失败(重复值)
//-----------------------------------------------------------------------------
function TIntSet.Add(Value: Integer): Boolean;
var
  Exists: Boolean;
  Index: Integer;
begin
  Lock;
  try
    Result := False;
    Index := FindInsPos(Value, Exists);
    if Exists then Exit;

    FItems.Insert(Index, Value);
    Result := True;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 Set 中的值
// 返回:
//   True  - 成功
//   False - 失败(未找到)
//-----------------------------------------------------------------------------
function TIntSet.Remove(Value: Integer): Boolean;
var
  Index: Integer;
begin
  Lock;
  try
    Index := Find(Value);
    Result := (Index <> -1);
    if Result then
      FItems.Delete(Index)
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 Set 中的值
// 返回:
//   True  - 成功
//   False - 失败(下标值超出范围)
//-----------------------------------------------------------------------------
function TIntSet.Delete(Index: Integer): Boolean;
begin
  Lock;
  try
    Result := (Index >= 0) and (Index < Count);
    if Result then
      FItems.Delete(Index);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空 Set
//-----------------------------------------------------------------------------
procedure TIntSet.Clear;
begin
  Lock;
  try
    FItems.Clear;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Set 中的最小值
//-----------------------------------------------------------------------------
function TIntSet.FirstValue: Integer;
begin
  Lock;
  try
    if Count > 0 then
      Result := FItems[0]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Set 中的最大值
//-----------------------------------------------------------------------------
function TIntSet.LastValue: Integer;
begin
  Lock;
  try
    if Count > 0 then
      Result := FItems[Count - 1]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断值是否存在
//-----------------------------------------------------------------------------
function TIntSet.ValueExists(Value: Integer): Boolean;
begin
  Lock;
  try
    Result := Find(Value) <> -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回值(Value)在 Set 中的下标号 (0-based)
//-----------------------------------------------------------------------------
function TIntSet.IndexOf(Value: Integer): Integer;
begin
  Lock;
  try
    Result := Find(Value);
  finally
    Unlock;
  end;
end;

{ TIntSet }

constructor TInt64Set.Create;
begin
  inherited;
  FItems := TInt64List.Create;
end;

destructor TInt64Set.Destroy;
begin
  Clear;
  FItems.Free;
  inherited;
end;

procedure TInt64Set.Assign(Source: TInt64Set);
var
  I: Integer;
begin
  Source.Lock;
  Lock;
  try
    FItems.Clear;
    for I := 0 to Source.FItems.Count - 1 do
      FItems.Add(Source.FItems[I]);
  finally
    Unlock;
    Source.Unlock;
  end;
end;

function TInt64Set.GetCount: Integer;
begin
  Lock;
  try
    Result := FItems.Count;
  finally
    Unlock;
  end;
end;

function TInt64Set.GetItems(Index: Integer): Int64;
begin
  Lock;
  try
    Assert((Index >= 0) and (Index < Count));
    Result := FItems[Index];
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找值
// 参数:
//   Value - 待查找的值
// 返回:
//   Value 在 FItems 中的下标号，如果没找到则返回-1
//-----------------------------------------------------------------------------
function TInt64Set.Find(Value: Int64): Integer;
var
  ResultState: Integer;
begin
  Result := FindNearest(Value, ResultState);
  if ResultState <> 0 then Result := -1;
end;

//-----------------------------------------------------------------------------
// 描述: 查找离指定值最近的位置
// 参数:
//   Key         - 待查找的值
//   ResultState - 存放搜索结果状态
//     0:  待查找的值 = 查找结果位置的值
//     1:  待查找的值 > 查找结果位置的值
//    -1:  待查找的值 < 查找结果位置的值
//    -2:  无记录
// 返回:
//   Value 在 FItems 中的下标号，如果无记录则返回-1
//-----------------------------------------------------------------------------
function TInt64Set.FindNearest(Value: Int64;
  var ResultState: Integer): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := Count - 1;
  Result := -1;
  ResultState := -2;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    Result := Mid;
    if Value > FItems[Mid] then
    begin
      Lo := Mid + 1;
      ResultState := 1;
    end else if Value < FItems[Mid] then
    begin
      Hi := Mid - 1;
      ResultState := -1;
    end else
    begin
      ResultState := 0;
      Break;
    end;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 查找值的插入位置
// 参数:
//   Key    - 待插入的值
//   Exists - 返回该值是否已经存在
// 返回:
//   插入位置(0-based)
//-----------------------------------------------------------------------------
function TInt64Set.FindInsPos(Value: Int64; var Exists: Boolean): Integer;
var
  ResultState: Integer;
begin
  Result := FindNearest(Value, ResultState);
  if ResultState in [0, 1] then Inc(Result)
  else if ResultState = -2 then Result := 0;
  Exists := (ResultState = 0);
end;

//-----------------------------------------------------------------------------
// 描述: 向 Set 中增加值
// 返回:
//   True  - 成功
//   False - 失败(重复值)
//-----------------------------------------------------------------------------
function TInt64Set.Add(Value: Int64): Boolean;
var
  Exists: Boolean;
  Index: Integer;
begin
  Lock;
  try
    Result := False;
    Index := FindInsPos(Value, Exists);
    if Exists then Exit;

    FItems.Insert(Index, Value);
    Result := True;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 Set 中的值
// 返回:
//   True  - 成功
//   False - 失败(未找到)
//-----------------------------------------------------------------------------
function TInt64Set.Remove(Value: Int64): Boolean;
var
  Index: Integer;
begin
  Lock;
  try
    Index := Find(Value);
    Result := (Index <> -1);
    if Result then
      FItems.Delete(Index)
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 删除 Set 中的值
// 返回:
//   True  - 成功
//   False - 失败(下标值超出范围)
//-----------------------------------------------------------------------------
function TInt64Set.Delete(Index: Integer): Boolean;
begin
  Lock;
  try
    Result := (Index >= 0) and (Index < Count);
    if Result then
      FItems.Delete(Index);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空 Set
//-----------------------------------------------------------------------------
procedure TInt64Set.Clear;
begin
  Lock;
  try
    FItems.Clear;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Set 中的最小值
//-----------------------------------------------------------------------------
function TInt64Set.FirstValue: Int64;
begin
  Lock;
  try
    if Count > 0 then
      Result := FItems[0]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Set 中的最大值
//-----------------------------------------------------------------------------
function TInt64Set.LastValue: Int64;
begin
  Lock;
  try
    if Count > 0 then
      Result := FItems[Count - 1]
    else
      Result := 0;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断值是否存在
//-----------------------------------------------------------------------------
function TInt64Set.ValueExists(Value: Int64): Boolean;
begin
  Lock;
  try
    Result := Find(Value) <> -1;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回值(Value)在 Set 中的下标号 (0-based)
//-----------------------------------------------------------------------------
function TInt64Set.IndexOf(Value: Int64): Integer;
begin
  Lock;
  try
    Result := Find(Value);
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 比较两个 IntSet 是否相同
//-----------------------------------------------------------------------------
function TIntSet.Equal(IntSet: TIntSet): Boolean;
begin
  Lock;
  try
    Result := FItems.Equal(IntSet.FItems);
  finally
    Unlock;
  end;
end;

{ TPropertyList }

constructor TPropertyList.Create;
begin
  inherited;
  FItems := TList.Create;
end;

destructor TPropertyList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited;
end;

function TPropertyList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TPropertyList.GetItemPtrs(Index: Integer): PPropertyItem;
begin
  Assert((Index >= 0) and (Index < Count));
  Result := PPropertyItem(FItems[Index]);
end;

function TPropertyList.GetItems(Index: Integer): TPropertyItem;
begin
  Lock;
  try
    Result := ItemPtrs[Index]^;
  finally
    Unlock;
  end;
end;

function TPropertyList.GetValues(const Name: string): string;
begin
  if not GetValue(Name, Result) then
    Result := '';
end;

//-----------------------------------------------------------------------------
// 描述: 将整个列表转换成 PropString 并返回
// 示例:
//   [<abc,123>, <def,456>]   ->  abc=123,def=456
//   [<abc,123>, <,456>]      ->  abc=123,=456
//   [<abc,123>, <",456>]     ->  abc=123,"""=456"
//   [<abc,123>, <',456>]     ->  abc=123,'=456
//   [<abc,123>, <def,">]     ->  abc=123,"def="""
//   [<abc,123>, < def,456>]  ->  abc=123," def=456"
//   [<abc,123>, <def,=>]     ->  abc=123,def==
//   [<abc,123>, <=,456>]     ->  抛出异常(Name中不允许存在等号"=")
//-----------------------------------------------------------------------------
function TPropertyList.GetPropString: string;
var
  I: Integer;
  ItemPtr: PPropertyItem;
  StrList: TStringList;
begin
  Lock;
  try
    StrList := TStringList.Create;
    try
      StrList.CaseSensitive := False;

      for I := 0 to FItems.Count - 1 do
      begin
        ItemPtr := ItemPtrs[I];
        StrList.Values[ItemPtr.Name] := ItemPtr.Value;
      end;
      Result := StrList.CommaText;
    finally
      StrList.Free;
    end;
  finally
    Unlock;
  end;
end;

procedure TPropertyList.SetValues(const Name, Value: string);
var
  I: Integer;
begin
  Lock;
  try
    I := IndexOf(Name);
    if I >= 0 then
      ItemPtrs[I].Value := Value
    else
      DoAdd(Name, Value);
  finally
    Unlock;
  end;
end;

procedure TPropertyList.SetPropString(const Value: string);
var
  I: Integer;
  StrList: TStringList;
  Name: string;
begin
  Lock;
  try
    StrList := TStringList.Create;
    try
      StrList.CaseSensitive := False;
      StrList.CommaText := Value;

      Clear;
      for I := 0 to StrList.Count - 1 do
      begin
        Name := StrList.Names[I];
        Add(Name, StrList.Values[Name]);
      end;
    finally
      StrList.Free;
    end;
  finally
    Unlock;
  end;
end;

procedure TPropertyList.DoAdd(const Name, Value: string);
const
  NameValueSeparator = '=';
var
  ItemPtr: PPropertyItem;
begin
  if Pos(NameValueSeparator, Name) <> 0 then
    raise Exception.CreateFmt(SPropListNameError, [Name]);

  New(ItemPtr);
  ItemPtr.Name := Name;
  ItemPtr.Value := Value;
  FItems.Add(ItemPtr);
end;

procedure TPropertyList.Assign(Source: TPropertyList);
var
  I: Integer;
  ItemPtr: PPropertyItem;
begin
  Lock;
  try
    Clear;
    for I := 0 to Source.Count - 1 do
    begin
      ItemPtr := Source.ItemPtrs[I];
      Add(ItemPtr.Name, ItemPtr.Value);
    end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 向列表中添加元素
// 备注: 若 Name 重复，则覆盖 Value 值。
//-----------------------------------------------------------------------------
procedure TPropertyList.Add(const Name, Value: string);
begin
  Lock;
  try
    Values[Name] := Value;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 从列表中删除元素
// 返回:
//   True  - 成功
//   False - 失败(未找到)
//-----------------------------------------------------------------------------
function TPropertyList.Remove(const Name: string): Boolean;
var
  I: Integer;
begin
  Lock;
  try
    I := IndexOf(Name);
    Result := (I >= 0);
    if Result then
    begin
      Dispose(ItemPtrs[I]);
      FItems.Delete(I);
    end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 清空列表
//-----------------------------------------------------------------------------
procedure TPropertyList.Clear;
var
  I: Integer;
begin
  Lock;
  try
    for I := 0 to FItems.Count - 1 do
      Dispose(ItemPtrs[I]);
    FItems.Clear;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 返回 Name 在列表中的下标号 (0-based)
//-----------------------------------------------------------------------------
function TPropertyList.IndexOf(const Name: string): Integer;
var
  I: Integer;
begin
  Lock;
  try
    Result := -1;
    for I := 0 to FItems.Count - 1 do
      if SameText(Name, PPropertyItem(FItems[I]).Name) then
      begin
        Result := I;
        Break;
      end;
  finally
    Unlock;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 判断属性 Name 是否存在于列表中
//-----------------------------------------------------------------------------
function TPropertyList.NameExists(const Name: string): Boolean;
begin
  Result := (IndexOf(Name) >= 0);
end;

//-----------------------------------------------------------------------------
// 描述: 根据键(Name)取得键值(Value)
// 返回:
//   True  - 成功
//   False - 失败 (键不存在)
//-----------------------------------------------------------------------------
function TPropertyList.GetValue(const Name: string; var Value: string): Boolean;
var
  I: Integer;
begin
  Lock;
  try
    I := IndexOf(Name);
    Result := (I >= 0);
    if Result then
      Value := ItemPtrs[I].Value;
  finally
    Unlock;
  end;
end;

{ TBufferStream }

constructor TBufferStream.Create;
begin
  inherited;
  FMemoryDelta := DefBufStreamMemDelta;
end;

function TBufferStream.GetMemory: PChar;
begin
  Result := PChar(inherited Memory);
end;

procedure TBufferStream.SetMemoryDelta(Value: Integer);
const
  MinValue = 256;
var
  I: Integer;
begin
  if Value < MinValue then Value := MinValue;

  // 保证Value是2的N次方
  for I := SizeOf(Integer) * 8 - 1 downto 0 do
    if ((1 shl I) and Value) <> 0 then
    begin
      Value := Value and (1 shl I);
      Break;
    end;
  FMemoryDelta := Value;
end;

function TBufferStream.Realloc(var NewCapacity: Integer): Pointer;
begin
  if (NewCapacity > 0) and (NewCapacity <> Size) then
    NewCapacity := (NewCapacity + (FMemoryDelta - 1)) and not (FMemoryDelta - 1);
  Result := Memory;
  if NewCapacity <> Capacity then
  begin
    if NewCapacity = 0 then
    begin
      FreeMem(Memory);
      Result := nil;
    end else
    begin
      if Capacity = 0 then
        GetMem(Result, NewCapacity)
      else
        ReallocMem(Result, NewCapacity);
      if Result = nil then
        raise EStreamError.Create(SBufferStreamOutOfMemory);
    end;
  end;
end;

procedure TBufferStream.Assign(Source: TMemoryStream);
var
  SavePos: Integer;
begin
  SavePos := Source.Position;
  Self.LoadFromStream(Source);
  Source.Position := SavePos;
end;

procedure TBufferStream.Assign(const Buffer; Size: Integer);
begin
  Clear;
  WriteBuffer(Buffer, Size);
  Position := 0;
end;

{ TBufferList }

function TBufferList.GetItems(Index: Integer): TBufferStream;
begin
  Result := TBufferStream(inherited GetItems(Index));
end;

procedure TBufferList.SetItems(Index: Integer; Item: TBufferStream);
begin
  inherited SetItems(Index, Item);
end;

function TBufferList.New: TBufferStream;
begin
  Result := TBufferStream.Create;
  Add(Result);
end;

function TBufferList.Add(Item: TBufferStream): Integer;
begin
  Result := inherited Add(Item);
end;

function TBufferList.Remove(Item: TBufferStream): Integer;
begin
  Result := inherited Remove(Item);
end;

function TBufferList.Extract(Item: TBufferStream): TBufferStream;
begin
  Result := TBufferStream(inherited Extract(Item));
end;

function TBufferList.Extract(Index: Integer): TBufferStream; 
begin
  Result := TBufferStream(inherited Extract(Index));
end;

procedure TBufferList.Delete(Index: Integer);
begin
  inherited Delete(Index);
end;

procedure TBufferList.Insert(Index: Integer; Item: TBufferStream);
begin
  inherited Insert(Index, Item);
end;

function TBufferList.IndexOf(Item: TBufferStream): Integer;
begin
  Result := inherited IndexOf(Item); 
end;

function TBufferList.First: TBufferStream;
begin
  Result := TBufferStream(inherited First);
end;

function TBufferList.Last: TBufferStream;
begin
  Result := TBufferStream(inherited Last);
end;

procedure TBufferList.Clear;
begin
  inherited Clear;
end;

{ TWrapStream }

constructor TWrapStream.Create;
begin
  inherited;
end;

destructor TWrapStream.Destroy;
begin
  inherited;
end;

procedure TWrapStream.Wrap(const Buffer; Count: Integer);
begin
  if Size < 0 then Size := 0;
  FBuffer := @Buffer;
  FSize := Count;
  FPosition := 0;
end;

function TWrapStream.Read(var Buffer; Count: Integer): Longint;
begin
  if (FPosition >= 0) and (Count >= 0) then
  begin
    Result := FSize - FPosition;
    if Result > 0 then
    begin
      if Result > Count then Result := Count;
      Move(Pointer(Longint(FBuffer) + FPosition)^, Buffer, Result);
      Inc(FPosition, Result);
      Exit;
    end;
  end;
  Result := 0;
end;

function TWrapStream.Write(const Buffer; Count: Integer): Longint;
var
  Pos: Longint;
begin
  if (FPosition >= 0) and (Count >= 0) then
  begin
    if FPosition + Count > FSize then
      Count := FSize - FPosition;
    Pos := FPosition + Count;

    if Pos > 0 then
    begin
      Move(Buffer, Pointer(Longint(FBuffer) + FPosition)^, Count);
      FPosition := Pos;
      Result := Count;
      Exit;
    end;
  end;
  Result := 0;
end;

function TWrapStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  case Origin of
    soFromBeginning: FPosition := Offset;
    soFromCurrent: Inc(FPosition, Offset);
    soFromEnd: FPosition := FSize + Offset;
  end;
  Result := FPosition;
end;

procedure TWrapStream.SetSize(NewSize: Integer);
begin
  raise Exception.Create(SWrapStreamCannotSetSize);
end;

{ TFixedCircleBuffer }

constructor TCircleStream.Create(AMaxSize: Integer);
begin
  inherited Create;
  FSection := TCriticalSection.Create;

  // 注意+1是为了防止头尾指针重叠
  FMaxSize := AMaxSize;
  FBufLen := FMaxSize + 1;

  SetLength(FBufStr, FBufLen);
  FillChar(FBufStr[1], Length(FBufStr), 0);

  FReadPos := 0;
  FWritePos := FReadPos;
end;

destructor TCircleStream.Destroy;
begin
  FSection.Free;
  inherited;
end;

function TCircleStream.GetFirstPtr: PChar;
begin
  Result := PChar(@FBufStr[1]);
end;

function TCircleStream.GetMaxSize: Integer;
begin
  Result := FMaxSize;
end;

function TCircleStream.GetReadPtr: PChar;
begin
  Result := FirstPtr + FReadPos;
end;

function TCircleStream.GetSize: Integer;
begin
  Result := (FWritePos - FReadPos + FBufLen) mod FBufLen;
end;

function TCircleStream.GetWritePtr: PChar;
begin
  Result := FirstPtr + FWritePos;
end;

procedure TCircleStream.InitPosition;
begin
  FWritePos := 0;
  FReadPos := 0;
end;

procedure TCircleStream.Lock;
begin
  FSection.Enter;
end;

function TCircleStream.Read(var Buffer; ASize: Integer): Integer;
var
  APos: Integer;
  LenA, LenB: Integer;
begin
  if ASize < 0 then ASize := 0;
  if ASize >= Size then ASize := Size;

  Result := ASize;

  if ASize <> 0 then
  begin
    // 计算读取完成后的位置
    APos := FReadPos;
    SeekForward(APos, ASize);

    //判断位置是否出现越过最大值
    if APos >= FReadPos then
    begin
      Move(ReadPtr^, Buffer, ASize);
    end else
    begin
      // 分成2段来拷贝, 后边一段长度为FBufLen-FReadPos, 前面一段长度=APos
      LenA := FBufLen - FReadPos;
      LenB := APos;

      Move(ReadPtr^, Buffer, LenA);
      Move(FirstPtr^, (PChar(@Buffer)+LenA)^, LenB);
    end;

    // 移动读指针到指定位置
    FReadPos := APos;
  end;
end;

procedure TCircleStream.SeekForward(var Pos: Integer; Len: Integer);
begin
  Pos := (Pos + Len) mod FBufLen;
end;

procedure TCircleStream.UnLock;
begin
  FSection.Leave;
end;

function TCircleStream.Write(const Buffer; ASize: Integer): Integer;
var
  APos: Integer;
  LenA, LenB: Integer;
begin
  if ASize < 0 then ASize := 0;
  if ASize >= (FMaxSize - Size) then ASize := (FMaxSize - Size);

  Result := ASize;

  if ASize <> 0 then
  begin
    // 计算写入完成后的位置
    APos := FWritePos;
    SeekForward(APos, ASize);

    //判断位置是否出现越过最大值
    if APos >= FWritePos then
    begin
      Move(Buffer, WritePtr^, ASize);
    end else
    begin
      // 分成2段来拷贝, 后边一段长度为FBufLen-FReadPos, 前面一段长度=APos
      LenA := FBufLen - FWritePos;
      LenB := APos;

      Move(Buffer, WritePtr^, LenA);
      Move((PChar(@Buffer)+LenA)^, FirstPtr^, LenB);
    end;

    // 移动读指针到指定位置
    FWritePos := APos;
  end;
end;


end.

