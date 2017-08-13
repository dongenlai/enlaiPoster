
{**********************************************************}
{                                                          }
{    Encrypt, Decrypt and Hash Algorithms                  }
{                                                          }
{    Copyright 2000-2006 DayDream Software                 }
{    All rights reserved.                                  }
{                                                          }
{**********************************************************}

unit JaCipher;

interface

uses
  Windows, Classes, SysUtils;

const
  // 错误代码
  CipherErrGeneric        = 0;  { generic Error }
  CipherErrInvalidKey     = 1;  { Decode Key is not correct }
  CipherErrInvalidKeySize = 2;  { Size of the Key is too large }
  CipherErrNotInitialized = 3;  { Methods Init() or InitKey() were not called }

type

{ Exception classes }

  ECipherException = class(Exception)
  public
    ErrorCode: Integer;
  end;

{ Types }

  PIntArray = ^TIntArray;
  TIntArray = array[0..1023] of Longword;
  PByte = ^Byte;
  PWord = ^Word;
  PLongWord = ^LongWord;

{ THash - 散列算法基类 }

  THashClass = class of THash;

  THash = class(TObject)
  private
    function GetDigestStr(Index: Integer): RawByteString;
  protected
    class function TestVector: Pointer; virtual; {must override}
  public
    destructor Destroy; override;
    procedure Init; virtual;
    procedure Calc(const Data; DataSize: Integer); virtual; {must override}
    procedure Done; virtual;
    function DigestKey: Pointer; virtual; {must override}

    class function DigestKeySize: Integer; virtual; {must override}
    class function CalcBuffer(Digest: Pointer; const Buffer; BufferSize: Integer): RawByteString;
    class function CalcStream(Digest: Pointer; const Stream: TStream; StreamSize: Integer): RawByteString;
    class function CalcString(Digest: Pointer; const Data: RawByteString): RawByteString;
    class function CalcFile(Digest: Pointer; const FileName: RawByteString): RawByteString;
    {test the correct working}
    class function SelfTest: Boolean;

    {give back the Digest binary in a RawByteString}
    property DigestKeyStr: RawByteString index -1 read GetDigestStr;
    {give back the Default RawByteString Format from the Digest}
    property DigestString: RawByteString index  0 read GetDigestStr;
    {give back a HEX-RawByteString form the Digest}
    property DigestBase16: RawByteString index 16 read GetDigestStr;
    {give back a Base64-MIME RawByteString}
    property DigestBase64: RawByteString index 64 read GetDigestStr;
  end;

{ THash_XOR16 }

  THash_XOR16 = class(THash)
  private
    FCRC: Word;
  protected
    class function TestVector: Pointer; override;
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

{ THash_XOR32 }

  THash_XOR32 = class(THash)
  private
    FCRC: Longword;
  protected
    class function TestVector: Pointer; override;
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

{ THash_CRC32 }

  THash_CRC32 = class(THash_XOR32)
  private
  protected
    class function TestVector: Pointer; override;
  public
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
    procedure Done; override;
  end;

{ THash_MD4 }

  THash_MD4 = class(THash)
  protected
    FCount: Longword;
    FBuffer: array[0..63] of Byte;
    FDigest: array[0..9] of Longword;
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); virtual;
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Done; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

{ THash_MD5 }

  THash_MD5 = class(THash_MD4)
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  end;

{ THash_SHA }

  THash_SHA = class(THash_MD4)
  private
    FRotate: Boolean;
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  public
    class function DigestKeySize: Integer; override;
    procedure Done; override;
  end;

{ THash_SHA1 }

  THash_SHA1 = class(THash_SHA)
  protected
    class function TestVector: Pointer; override;
  public
    procedure Init; override;
  end;

{ TEncrypt - 加密算法基类 }

  TEncryptMode = (emCTS, emCBC, emCFB, emOFB, emECB);

  PEncryptRec = ^TEncryptRec;
  TEncryptRec = packed record
    case Integer of
      0: (X: array[0..7] of Byte);
      1: (A, B: Longword);
  end;

  TEncryptClass = class of TEncrypt;

  TEncrypt = class(TObject)
  private
    FMode: TEncryptMode;
    FHash: THash;
    FHashClass: THashClass;
    FKeySize: Integer;
    FBufSize: Integer;
    FUserSize: Integer;
    FBuffer: Pointer;
    FVector: Pointer;
    FFeedback: Pointer;
    FUser: Pointer;
    FFlags: Integer;
    function GetHash: THash;
    procedure SetHashClass(Value: THashClass);
    procedure InternalCodeStream(Source, Dest: TStream; DataSize: Integer; Encode: Boolean);
    procedure InternalCodeFile(const Source, Dest: RawByteString; Encode: Boolean);
  protected
    function GetFlag(Index: Integer): Boolean;
    procedure SetFlag(Index: Integer; Value: Boolean); virtual;
    {used in method Init()}
    procedure InitBegin(var Size: Integer);
    procedure InitEnd(IVector: Pointer);
    {must override}
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); virtual;
    class function TestVector: Pointer; virtual;

    {the encode function, must override}
    procedure Encode(Data: Pointer); virtual;
    {the decode function, must override}
    procedure Decode(Data: Pointer); virtual;
    {the individual Userdata}
    property User: Pointer read FUser;
    property UserSize: Integer read FUserSize;
    {the Key is set from InitKey() and the Hash.DigestKey^ include the encrypted Hash-Key}
    property HasHashKey: Boolean index 0 read GetFlag write SetFlag;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    class function MaxKeySize: Integer;
    {performs a Test of correct work}
    class function SelfTest: Boolean;
    {initialization form the Encrypt}
    procedure Init(const Key; Size: Integer; IVector: Pointer); virtual;
    procedure InitKey(const Key: RawByteString; IVector: Pointer);
    {reset the Feedbackregister with the actual IVector}
    procedure Done; virtual;
    {protect the security Data's, Feedback, Buffer, Vector etc.}
    procedure Protect; virtual;
    {en/decode a TStream, Source and Dest can be the same or Dest = nil
     when DataSize < 0 the Source.Size is used}
    procedure EncodeStream(const Source, Dest: TStream; DataSize: Integer);
    procedure DecodeStream(const Source, Dest: TStream; DataSize: Integer);
    {en/decode a File, Source and Dest can be the same File}
    procedure EncodeFile(const Source, Dest: RawByteString);
    procedure DecodeFile(const Source, Dest: RawByteString);
    {en/decode a Memory, Source and Dest can be the same}
    procedure EncodeBuffer(const Source; var Dest; DataSize: Integer);
    procedure DecodeBuffer(const Source; var Dest; DataSize: Integer);
    {en/decode a RawByteString}
    function EncodeString(const Source: RawByteString): RawByteString;
    function DecodeString(const Source: RawByteString): RawByteString;
    {the Encrypt Mode = cmXXX}
    property Mode: TEncryptMode read FMode write FMode;
    {the Current Hash-Object, to build a Digest from InitKey()}
    property Hash: THash read GetHash;
    {the Class of the Hash-Object}
    property HashClass: THashClass read FHashClass write SetHashClass;
    {the maximal KeySize and BufSize (Size of Feedback, Buffer and Vector}
    property KeySize: Integer read FKeySize;
    property BufSize: Integer read FBufSize;
    {when the Key is set with InitKey() = HasHashKey and IncludeHashKey = True then
     En/Decodefile & En/Decodestream read, write at first the encrypted Key}
    property IncludeHashKey: Boolean index 8 read GetFlag write SetFlag;
    {Init() was called}
    property Initialized: Boolean index 9 read GetFlag write SetFlag;
    {the actual IVector, BufSize Bytes long}
    property Vector: Pointer read FVector;
    {the Feedback register, BufSize Bytes long}
    property Feedback: Pointer read FFeedback;
  end;

{ TEnc_Blowfish }

  TEnc_Blowfish = class(TEncrypt)
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  public
    procedure Init(const Key; Size: Integer; IVector: Pointer); override;
  end;

{ TEnc_Twofish }

  TEnc_Twofish = class(TEncrypt)
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  public
    procedure Init(const Key; Size: Integer; IVector: Pointer); override;
  end;

{ TEnc_IDEA - International Data Encryption Algorithm}

  TEnc_IDEA = class(TEncrypt)
  private
    procedure Cipher(Data, Key: PWordArray);
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  public
    procedure Init(const Key; Size: Integer; IVector: Pointer); override;
  end;

{ Misc Routines }

// 散列函数
function HashString(HashClass: THashClass; const Source: RawByteString; Digest: Pointer = nil): RawByteString;
function HashBuffer(HashClass: THashClass; const Buffer; DataSize: Integer; Digest: Pointer = nil): RawByteString;
function HashStream(HashClass: THashClass; Stream: TStream; Digest: Pointer = nil): RawByteString;
function HashFile(HashClass: THashClass; const FileName: RawByteString; Digest: Pointer = nil): RawByteString;

function HashMD5(const Source: RawByteString; Digest: Pointer = nil): RawByteString;
function HashSHA(const Source: RawByteString; Digest: Pointer = nil): RawByteString;
function HashSHA1(const Source: RawByteString; Digest: Pointer = nil): RawByteString;
function CalcCRC32(const Data; DataSize: Integer): Longword; overload;
function CalcCRC32(LastResult: Longword; const Data; DataSize: Integer): Longword; overload;

// 加密函数
procedure EncryptBuffer(EncryptClass: TEncryptClass;
  const Source; var Dest; DataSize: Integer; const Key: RawByteString);
procedure DecryptBuffer(EncryptClass: TEncryptClass;
  const Source; var Dest; DataSize: Integer; const Key: RawByteString);
procedure EncryptStream(EncryptClass: TEncryptClass;
  SourceStream, DestStream: TStream; const Key: RawByteString);
procedure DecryptStream(EncryptClass: TEncryptClass;
  SourceStream, DestStream: TStream; const Key: RawByteString);
procedure EncryptFile(EncryptClass: TEncryptClass;
  const SourceFile, DestFile: RawByteString; const Key: RawByteString);
procedure DecryptFile(EncryptClass: TEncryptClass;
  const SourceFile, DestFile: RawByteString; const Key: RawByteString);

// 字符串编码
function StrToBase64(Value: PAnsiChar; Len: Integer): RawByteString;
function Base64ToStr(Value: PAnsiChar; Len: Integer): RawByteString;
function StrToBase16(Value: PAnsiChar; Len: Integer): RawByteString;
function Base16ToStr(Value: PAnsiChar; Len: Integer): RawByteString;

implementation

const
  // blowfish -----------------------------------------------------------------
  Blowfish_Data: array[0..3, 0..255] of Longword = (
   ($D1310BA6,$98DFB5AC,$2FFD72DB,$D01ADFB7,$B8E1AFED,$6A267E96,$BA7C9045,$F12C7F99,
    $24A19947,$B3916CF7,$0801F2E2,$858EFC16,$636920D8,$71574E69,$A458FEA3,$F4933D7E,
    $0D95748F,$728EB658,$718BCD58,$82154AEE,$7B54A41D,$C25A59B5,$9C30D539,$2AF26013,
    $C5D1B023,$286085F0,$CA417918,$B8DB38EF,$8E79DCB0,$603A180E,$6C9E0E8B,$B01E8A3E,
    $D71577C1,$BD314B27,$78AF2FDA,$55605C60,$E65525F3,$AA55AB94,$57489862,$63E81440,
    $55CA396A,$2AAB10B6,$B4CC5C34,$1141E8CE,$A15486AF,$7C72E993,$B3EE1411,$636FBC2A,
    $2BA9C55D,$741831F6,$CE5C3E16,$9B87931E,$AFD6BA33,$6C24CF5C,$7A325381,$28958677,
    $3B8F4898,$6B4BB9AF,$C4BFE81B,$66282193,$61D809CC,$FB21A991,$487CAC60,$5DEC8032,
    $EF845D5D,$E98575B1,$DC262302,$EB651B88,$23893E81,$D396ACC5,$0F6D6FF3,$83F44239,
    $2E0B4482,$A4842004,$69C8F04A,$9E1F9B5E,$21C66842,$F6E96C9A,$670C9C61,$ABD388F0,
    $6A51A0D2,$D8542F68,$960FA728,$AB5133A3,$6EEF0B6C,$137A3BE4,$BA3BF050,$7EFB2A98,
    $A1F1651D,$39AF0176,$66CA593E,$82430E88,$8CEE8619,$456F9FB4,$7D84A5C3,$3B8B5EBE,
    $E06F75D8,$85C12073,$401A449F,$56C16AA6,$4ED3AA62,$363F7706,$1BFEDF72,$429B023D,
    $37D0D724,$D00A1248,$DB0FEAD3,$49F1C09B,$075372C9,$80991B7B,$25D479D8,$F6E8DEF7,
    $E3FE501A,$B6794C3B,$976CE0BD,$04C006BA,$C1A94FB6,$409F60C4,$5E5C9EC2,$196A2463,
    $68FB6FAF,$3E6C53B5,$1339B2EB,$3B52EC6F,$6DFC511F,$9B30952C,$CC814544,$AF5EBD09,
    $BEE3D004,$DE334AFD,$660F2807,$192E4BB3,$C0CBA857,$45C8740F,$D20B5F39,$B9D3FBDB,
    $5579C0BD,$1A60320A,$D6A100C6,$402C7279,$679F25FE,$FB1FA3CC,$8EA5E9F8,$DB3222F8,
    $3C7516DF,$FD616B15,$2F501EC8,$AD0552AB,$323DB5FA,$FD238760,$53317B48,$3E00DF82,
    $9E5C57BB,$CA6F8CA0,$1A87562E,$DF1769DB,$D542A8F6,$287EFFC3,$AC6732C6,$8C4F5573,
    $695B27B0,$BBCA58C8,$E1FFA35D,$B8F011A0,$10FA3D98,$FD2183B8,$4AFCB56C,$2DD1D35B,
    $9A53E479,$B6F84565,$D28E49BC,$4BFB9790,$E1DDF2DA,$A4CB7E33,$62FB1341,$CEE4C6E8,
    $EF20CADA,$36774C01,$D07E9EFE,$2BF11FB4,$95DBDA4D,$AE909198,$EAAD8E71,$6B93D5A0,
    $D08ED1D0,$AFC725E0,$8E3C5B2F,$8E7594B7,$8FF6E2FB,$F2122B64,$8888B812,$900DF01C,
    $4FAD5EA0,$688FC31C,$D1CFF191,$B3A8C1AD,$2F2F2218,$BE0E1777,$EA752DFE,$8B021FA1,
    $E5A0CC0F,$B56F74E8,$18ACF3D6,$CE89E299,$B4A84FE0,$FD13E0B7,$7CC43B81,$D2ADA8D9,
    $165FA266,$80957705,$93CC7314,$211A1477,$E6AD2065,$77B5FA86,$C75442F5,$FB9D35CF,
    $EBCDAF0C,$7B3E89A0,$D6411BD3,$AE1E7E49,$00250E2D,$2071B35E,$226800BB,$57B8E0AF,
    $2464369B,$F009B91E,$5563911D,$59DFA6AA,$78C14389,$D95A537F,$207D5BA2,$02E5B9C5,
    $83260376,$6295CFA9,$11C81968,$4E734A41,$B3472DCA,$7B14A94A,$1B510052,$9A532915,
    $D60F573F,$BC9BC6E4,$2B60A476,$81E67400,$08BA6FB5,$571BE91F,$F296EC6B,$2A0DD915,
    $B6636521,$E7B9F9B6,$FF34052E,$C5855664,$53B02D5D,$A99F8FA1,$08BA4799,$6E85076A),
   ($4B7A70E9,$B5B32944,$DB75092E,$C4192623,$AD6EA6B0,$49A7DF7D,$9CEE60B8,$8FEDB266,
    $ECAA8C71,$699A17FF,$5664526C,$C2B19EE1,$193602A5,$75094C29,$A0591340,$E4183A3E,
    $3F54989A,$5B429D65,$6B8FE4D6,$99F73FD6,$A1D29C07,$EFE830F5,$4D2D38E6,$F0255DC1,
    $4CDD2086,$8470EB26,$6382E9C6,$021ECC5E,$09686B3F,$3EBAEFC9,$3C971814,$6B6A70A1,
    $687F3584,$52A0E286,$B79C5305,$AA500737,$3E07841C,$7FDEAE5C,$8E7D44EC,$5716F2B8,
    $B03ADA37,$F0500C0D,$F01C1F04,$0200B3FF,$AE0CF51A,$3CB574B2,$25837A58,$DC0921BD,
    $D19113F9,$7CA92FF6,$94324773,$22F54701,$3AE5E581,$37C2DADC,$C8B57634,$9AF3DDA7,
    $A9446146,$0FD0030E,$ECC8C73E,$A4751E41,$E238CD99,$3BEA0E2F,$3280BBA1,$183EB331,
    $4E548B38,$4F6DB908,$6F420D03,$F60A04BF,$2CB81290,$24977C79,$5679B072,$BCAF89AF,
    $DE9A771F,$D9930810,$B38BAE12,$DCCF3F2E,$5512721F,$2E6B7124,$501ADDE6,$9F84CD87,
    $7A584718,$7408DA17,$BC9F9ABC,$E94B7D8C,$EC7AEC3A,$DB851DFA,$63094366,$C464C3D2,
    $EF1C1847,$3215D908,$DD433B37,$24C2BA16,$12A14D43,$2A65C451,$50940002,$133AE4DD,
    $71DFF89E,$10314E55,$81AC77D6,$5F11199B,$043556F1,$D7A3C76B,$3C11183B,$5924A509,
    $F28FE6ED,$97F1FBFA,$9EBABF2C,$1E153C6E,$86E34570,$EAE96FB1,$860E5E0A,$5A3E2AB3,
    $771FE71C,$4E3D06FA,$2965DCB9,$99E71D0F,$803E89D6,$5266C825,$2E4CC978,$9C10B36A,
    $C6150EBA,$94E2EA78,$A5FC3C53,$1E0A2DF4,$F2F74EA7,$361D2B3D,$1939260F,$19C27960,
    $5223A708,$F71312B6,$EBADFE6E,$EAC31F66,$E3BC4595,$A67BC883,$B17F37D1,$018CFF28,
    $C332DDEF,$BE6C5AA5,$65582185,$68AB9802,$EECEA50F,$DB2F953B,$2AEF7DAD,$5B6E2F84,
    $1521B628,$29076170,$ECDD4775,$619F1510,$13CCA830,$EB61BD96,$0334FE1E,$AA0363CF,
    $B5735C90,$4C70A239,$D59E9E0B,$CBAADE14,$EECC86BC,$60622CA7,$9CAB5CAB,$B2F3846E,
    $648B1EAF,$19BDF0CA,$A02369B9,$655ABB50,$40685A32,$3C2AB4B3,$319EE9D5,$C021B8F7,
    $9B540B19,$875FA099,$95F7997E,$623D7DA8,$F837889A,$97E32D77,$11ED935F,$16681281,
    $0E358829,$C7E61FD6,$96DEDFA1,$7858BA99,$57F584A5,$1B227263,$9B83C3FF,$1AC24696,
    $CDB30AEB,$532E3054,$8FD948E4,$6DBC3128,$58EBF2EF,$34C6FFEA,$FE28ED61,$EE7C3C73,
    $5D4A14D9,$E864B7E3,$42105D14,$203E13E0,$45EEE2B6,$A3AAABEA,$DB6C4F15,$FACB4FD0,
    $C742F442,$EF6ABBB5,$654F3B1D,$41CD2105,$D81E799E,$86854DC7,$E44B476A,$3D816250,
    $CF62A1F2,$5B8D2646,$FC8883A0,$C1C7B6A3,$7F1524C3,$69CB7492,$47848A0B,$5692B285,
    $095BBF00,$AD19489D,$1462B174,$23820E00,$58428D2A,$0C55F5EA,$1DADF43E,$233F7061,
    $3372F092,$8D937E41,$D65FECF1,$6C223BDB,$7CDE3759,$CBEE7460,$4085F2A7,$CE77326E,
    $A6078084,$19F8509E,$E8EFD855,$61D99735,$A969A7AA,$C50C06C2,$5A04ABFC,$800BCADC,
    $9E447A2E,$C3453484,$FDD56705,$0E1E9EC9,$DB73DBD3,$105588CD,$675FDA79,$E3674340,
    $C5C43465,$713E38D8,$3D28F89E,$F16DFF20,$153E21E7,$8FB03D4A,$E6E39F2B,$DB83ADF7),
   ($E93D5A68,$948140F7,$F64C261C,$94692934,$411520F7,$7602D4F7,$BCF46B2E,$D4A20068,
    $D4082471,$3320F46A,$43B7D4B7,$500061AF,$1E39F62E,$97244546,$14214F74,$BF8B8840,
    $4D95FC1D,$96B591AF,$70F4DDD3,$66A02F45,$BFBC09EC,$03BD9785,$7FAC6DD0,$31CB8504,
    $96EB27B3,$55FD3941,$DA2547E6,$ABCA0A9A,$28507825,$530429F4,$0A2C86DA,$E9B66DFB,
    $68DC1462,$D7486900,$680EC0A4,$27A18DEE,$4F3FFEA2,$E887AD8C,$B58CE006,$7AF4D6B6,
    $AACE1E7C,$D3375FEC,$CE78A399,$406B2A42,$20FE9E35,$D9F385B9,$EE39D7AB,$3B124E8B,
    $1DC9FAF7,$4B6D1856,$26A36631,$EAE397B2,$3A6EFA74,$DD5B4332,$6841E7F7,$CA7820FB,
    $FB0AF54E,$D8FEB397,$454056AC,$BA489527,$55533A3A,$20838D87,$FE6BA9B7,$D096954B,
    $55A867BC,$A1159A58,$CCA92963,$99E1DB33,$A62A4A56,$3F3125F9,$5EF47E1C,$9029317C,
    $FDF8E802,$04272F70,$80BB155C,$05282CE3,$95C11548,$E4C66D22,$48C1133F,$C70F86DC,
    $07F9C9EE,$41041F0F,$404779A4,$5D886E17,$325F51EB,$D59BC0D1,$F2BCC18F,$41113564,
    $257B7834,$602A9C60,$DFF8E8A3,$1F636C1B,$0E12B4C2,$02E1329E,$AF664FD1,$CAD18115,
    $6B2395E0,$333E92E1,$3B240B62,$EEBEB922,$85B2A20E,$E6BA0D99,$DE720C8C,$2DA2F728,
    $D0127845,$95B794FD,$647D0862,$E7CCF5F0,$5449A36F,$877D48FA,$C39DFD27,$F33E8D1E,
    $0A476341,$992EFF74,$3A6F6EAB,$F4F8FD37,$A812DC60,$A1EBDDF8,$991BE14C,$DB6E6B0D,
    $C67B5510,$6D672C37,$2765D43B,$DCD0E804,$F1290DC7,$CC00FFA3,$B5390F92,$690FED0B,
    $667B9FFB,$CEDB7D9C,$A091CF0B,$D9155EA3,$BB132F88,$515BAD24,$7B9479BF,$763BD6EB,
    $37392EB3,$CC115979,$8026E297,$F42E312D,$6842ADA7,$C66A2B3B,$12754CCC,$782EF11C,
    $6A124237,$B79251E7,$06A1BBE6,$4BFB6350,$1A6B1018,$11CAEDFA,$3D25BDD8,$E2E1C3C9,
    $44421659,$0A121386,$D90CEC6E,$D5ABEA2A,$64AF674E,$DA86A85F,$BEBFE988,$64E4C3FE,
    $9DBC8057,$F0F7C086,$60787BF8,$6003604D,$D1FD8346,$F6381FB0,$7745AE04,$D736FCCC,
    $83426B33,$F01EAB71,$B0804187,$3C005E5F,$77A057BE,$BDE8AE24,$55464299,$BF582E61,
    $4E58F48F,$F2DDFDA2,$F474EF38,$8789BDC2,$5366F9C3,$C8B38E74,$B475F255,$46FCD9B9,
    $7AEB2661,$8B1DDF84,$846A0E79,$915F95E2,$466E598E,$20B45770,$8CD55591,$C902DE4C,
    $B90BACE1,$BB8205D0,$11A86248,$7574A99E,$B77F19B6,$E0A9DC09,$662D09A1,$C4324633,
    $E85A1F02,$09F0BE8C,$4A99A025,$1D6EFE10,$1AB93D1D,$0BA5A4DF,$A186F20F,$2868F169,
    $DCB7DA83,$573906FE,$A1E2CE9B,$4FCD7F52,$50115E01,$A70683FA,$A002B5C4,$0DE6D027,
    $9AF88C27,$773F8641,$C3604C06,$61A806B5,$F0177A28,$C0F586E0,$006058AA,$30DC7D62,
    $11E69ED7,$2338EA63,$53C2DD94,$C2C21634,$BBCBEE56,$90BCB6DE,$EBFC7DA1,$CE591D76,
    $6F05E409,$4B7C0188,$39720A3D,$7C927C24,$86E3725F,$724D9DB9,$1AC15BB4,$D39EB8FC,
    $ED545578,$08FCA5B5,$D83D7CD3,$4DAD0FC4,$1E50EF5E,$B161E6F8,$A28514D9,$6C51133C,
    $6FD5C7E7,$56E14EC4,$362ABFCE,$DDC6C837,$D79A3234,$92638212,$670EFA8E,$406000E0),
   ($3A39CE37,$D3FAF5CF,$ABC27737,$5AC52D1B,$5CB0679E,$4FA33742,$D3822740,$99BC9BBE,
    $D5118E9D,$BF0F7315,$D62D1C7E,$C700C47B,$B78C1B6B,$21A19045,$B26EB1BE,$6A366EB4,
    $5748AB2F,$BC946E79,$C6A376D2,$6549C2C8,$530FF8EE,$468DDE7D,$D5730A1D,$4CD04DC6,
    $2939BBDB,$A9BA4650,$AC9526E8,$BE5EE304,$A1FAD5F0,$6A2D519A,$63EF8CE2,$9A86EE22,
    $C089C2B8,$43242EF6,$A51E03AA,$9CF2D0A4,$83C061BA,$9BE96A4D,$8FE51550,$BA645BD6,
    $2826A2F9,$A73A3AE1,$4BA99586,$EF5562E9,$C72FEFD3,$F752F7DA,$3F046F69,$77FA0A59,
    $80E4A915,$87B08601,$9B09E6AD,$3B3EE593,$E990FD5A,$9E34D797,$2CF0B7D9,$022B8B51,
    $96D5AC3A,$017DA67D,$D1CF3ED6,$7C7D2D28,$1F9F25CF,$ADF2B89B,$5AD6B472,$5A88F54C,
    $E029AC71,$E019A5E6,$47B0ACFD,$ED93FA9B,$E8D3C48D,$283B57CC,$F8D56629,$79132E28,
    $785F0191,$ED756055,$F7960E44,$E3D35E8C,$15056DD4,$88F46DBA,$03A16125,$0564F0BD,
    $C3EB9E15,$3C9057A2,$97271AEC,$A93A072A,$1B3F6D9B,$1E6321F5,$F59C66FB,$26DCF319,
    $7533D928,$B155FDF5,$03563482,$8ABA3CBB,$28517711,$C20AD9F8,$ABCC5167,$CCAD925F,
    $4DE81751,$3830DC8E,$379D5862,$9320F991,$EA7A90C2,$FB3E7BCE,$5121CE64,$774FBE32,
    $A8B6E37E,$C3293D46,$48DE5369,$6413E680,$A2AE0810,$DD6DB224,$69852DFD,$09072166,
    $B39A460A,$6445C0DD,$586CDECF,$1C20C8AE,$5BBEF7DD,$1B588D40,$CCD2017F,$6BB4E3BB,
    $DDA26A7E,$3A59FF45,$3E350A44,$BCB4CDD5,$72EACEA8,$FA6484BB,$8D6612AE,$BF3C6F47,
    $D29BE463,$542F5D9E,$AEC2771B,$F64E6370,$740E0D8D,$E75B1357,$F8721671,$AF537D5D,
    $4040CB08,$4EB4E2CC,$34D2466A,$0115AF84,$E1B00428,$95983A1D,$06B89FB4,$CE6EA048,
    $6F3F3B82,$3520AB82,$011A1D4B,$277227F8,$611560B1,$E7933FDC,$BB3A792B,$344525BD,
    $A08839E1,$51CE794B,$2F32C9B7,$A01FBAC9,$E01CC87E,$BCC7D1F6,$CF0111C3,$A1E8AAC7,
    $1A908749,$D44FBD9A,$D0DADECB,$D50ADA38,$0339C32A,$C6913667,$8DF9317C,$E0B12B4F,
    $F79E59B7,$43F5BB3A,$F2D519FF,$27D9459C,$BF97222C,$15E6FC2A,$0F91FC71,$9B941525,
    $FAE59361,$CEB69CEB,$C2A86459,$12BAA8D1,$B6C1075E,$E3056A0C,$10D25065,$CB03A442,
    $E0EC6E0E,$1698DB3B,$4C98A0BE,$3278E964,$9F1F9532,$E0D392DF,$D3A0342B,$8971F21E,
    $1B0A7441,$4BA3348C,$C5BE7120,$C37632D8,$DF359F8D,$9B992F2E,$E60B6F47,$0FE3F11D,
    $E54CDA54,$1EDAD891,$CE6279CF,$CD3E7E6F,$1618B166,$FD2C1D05,$848FD2C5,$F6FB2299,
    $F523F357,$A6327623,$93A83531,$56CCCD02,$ACF08162,$5A75EBB5,$6E163697,$88D273CC,
    $DE966292,$81B949D0,$4C50901B,$71C65614,$E6C6C7BD,$327A140A,$45E1D006,$C3F27B9A,
    $C9AA53FD,$62A80F00,$BB25BFE2,$35BDD2F6,$71126905,$B2040222,$B6CBCF7C,$CD769C2B,
    $53113EC0,$1640E3D3,$38ABBD60,$2547ADF0,$BA38209C,$F746CE76,$77AFA1C5,$20756060,
    $85CBFE4E,$8AE88DD8,$7AAAF9B0,$4CF9AA7E,$1948C25C,$02FB8A8C,$01C36AE4,$D6EBE1F9,
    $90D4F869,$A65CDEA0,$3F09252D,$C208E69F,$B74E6132,$CE77E25B,$578FDFE3,$3AC372E6));

  Blowfish_Key: array[0..17] of Longword = (
    $243F6A88,$85A308D3,$13198A2E,$03707344,$A4093822,$299F31D0,
    $082EFA98,$EC4E6C89,$452821E6,$38D01377,$BE5466CF,$34E90C6C,
    $C0AC29B7,$C97C50DD,$3F84D5B5,$B5470917,$9216D5D9,$8979FB1B);

  // Twofish ------------------------------------------------------------------
  Twofish_8x8: array[0..1, 0..255] of Byte = (
   ($A9,$67,$B3,$E8,$04,$FD,$A3,$76,$9A,$92,$80,$78,$E4,$DD,$D1,$38,
    $0D,$C6,$35,$98,$18,$F7,$EC,$6C,$43,$75,$37,$26,$FA,$13,$94,$48,
    $F2,$D0,$8B,$30,$84,$54,$DF,$23,$19,$5B,$3D,$59,$F3,$AE,$A2,$82,
    $63,$01,$83,$2E,$D9,$51,$9B,$7C,$A6,$EB,$A5,$BE,$16,$0C,$E3,$61,
    $C0,$8C,$3A,$F5,$73,$2C,$25,$0B,$BB,$4E,$89,$6B,$53,$6A,$B4,$F1,
    $E1,$E6,$BD,$45,$E2,$F4,$B6,$66,$CC,$95,$03,$56,$D4,$1C,$1E,$D7,
    $FB,$C3,$8E,$B5,$E9,$CF,$BF,$BA,$EA,$77,$39,$AF,$33,$C9,$62,$71,
    $81,$79,$09,$AD,$24,$CD,$F9,$D8,$E5,$C5,$B9,$4D,$44,$08,$86,$E7,
    $A1,$1D,$AA,$ED,$06,$70,$B2,$D2,$41,$7B,$A0,$11,$31,$C2,$27,$90,
    $20,$F6,$60,$FF,$96,$5C,$B1,$AB,$9E,$9C,$52,$1B,$5F,$93,$0A,$EF,
    $91,$85,$49,$EE,$2D,$4F,$8F,$3B,$47,$87,$6D,$46,$D6,$3E,$69,$64,
    $2A,$CE,$CB,$2F,$FC,$97,$05,$7A,$AC,$7F,$D5,$1A,$4B,$0E,$A7,$5A,
    $28,$14,$3F,$29,$88,$3C,$4C,$02,$B8,$DA,$B0,$17,$55,$1F,$8A,$7D,
    $57,$C7,$8D,$74,$B7,$C4,$9F,$72,$7E,$15,$22,$12,$58,$07,$99,$34,
    $6E,$50,$DE,$68,$65,$BC,$DB,$F8,$C8,$A8,$2B,$40,$DC,$FE,$32,$A4,
    $CA,$10,$21,$F0,$D3,$5D,$0F,$00,$6F,$9D,$36,$42,$4A,$5E,$C1,$E0),
   ($75,$F3,$C6,$F4,$DB,$7B,$FB,$C8,$4A,$D3,$E6,$6B,$45,$7D,$E8,$4B,
    $D6,$32,$D8,$FD,$37,$71,$F1,$E1,$30,$0F,$F8,$1B,$87,$FA,$06,$3F,
    $5E,$BA,$AE,$5B,$8A,$00,$BC,$9D,$6D,$C1,$B1,$0E,$80,$5D,$D2,$D5,
    $A0,$84,$07,$14,$B5,$90,$2C,$A3,$B2,$73,$4C,$54,$92,$74,$36,$51,
    $38,$B0,$BD,$5A,$FC,$60,$62,$96,$6C,$42,$F7,$10,$7C,$28,$27,$8C,
    $13,$95,$9C,$C7,$24,$46,$3B,$70,$CA,$E3,$85,$CB,$11,$D0,$93,$B8,
    $A6,$83,$20,$FF,$9F,$77,$C3,$CC,$03,$6F,$08,$BF,$40,$E7,$2B,$E2,
    $79,$0C,$AA,$82,$41,$3A,$EA,$B9,$E4,$9A,$A4,$97,$7E,$DA,$7A,$17,
    $66,$94,$A1,$1D,$3D,$F0,$DE,$B3,$0B,$72,$A7,$1C,$EF,$D1,$53,$3E,
    $8F,$33,$26,$5F,$EC,$76,$2A,$49,$81,$88,$EE,$21,$C4,$1A,$EB,$D9,
    $C5,$39,$99,$CD,$AD,$31,$8B,$01,$18,$23,$DD,$1F,$4E,$2D,$F9,$48,
    $4F,$F2,$65,$8E,$78,$5C,$58,$19,$8D,$E5,$98,$57,$67,$7F,$05,$64,
    $AF,$63,$B6,$FE,$F5,$B7,$3C,$A5,$CE,$E9,$68,$44,$E0,$4D,$43,$69,
    $29,$2E,$AC,$15,$59,$A8,$0A,$9E,$6E,$47,$DF,$34,$35,$6A,$CF,$DC,
    $22,$C9,$C0,$9B,$89,$D4,$ED,$AB,$12,$A2,$0D,$52,$BB,$02,$2F,$A9,
    $D7,$61,$1E,$B4,$50,$04,$F6,$C2,$16,$25,$86,$56,$55,$09,$BE,$91));

  Twofish_Data: array[0..3, 0..255] of Longword = (
  ($BCBC3275,$ECEC21F3,$202043C6,$B3B3C9F4,$DADA03DB,$02028B7B,$E2E22BFB,$9E9EFAC8,
   $C9C9EC4A,$D4D409D3,$18186BE6,$1E1E9F6B,$98980E45,$B2B2387D,$A6A6D2E8,$2626B74B,
   $3C3C57D6,$93938A32,$8282EED8,$525298FD,$7B7BD437,$BBBB3771,$5B5B97F1,$474783E1,
   $24243C30,$5151E20F,$BABAC6F8,$4A4AF31B,$BFBF4887,$0D0D70FA,$B0B0B306,$7575DE3F,
   $D2D2FD5E,$7D7D20BA,$666631AE,$3A3AA35B,$59591C8A,$00000000,$CDCD93BC,$1A1AE09D,
   $AEAE2C6D,$7F7FABC1,$2B2BC7B1,$BEBEB90E,$E0E0A080,$8A8A105D,$3B3B52D2,$6464BAD5,
   $D8D888A0,$E7E7A584,$5F5FE807,$1B1B1114,$2C2CC2B5,$FCFCB490,$3131272C,$808065A3,
   $73732AB2,$0C0C8173,$79795F4C,$6B6B4154,$4B4B0292,$53536974,$94948F36,$83831F51,
   $2A2A3638,$C4C49CB0,$2222C8BD,$D5D5F85A,$BDBDC3FC,$48487860,$FFFFCE62,$4C4C0796,
   $4141776C,$C7C7E642,$EBEB24F7,$1C1C1410,$5D5D637C,$36362228,$6767C027,$E9E9AF8C,
   $4444F913,$1414EA95,$F5F5BB9C,$CFCF18C7,$3F3F2D24,$C0C0E346,$7272DB3B,$54546C70,
   $29294CCA,$F0F035E3,$0808FE85,$C6C617CB,$F3F34F11,$8C8CE4D0,$A4A45993,$CACA96B8,
   $68683BA6,$B8B84D83,$38382820,$E5E52EFF,$ADAD569F,$0B0B8477,$C8C81DC3,$9999FFCC,
   $5858ED03,$19199A6F,$0E0E0A08,$95957EBF,$70705040,$F7F730E7,$6E6ECF2B,$1F1F6EE2,
   $B5B53D79,$09090F0C,$616134AA,$57571682,$9F9F0B41,$9D9D803A,$111164EA,$2525CDB9,
   $AFAFDDE4,$4545089A,$DFDF8DA4,$A3A35C97,$EAEAD57E,$353558DA,$EDEDD07A,$4343FC17,
   $F8F8CB66,$FBFBB194,$3737D3A1,$FAFA401D,$C2C2683D,$B4B4CCF0,$32325DDE,$9C9C71B3,
   $5656E70B,$E3E3DA72,$878760A7,$15151B1C,$F9F93AEF,$6363BFD1,$3434A953,$9A9A853E,
   $B1B1428F,$7C7CD133,$88889B26,$3D3DA65F,$A1A1D7EC,$E4E4DF76,$8181942A,$91910149,
   $0F0FFB81,$EEEEAA88,$161661EE,$D7D77321,$9797F5C4,$A5A5A81A,$FEFE3FEB,$6D6DB5D9,
   $7878AEC5,$C5C56D39,$1D1DE599,$7676A4CD,$3E3EDCAD,$CBCB6731,$B6B6478B,$EFEF5B01,
   $12121E18,$6060C523,$6A6AB0DD,$4D4DF61F,$CECEE94E,$DEDE7C2D,$55559DF9,$7E7E5A48,
   $2121B24F,$03037AF2,$A0A02665,$5E5E198E,$5A5A6678,$65654B5C,$62624E58,$FDFD4519,
   $0606F48D,$404086E5,$F2F2BE98,$3333AC57,$17179067,$05058E7F,$E8E85E05,$4F4F7D64,
   $89896AAF,$10109563,$74742FB6,$0A0A75FE,$5C5C92F5,$9B9B74B7,$2D2D333C,$3030D6A5,
   $2E2E49CE,$494989E9,$46467268,$77775544,$A8A8D8E0,$9696044D,$2828BD43,$A9A92969,
   $D9D97929,$8686912E,$D1D187AC,$F4F44A15,$8D8D1559,$D6D682A8,$B9B9BC0A,$42420D9E,
   $F6F6C16E,$2F2FB847,$DDDD06DF,$23233934,$CCCC6235,$F1F1C46A,$C1C112CF,$8585EBDC,
   $8F8F9E22,$7171A1C9,$9090F0C0,$AAAA539B,$0101F189,$8B8BE1D4,$4E4E8CED,$8E8E6FAB,
   $ABABA212,$6F6F3EA2,$E6E6540D,$DBDBF252,$92927BBB,$B7B7B602,$6969CA2F,$3939D9A9,
   $D3D30CD7,$A7A72361,$A2A2AD1E,$C3C399B4,$6C6C4450,$07070504,$04047FF6,$272746C2,
   $ACACA716,$D0D07625,$50501386,$DCDCF756,$84841A55,$E1E15109,$7A7A25BE,$1313EF91),
  ($A9D93939,$67901717,$B3719C9C,$E8D2A6A6,$04050707,$FD985252,$A3658080,$76DFE4E4,
   $9A084545,$92024B4B,$80A0E0E0,$78665A5A,$E4DDAFAF,$DDB06A6A,$D1BF6363,$38362A2A,
   $0D54E6E6,$C6432020,$3562CCCC,$98BEF2F2,$181E1212,$F724EBEB,$ECD7A1A1,$6C774141,
   $43BD2828,$7532BCBC,$37D47B7B,$269B8888,$FA700D0D,$13F94444,$94B1FBFB,$485A7E7E,
   $F27A0303,$D0E48C8C,$8B47B6B6,$303C2424,$84A5E7E7,$54416B6B,$DF06DDDD,$23C56060,
   $1945FDFD,$5BA33A3A,$3D68C2C2,$59158D8D,$F321ECEC,$AE316666,$A23E6F6F,$82165757,
   $63951010,$015BEFEF,$834DB8B8,$2E918686,$D9B56D6D,$511F8383,$9B53AAAA,$7C635D5D,
   $A63B6868,$EB3FFEFE,$A5D63030,$BE257A7A,$16A7ACAC,$0C0F0909,$E335F0F0,$6123A7A7,
   $C0F09090,$8CAFE9E9,$3A809D9D,$F5925C5C,$73810C0C,$2C273131,$2576D0D0,$0BE75656,
   $BB7B9292,$4EE9CECE,$89F10101,$6B9F1E1E,$53A93434,$6AC4F1F1,$B499C3C3,$F1975B5B,
   $E1834747,$E66B1818,$BDC82222,$450E9898,$E26E1F1F,$F4C9B3B3,$B62F7474,$66CBF8F8,
   $CCFF9999,$95EA1414,$03ED5858,$56F7DCDC,$D4E18B8B,$1C1B1515,$1EADA2A2,$D70CD3D3,
   $FB2BE2E2,$C31DC8C8,$8E195E5E,$B5C22C2C,$E9894949,$CF12C1C1,$BF7E9595,$BA207D7D,
   $EA641111,$77840B0B,$396DC5C5,$AF6A8989,$33D17C7C,$C9A17171,$62CEFFFF,$7137BBBB,
   $81FB0F0F,$793DB5B5,$0951E1E1,$ADDC3E3E,$242D3F3F,$CDA47676,$F99D5555,$D8EE8282,
   $E5864040,$C5AE7878,$B9CD2525,$4D049696,$44557777,$080A0E0E,$86135050,$E730F7F7,
   $A1D33737,$1D40FAFA,$AA346161,$ED8C4E4E,$06B3B0B0,$706C5454,$B22A7373,$D2523B3B,
   $410B9F9F,$7B8B0202,$A088D8D8,$114FF3F3,$3167CBCB,$C2462727,$27C06767,$90B4FCFC,
   $20283838,$F67F0404,$60784848,$FF2EE5E5,$96074C4C,$5C4B6565,$B1C72B2B,$AB6F8E8E,
   $9E0D4242,$9CBBF5F5,$52F2DBDB,$1BF34A4A,$5FA63D3D,$9359A4A4,$0ABCB9B9,$EF3AF9F9,
   $91EF1313,$85FE0808,$49019191,$EE611616,$2D7CDEDE,$4FB22121,$8F42B1B1,$3BDB7272,
   $47B82F2F,$8748BFBF,$6D2CAEAE,$46E3C0C0,$D6573C3C,$3E859A9A,$6929A9A9,$647D4F4F,
   $2A948181,$CE492E2E,$CB17C6C6,$2FCA6969,$FCC3BDBD,$975CA3A3,$055EE8E8,$7AD0EDED,
   $AC87D1D1,$7F8E0505,$D5BA6464,$1AA8A5A5,$4BB72626,$0EB9BEBE,$A7608787,$5AF8D5D5,
   $28223636,$14111B1B,$3FDE7575,$2979D9D9,$88AAEEEE,$3C332D2D,$4C5F7979,$02B6B7B7,
   $B896CACA,$DA583535,$B09CC4C4,$17FC4343,$551A8484,$1FF64D4D,$8A1C5959,$7D38B2B2,
   $57AC3333,$C718CFCF,$8DF40606,$74695353,$B7749B9B,$C4F59797,$9F56ADAD,$72DAE3E3,
   $7ED5EAEA,$154AF4F4,$229E8F8F,$12A2ABAB,$584E6262,$07E85F5F,$99E51D1D,$34392323,
   $6EC1F6F6,$50446C6C,$DE5D3232,$68724646,$6526A0A0,$BC93CDCD,$DB03DADA,$F8C6BABA,
   $C8FA9E9E,$A882D6D6,$2BCF6E6E,$40507070,$DCEB8585,$FE750A0A,$328A9393,$A48DDFDF,
   $CA4C2929,$10141C1C,$2173D7D7,$F0CCB4B4,$D309D4D4,$5D108A8A,$0FE25151,$00000000,
   $6F9A1919,$9DE01A1A,$368F9494,$42E6C7C7,$4AECC9C9,$5EFDD2D2,$C1AB7F7F,$E0D8A8A8),
  ($BC75BC32,$ECF3EC21,$20C62043,$B3F4B3C9,$DADBDA03,$027B028B,$E2FBE22B,$9EC89EFA,
   $C94AC9EC,$D4D3D409,$18E6186B,$1E6B1E9F,$9845980E,$B27DB238,$A6E8A6D2,$264B26B7,
   $3CD63C57,$9332938A,$82D882EE,$52FD5298,$7B377BD4,$BB71BB37,$5BF15B97,$47E14783,
   $2430243C,$510F51E2,$BAF8BAC6,$4A1B4AF3,$BF87BF48,$0DFA0D70,$B006B0B3,$753F75DE,
   $D25ED2FD,$7DBA7D20,$66AE6631,$3A5B3AA3,$598A591C,$00000000,$CDBCCD93,$1A9D1AE0,
   $AE6DAE2C,$7FC17FAB,$2BB12BC7,$BE0EBEB9,$E080E0A0,$8A5D8A10,$3BD23B52,$64D564BA,
   $D8A0D888,$E784E7A5,$5F075FE8,$1B141B11,$2CB52CC2,$FC90FCB4,$312C3127,$80A38065,
   $73B2732A,$0C730C81,$794C795F,$6B546B41,$4B924B02,$53745369,$9436948F,$8351831F,
   $2A382A36,$C4B0C49C,$22BD22C8,$D55AD5F8,$BDFCBDC3,$48604878,$FF62FFCE,$4C964C07,
   $416C4177,$C742C7E6,$EBF7EB24,$1C101C14,$5D7C5D63,$36283622,$672767C0,$E98CE9AF,
   $441344F9,$149514EA,$F59CF5BB,$CFC7CF18,$3F243F2D,$C046C0E3,$723B72DB,$5470546C,
   $29CA294C,$F0E3F035,$088508FE,$C6CBC617,$F311F34F,$8CD08CE4,$A493A459,$CAB8CA96,
   $68A6683B,$B883B84D,$38203828,$E5FFE52E,$AD9FAD56,$0B770B84,$C8C3C81D,$99CC99FF,
   $580358ED,$196F199A,$0E080E0A,$95BF957E,$70407050,$F7E7F730,$6E2B6ECF,$1FE21F6E,
   $B579B53D,$090C090F,$61AA6134,$57825716,$9F419F0B,$9D3A9D80,$11EA1164,$25B925CD,
   $AFE4AFDD,$459A4508,$DFA4DF8D,$A397A35C,$EA7EEAD5,$35DA3558,$ED7AEDD0,$431743FC,
   $F866F8CB,$FB94FBB1,$37A137D3,$FA1DFA40,$C23DC268,$B4F0B4CC,$32DE325D,$9CB39C71,
   $560B56E7,$E372E3DA,$87A78760,$151C151B,$F9EFF93A,$63D163BF,$345334A9,$9A3E9A85,
   $B18FB142,$7C337CD1,$8826889B,$3D5F3DA6,$A1ECA1D7,$E476E4DF,$812A8194,$91499101,
   $0F810FFB,$EE88EEAA,$16EE1661,$D721D773,$97C497F5,$A51AA5A8,$FEEBFE3F,$6DD96DB5,
   $78C578AE,$C539C56D,$1D991DE5,$76CD76A4,$3EAD3EDC,$CB31CB67,$B68BB647,$EF01EF5B,
   $1218121E,$602360C5,$6ADD6AB0,$4D1F4DF6,$CE4ECEE9,$DE2DDE7C,$55F9559D,$7E487E5A,
   $214F21B2,$03F2037A,$A065A026,$5E8E5E19,$5A785A66,$655C654B,$6258624E,$FD19FD45,
   $068D06F4,$40E54086,$F298F2BE,$335733AC,$17671790,$057F058E,$E805E85E,$4F644F7D,
   $89AF896A,$10631095,$74B6742F,$0AFE0A75,$5CF55C92,$9BB79B74,$2D3C2D33,$30A530D6,
   $2ECE2E49,$49E94989,$46684672,$77447755,$A8E0A8D8,$964D9604,$284328BD,$A969A929,
   $D929D979,$862E8691,$D1ACD187,$F415F44A,$8D598D15,$D6A8D682,$B90AB9BC,$429E420D,
   $F66EF6C1,$2F472FB8,$DDDFDD06,$23342339,$CC35CC62,$F16AF1C4,$C1CFC112,$85DC85EB,
   $8F228F9E,$71C971A1,$90C090F0,$AA9BAA53,$018901F1,$8BD48BE1,$4EED4E8C,$8EAB8E6F,
   $AB12ABA2,$6FA26F3E,$E60DE654,$DB52DBF2,$92BB927B,$B702B7B6,$692F69CA,$39A939D9,
   $D3D7D30C,$A761A723,$A21EA2AD,$C3B4C399,$6C506C44,$07040705,$04F6047F,$27C22746,
   $AC16ACA7,$D025D076,$50865013,$DC56DCF7,$8455841A,$E109E151,$7ABE7A25,$139113EF),
  ($D939A9D9,$90176790,$719CB371,$D2A6E8D2,$05070405,$9852FD98,$6580A365,$DFE476DF,
   $08459A08,$024B9202,$A0E080A0,$665A7866,$DDAFE4DD,$B06ADDB0,$BF63D1BF,$362A3836,
   $54E60D54,$4320C643,$62CC3562,$BEF298BE,$1E12181E,$24EBF724,$D7A1ECD7,$77416C77,
   $BD2843BD,$32BC7532,$D47B37D4,$9B88269B,$700DFA70,$F94413F9,$B1FB94B1,$5A7E485A,
   $7A03F27A,$E48CD0E4,$47B68B47,$3C24303C,$A5E784A5,$416B5441,$06DDDF06,$C56023C5,
   $45FD1945,$A33A5BA3,$68C23D68,$158D5915,$21ECF321,$3166AE31,$3E6FA23E,$16578216,
   $95106395,$5BEF015B,$4DB8834D,$91862E91,$B56DD9B5,$1F83511F,$53AA9B53,$635D7C63,
   $3B68A63B,$3FFEEB3F,$D630A5D6,$257ABE25,$A7AC16A7,$0F090C0F,$35F0E335,$23A76123,
   $F090C0F0,$AFE98CAF,$809D3A80,$925CF592,$810C7381,$27312C27,$76D02576,$E7560BE7,
   $7B92BB7B,$E9CE4EE9,$F10189F1,$9F1E6B9F,$A93453A9,$C4F16AC4,$99C3B499,$975BF197,
   $8347E183,$6B18E66B,$C822BDC8,$0E98450E,$6E1FE26E,$C9B3F4C9,$2F74B62F,$CBF866CB,
   $FF99CCFF,$EA1495EA,$ED5803ED,$F7DC56F7,$E18BD4E1,$1B151C1B,$ADA21EAD,$0CD3D70C,
   $2BE2FB2B,$1DC8C31D,$195E8E19,$C22CB5C2,$8949E989,$12C1CF12,$7E95BF7E,$207DBA20,
   $6411EA64,$840B7784,$6DC5396D,$6A89AF6A,$D17C33D1,$A171C9A1,$CEFF62CE,$37BB7137,
   $FB0F81FB,$3DB5793D,$51E10951,$DC3EADDC,$2D3F242D,$A476CDA4,$9D55F99D,$EE82D8EE,
   $8640E586,$AE78C5AE,$CD25B9CD,$04964D04,$55774455,$0A0E080A,$13508613,$30F7E730,
   $D337A1D3,$40FA1D40,$3461AA34,$8C4EED8C,$B3B006B3,$6C54706C,$2A73B22A,$523BD252,
   $0B9F410B,$8B027B8B,$88D8A088,$4FF3114F,$67CB3167,$4627C246,$C06727C0,$B4FC90B4,
   $28382028,$7F04F67F,$78486078,$2EE5FF2E,$074C9607,$4B655C4B,$C72BB1C7,$6F8EAB6F,
   $0D429E0D,$BBF59CBB,$F2DB52F2,$F34A1BF3,$A63D5FA6,$59A49359,$BCB90ABC,$3AF9EF3A,
   $EF1391EF,$FE0885FE,$01914901,$6116EE61,$7CDE2D7C,$B2214FB2,$42B18F42,$DB723BDB,
   $B82F47B8,$48BF8748,$2CAE6D2C,$E3C046E3,$573CD657,$859A3E85,$29A96929,$7D4F647D,
   $94812A94,$492ECE49,$17C6CB17,$CA692FCA,$C3BDFCC3,$5CA3975C,$5EE8055E,$D0ED7AD0,
   $87D1AC87,$8E057F8E,$BA64D5BA,$A8A51AA8,$B7264BB7,$B9BE0EB9,$6087A760,$F8D55AF8,
   $22362822,$111B1411,$DE753FDE,$79D92979,$AAEE88AA,$332D3C33,$5F794C5F,$B6B702B6,
   $96CAB896,$5835DA58,$9CC4B09C,$FC4317FC,$1A84551A,$F64D1FF6,$1C598A1C,$38B27D38,
   $AC3357AC,$18CFC718,$F4068DF4,$69537469,$749BB774,$F597C4F5,$56AD9F56,$DAE372DA,
   $D5EA7ED5,$4AF4154A,$9E8F229E,$A2AB12A2,$4E62584E,$E85F07E8,$E51D99E5,$39233439,
   $C1F66EC1,$446C5044,$5D32DE5D,$72466872,$26A06526,$93CDBC93,$03DADB03,$C6BAF8C6,
   $FA9EC8FA,$82D6A882,$CF6E2BCF,$50704050,$EB85DCEB,$750AFE75,$8A93328A,$8DDFA48D,
   $4C29CA4C,$141C1014,$73D72173,$CCB4F0CC,$09D4D309,$108A5D10,$E2510FE2,$00000000,
   $9A196F9A,$E01A9DE0,$8F94368F,$E6C742E6,$ECC94AEC,$FDD25EFD,$AB7FC1AB,$D8A8E0D8));

const
  SInvalidKey          = 'Encryptionkey is invalid';
  SInvalidKeySize      = 'Length from Encryptionkey is invalid.'#13#10 + 'Keysize for %s must be to %d-%d bytes';
  SNotInitialized      = '%s is not initialized call Init() or InitKey() before.';
  SHashAlgoNotFound    = 'Hash algorithm ''%s'' not found';
  SEncryptAlgoNotFound = 'Encryption algorithm ''%s'' not found';

const
  // 缺省 Hash 类
  DefaultHashClass: THashClass = THash_SHA;
  // 缺省加密模式
  DefaultEncMode: TEncryptMode = emCTS;
  // 16: HEX, 64: Base64, -1: binary
  DefaultDigestStringFormat: Integer = 64;

  // Hash buffer size
  HashMaxBufSize = 1024 * 4;
  // Encrypt buffer size
  EncMaxBufSize = 1024 * 4;

var
  // This is set to SwapInt for <= 386 and BSwapInt >= 486 CPU, don't modify
  SwapInteger: function(Value: Longword): Longword  = nil;
  // Count of Integers Buffer
  SwapIntegerBuffer: procedure(Source, Dest: Pointer; Count: Integer) = nil;

  // 3 = 386, 4 = 486, 5 = Pentium, 6 > Pentium
  CpuType: Integer = 0;
  InitTestIsOk: Boolean = False;

  // Set to True raises Exception when Size of the Key is too large, (Method Init())
  // otherwise will truncate the Key, default mode is False
  CheckEncryptKeySize: Boolean = False;

type
  TCodeProc = procedure(const Source; var Dest; DataSize: Integer) of object;

function GetTestVector: PAnsiChar; register; forward;
procedure RaiseCipherException(const ErrorCode: Integer; const Msg: RawByteString); forward;
// calculate CRC32 Checksum, CRC is default $FFFFFFFF, after calc you must inverse Result with NOT
function CRC32(CRC: Longword; Data: Pointer; DataSize: Longword): Longword; forward;
procedure XORBuffers(I1, I2: Pointer; Size: Integer; Dest: Pointer); assembler; forward;
procedure SHIFTBuffers(P, N: PByteArray; Size, Shift: Integer); forward;
procedure INCBuffer(P: PByteArray; Size: Integer); forward;
// Utility funcs
function ROL(Value: Longword; Shift: Integer): Longword; forward;
function ROLADD(Value, Add: Longword; Shift: Integer): Longword; forward;
function ROLSUB(Value, Sub: Longword; Shift: Integer): Longword; forward;
function ROR(Value: Longword; Shift: Integer): Longword; forward;
function RORADD(Value, Add: Longword; Shift: Integer): Longword; forward;
function RORSUB(Value, Sub: Longword; Shift: Integer): Longword; forward;
function SwapBits(Value: Longword): Longword; forward;

{ Misc Routines }

//-----------------------------------------------------------------------------
// 描述: 散列函数
// 参数:
//   HashClass - 散列算法类
//   Source    - 待散列的源字符串
//   Digest    - 存放散列值 (不同算法的散列值字节数不一样，字节数为THash.DigestKeySize)
//               > MD5: 16字节
//               > SHA, SHA1: 20字节
// 返回:
//   散列后的字符串(对散列值进行Base64编码，不含#0字符)
//   MD5: 24字节.  SHA, SHA1: 28字节
//-----------------------------------------------------------------------------
function HashString(HashClass: THashClass; const Source: RawByteString;
  Digest: Pointer): RawByteString;
begin
  Result := HashClass.CalcString(Digest, Source);
end;

//-----------------------------------------------------------------------------
// 描述: 散列函数
// 参数:
//   HashClass - 散列算法类
//   Buffer    - 待散列的缓冲区
//   DataSize  - 缓冲区字节数
//   Digest    - 存放散列值 (不同算法的散列值字节数不一样，字节数为THash.DigestKeySize)
// 返回:
//   散列后的字符串(对散列值进行Base64编码，不含#0字符)
//-----------------------------------------------------------------------------
function HashBuffer(HashClass: THashClass; const Buffer; DataSize: Integer;
  Digest: Pointer): RawByteString;
begin
  Result := HashClass.CalcBuffer(Digest, Buffer, DataSize);
end;

//-----------------------------------------------------------------------------
// 描述: 散列函数
// 参数:
//   HashClass - 散列算法类
//   Stream    - 待散列的流 (对整个流中的数据)
//   Digest    - 存放散列值 (不同算法的散列值字节数不一样，字节数为THash.DigestKeySize)
// 返回:
//   散列后的字符串(对散列值进行Base64编码，不含#0字符)
//-----------------------------------------------------------------------------
function HashStream(HashClass: THashClass; Stream: TStream; Digest: Pointer): RawByteString;
begin
  Result := HashClass.CalcStream(Digest, Stream, -1);
end;

//-----------------------------------------------------------------------------
// 描述: 散列函数
// 参数:
//   HashClass - 散列算法类
//   Stream    - 待散列的流 (对整个流中的数据)
//   Digest    - 存放散列值 (不同算法的散列值字节数不一样，字节数为THash.DigestKeySize)
// 返回:
//   散列后的字符串(对散列值进行Base64编码，不含#0字符)
//-----------------------------------------------------------------------------
function HashFile(HashClass: THashClass; const FileName: RawByteString; Digest: Pointer): RawByteString;
begin
  Result := HashClass.CalcFile(Digest, FileName);
end;

//-----------------------------------------------------------------------------
// 描述: 散列函数(MD5)
// 参数:
//   Source    - 待散列的源字符串
//   Digest    - 存放散列值 (16字节)
// 返回:
//   散列后的字符串(24字节)
//-----------------------------------------------------------------------------
function HashMD5(const Source: RawByteString; Digest: Pointer): RawByteString;
begin
  Result := HashString(THash_MD5, Source, Digest);
end;

//-----------------------------------------------------------------------------
// 描述: 散列函数(SHA)
// 参数:
//   Source    - 待散列的源字符串
//   Digest    - 存放散列值 (20字节)
// 返回:
//   散列后的字符串(28字节)
//-----------------------------------------------------------------------------
function HashSHA(const Source: RawByteString; Digest: Pointer): RawByteString;
begin
  Result := HashString(THash_SHA, Source, Digest);
end;

//-----------------------------------------------------------------------------
// 描述: 散列函数(SHA1)
// 参数:
//   Source    - 待散列的源字符串
//   Digest    - 存放散列值 (20字节)
// 返回:
//   散列后的字符串(28字节)
//-----------------------------------------------------------------------------
function HashSHA1(const Source: RawByteString; Digest: Pointer): RawByteString;
begin
  Result := HashString(THash_SHA1, Source, Digest);
end;

//-----------------------------------------------------------------------------
// 描述: CRC32散列
// 参数:
//   Data      - 待散列的数据
//   DataSize  - 待散列数据的长度
// 返回:
//   散列值
//-----------------------------------------------------------------------------
function CalcCRC32(const Data; DataSize: Integer): Longword;
begin
  THash_CRC32.CalcBuffer(@Result, Data, DataSize);
end;

//-----------------------------------------------------------------------------
// 描述: CRC32散列 (适用于循环累积计算)
// 参数:
//   LastResult - 第一次调用传入$FFFFFFFF，之后传入上次计算的结果值
//   Data       - 待散列的数据
//   DataSize   - 待散列数据的长度
// 返回:
//   散列值
//-----------------------------------------------------------------------------
function CalcCRC32(LastResult: Longword; const Data; DataSize: Integer): Longword;
begin
  Result := CRC32(LastResult, @Data, DataSize);
  Result := not Result;
end;

//-----------------------------------------------------------------------------
// 描述: 加密函数
// 参数:
//   EncryptClass - 加密算法类
//   Source       - 待加密的缓冲区
//   Dest         - 加密后的缓冲区 (可以和Source一样)
//   DataSize     - 缓冲区字节数
//   Key          - 密钥
//-----------------------------------------------------------------------------
procedure EncryptBuffer(EncryptClass: TEncryptClass;
  const Source; var Dest; DataSize: Integer; const Key: RawByteString);
var
  EncObj: TEncrypt;
begin
  EncObj := EncryptClass.Create;
  try
    EncObj.InitKey(Key, nil);
    EncObj.EncodeBuffer(Source, Dest, DataSize);
    EncObj.Done;
  finally
    EncObj.Free;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 解密函数
// 参数:
//   EncryptClass - 加密算法类
//   Source       - 待解密的缓冲区
//   Dest         - 解密后的缓冲区 (可以和Source一样)
//   DataSize     - 缓冲区字节数
//   Key          - 密钥
//-----------------------------------------------------------------------------
procedure DecryptBuffer(EncryptClass: TEncryptClass;
  const Source; var Dest; DataSize: Integer; const Key: RawByteString);
var
  EncObj: TEncrypt;
begin
  EncObj := EncryptClass.Create;
  try
    EncObj.InitKey(Key, nil);
    EncObj.DecodeBuffer(Source, Dest, DataSize);
    EncObj.Done;
  finally
    EncObj.Free;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 加密函数
// 参数:
//   EncryptClass - 加密算法类
//   SourceStream - 待加密的流 (对整个流)
//   DestStream   - 加密后的流 (可以和SourceStream一样)
//   Key          - 密钥
//-----------------------------------------------------------------------------
procedure EncryptStream(EncryptClass: TEncryptClass;
  SourceStream, DestStream: TStream; const Key: RawByteString);
var
  EncObj: TEncrypt;
begin
  EncObj := EncryptClass.Create;
  try
    EncObj.InitKey(Key, nil);
    EncObj.EncodeStream(SourceStream, DestStream, -1);
    EncObj.Done;
  finally
    EncObj.Free;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 解密函数
// 参数:
//   EncryptClass - 加密算法类
//   SourceStream - 待解密的流 (对整个流)
//   DestStream   - 解密后的流 (可以和SourceStream一样)
//   Key          - 密钥
//-----------------------------------------------------------------------------
procedure DecryptStream(EncryptClass: TEncryptClass;
  SourceStream, DestStream: TStream; const Key: RawByteString);
var
  EncObj: TEncrypt;
begin
  EncObj := EncryptClass.Create;
  try
    EncObj.InitKey(Key, nil);
    EncObj.DecodeStream(SourceStream, DestStream, -1);
    EncObj.Done;
  finally
    EncObj.Free;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 加密函数
// 参数:
//   EncryptClass - 加密算法类
//   SourceFile   - 待加密的文件
//   DestFile     - 加密后的文件 (可以和SourceFile一样)
//   Key          - 密钥
//-----------------------------------------------------------------------------
procedure EncryptFile(EncryptClass: TEncryptClass;
  const SourceFile, DestFile: RawByteString; const Key: RawByteString);
var
  EncObj: TEncrypt;
begin
  EncObj := EncryptClass.Create;
  try
    EncObj.InitKey(Key, nil);
    EncObj.EncodeFile(SourceFile, DestFile);
    EncObj.Done;
  finally
    EncObj.Free;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 加密函数
// 参数:
//   EncryptClass - 加密算法类
//   SourceFile   - 待解密的文件
//   DestFile     - 解密后的文件 (可以和SourceFile一样)
//   Key          - 密钥
//-----------------------------------------------------------------------------
procedure DecryptFile(EncryptClass: TEncryptClass;
  const SourceFile, DestFile: RawByteString; const Key: RawByteString);
var
  EncObj: TEncrypt;
begin
  EncObj := EncryptClass.Create;
  try
    EncObj.InitKey(Key, nil);
    EncObj.DecodeFile(SourceFile, DestFile);
    EncObj.Done;
  finally
    EncObj.Free;
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 对字符串进行 base64 编码
// 参数:
//   Value - 待编码的缓冲区
//   Len   - Value的长度 (若为-1，则表示取StrLen(Value)。)
// 返回:
//   编码后的字符串
//-----------------------------------------------------------------------------
function StrToBase64(Value: PAnsiChar; Len: Integer): RawByteString;
const
  Table: PAnsiChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
var
  B: Cardinal;
  I: Integer;
  D,T: PAnsiChar;
begin
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := StrLen(Value);
  if Len = 0 then Exit;
  SetLength(Result, Len * 4 div 3 + 4);
  D := PAnsiChar(Result);
  T := Table;
  while Len > 0 do
  begin
    B := 0;
    for I := 0 to 2 do
    begin
      B := B shl 8;
      if Len > 0 then
      begin
        B := B or Byte(Value^);
        Inc(Value);
      end;
      Dec(Len);
    end;
    for I := 3 downto 0 do
    begin
      if Len < 0 then
      begin
        D[I] := T[64];
        Inc(Len);
      end else D[I] := T[B and $3F];
      B := B shr 6;
    end;
    Inc(D, 4);
  end;
  SetLength(Result, D - PAnsiChar(Result));
end;

//-----------------------------------------------------------------------------
// 描述: 将 base64 编码的内容还原成字符串
// 参数:
//   Value - 待解码的缓冲区
//   Len   - Value的长度 (若为-1，则表示取StrLen(Value)。)
// 返回:
//   解码后的字符串
//-----------------------------------------------------------------------------
function Base64ToStr(Value: PAnsiChar; Len: Integer): RawByteString;
var
  B,J: Integer;
  D: PAnsiChar;
  S: PByte;
begin
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := StrLen(Value);
  SetLength(Result, Len);
  if Len = 0 then Exit;
  Move(PAnsiChar(Value)^, PAnsiChar(Result)^, Len);
  while Len and 3 <> 0 do
  begin
    Result := Result + '=';
    Inc(Len);
  end;
  D := PAnsiChar(Result);
  S := PByte(Result);
  Len := Len div 4 * 3;
  while Len > 0 do
  begin
    B := 0;
    for J := 1 to 4 do
    begin
      if (S^ >= 97) and (S^ <= 122) then Inc(B, S^ - 71) else
        if (S^ >= 65) and (S^ <= 90) then Inc(B, S^ - 65) else
          if (S^ >= 48) and (S^ <= 57) then Inc(B, S^ + 4) else
            if S^ = 43 then Inc(B, 62) else
              if S^ <> 61 then Inc(B, 63) else Dec(Len);
      B := B shl 6;
      Inc(S);
    end;
    B := ROL(B, 2);
    for J := 1 to 3 do
    begin
      if Len <= 0 then Break;
      B := ROL(B, 8);
      D^ := AnsiChar(B);
      Inc(D);
      Dec(Len);
    end;
  end;
  SetLength(Result, D - PAnsiChar(Result));
end;

//-----------------------------------------------------------------------------
// 描述: 对字符串进行 base16 编码
// 参数:
//   Value - 待编码的缓冲区
//   Len   - Value的长度 (若为-1，则表示取StrLen(Value)。)
// 返回:
//   编码后的字符串
//-----------------------------------------------------------------------------
function StrToBase16(Value: PAnsiChar; Len: Integer): RawByteString;
const
  H: array[0..15] of AnsiChar = '0123456789ABCDEF';
var
  S: PByte;
  D: PAnsiChar;
begin
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := StrLen(Value);
  SetLength(Result, Len * 2);
  if Len = 0 then Exit;
  D := PAnsiChar(Result);
  S := PByte(Value);
  while Len > 0 do
  begin
    D^ := H[S^ shr  4]; Inc(D);
    D^ := H[S^ and $F]; Inc(D);
    Inc(S);
    Dec(Len);
  end;
end;

//-----------------------------------------------------------------------------
// 描述: 将 base16 编码的内容还原成字符串
// 参数:
//   Value - 待解码的缓冲区
//   Len   - Value的长度 (若为-1，则表示取StrLen(Value)。)
// 返回:
//   解码后的字符串
//-----------------------------------------------------------------------------
function Base16ToStr(Value: PAnsiChar; Len: Integer): RawByteString;
var
  D: PByte;
  V: Byte;
  S: PAnsiChar;
begin
  Result := '';
  if Value = nil then Exit;
  if Len < 0 then Len := StrLen(Value);
  SetLength(Result, (Len +1) div 2);
  D := PByte(Result);
  S := PAnsiChar(Value);
  while Len > 0 do
  begin
    V := Byte(UpCase(S^));
    Inc(S);
    if V > Byte('9') then D^ := V - Byte('A') + 10
      else D^ := V - Byte('0');
    V := Byte(UpCase(S^));
    Inc(S);
    D^ := D^ shl 4;
    if V > Byte('9') then D^ := D^ or (V - Byte('A') + 10)
      else D^ := D^ or (V - Byte('0'));
    Dec(Len, 2);
    Inc(D);
  end;
  SetLength(Result, PAnsiChar(D) - PAnsiChar(Result));
end;

function ROL(Value: Longword; Shift: Integer): Longword; assembler;
asm
       MOV   CL,DL
       ROL   EAX,CL
end;

function ROLADD(Value, Add: Longword; Shift: Integer): Longword; assembler;
asm
       ROL   EAX,CL
       ADD   EAX,EDX
end;

function ROLSUB(Value, Sub: Longword; Shift: Integer): Longword; assembler;
asm
       ROL   EAX,CL
       SUB   EAX,EDX
end;

function ROR(Value: Longword; Shift: Integer): Longword; assembler;
asm
       MOV   CL,DL
       ROR   EAX,CL
end;

function RORADD(Value, Add: Longword; Shift: Integer): Longword; assembler;
asm
       ROR  EAX,CL
       ADD  EAX,EDX
end;

function RORSUB(Value, Sub: Longword; Shift: Integer): Longword; assembler;
asm
       ROR  EAX,CL
       SUB  EAX,EDX
end;

//swap 4 Bytes Intel
function SwapInt(Value: Longword): Longword; assembler; register;
asm
       XCHG  AH,AL
       ROL   EAX,16
       XCHG  AH,AL
end;

function BSwapInt(Value: Longword): Longword; assembler; register;
asm
       BSWAP  EAX
end;

procedure SwapIntBuf(Source,Dest: Pointer; Count: Integer); assembler; register;
asm
       JCXZ   @Exit
       PUSH   EBX
       SUB    EAX,4
       SUB    EDX,4
@@1:   MOV    EBX,[EAX + ECX * 4]
       XCHG   BL,BH
       ROL    EBX,16
       XCHG   BL,BH
       MOV    [EDX + ECX * 4],EBX
       DEC    ECX
       JNZ    @@1
       POP    EBX
@Exit:
end;

procedure BSwapIntBuf(Source, Dest: Pointer; Count: Integer); assembler; register;
asm
       JCXZ   @Exit
       PUSH   EBX
       SUB    EAX,4
       SUB    EDX,4
@@1:   MOV    EBX,[EAX + ECX * 4]
       BSWAP  EBX
       MOV    [EDX + ECX * 4],EBX
       DEC    ECX
       JNZ    @@1
       POP    EBX
@Exit:
end;

//reverse the bit order from a integer
function SwapBits(Value: Longword): Longword;
asm
       CMP    CpuType,3
       JLE    @@1
       BSWAP  EAX
       JMP    @@2
@@1:   XCHG   AH,AL
       ROL    EAX,16
       XCHG   AH,AL
@@2:   MOV    EDX,EAX
       AND    EAX,0AAAAAAAAh
       SHR    EAX,1
       AND    EDX,055555555h
       SHL    EDX,1
       OR     EAX,EDX
       MOV    EDX,EAX
       AND    EAX,0CCCCCCCCh
       SHR    EAX,2
       AND    EDX,033333333h
       SHL    EDX,2
       OR     EAX,EDX
       MOV    EDX,EAX
       AND    EAX,0F0F0F0F0h
       SHR    EAX,4
       AND    EDX,00F0F0F0Fh
       SHL    EDX,4
       OR     EAX,EDX
end;

function CRC32(CRC: Longword; Data: Pointer; DataSize: Longword): Longword; assembler;
asm
         AND    EDX,EDX
         JZ     @Exit
         AND    ECX,ECX
         JLE    @Exit
         PUSH   EBX
         PUSH   EDI
         XOR    EBX,EBX
         LEA    EDI,CS:[OFFSET @CRC32]
@Start:  MOV    BL,AL
         SHR    EAX,8
         XOR    BL,[EDX]
         XOR    EAX,[EDI + EBX * 4]
         INC    EDX
         DEC    ECX
         JNZ    @Start
         POP    EDI
         POP    EBX
@Exit:   RET
         DB 0, 0, 0, 0, 0 // Align Table
@CRC32:  DD 000000000h, 077073096h, 0EE0E612Ch, 0990951BAh
         DD 0076DC419h, 0706AF48Fh, 0E963A535h, 09E6495A3h
         DD 00EDB8832h, 079DCB8A4h, 0E0D5E91Eh, 097D2D988h
         DD 009B64C2Bh, 07EB17CBDh, 0E7B82D07h, 090BF1D91h
         DD 01DB71064h, 06AB020F2h, 0F3B97148h, 084BE41DEh
         DD 01ADAD47Dh, 06DDDE4EBh, 0F4D4B551h, 083D385C7h
         DD 0136C9856h, 0646BA8C0h, 0FD62F97Ah, 08A65C9ECh
         DD 014015C4Fh, 063066CD9h, 0FA0F3D63h, 08D080DF5h
         DD 03B6E20C8h, 04C69105Eh, 0D56041E4h, 0A2677172h
         DD 03C03E4D1h, 04B04D447h, 0D20D85FDh, 0A50AB56Bh
         DD 035B5A8FAh, 042B2986Ch, 0DBBBC9D6h, 0ACBCF940h
         DD 032D86CE3h, 045DF5C75h, 0DCD60DCFh, 0ABD13D59h
         DD 026D930ACh, 051DE003Ah, 0C8D75180h, 0BFD06116h
         DD 021B4F4B5h, 056B3C423h, 0CFBA9599h, 0B8BDA50Fh
         DD 02802B89Eh, 05F058808h, 0C60CD9B2h, 0B10BE924h
         DD 02F6F7C87h, 058684C11h, 0C1611DABh, 0B6662D3Dh
         DD 076DC4190h, 001DB7106h, 098D220BCh, 0EFD5102Ah
         DD 071B18589h, 006B6B51Fh, 09FBFE4A5h, 0E8B8D433h
         DD 07807C9A2h, 00F00F934h, 09609A88Eh, 0E10E9818h
         DD 07F6A0DBBh, 0086D3D2Dh, 091646C97h, 0E6635C01h
         DD 06B6B51F4h, 01C6C6162h, 0856530D8h, 0F262004Eh
         DD 06C0695EDh, 01B01A57Bh, 08208F4C1h, 0F50FC457h
         DD 065B0D9C6h, 012B7E950h, 08BBEB8EAh, 0FCB9887Ch
         DD 062DD1DDFh, 015DA2D49h, 08CD37CF3h, 0FBD44C65h
         DD 04DB26158h, 03AB551CEh, 0A3BC0074h, 0D4BB30E2h
         DD 04ADFA541h, 03DD895D7h, 0A4D1C46Dh, 0D3D6F4FBh
         DD 04369E96Ah, 0346ED9FCh, 0AD678846h, 0DA60B8D0h
         DD 044042D73h, 033031DE5h, 0AA0A4C5Fh, 0DD0D7CC9h
         DD 05005713Ch, 0270241AAh, 0BE0B1010h, 0C90C2086h
         DD 05768B525h, 0206F85B3h, 0B966D409h, 0CE61E49Fh
         DD 05EDEF90Eh, 029D9C998h, 0B0D09822h, 0C7D7A8B4h
         DD 059B33D17h, 02EB40D81h, 0B7BD5C3Bh, 0C0BA6CADh
         DD 0EDB88320h, 09ABFB3B6h, 003B6E20Ch, 074B1D29Ah
         DD 0EAD54739h, 09DD277AFh, 004DB2615h, 073DC1683h
         DD 0E3630B12h, 094643B84h, 00D6D6A3Eh, 07A6A5AA8h
         DD 0E40ECF0Bh, 09309FF9Dh, 00A00AE27h, 07D079EB1h
         DD 0F00F9344h, 08708A3D2h, 01E01F268h, 06906C2FEh
         DD 0F762575Dh, 0806567CBh, 0196C3671h, 06E6B06E7h
         DD 0FED41B76h, 089D32BE0h, 010DA7A5Ah, 067DD4ACCh
         DD 0F9B9DF6Fh, 08EBEEFF9h, 017B7BE43h, 060B08ED5h
         DD 0D6D6A3E8h, 0A1D1937Eh, 038D8C2C4h, 04FDFF252h
         DD 0D1BB67F1h, 0A6BC5767h, 03FB506DDh, 048B2364Bh
         DD 0D80D2BDAh, 0AF0A1B4Ch, 036034AF6h, 041047A60h
         DD 0DF60EFC3h, 0A867DF55h, 0316E8EEFh, 04669BE79h
         DD 0CB61B38Ch, 0BC66831Ah, 0256FD2A0h, 05268E236h
         DD 0CC0C7795h, 0BB0B4703h, 0220216B9h, 05505262Fh
         DD 0C5BA3BBEh, 0B2BD0B28h, 02BB45A92h, 05CB36A04h
         DD 0C2D7FFA7h, 0B5D0CF31h, 02CD99E8Bh, 05BDEAE1Dh
         DD 09B64C2B0h, 0EC63F226h, 0756AA39Ch, 0026D930Ah
         DD 09C0906A9h, 0EB0E363Fh, 072076785h, 005005713h
         DD 095BF4A82h, 0E2B87A14h, 07BB12BAEh, 00CB61B38h
         DD 092D28E9Bh, 0E5D5BE0Dh, 07CDCEFB7h, 00BDBDF21h
         DD 086D3D2D4h, 0F1D4E242h, 068DDB3F8h, 01FDA836Eh
         DD 081BE16CDh, 0F6B9265Bh, 06FB077E1h, 018B74777h
         DD 088085AE6h, 0FF0F6A70h, 066063BCAh, 011010B5Ch
         DD 08F659EFFh, 0F862AE69h, 0616BFFD3h, 0166CCF45h
         DD 0A00AE278h, 0D70DD2EEh, 04E048354h, 03903B3C2h
         DD 0A7672661h, 0D06016F7h, 04969474Dh, 03E6E77DBh
         DD 0AED16A4Ah, 0D9D65ADCh, 040DF0B66h, 037D83BF0h
         DD 0A9BCAE53h, 0DEBB9EC5h, 047B2CF7Fh, 030B5FFE9h
         DD 0BDBDF21Ch, 0CABAC28Ah, 053B39330h, 024B4A3A6h
         DD 0BAD03605h, 0CDD70693h, 054DE5729h, 023D967BFh
         DD 0B3667A2Eh, 0C4614AB8h, 05D681B02h, 02A6F2B94h
         DD 0B40BBE37h, 0C30C8EA1h, 05A05DF1Bh, 02D02EF8Dh
         DD 074726F50h, 0736E6F69h, 0706F4320h, 067697279h
         DD 028207468h, 031202963h, 020393939h, 048207962h
         DD 06E656761h, 064655220h, 06E616D64h, 06FBBA36Eh
end;

//a Random generated Testvector 256bit - 32 Bytes, it's used for Self Test
function GetTestVector: PAnsiChar; assembler; register;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    030h,044h,0EDh,06Eh,045h,0A4h,096h,0F5h
         DB    0F6h,035h,0A2h,0EBh,03Dh,01Ah,05Dh,0D6h
         DB    0CBh,01Dh,009h,082h,02Dh,0BDh,0F5h,060h
         DB    0C2h,0B8h,058h,0A1h,091h,0F9h,081h,0B1h
         DB    000h,000h,000h,000h,000h,000h,000h,000h
end;

procedure RaiseCipherException(const ErrorCode: Integer; const Msg: RawByteString);
var
  E: ECipherException;
begin
  E := ECipherException.Create(string(Msg));
  E.ErrorCode := ErrorCode;
  raise E;
end;

procedure XORBuffers(I1, I2: Pointer; Size: Integer; Dest: Pointer); assembler;
asm
       AND   ECX,ECX
       JZ    @@3
       PUSH  ESI
       PUSH  EDI
       MOV   ESI,EAX
       MOV   EDI,Dest
       TEST  ECX,1
       JZ    @@0
       DEC   ECX
       MOV   AL,[ESI + ECX]
       XOR   AL,[EDX + ECX]
       MOV   [EDI + ECX],AL
       AND   ECX,ECX
       JZ    @@2
@@0:   SHR   ECX,1
       TEST  ECX,1
       JZ    @@00
       DEC   ECX
       MOV   AX,[ESI + ECX * 2]
       XOR   AX,[EDX + ECX * 2]
       MOV   [EDI + ECX * 2],AX
@@00:  SHR   ECX,1
@@1:   DEC   ECX
       JL    @@2
       MOV   EAX,[ESI + ECX * 4]
       XOR   EAX,[EDX + ECX * 4]
       MOV   [EDI + ECX * 4],EAX
       JMP   @@1
@@2:   POP   EDI
       POP   ESI
@@3:
end;

procedure SHIFTBuffers(P, N: PByteArray; Size, Shift: Integer);
var
  I,S: Integer;
begin
  if Shift >= 8 then
  begin
    S := Shift div 8;
    Move(P[S], P[0], Size - S);
    Move(N[0], P[Size-S], S);
  end else
    if Shift <= -8 then
    begin
      S := -Shift div 8;
      Move(P[0], P[S], Size - S);
      Move(N[0], P[0], S);
    end;
  Shift := Shift mod 8;
  if Shift > 0 then
  begin
    S := 8 - Shift;
    for I := Size-1 downto 1 do
      P[I] := (P[I] shl Shift) or (P[I-1] shr S);
    P[0] := (P[0] shl Shift) or (N[Size-1] shr S);
  end else
    if Shift < 0 then
    begin
      Shift := -Shift;
      S := 8 - Shift;
      for I := Size-1 downto 1 do
        P[I] := (P[I] shr Shift) or (P[I-1] shl S);
      P[0] := (P[0] shr Shift) or (N[Size-1] shl S);
    end;
end;

procedure INCBuffer(P: PByteArray; Size: Integer);
begin
  repeat
    Dec(Size);
    Inc(P[Size]);
  until (P[Size] <> 0) or (Size <= 1);
end;

{ THash }

destructor THash.Destroy;
begin
  FillChar(DigestKey^, DigestKeySize, 0);
  inherited Destroy;
end;

procedure THash.Init;
begin
end;

procedure THash.Calc(const Data; DataSize: Integer);
begin
end;

procedure THash.Done;
begin
end;

function THash.DigestKey: Pointer;
begin
  Result := GetTestVector;
end;

class function THash.DigestKeySize: Integer;
begin
  Result := 0;
end;

function THash.GetDigestStr(Index: Integer): RawByteString;
begin
  if Index = 0 then Index := DefaultDigestStringFormat;
  case Index of
    16: Result := StrToBase16(PAnsiChar(DigestKey), DigestKeySize);
    64: Result := StrToBase64(PAnsiChar(DigestKey), DigestKeySize);
  else
    begin
      SetLength(Result, DigestKeySize);
      Move(DigestKey^, PAnsiChar(Result)^, DigestKeySize);
    end;
  end;
end;

class function THash.TestVector: Pointer;
begin
  Result := GetTestVector;
end;

class function THash.CalcStream(Digest: Pointer; const Stream: TStream; StreamSize: Integer): RawByteString;
var
  Buf: Pointer;
  BufSize: Integer;
  //Size: Integer;
  H: THash;
begin
  H := Create;
  with H do
  try
    Buf := AllocMem(HashMaxBufSize);
    Init;
    if StreamSize < 0 then
 {if Size < 0 then reset the Position, otherwise, calc with the specific
  Size and from the aktual Position in the Stream}
    begin
      Stream.Position := 0;
      StreamSize := Stream.Size;
    end;
    //Size := StreamSize;
    //DoProgress(H, 0, Size);
    repeat
      BufSize := StreamSize;
      if BufSize > HashMaxBufSize then BufSize := HashMaxBufSize;
      BufSize := Stream.Read(Buf^, BufSize);
      if BufSize <= 0 then Break;
      Calc(Buf^, BufSize);
      Dec(StreamSize, BufSize);
      //DoProgress(H, Size - StreamSize, Size);
    until BufSize <= 0;
    Done;
    if Digest <> nil then Move(DigestKey^, Digest^, DigestKeySize);
    Result := DigestString;
  finally
    //DoProgress(H, 0, 0);
    Free;
    ReallocMem(Buf, 0);
  end;
end;

class function THash.CalcString(Digest: Pointer; const Data: RawByteString): RawByteString;
begin
  with Self.Create do
  try
    Init;
    Calc(PAnsiChar(Data)^, Length(Data));
    Done;
    Result := DigestString;
    if Digest <> nil then Move(DigestKey^, Digest^, DigestKeySize);
  finally
    Free;
  end;
end;

class function THash.CalcFile(Digest: Pointer; const FileName: RawByteString): RawByteString;
var
  S: TFileStream;
begin
  S := nil;
  try
    // 如果文件不可读，则会抛出异常，但S是需要释放的，不然有内存泄露
    S := TFileStream.Create(string(FileName), fmOpenRead or fmShareDenyNone);
    Result := CalcStream(Digest, S, -1);
  finally
    FreeAndNil(S);
  end;
end;

class function THash.CalcBuffer(Digest: Pointer; const Buffer; BufferSize: Integer): RawByteString;
begin
  with Create do {create an object from my Classtype}
  try
    Init;
    Calc(Buffer, BufferSize);
    Done;
    if Digest <> nil then Move(DigestKey^, Digest^, DigestKeySize);
    Result := DigestString;
  finally
    Free; {destroy it}
  end;
end;

class function THash.SelfTest: Boolean;
var
  Test: RawByteString;
begin
  SetLength(Test, DigestKeySize);
  CalcBuffer(PAnsiChar(Test), GetTestVector^, 32);
  Result := InitTestIsOk and CompareMem(PAnsiChar(Test), TestVector, DigestKeySize);
end;

{get the CPU Type from your system}
function GetCPUType: Integer; assembler;
asm
         PUSH   EBX
         PUSH   ECX
         PUSH   EDX
         MOV    EBX,ESP
         AND    ESP,0FFFFFFFCh
         PUSHFD
         PUSHFD
         POP    EAX
         MOV    ECX,EAX
         XOR    EAX,40000h
         PUSH   EAX
         POPFD
         PUSHFD
         POP    EAX
         XOR    EAX,ECX
         MOV    EAX,3
         JE     @Exit
         PUSHFD
         POP    EAX
         MOV    ECX,EAX
         XOR    EAX,200000h
         PUSH   EAX
         POPFD
         PUSHFD
         POP    EAX
         XOR    EAX,ECX
         MOV    EAX,4
         JE     @Exit
         PUSH   EBX
         MOV    EAX,1
         DB     0Fh,0A2h      //CPUID
         MOV    AL,AH
         AND    EAX,0Fh
         POP    EBX
@Exit:   POPFD
         MOV    ESP,EBX
         POP    EDX
         POP    ECX
         POP    EBX
end;

{ THash_XOR16 }

class function THash_XOR16.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    079h,0E8h
end;

class function THash_XOR16.DigestKeySize: Integer;
begin
  Result := 2;
end;

procedure THash_XOR16.Init;
begin
  FCRC := 0;
end;

procedure THash_XOR16.Calc(const Data; DataSize: Integer); assembler; register;
asm
         JECXZ   @Exit
         PUSH    EAX
         MOV     AX,[EAX].THash_XOR16.FCRC
@@1:     ROL     AX,5
         XOR     AL,[EDX]
         INC     EDX
         DEC     ECX
         JNZ     @@1
         POP     EDX
         MOV     [EDX].THash_XOR16.FCRC,AX
@Exit:
end;

function THash_XOR16.DigestKey: Pointer;
begin
  Result := @FCRC;
end;

{ THash_XOR32 }

class function THash_XOR32.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    08Dh,0ADh,089h,07Fh
end;

class function THash_XOR32.DigestKeySize: Integer;
begin
  Result := 4;
end;

procedure THash_XOR32.Init;
begin
  FCRC := 0;
end;

procedure THash_XOR32.Calc(const Data; DataSize: Integer); assembler; register;
asm
         JECXZ   @Exit
         PUSH    EAX
         MOV     EAX,[EAX].THash_XOR32.FCRC
         TEST    ECX,1
         JE      @@1
         XOR     AX,[EDX]
         INC     EDX
@@1:     SHR     ECX,1
         JECXZ   @@3
@@2:     ROL     EAX,5
         XOR     AX,[EDX]
         ADD     EDX,2
         DEC     ECX
         JNZ     @@2
@@3:     POP     EDX
         MOV     [EDX].THash_XOR32.FCRC,EAX
@Exit:
end;

function THash_XOR32.DigestKey: Pointer;
begin
  Result := @FCRC;
end;

{ THash_CRC32 }

class function THash_CRC32.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    058h,0EEh,01Fh,031h
end;

procedure THash_CRC32.Init;
begin
  FCRC := $FFFFFFFF;
end;

procedure THash_CRC32.Calc(const Data; DataSize: Integer); assembler; register;
asm
         PUSH   EAX
         MOV    EAX,[EAX].THash_CRC32.FCRC
         CALL   CRC32
         POP    EDX
         MOV    [EDX].THash_CRC32.FCRC,EAX
end;

procedure THash_CRC32.Done;
begin
  FCRC := not FCRC;
end;

{ THash_MD4 }

class function THash_MD4.TestVector: Pointer; assembler;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    025h,0EAh,0BFh,0CCh,08Ch,0C9h,06Fh,0D9h
         DB    02Dh,0CFh,07Eh,0BDh,07Fh,087h,07Ch,07Ch
end;

procedure THash_MD4.Transform(Buffer: PIntArray);
{calculate the Digest, fast}
var
  A, B, C, D: Longword;
begin
  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];

  Inc(A, Buffer[ 0] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 1] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[ 2] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[ 3] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[ 4] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 5] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[ 6] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[ 7] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[ 8] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 9] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[10] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[11] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[12] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[13] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[14] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[15] + (C and D or not C and A)); B := B shl 19 or B shr 13;

  Inc(A, Buffer[ 0] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 4] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[ 8] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[12] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 1] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 5] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[ 9] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[13] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 2] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 6] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[10] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[14] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 3] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 7] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[11] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[15] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;

  Inc(A, Buffer[ 0] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 8] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 4] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[12] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 2] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[10] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 6] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[14] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 1] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 9] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 5] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[13] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 3] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[11] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 7] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[15] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;

  Inc(FDigest[0], A);
  Inc(FDigest[1], B);
  Inc(FDigest[2], C);
  Inc(FDigest[3], D);
end;

class function THash_MD4.DigestKeySize: Integer;
begin
  Result := 16;
end;

function THash_MD4.DigestKey: Pointer;
begin
  Result := @FDigest;
end;

procedure THash_MD4.Init;
begin
  FillChar(FBuffer, SizeOf(FBuffer), 0);
{all Descend from MD4 (MD4, SHA1, RipeMD128, RipeMD160, RipeMD256) use this Init-Key}
  FDigest[0] := $67452301;
  FDigest[1] := $EFCDAB89;
  FDigest[2] := $98BADCFE;
  FDigest[3] := $10325476;
  FDigest[4] := $C3D2E1F0;
{for RMD320}
  FDigest[5] := $76543210;
  FDigest[6] := $FEDCBA98;
  FDigest[7] := $89ABCDEF;
  FDigest[8] := $01234567;
  FDigest[9] := $3C2D1E0F;
  FCount := 0;
end;

procedure THash_MD4.Done;
var
  I: Integer;
  S: Comp;
begin
  I := FCount and $3F;
  FBuffer[I] := $80;
  Inc(I);
  if I > 64 - 8 then
  begin
    FillChar(FBuffer[I], 64 - I, 0);
    Transform(@FBuffer);
    I := 0;
  end;
  FillChar(FBuffer[I], 64 - I, 0);
  S := FCount * 8;
  Move(S, FBuffer[64 - 8], SizeOf(S));
  Transform(@FBuffer);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
end;

procedure THash_MD4.Calc(const Data; DataSize: Integer);
var
  Index: Integer;
  P: PAnsiChar;
begin
  if DataSize <= 0 then Exit;
  Index := FCount and $3F;
  Inc(FCount, DataSize);
  if Index > 0 then
  begin
    if DataSize < 64 - Index then
    begin
      Move(Data, FBuffer[Index], DataSize);
      Exit;
    end;
    Move(Data, FBuffer[Index], 64 - Index);
    Transform(@FBuffer);
    Dec(DataSize, 64 - Index);
  end;
  P := @TByteArray(Data)[Index];
  Inc(Index, DataSize and not $3F);
  while DataSize >= 64 do
  begin
    Transform(Pointer(P));
    Inc(P, 64);
    Dec(DataSize, 64);
  end;
  Move(TByteArray(Data)[Index], FBuffer, DataSize);
end;

{ THash_MD5 }

class function THash_MD5.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    03Eh,0D8h,034h,08Ch,0D2h,0A4h,045h,0D6h
         DB    075h,05Dh,04Bh,0C9h,0FEh,0DCh,0C2h,0C6h
end;

procedure THash_MD5.Transform(Buffer: PIntArray);
var
  A, B, C, D: Longword;
begin
  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];

  Inc(A, Buffer[ 0] + $D76AA478 + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 1] + $E8C7B756 + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[ 2] + $242070DB + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[ 3] + $C1BDCEEE + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[ 4] + $F57C0FAF + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 5] + $4787C62A + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[ 6] + $A8304613 + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[ 7] + $FD469501 + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[ 8] + $698098D8 + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 9] + $8B44F7AF + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[10] + $FFFF5BB1 + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[11] + $895CD7BE + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[12] + $6B901122 + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[13] + $FD987193 + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[14] + $A679438E + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[15] + $49B40821 + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;

  Inc(A, Buffer[ 1] + $F61E2562 + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[ 6] + $C040B340 + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[11] + $265E5A51 + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 0] + $E9B6C7AA + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[ 5] + $D62F105D + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[10] + $02441453 + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[15] + $D8A1E681 + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 4] + $E7D3FBC8 + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[ 9] + $21E1CDE6 + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[14] + $C33707D6 + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[ 3] + $F4D50D87 + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 8] + $455A14ED + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[13] + $A9E3E905 + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[ 2] + $FCEFA3F8 + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[ 7] + $676F02D9 + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[12] + $8D2A4C8A + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;

  Inc(A, Buffer[ 5] + $FFFA3942 + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 8] + $8771F681 + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[11] + $6D9D6122 + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[14] + $FDE5380C + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[ 1] + $A4BEEA44 + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 4] + $4BDECFA9 + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[ 7] + $F6BB4B60 + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[10] + $BEBFBC70 + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[13] + $289B7EC6 + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 0] + $EAA127FA + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[ 3] + $D4EF3085 + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[ 6] + $04881D05 + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[ 9] + $D9D4D039 + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[12] + $E6DB99E5 + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[15] + $1FA27CF8 + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[ 2] + $C4AC5665 + (C xor D xor A)); B := B shl 23 or B shr  9 + C;

  Inc(A, Buffer[ 0] + $F4292244 + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[ 7] + $432AFF97 + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[14] + $AB9423A7 + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 5] + $FC93A039 + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[12] + $655B59C3 + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[ 3] + $8F0CCC92 + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[10] + $FFEFF47D + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 1] + $85845DD1 + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[ 8] + $6FA87E4F + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[15] + $FE2CE6E0 + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[ 6] + $A3014314 + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[13] + $4E0811A1 + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[ 4] + $F7537E82 + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[11] + $BD3AF235 + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[ 2] + $2AD7D2BB + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 9] + $EB86D391 + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;

  Inc(FDigest[0], A);
  Inc(FDigest[1], B);
  Inc(FDigest[2], C);
  Inc(FDigest[3], D);
end;

{ THash_SHA }

class function THash_SHA.DigestKeySize: Integer;
begin
  Result := 20;
end;

class function THash_SHA.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    0DCh,01Fh,07Dh,07Ch,096h,0DDh,0C7h,0FCh
         DB    04Dh,00Ah,0F2h,0CCh,012h,0E7h,0F7h,066h
         DB    05Bh,0B1h,085h,0ACh
end;

procedure THash_SHA.Transform(Buffer: PIntArray);

  procedure AssignBuffer(S, D: Pointer; Rotate: Boolean); assembler;
{  for I := 0 to 15 do W[I] := SwapInteger(Buffer[I]);
  for i:= 16 to 79 do
--- SHA  Rotate = False ---
    W[i] :=     W[I-3] xor W[I-8] xor W[i-14] xor W[i-16]
--- SHA1 Rotate = True  ---
    W[i] := ROL(W[i-3] xor W[i-8] xor W[i-14] xor W[i-16], 1);
    }
  asm
     PUSH  EBX
     PUSH  ECX
     MOV   EBX,EAX
     XOR   ECX,ECX
     CMP   CpuType,4
     JGE   @2
@1:  MOV   EAX,[EDX + ECX * 4]
     XCHG  AL,AH
     ROL   EAX,16
     XCHG  AL,AH
     MOV   [EBX],EAX
     ADD   EBX,4
     INC   ECX
     CMP   ECX,16
     JNZ   @1
     JMP   @@1

@2:  MOV   EAX,[EDX + ECX * 4]
     BSWAP EAX
     MOV   [EBX],EAX
     ADD   EBX,4
     INC   ECX
     CMP   ECX,16
     JNZ   @2
@@1:
     MOV   ECX,64
     POP   EDX
     CMP   DL,0
     JZ    @@3
@@2: MOV   EAX,[EBX -  3 * 4]
     XOR   EAX,[EBX -  8 * 4]
     XOR   EAX,[EBX - 14 * 4]
     XOR   EAX,[EBX - 16 * 4]
     ROL   EAX,1
     MOV   [EBX],EAX
     ADD   EBX,4
     DEC   ECX
     JNZ   @@2
     JMP   @@4

@@3: MOV   EAX,[EBX -  3 * 4]
     XOR   EAX,[EBX -  8 * 4]
     XOR   EAX,[EBX - 14 * 4]
     XOR   EAX,[EBX - 16 * 4]
     MOV   [EBX],EAX
     ADD   EBX,4
     DEC   ECX
     JNZ   @@3

@@4: POP   EBX
  end;

var
  A, B, C, D, E: Longword;
  W: array[0..79] of Longword;
begin
  AssignBuffer(@W, Buffer, FRotate);

  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];
  E := FDigest[4];

  Inc(E, (A shl 5 or A shr 27) + (D xor (B and (C xor D))) + W[ 0] + $5A827999); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor (A and (B xor C))) + W[ 1] + $5A827999); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor (E and (A xor B))) + W[ 2] + $5A827999); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor (D and (E xor A))) + W[ 3] + $5A827999); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor (C and (D xor E))) + W[ 4] + $5A827999); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor (B and (C xor D))) + W[ 5] + $5A827999); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor (A and (B xor C))) + W[ 6] + $5A827999); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor (E and (A xor B))) + W[ 7] + $5A827999); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor (D and (E xor A))) + W[ 8] + $5A827999); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor (C and (D xor E))) + W[ 9] + $5A827999); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor (B and (C xor D))) + W[10] + $5A827999); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor (A and (B xor C))) + W[11] + $5A827999); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor (E and (A xor B))) + W[12] + $5A827999); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor (D and (E xor A))) + W[13] + $5A827999); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor (C and (D xor E))) + W[14] + $5A827999); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor (B and (C xor D))) + W[15] + $5A827999); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor (A and (B xor C))) + W[16] + $5A827999); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor (E and (A xor B))) + W[17] + $5A827999); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor (D and (E xor A))) + W[18] + $5A827999); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor (C and (D xor E))) + W[19] + $5A827999); C := C shr 2 or C shl 30;

  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[20] + $6ED9EBA1); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[21] + $6ED9EBA1); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[22] + $6ED9EBA1); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[23] + $6ED9EBA1); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[24] + $6ED9EBA1); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[25] + $6ED9EBA1); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[26] + $6ED9EBA1); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[27] + $6ED9EBA1); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[28] + $6ED9EBA1); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[29] + $6ED9EBA1); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[30] + $6ED9EBA1); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[31] + $6ED9EBA1); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[32] + $6ED9EBA1); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[33] + $6ED9EBA1); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[34] + $6ED9EBA1); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[35] + $6ED9EBA1); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[36] + $6ED9EBA1); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[37] + $6ED9EBA1); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[38] + $6ED9EBA1); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[39] + $6ED9EBA1); C := C shr 2 or C shl 30;

  Inc(E, (A shl 5 or A shr 27) + ((B and C) or (D and (B or C))) + W[40] + $8F1BBCDC); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + ((A and B) or (C and (A or B))) + W[41] + $8F1BBCDC); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + ((E and A) or (B and (E or A))) + W[42] + $8F1BBCDC); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + ((D and E) or (A and (D or E))) + W[43] + $8F1BBCDC); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + ((C and D) or (E and (C or D))) + W[44] + $8F1BBCDC); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + ((B and C) or (D and (B or C))) + W[45] + $8F1BBCDC); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + ((A and B) or (C and (A or B))) + W[46] + $8F1BBCDC); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + ((E and A) or (B and (E or A))) + W[47] + $8F1BBCDC); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + ((D and E) or (A and (D or E))) + W[48] + $8F1BBCDC); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + ((C and D) or (E and (C or D))) + W[49] + $8F1BBCDC); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + ((B and C) or (D and (B or C))) + W[50] + $8F1BBCDC); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + ((A and B) or (C and (A or B))) + W[51] + $8F1BBCDC); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + ((E and A) or (B and (E or A))) + W[52] + $8F1BBCDC); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + ((D and E) or (A and (D or E))) + W[53] + $8F1BBCDC); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + ((C and D) or (E and (C or D))) + W[54] + $8F1BBCDC); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + ((B and C) or (D and (B or C))) + W[55] + $8F1BBCDC); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + ((A and B) or (C and (A or B))) + W[56] + $8F1BBCDC); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + ((E and A) or (B and (E or A))) + W[57] + $8F1BBCDC); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + ((D and E) or (A and (D or E))) + W[58] + $8F1BBCDC); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + ((C and D) or (E and (C or D))) + W[59] + $8F1BBCDC); C := C shr 2 or C shl 30;

  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[60] + $CA62C1D6); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[61] + $CA62C1D6); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[62] + $CA62C1D6); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[63] + $CA62C1D6); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[64] + $CA62C1D6); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[65] + $CA62C1D6); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[66] + $CA62C1D6); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[67] + $CA62C1D6); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[68] + $CA62C1D6); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[69] + $CA62C1D6); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[70] + $CA62C1D6); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[71] + $CA62C1D6); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[72] + $CA62C1D6); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[73] + $CA62C1D6); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[74] + $CA62C1D6); C := C shr 2 or C shl 30;
  Inc(E, (A shl 5 or A shr 27) + (D xor B xor C) + W[75] + $CA62C1D6); B := B shr 2 or B shl 30;
  Inc(D, (E shl 5 or E shr 27) + (C xor A xor B) + W[76] + $CA62C1D6); A := A shr 2 or A shl 30;
  Inc(C, (D shl 5 or D shr 27) + (B xor E xor A) + W[77] + $CA62C1D6); E := E shr 2 or E shl 30;
  Inc(B, (C shl 5 or C shr 27) + (A xor D xor E) + W[78] + $CA62C1D6); D := D shr 2 or D shl 30;
  Inc(A, (B shl 5 or B shr 27) + (E xor C xor D) + W[79] + $CA62C1D6); C := C shr 2 or C shl 30;

  Inc(FDigest[0], A);
  Inc(FDigest[1], B);
  Inc(FDigest[2], C);
  Inc(FDigest[3], D);
  Inc(FDigest[4], E);
end;

procedure THash_SHA.Done;
var
  I: Integer;
  S: Comp;
begin
  I := FCount mod 64;
  FBuffer[I] := $80;
  Inc(I);
  if I > 64 - 8 then
  begin
    FillChar(FBuffer[I], 64 - I, 0);
    Transform(@FBuffer);
    I := 0;
  end;
  FillChar(FBuffer[I], 64 - I, 0);
  S := FCount * 8;
  for I := 0 to 7 do FBuffer[63 - I] := PByteArray(@S)^[I];
  Transform(@FBuffer);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
{and here the MAC}
  SwapIntegerBuffer(@FDigest, @FDigest, 5);
end;

{ THash_SHA1 }

class function THash_SHA1.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    09Ah,001h,02Eh,063h,096h,02Ah,092h,0EBh
         DB    0D8h,02Eh,0F0h,0BCh,01Ch,0A4h,051h,06Ah
         DB    008h,069h,02Eh,068h
end;

procedure THash_SHA1.Init;
begin
  FRotate := True;
  inherited Init;
end;

{ TEncrypt }

constructor TEncrypt.Create;
begin
  inherited Create;
  FHashClass := DefaultHashClass;
  GetContext(FBufSize, FKeySize, FUserSize);
  GetMem(FVector, FBufSize);
  GetMem(FFeedback, FBufSize);
  GetMem(FBuffer, FBufSize);
  GetMem(FUser, FUserSize);
  Protect;
end;

destructor TEncrypt.Destroy;
begin
  Protect;
  ReallocMem(FVector, 0);
  ReallocMem(FFeedback, 0);
  ReallocMem(FBuffer, 0);
  ReallocMem(FUser, 0);
  FHash.Free;
  FHash := nil;
  inherited Destroy;
end;

function TEncrypt.GetFlag(Index: Integer): Boolean;
begin
  Result := FFlags and (1 shl Index) <> 0;
end;

procedure TEncrypt.SetFlag(Index: Integer; Value: Boolean);
begin
  Index := 1 shl Index;
  if Value then FFlags := FFlags or Index
    else FFlags := FFlags and not Index;
end;

procedure TEncrypt.InitBegin(var Size: Integer);
begin
  Initialized := False;
  Protect;
  if Size < 0 then Size := 0;
  if Size > KeySize then
    if not CheckEncryptKeySize then Size := KeySize
      else RaiseCipherException(CipherErrInvalidKeySize, RawByteString(Format(SInvalidKeySize, [ClassName, 0, KeySize])));
end;

procedure TEncrypt.InitEnd(IVector: Pointer);
begin
  if IVector = nil then Encode(Vector)
    else Move(IVector^, Vector^, BufSize);
  Move(Vector^, Feedback^, BufSize);
  Initialized := True;
end;

class procedure TEncrypt.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := 0;
  AKeySize := 0;
  AUserSize := 0;
end;

class function TEncrypt.TestVector: Pointer;
begin
  Result := GetTestVector;
end;

procedure TEncrypt.Encode(Data: Pointer);
begin
end;

procedure TEncrypt.Decode(Data: Pointer);
begin
end;

class function TEncrypt.MaxKeySize: Integer;
var
  Dummy: Integer;
begin
  GetContext(Dummy, Result, Dummy);
end;

class function TEncrypt.SelfTest: Boolean;
var
  Data: array[0..63] of AnsiChar;
  Key: RawByteString;
  SaveKeyCheck: Boolean;
begin
  Result       := InitTestIsOk; {have anonyme modified the testvectors ?}
{we will use the ClassName as Key :-)}
  Key          := RawByteString(ClassName);
  SaveKeyCheck := CheckEncryptKeySize;
  with Self.Create do
  try
    CheckEncryptKeySize := False;
    Mode := emCTS;
    Init(PAnsiChar(Key)^, Length(Key), nil);
    EncodeBuffer(GetTestVector^, Data, 32);
    Result := Result and CompareMem(TestVector, @Data, 32);
    Done;
    DecodeBuffer(Data, Data, 32);
    Result := Result and CompareMem(GetTestVector, @Data, 32);
  finally
    CheckEncryptKeySize := SaveKeyCheck;
    Free;
  end;
  FillChar(Data, SizeOf(Data), 0);
end;

procedure TEncrypt.Init(const Key; Size: Integer; IVector: Pointer);
begin
end;

procedure TEncrypt.InitKey(const Key: RawByteString; IVector: Pointer);
var
  I: Integer;
begin
  Hash.Init;
  Hash.Calc(PAnsiChar(Key)^, Length(Key));
  Hash.Done;
  I := Hash.DigestKeySize;
  if I > FKeySize then I := FKeySize; //generaly will truncate to large Keys
  Init(Hash.DigestKey^, I, IVector);
  EncodeBuffer(Hash.DigestKey^, Hash.DigestKey^, Hash.DigestKeySize);
  Done;
  HasHashKey := True;
end;

procedure TEncrypt.Done;
begin
  Move(FVector^, FFeedback^, FBufSize);
end;

procedure TEncrypt.Protect;
begin
  HasHashKey := False;
  Initialized := False;
  FillChar(FVector^, FBufSize, $FF);
  FillChar(FFeedback^, FBufSize, $FF);
  FillChar(FBuffer^, FBufSize, 0);
  FillChar(FUser^, FUserSize, 0);
end;

function TEncrypt.GetHash: THash;
begin
  if FHash = nil then
  begin
    if FHashClass = nil then FHashClass := DefaultHashClass;
    FHash := FHashClass.Create;
  end;
  Result := FHash;
end;

procedure TEncrypt.SetHashClass(Value: THashClass);
begin
  if Value <> FHashClass then
  begin
    FHash.Free;
    FHash := nil;
    FHashClass := Value;
    if FHashClass = nil then FHashClass := DefaultHashClass; 
  end;
end;

procedure TEncrypt.InternalCodeStream(Source, Dest: TStream; DataSize: Integer; Encode: Boolean);
var
  Buf: PAnsiChar;
  Over: PAnsiChar;
  OverSize: Integer;
  SPos: Integer;
  DPos: Integer;
  Len: Integer;
  Proc: TCodeProc;
begin
  if Source = nil then Exit;
  if Encode then Proc := EncodeBuffer else Proc := DecodeBuffer;
  if Dest = nil then Dest := Source;
  if DataSize < 0 then
  begin
    DataSize := Source.Size;
    Source.Position := 0;
  end;
  Buf := nil;
  Over := nil;
  OverSize := 0;
  //DoProgress(0, Size);
  try
    Buf    := AllocMem(EncMaxBufSize);
    DPos   := Dest.Position;
    SPos   := Source.Position;
    if IncludeHashKey and HasHashKey then
      if Encode then
      begin
        if Source = Dest then
        begin
          OverSize := Hash.DigestKeySize;
          Over := AllocMem(OverSize);
          OverSize := Source.Read(Over^, OverSize);
          SPos := Source.Position;
        end;
        Dest.Position := DPos;
        Dest.Write(Hash.DigestKey^, Hash.DigestKeySize);
        DPos := Dest.Position;
      end else
      begin
        OverSize := Hash.DigestKeySize;
        OverSize := Source.Read(Buf^, OverSize);
        if not CompareMem(Buf, Hash.DigestKey, Hash.DigestKeySize) then
          RaiseCipherException(CipherErrInvalidKey, SInvalidKey);
        SPos := Source.Position;
//        Dec(DataSize, OverSize);
      end;
    while DataSize > 0 do
    begin
      Source.Position := SPos;
      Len := DataSize;
      if Len > EncMaxBufSize then Len := EncMaxBufSize;
      if Over <> nil then
      begin
        if Len < OverSize then
        begin
          Move(Over^, Buf^, Len);
          Move(PByteArray(Over)[Len], Over^, OverSize - Len);
          Dec(OverSize, Len);
          OverSize := Source.Read(PByteArray(Over)[OverSize], Len) + OverSize;
        end else
        begin
          Move(Over^, Buf^, OverSize);
          Dec(Len, OverSize);
          Len := Source.Read(PAnsiChar(Buf + OverSize)^, Len) + OverSize;
          OverSize := Source.Read(Over^, OverSize);
        end;
      end else Len := Source.Read(Buf^, Len);
      SPos := Source.Position;
      if Len <= 0 then Break;
      Proc(Buf^, Buf^, Len);
      Dest.Position := DPos;
      Dest.Write(Buf^, Len);
      DPos := Dest.Position;
      Dec(DataSize, Len);
      //DoProgress(Size - DataSize, Size);
    end;
    if IncludeHashKey and HasHashKey and (Dest = Source) then
      if Encode and (Over <> nil) then
      begin
        while OverSize > 0 do
        begin
          Len := EncMaxBufSize;
          Move(Over^, Buf^, OverSize);
          Dec(Len, OverSize);
          Source.Position := SPos;
          Len := Source.Read(PAnsiChar(Buf + OverSize)^, Len) + OverSize;
          OverSize := Source.Read(Over^, OverSize);
          SPos := Source.Position;
          Source.Position := DPos;
          Source.Write(Buf^, Len);
          DPos := Source.Position;
        end;
      end else
        if not Encode then
        begin
          repeat
            Source.Position := SPos;
            Len := Source.Read(Buf^, EncMaxBufSize);
            SPos := Source.Position;
            Source.Position := DPos;
            Source.Write(Buf^, Len);
            DPos := Source.Position;
          until Len <= 0;
          Source.Size := Source.Position;
        end;
  finally
    //DoProgress(0, 0);
    ReallocMem(Buf, 0);
    ReallocMem(Over, 0);
  end;
end;

procedure TEncrypt.InternalCodeFile(const Source, Dest: RawByteString; Encode: Boolean);
var
  S,D: TFileStream;
begin
  S := nil;
  D := nil;
  try
    if (AnsiCompareText(string(Source), string(Dest)) <> 0) and (Trim(string(Dest)) <> '') then
    begin
      S := TFileStream.Create(string(Source), fmOpenRead or fmShareDenyNone);
      if not FileExists(string(Dest)) then D := TFileStream.Create(string(Dest), fmCreate)
        else D := TFileStream.Create(string(Dest), fmOpenReadWrite);
    end else
    begin
      S := TFileStream.Create(string(Source), fmOpenReadWrite);
      D := S;
    end;
    InternalCodeStream(S, D, -1, Encode);
  finally
    S.Free;
    if S <> D then
    begin
      D.Size := D.Position;
      D.Free;
    end;
  end;
end;

procedure TEncrypt.EncodeStream(const Source, Dest: TStream; DataSize: Integer);
begin
  InternalCodeStream(Source, Dest, DataSize, True);
end;

procedure TEncrypt.DecodeStream(const Source, Dest: TStream; DataSize: Integer);
begin
  InternalCodeStream(Source, Dest, DataSize, False);
end;

procedure TEncrypt.EncodeFile(const Source, Dest: RawByteString);
begin
  InternalCodeFile(Source, Dest, True);
end;

procedure TEncrypt.DecodeFile(const Source, Dest: RawByteString);
begin
  InternalCodeFile(Source, Dest, False);
end;

function TEncrypt.EncodeString(const Source: RawByteString): RawByteString;
begin
  SetLength(Result, Length(Source));
  EncodeBuffer(PAnsiChar(Source)^, PAnsiChar(Result)^, Length(Source));
end;

function TEncrypt.DecodeString(const Source: RawByteString): RawByteString;
begin
  SetLength(Result, Length(Source));
  DecodeBuffer(PAnsiChar(Source)^, PAnsiChar(Result)^, Length(Source));
end;

procedure TEncrypt.EncodeBuffer(const Source; var Dest; DataSize: Integer);
var
  S,D,F: PByte;
begin
  if not Initialized then
    RaiseCipherException(CipherErrNotInitialized, RawByteString(Format(SNotInitialized, [ClassName])));
  S := @Source;
  D := @Dest;
  case FMode of
    emECB:
      begin
        if S <> D then Move(S^, D^, DataSize);
        while DataSize >= FBufSize do
        begin
          Encode(D);
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if DataSize > 0 then
        begin
          Move(D^, FBuffer^, DataSize);
          //Encode(FBuffer);
          Move(FBuffer^, D^, DataSize);
        end;
      end;
    emCTS:
      begin
        while DataSize >= FBufSize do
        begin
          XORBuffers(S, FFeedback, FBufSize, D);
          Encode(D);
          XORBuffers(D, FFeedback, FBufSize, FFeedback);
          Inc(S, FBufSize);
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(S, FBuffer, DataSize, D);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
        end;
      end;
    emCBC:
      begin
        F := FFeedback;
        while DataSize >= FBufSize do
        begin
          XORBuffers(S, F, FBufSize, D);
          Encode(D);
          F := D;
          Inc(S, FBufSize);
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        Move(F^, FFeedback^, FBufSize);
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(S, FBuffer, DataSize, D);
        end;
      end;
    emCFB:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        D^ := S^ xor PByte(FBuffer)^;
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := D^;
//        SHIFTBuffers(FFeedback, PByteArray(D), FBufSize, 8);
        Inc(D);
        Inc(S);
        Dec(DataSize);
      end;
    emOFB:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        D^ := S^ xor PByte(FBuffer)^;
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := PByte(FBuffer)^;
//        SHIFTBuffers(FFeedback, PByteArray(D), FBufSize, 8);
        Inc(D);
        Inc(S);
        Dec(DataSize);
      end;
  end;
  FillChar(FBuffer^, FBufSize, 0);
end;

procedure TEncrypt.DecodeBuffer(const Source; var Dest; DataSize: Integer);
var
  S,D,F,B: PByte;
begin
  if not Initialized then
    RaiseCipherException(CipherErrNotInitialized, RawByteString(Format(SNotInitialized, [ClassName])));
  S := @Source;
  D := @Dest;
  case FMode of
    emECB:
      begin
        if S <> D then Move(S^, D^, DataSize);
        while DataSize >= FBufSize do
        begin
          Decode(D);
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if DataSize > 0 then
        begin
          Move(D^, FBuffer^, DataSize);
          //Encode(FBuffer);
          Move(FBuffer^, D^, DataSize);
        end;
      end;
    emCTS:
      begin
        if S <> D then Move(S^, D^, DataSize);
        F := FFeedback;
        B := FBuffer;
        while DataSize >= FBufSize do
        begin
          XORBuffers(D, F, FBufSize, B);
          Decode(D);
          XORBuffers(D, F, FBufSize, D);
          S := B;
          B := F;
          F := S;
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if F <> FFeedback then Move(F^, FFeedback^, FBufSize);
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(FBuffer, D, DataSize, D);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
        end;
      end;
    emCBC:
      begin
        if S <> D then Move(S^, D^, DataSize);
        F := FFeedback;
        B := FBuffer;
        while DataSize >= FBufSize do
        begin
          Move(D^, B^, FBufSize);
          Decode(D);
          XORBuffers(F, D, FBufSize, D);
          S := B;
          B := F;
          F := S;
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if F <> FFeedback then Move(F^, FFeedback^, FBufSize);
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(D, FBuffer, DataSize, D);
        end;
      end;
    emCFB:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := S^;
//        SHIFTBuffers(FFeedback, PByteArray(S), FBufSize, 8);
        D^ := S^ xor PByte(FBuffer)^;
        Inc(D);
        Inc(S);
        Dec(DataSize);
      end;
    emOFB:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        D^ := S^ xor PByte(FBuffer)^;
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := PByte(FBuffer)^;
//        SHIFTBuffers(FFeedback, PByteArray(D), FBufSize, 8);
        Inc(D);
        Inc(S);
        Dec(DataSize);
      end;
  end;
  FillChar(FBuffer^, FBufSize, 0);
end;

{ TEnc_Blowfish }

class procedure TEnc_Blowfish.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := 8;
  AKeySize := 56;
  AUserSize := SizeOf(Blowfish_Data) + SizeOf(Blowfish_Key);
end;

class function TEnc_Blowfish.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    019h,071h,0CAh,0CDh,02Bh,09Ch,085h,029h
         DB    0DAh,081h,047h,0B7h,0EBh,0CEh,016h,0C6h
         DB    091h,00Eh,01Dh,0C8h,040h,012h,03Eh,035h
         DB    070h,0EDh,0BCh,096h,04Ch,013h,0D0h,0B8h
end;

type
  PBlowfish = ^TBlowfish;
  TBlowfish = array[0..3, 0..255] of Longword;

procedure TEnc_Blowfish.Encode(Data: Pointer);
var
  I,A,B: Longword;
  P: PLongWord;
  D: PBlowfish;
begin
  D := User;
  P := Pointer(PAnsiChar(User) + SizeOf(Blowfish_Data));
  A := SwapInteger(PEncryptRec(Data).A) xor P^; Inc(P);
  B := SwapInteger(PEncryptRec(Data).B);
  for I := 0 to 7 do
  begin
    B := B xor P^ xor (D[0, A shr 24] +
                       D[1, A shr 16 and $FF] xor
                       D[2, A shr  8 and $FF] +
                       D[3, A and $FF]);
    Inc(P);
    A := A xor P^ xor (D[0, B shr 24] +
                       D[1, B shr 16 and $FF] xor
                       D[2, B shr  8 and $FF] +
                       D[3, B and $FF]);
    Inc(P);
  end;
  PEncryptRec(Data).A := SwapInteger(B xor P^);
  PEncryptRec(Data).B := SwapInteger(A);
end;

procedure TEnc_Blowfish.Decode(Data: Pointer);
var
  I,A,B: Longword;
  P: PLongWord;
  D: PBlowfish;
begin
  D := User;
  P := Pointer(PAnsiChar(User) + SizeOf(Blowfish_Data) + SizeOf(Blowfish_Key) - SizeOf(Integer));
  A := SwapInteger(PEncryptRec(Data).A) xor P^; Dec(P);
  B := SwapInteger(PEncryptRec(Data).B);
  for I := 0 to 7 do
  begin
    B := B xor P^ xor (D[0, A shr 24] +
                       D[1, A shr 16 and $FF] xor
                       D[2, A shr  8 and $FF] +
                       D[3, A and $FF]);
    Dec(P);
    A := A xor P^ xor (D[0, B shr 24] +
                       D[1, B shr 16 and $FF] xor
                       D[2, B shr  8 and $FF] +
                       D[3, B and $FF]);
    Dec(P);
  end;
  PEncryptRec(Data).A := SwapInteger(B xor P^);
  PEncryptRec(Data).B := SwapInteger(A);
end;

procedure TEnc_Blowfish.Init(const Key; Size: Integer; IVector: Pointer);
var
  I,J: Integer;
  B: array[0..7] of Byte;
  K: PByteArray;
  P: PIntArray;
  S: PBlowfish;
begin
  InitBegin(Size);
  K := @Key;
  S := User;
  P := Pointer(PAnsiChar(User) + SizeOf(Blowfish_Data));
  Move(Blowfish_Data, S^, SizeOf(Blowfish_Data));
  Move(Blowfish_Key, P^, Sizeof(Blowfish_Key));
  J := 0;
  for I := 0 to 17 do
  begin
    P[I] := P[I] xor (K[(J + 3) mod Size] +
                      K[(J + 2) mod Size] shl 8 +
                      K[(J + 1) mod Size] shl 16 +
                      K[J] shl 24);
    J := (J + 4) mod Size;
  end;
  FillChar(B, SizeOf(B), 0);
  for I := 0 to 8 do
  begin
    Encode(@B);
    P[I * 2]     := SwapInteger(PEncryptRec(@B).A);
    P[I * 2 + 1] := SwapInteger(PEncryptRec(@B).B);
  end;
  for I := 0 to 3 do
    for J := 0 to 127 do
    begin
      Encode(@B);
      S[I, J * 2]    := SwapInteger(PEncryptRec(@B).A);
      S[I, J * 2 +1] := SwapInteger(PEncryptRec(@B).B);
    end;
  FillChar(B, SizeOf(B), 0);
  InitEnd(IVector);
end;

{ TEnc_Twofish }

class procedure TEnc_Twofish.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := 16;
  AKeySize := 32;
  AUserSize := 4256;
end;

class function TEnc_Twofish.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    04Ah,007h,091h,0E6h,0BCh,02Bh,04Bh,0ACh
         DB    0B6h,055h,0AEh,0A1h,07Fh,07Dh,019h,0AAh
         DB    0CDh,088h,09Dh,092h,045h,08Ah,040h,093h
         DB    09Fh,034h,032h,0C0h,072h,0E1h,08Ah,0E9h
end;

procedure TEnc_Twofish.Encode(Data: Pointer);
var
  I,X,Y: Longword;
  A,B,C,D: Longword;
  S: PLongword;
  Box: PIntArray;
begin
  S := User;
  Box := @PIntArray(User)[40];
  A := PIntArray(Data)[0] xor S^; Inc(S);
  B := PIntArray(Data)[1] xor S^; Inc(S);
  C := PIntArray(Data)[2] xor S^; Inc(S);
  D := PIntArray(Data)[3] xor S^;
  S := @PIntArray(User)[8];
  for I := 0 to 14 do
  begin
    X := Box[A shl  1 and $1FE] xor
         Box[A shr  7 and $1FE + 1] xor
         Box[A shr 15 and $1FE + 512] xor
         Box[A shr 23 and $1FE + 513];
    Y := Box[B shr 23 and $1FE] xor
         Box[B shl  1 and $1FE + 1] xor
         Box[B shr  7 and $1FE + 512] xor
         Box[B shr 15 and $1FE + 513];
    D := D shl 1 or D shr 31;
    C := C xor (X + Y       + S^); Inc(S);
    D := D xor (X + Y shl 1 + S^); Inc(S);
    C := C shr 1 or C shl 31;

    X := Box[C shl  1 and $1FE] xor
         Box[C shr  7 and $1FE + 1] xor
         Box[C shr 15 and $1FE + 512] xor
         Box[C shr 23 and $1FE + 513];
    Y := Box[D shr 23 and $1FE] xor
         Box[D shl  1 and $1FE + 1] xor
         Box[D shr  7 and $1FE + 512] xor
         Box[D shr 15 and $1FE + 513];
    B := B shl 1 or B shr 31;
    A := A xor (X + Y       + S^); Inc(S);
    B := B xor (X + Y shl 1 + S^); Dec(S);
    A := A shr 1 or A shl 31;
  end;
  S := @PIntArray(User)[4];
  PIntArray(Data)[0] := C xor S^; Inc(S);
  PIntArray(Data)[1] := D xor S^; Inc(S);
  PIntArray(Data)[2] := A xor S^; Inc(S);
  PIntArray(Data)[3] := B xor S^;
end;

procedure TEnc_Twofish.Decode(Data: Pointer);
var
  I,T0,T1: Longword;
  A,B,C,D: Longword;
  S: PLongword;
  Box: PIntArray;
begin
  S := @PIntArray(User)[4];
  Box := @PIntArray(User)[40];
  C := PIntArray(Data)[0] xor S^; Inc(S);
  D := PIntArray(Data)[1] xor S^; Inc(S);
  A := PIntArray(Data)[2] xor S^; Inc(S);
  B := PIntArray(Data)[3] xor S^;
  S := @PIntArray(User)[39];
  for I := 0 to 14 do
  begin
    T0 := Box[C shl  1 and $1FE] xor
          Box[C shr  7 and $1FE + 1] xor
          Box[C shr 15 and $1FE + 512] xor
          Box[C shr 23 and $1FE + 513];
    T1 := Box[D shr 23 and $1FE] xor
          Box[D shl  1 and $1FE + 1] xor
          Box[D shr  7 and $1FE + 512] xor
          Box[D shr 15 and $1FE + 513];
    A  := A shl 1 or A shr 31;
    B  := B xor (T0 + T1 shl 1 + S^); Dec(S);
    A  := A xor (T0 + T1       + S^); Dec(S);
    B  := B shr 1 or B shl 31;

    T0 := Box[A shl  1 and $1FE] xor
          Box[A shr  7 and $1FE + 1] xor
          Box[A shr 15 and $1FE + 512] xor
          Box[A shr 23 and $1FE + 513];
    T1 := Box[B shr 23 and $1FE] xor
          Box[B shl  1 and $1FE + 1] xor
          Box[B shr  7 and $1FE + 512] xor
          Box[B shr 15 and $1FE + 513];
    C  := C shl 1 or C shr 31;
    D  := D xor (T0 + T1 shl 1 + S^); Dec(S);
    C  := C xor (T0 + T1       + S^); Inc(S);
    D  := D shr 1 or D shl 31;
  end;
  S := User;
  PIntArray(Data)[0] := A xor S^; Inc(S);
  PIntArray(Data)[1] := B xor S^; Inc(S);
  PIntArray(Data)[2] := C xor S^; Inc(S);
  PIntArray(Data)[3] := D xor S^;
end;

procedure TEnc_Twofish.Init(const Key; Size: Integer; IVector: Pointer);
var
  BoxKey: array[0..3] of Integer;
  SubKey: PIntArray;
  Box: PIntArray;

  procedure SetupKey;

    function Encode(K0, K1: Integer): Integer;
    var
      R, I, J, G2, G3: Integer;
      B: byte;
    begin
      R := 0;
      for I := 0 to 1 do
      begin
        if I <> 0 then R := R xor K0 else R := R xor K1;
        for J := 0 to 3 do
        begin
          B := R shr 24;
          if B and $80 <> 0 then G2 := (B shl 1 xor $014D) and $FF
            else G2 := B shl 1 and $FF;
          if B and 1 <> 0 then G3 := (B shr 1 and $7F) xor $014D shr 1 xor G2
            else G3 := (B shr 1 and $7F) xor G2;
          R := R shl 8 xor G3 shl 24 xor G2 shl 16 xor G3 shl 8 xor B;
        end;
      end;
      Result := R;
    end;

    function F32(X: Integer; K: array of Integer): Integer;
    var
      A, B, C, D: Integer;
    begin
      A := X and $FF;
      B := X shr  8 and $FF;
      C := X shr 16 and $FF;
      D := X shr 24;
      if Size = 32 then
      begin
        A := Twofish_8x8[1, A] xor K[3] and $FF;
        B := Twofish_8x8[0, B] xor K[3] shr  8 and $FF;
        C := Twofish_8x8[0, C] xor K[3] shr 16 and $FF;
        D := Twofish_8x8[1, D] xor K[3] shr 24;
      end;
      if Size >= 24 then
      begin
        A := Twofish_8x8[1, A] xor K[2] and $FF;
        B := Twofish_8x8[1, B] xor K[2] shr  8 and $FF;
        C := Twofish_8x8[0, C] xor K[2] shr 16 and $FF;
        D := Twofish_8x8[0, D] xor K[2] shr 24;
      end;
      A := Twofish_8x8[0, A] xor K[1] and $FF;
      B := Twofish_8x8[1, B] xor K[1] shr  8 and $FF;
      C := Twofish_8x8[0, C] xor K[1] shr 16 and $FF;
      D := Twofish_8x8[1, D] xor K[1] shr 24;

      A := Twofish_8x8[0, A] xor K[0] and $FF;
      B := Twofish_8x8[0, B] xor K[0] shr  8 and $FF;
      C := Twofish_8x8[1, C] xor K[0] shr 16 and $FF;
      D := Twofish_8x8[1, D] xor K[0] shr 24;

      Result := Twofish_Data[0, A] xor Twofish_Data[1, B] xor
                Twofish_Data[2, C] xor Twofish_Data[3, D];
    end;

  var
    I,J,A,B: Integer;
    E,O: array[0..3] of Integer;
    K: array[0..7] of Integer;
  begin
    FillChar(K, SizeOf(K), 0);
    Move(Key, K, Size);
    if Size <= 16 then Size := 16 else
      if Size <= 24 then Size := 24
        else Size := 32;
    J := Size shr 3 - 1;
    for I := 0 to J do
    begin
      E[I] := K[I shl 1];
      O[I] := K[I shl 1 + 1];
      BoxKey[J] := Encode(E[I], O[I]);
      Dec(J);
    end;
    J := 0;
    for I := 0 to 19 do
    begin
      A := F32(J, E);
      B := ROL(F32(J + $01010101, O), 8);
      SubKey[I shl 1] := A + B;
      B := A + B shr 1;
      SubKey[I shl 1 + 1] := ROL(B, 9);
      Inc(J, $02020202);
    end;
  end;

  procedure DoXOR(D, S: PIntArray; Value: Longword);
  var
    I: Longword;
  begin
    Value := Value and $FF;
    for I := 0 to 63 do D[I] := S[I] xor (Value * $01010101);
  end;

  procedure SetupBox128;
  var
    L: array[0..255] of Byte;
    A,I: Integer;
  begin
    DoXOR(@L, @Twofish_8x8[0], BoxKey[1]);
    A := BoxKey[0] and $FF;
    for I := 0 to 255 do
      Box[I shl 1] := Twofish_Data[0, Twofish_8x8[0, L[I]] xor A];
    DoXOR(@L, @Twofish_8x8[1], BoxKey[1] shr 8);
    A := BoxKey[0] shr  8 and $FF;
    for I := 0 to 255 do
      Box[I shl 1 + 1] := Twofish_Data[1, Twofish_8x8[0, L[I]] xor A];
    DoXOR(@L, @Twofish_8x8[0], BoxKey[1] shr 16);
    A := BoxKey[0] shr 16 and $FF;
    for I := 0 to 255 do
      Box[I shl 1 + 512] := Twofish_Data[2, Twofish_8x8[1, L[I]] xor A];
    DoXOR(@L, @Twofish_8x8[1], BoxKey[1] shr 24);
    A := BoxKey[0] shr 24;
    for I := 0 to 255 do
      Box[I shl 1 + 513] := Twofish_Data[3, Twofish_8x8[1, L[I]] xor A];
  end;

  procedure SetupBox192;
  var
    L: array[0..255] of Byte;
    A,B,I: Integer;
  begin
    DoXOR(@L, @Twofish_8x8[1], BoxKey[2]);
    A := BoxKey[0] and $FF;
    B := BoxKey[1] and $FF;
    for I := 0 to 255 do
      Box[I shl 1] := Twofish_Data[0, Twofish_8x8[0, Twofish_8x8[0, L[I]] xor B] xor A];
    DoXOR(@L, @Twofish_8x8[1], BoxKey[2] shr 8);
    A := BoxKey[0] shr  8 and $FF;
    B := BoxKey[1] shr  8 and $FF;
    for I := 0 to 255 do
      Box[I shl 1 + 1] := Twofish_Data[1, Twofish_8x8[0, Twofish_8x8[1, L[I]] xor B] xor A];
    DoXOR(@L, @Twofish_8x8[0], BoxKey[2] shr 16);
    A := BoxKey[0] shr 16 and $FF;
    B := BoxKey[1] shr 16 and $FF;
    for I := 0 to 255 do
      Box[I shl 1 + 512] := Twofish_Data[2, Twofish_8x8[1, Twofish_8x8[0, L[I]] xor B] xor A];
    DoXOR(@L ,@Twofish_8x8[0], BoxKey[2] shr 24);
    A := BoxKey[0] shr 24;
    B := BoxKey[1] shr 24;
    for I := 0 to 255 do
      Box[I shl 1 + 513] := Twofish_Data[3, Twofish_8x8[1, Twofish_8x8[1, L[I]] xor B] xor A];
  end;

  procedure SetupBox256;
  var
    L: array[0..255] of Byte;
    K: array[0..255] of Byte;
    A,B,I: Integer;
  begin
    DoXOR(@K, @Twofish_8x8[1], BoxKey[3]);
    for I := 0 to 255 do L[I] := Twofish_8x8[1, K[I]];
    DoXOR(@L, @L, BoxKey[2]);
    A := BoxKey[0] and $FF;
    B := BoxKey[1] and $FF;
    for I := 0 to 255 do
      Box[I shl 1] := Twofish_Data[0, Twofish_8x8[0, Twofish_8x8[0, L[I]] xor B] xor A];
    DoXOR(@K, @Twofish_8x8[0], BoxKey[3] shr 8);
    for I := 0 to 255 do L[I] := Twofish_8x8[1, K[I]];
    DoXOR(@L, @L, BoxKey[2] shr 8);
    A := BoxKey[0] shr  8 and $FF;
    B := BoxKey[1] shr  8 and $FF;
    for I := 0 to 255 do
      Box[I shl 1 + 1] := Twofish_Data[1, Twofish_8x8[0, Twofish_8x8[1, L[I]] xor B] xor A];
    DoXOR(@K, @Twofish_8x8[0],BoxKey[3] shr 16);
    for I := 0 to 255 do L[I] := Twofish_8x8[0, K[I]];
    DoXOR(@L, @L, BoxKey[2] shr 16);
    A := BoxKey[0] shr 16 and $FF;
    B := BoxKey[1] shr 16 and $FF;
    for I := 0 to 255 do
      Box[I shl 1 + 512] := Twofish_Data[2, Twofish_8x8[1, Twofish_8x8[0, L[I]] xor B] xor A];
    DoXOR(@K, @Twofish_8x8[1], BoxKey[3] shr 24);
    for I := 0 to 255 do L[I] := Twofish_8x8[0, K[I]];
    DoXOR(@L, @L, BoxKey[2] shr 24);
    A := BoxKey[0] shr 24;
    B := BoxKey[1] shr 24;
    for I := 0 to 255 do
      Box[I shl 1 + 513] := Twofish_Data[3, Twofish_8x8[1, Twofish_8x8[1, L[I]] xor B] xor A];
  end;

begin
  InitBegin(Size);
  SubKey := User;
  Box    := @SubKey[40];
  SetupKey;
  if Size = 16 then SetupBox128 else
    if Size = 24 then SetupBox192
      else SetupBox256;
  InitEnd(IVector);
end;

{ TEnc_IDEA }

class procedure TEnc_IDEA.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := 8;
  AKeySize := 16;
  AUserSize := 208;
end;

class function TEnc_IDEA.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    08Ch,065h,0CAh,0D8h,043h,0E7h,099h,093h
         DB    0EDh,041h,0EAh,048h,0FDh,066h,050h,094h
         DB    0A2h,025h,06Dh,0D7h,0B1h,0D0h,09Ah,023h
         DB    03Dh,0D2h,0E8h,0ECh,0C9h,045h,07Fh,07Eh
end;

function IDEAMul(X, Y: Longword): Longword; assembler; register;
asm
     AND    EAX,0FFFFh
     JZ     @@1
     AND    EDX,0FFFFh
     JZ     @@1
     MUL    EDX
     MOV    ECX,EAX
     MOV    EDX,EAX
     SHR    EDX,16
     SUB    EAX,EDX
     CMP    AX,CX
     JNA    @@2
     INC    EAX
@@2: RET
@@1: MOV    ECX,1
     SUB    ECX,EAX
     SUB    ECX,EDX
     MOV    EAX,ECX
end;

procedure TEnc_IDEA.Cipher(Data, Key: PWordArray);
var
  I: Longword;
  X,Y,A,B,C,D: Longword;
begin
  I := SwapInteger(PIntArray(Data)[0]);
  A := LongRec(I).Hi;
  B := LongRec(I).Lo;
  I := SwapInteger(PIntArray(Data)[1]);
  C := LongRec(I).Hi;
  D := LongRec(I).Lo;
  for I := 0 to 7 do
  begin
    A := IDEAMul(A, Key[0]);
    Inc(B, Key[1]);
    Inc(C, Key[2]);
    D := IDEAMul(D, Key[3]);
    Y := C xor A;
    Y := IDEAMul(Y, Key[4]);
    X := B xor D + Y;
    X := IDEAMul(X, Key[5]);
    Inc(Y, X);
    A := A xor X;
    D := D xor Y;
    Y := B xor Y;
    B := C xor X;
    C := Y;
    Inc(PWord(Key), 6);
  end;
  LongRec(I).Hi := IDEAMul(A, Key[0]);
  LongRec(I).Lo := C + Key[1];
  PIntArray(Data)[0] := SwapInteger(I);
  LongRec(I).Hi := B + Key[2];
  LongRec(I).Lo := IDEAMul(D, Key[3]);
  PIntArray(Data)[1] := SwapInteger(I);
end;

procedure TEnc_IDEA.Encode(Data: Pointer);
begin
  Cipher(Data, User);
end;

procedure TEnc_IDEA.Decode(Data: Pointer);
begin
  Cipher(Data, @PIntArray(User)[26]);
end;

procedure TEnc_IDEA.Init(const Key; Size: Integer; IVector: Pointer);

  function IDEAInv(X: Word): Word;
  var
    A, B, C, D: Word;
  begin
    if X <= 1 then
    begin
      Result := X;
      Exit;
    end;
    A := 1;
    B := $10001 div X;
    C := $10001 mod X;
    while C <> 1 do
    begin
      D := X div C;
      X := X mod C;
      Inc(A, B * D);
      if X = 1 then
      begin
        Result := A;
        Exit;
      end;
      D := C div X;
      C := C mod X;
      Inc(B, A * D);
    end;
    Result := 1 - B;
  end;

var
  I: Integer;
  E: PWordArray;
  A,B,C: Word;
  K,D: PWordArray;
begin
  InitBegin(Size);
  E := User;
  Move(Key, E^, Size);
  for I := 0 to 7 do E[I] := Swap(E[I]);
  for I := 0 to 39 do
    E[I + 8] := E[I and not 7 + (I + 1) and 7] shl 9 or
                E[I and not 7 + (I + 2) and 7] shr 7;
  for I := 41 to 44 do
    E[I + 7] := E[I] shl 9 or E[I + 1] shr 7;
  K  := E;
  D  := @E[100];
  A  := IDEAInv(K[0]);
  B  := 0 - K[1];
  C  := 0 - K[2];
  D[3] := IDEAInv(K[3]);
  D[2] := C;
  D[1] := B;
  D[0] := A;
  Inc(PWord(K), 4);
  for I := 1 to 8 do
  begin
    Dec(PWord(D), 6);
    A    := K[0];
    D[5] := K[1];
    D[4] := A;
    A    := IDEAInv(K[2]);
    B    := 0 - K[3];
    C    := 0 - K[4];
    D[3] := IDEAInv(K[5]);
    D[2] := B;
    D[1] := C;
    D[0] := A;
    Inc(PWord(K), 6);
  end;
  A := D[2]; D[2] := D[1]; D[1] := A;
  InitEnd(IVector);
end;

initialization
  CpuType := GetCPUType;
  if CpuType > 3 then
  begin
    SwapInteger := BSwapInt;
    SwapIntegerBuffer := BSwapIntBuf;
  end else
  begin
    SwapInteger := SwapInt;
    SwapIntegerBuffer := SwapIntBuf;
  end;
  InitTestIsOk := CRC32(CRC32($29524828, PAnsiChar(@CRC32) + 41, 1076), GetTestVector, 32) = $78D28741;

end.

