/*----------------------------------------------------------------
// 模块名：pluto
// 模块描述：rpc 以及 entity 的二进制封装
//----------------------------------------------------------------*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <string>

#include "pluto.h"
#include "util.h"
#include "world_select.h"
#include "memory_pool.h"
#include "logger.h"
#include "debug.h"


using namespace std;

static const unsigned char sg_mycryto_key[] = {15, 180, 213, 37, 40, 98, 85, 7, 152, 223, 48, 168, 71, 102, 191, 194};
CBitCryto sg_mycryto((char*)sg_mycryto_key, sizeof(sg_mycryto_key)); //客户端服务器交互包加解密类

#if (REVERSE_CONVERT == 1)

    void uint8_to_sz(uint8_t n, char* s)
    {
        s[0] = n;
    }

    void uint16_to_sz(uint16_t n, char* s)
    {
        s[0] = (n >> 8) & 0xff ;
        s[1] = n & 0xff;
    }

    void uint32_to_sz(uint32_t n, char* s)
    {
        s[0] = (n >> 24) & 0xff ;
        s[1] = (n >> 16) & 0xff ;
        s[2] = (n >> 8) & 0xff ;
        s[3] = n & 0xff;
    }

    void uint64_to_sz(uint64_t n, char* s)
    {
        s[0] = (n >> 56) & 0xff ;
        s[1] = (n >> 48) & 0xff ;
        s[2] = (n >> 40) & 0xff ;
        s[3] = (n >> 32) & 0xff ;
        s[4] = (n >> 24) & 0xff ;
        s[5] = (n >> 16) & 0xff ;
        s[6] = (n >> 8) & 0xff ;
        s[7] = n & 0xff;
    }

    void float32_to_sz(float32_t n, char* s)
    {
        uint32_to_sz(*(uint32_t*)(void*)&n, s)
    }

    void float64_to_sz(float64_t n, char* s)
    {
        uint64_to_sz(*(uint64_t*)(void*)&n, s)
    }

    uint8_t sz_to_uint8(unsigned char* s)
    {
        return s[0];
    }

    uint16_t sz_to_uint16(unsigned char* s)
    {
        return (s[0] << 8) + s[1];
    }

    uint32_t sz_to_uint32(unsigned char* s)
    {
        return (s[0] << 24) + (s[1] << 16) + (s[2] << 8) + s[3];
    }

    uint64_t sz_to_uint64(unsigned char* s)
    {
        return (s[0] << 56) + (s[1] << 48) + (s[2] << 40) + (s[3] << 32) \
            + (s[4] << 24) + (s[5] << 16) + (s[6] << 8) + s[7];
    }

    float32_t sz_to_float32(unsigned char* s)
    {
        uint32_t n = sz_to_uint32(s);
        return *(float32_t*)(void*)&n;
    }

    float64_t sz_to_float64(unsigned char* s)
    {
        uint64_t n = sz_to_uint64(s);
        return *(float64_t*)(void*)&n;
    }

#else

    void uint8_to_sz(uint8_t n, char* s)
    {
        s[0] = n;
    }

    void uint16_to_sz(uint16_t n, char* s)
    {
        *(uint16_t*)(void*)s = n;
    }

    void uint16_to_sz_big_endian(uint16_t n, char* s)
    {
        s[0] = (n >> 8) & 0xff ;
        s[1] = n & 0xff;
    }

    void uint32_to_sz(uint32_t n, char* s)
    {
        *(uint32_t*)(void*)s = n;
    }

    void uint64_to_sz(uint64_t n, char* s)
    {
        *(uint64_t*)(void*)s = n;
    }

    void float32_to_sz(float32_t n, char* s)
    {
        *(float32_t*)(void*)s = n;
    }

    void float64_to_sz(float64_t n, char* s)
    {
        *(float64_t*)(void*)s = n;
    }

    uint8_t sz_to_uint8(unsigned char* s)
    {
        return s[0];
    }

    uint16_t sz_to_uint16(unsigned char* s)
    {
        return *(uint16_t*)(void*)s;
    }

    uint16_t sz_to_uint16_big_endian(unsigned char* s)
    {
        return (s[0] << 8) + s[1];
    }

    uint32_t sz_to_uint32(unsigned char* s)
    {
        return *(uint32_t*)(void*)s;
    }

    uint64_t sz_to_uint64(unsigned char* s)
    {
        return *(uint64_t*)(void*)s;
    }

    float32_t sz_to_float32(unsigned char* s)
    {
        return *(float32_t*)(void*)s;
    }

    float64_t sz_to_float64(unsigned char* s)
    {
        return *(float64_t*)(void*)s;
    }

#endif


//将值如0x12的char转换为字符串"12"
void char_to_sz(unsigned char c, char* s)
{
    const static char char_map[] = "0123456789abcdef";

    unsigned char c1 = (c >> 4) & 0xf;
    unsigned char c2 = c & 0xf;
    s[0] = char_map[c1];
    s[1] = char_map[c2];

}

//将形如"12"的字符创转换为值为0x12的char
unsigned char sz_to_char(char* s)
{
    unsigned int i;
    sscanf(s, "%02x", &i);
    unsigned char c = (unsigned char)i;
    return c;
}

void PrintHex16(const char* s, size_t n)
{
    char buf[16*3 + 3 + 16 + 1 + 1];
    memset(buf, ' ', sizeof(buf) - 1);
    buf[sizeof(buf)-1] = '\0';

    for(size_t i=0; i<n; ++i)
    {
        unsigned char c = s[i];
        char_to_sz(c, buf+i*3);

        if(isprint(c))
        {
            buf[51+i] = c;
        }
        else
        {
            buf[51+i] = '.';
        }
    }

    g_logger.SendLog(buf, strlen(buf));
}

void PrintHex(const char* s, size_t n)
{
    size_t sixteen = 16;
    size_t count = n / sixteen + 1;

    for(size_t i=0; i<count; ++i)
    {
        if(i == count-1)
        {
            PrintHex16(s+i*sixteen, n % sixteen);
        }
        else
        {
            PrintHex16(s+i*sixteen, sixteen);
        }
    }

}

void PrintHexPluto(CPluto& c)
{
    uint32_t n = max(c.GetLen(), c.GetMaxLen());
    PrintHex(c.GetBuff(), n);
}


SEntityPropFromPluto::~SEntityPropFromPluto()
{
    ClearMap(data);
}

////////////////////////////////////////////////////////////////////////////////////////

CPluto::CPluto(uint32_t buff_size) : m_unLen(0), m_unMaxLen(0), m_nDecodeErrIdx(0), m_mb(NULL), m_bEncodeErr(false), m_srcFd(-2), m_dstFd(-2)
#ifdef __WEBSOCKET_CLIENT
    ,m_wsOpcode(WS_OPCODE_NONE), m_wsHeaderLen(0), m_wsMaskPos(-1), m_wsDataLen(-1)
#endif
{
    m_szBuff = new char[buff_size];
    m_unBuffSize = buff_size;
}

void CPluto::OverrideBuffer(const char* buffer, uint16_t len)
{
    if (len > m_unBuffSize)
    {
        LogWarning("OverrideBuffer_Error", "buffer too small");
        return;
    }

    memcpy(m_szBuff, buffer, len);
    EndRecv(len);
}

#ifdef __WEBSOCKET_CLIENT
/* has mask
CPluto::CPluto(uint8_t opCode, const char* wsDataBuffer, uint16_t dataLen) : m_unLen(0), m_unMaxLen(0), m_nDecodeErrIdx(0), m_mb(NULL), m_bEncodeErr(false), m_srcFd(-2), m_dstFd(-2)
    ,m_wsOpcode(opCode)
{
    uint8_t b1 = 0x80 | opCode;
    uint8_t b2 = 0;

    // 包括2字节头，和4字节mask
    m_wsHeaderLen = WS_PLUTO_MSGLEN_HEAD + 4;
    m_wsMaskPos = WS_PLUTO_MSGLEN_HEAD;
    bool isExpandLen = dataLen >= 0x7E;
    if (isExpandLen)
    {
        m_wsHeaderLen += 2;
        m_wsMaskPos += 2;
        b2 =  0x80 | 0x7E;
    }
    else
    {
        b2 = 0x80 | dataLen;
    }
    m_wsDataLen = dataLen;

    m_szBuff = new char[m_wsHeaderLen + m_wsDataLen];
    m_unBuffSize = m_wsHeaderLen + m_wsDataLen;

    // 写入header的2字节
    char* buffTemp = m_szBuff;
    uint8_to_sz(b1, buffTemp); 
    buffTemp++;
    uint8_to_sz(b2, buffTemp); 
    buffTemp++;
    // 写入长度
    if (isExpandLen)
    {
        uint16_to_sz_big_endian(dataLen, buffTemp); 
        buffTemp += sizeof(dataLen);
    }
    // 写入mask
    for(int i = 0; i < 4; i++)
    {
        buffTemp[i] = rand() % 0x100;
        buffTemp++;
    }
    // 写入data
    memcpy(buffTemp, wsDataBuffer, dataLen);
    // 加密
    WsMask();
    // 结束
    EndRecv(m_unBuffSize);
}
*/

CPluto::CPluto(uint8_t opCode, const char* wsDataBuffer, uint16_t dataLen) : m_unLen(0), m_unMaxLen(0), m_nDecodeErrIdx(0), m_mb(NULL), m_bEncodeErr(false), m_srcFd(-2), m_dstFd(-2)
    ,m_wsOpcode(opCode)
{
    uint8_t b1 = 0x80 | opCode;
    uint8_t b2 = 0;

    // 2字节头
    m_wsHeaderLen = WS_PLUTO_MSGLEN_HEAD;
    m_wsMaskPos = -1;
    bool isExpandLen = dataLen >= 0x7E;
    if (isExpandLen)
    {
        m_wsHeaderLen += 2;
        b2 =  0x7E;
    }
    else
    {
        b2 = dataLen & 0xFF;
    }
    m_wsDataLen = dataLen;

    m_szBuff = new char[m_wsHeaderLen + m_wsDataLen];
    m_unBuffSize = m_wsHeaderLen + m_wsDataLen;

    // 写入header的2字节
    char* buffTemp = m_szBuff;
    uint8_to_sz(b1, buffTemp); 
    buffTemp++;
    uint8_to_sz(b2, buffTemp); 
    buffTemp++;
    // 写入长度
    if (isExpandLen)
    {
        uint16_to_sz_big_endian(dataLen, buffTemp); 
        buffTemp += sizeof(dataLen);
    }
    // 写入data
    memcpy(buffTemp, wsDataBuffer, dataLen);
    // 结束
    EndRecv(m_unBuffSize);
}

#endif

CPluto::~CPluto()
{
    delete[] m_szBuff;
}

//输入
CPluto& CPluto::Encode(pluto_msgid_t msgid)
{
    m_unLen = MSGLEN_HEAD + MSGLEN_RESERVED;
    (*this) << msgid;
    return *this;
}

//encode时自动调整buff大小
void CPluto::Resize(uint32_t n)
{
    if(m_unLen + n <= m_unBuffSize)
    {
        return;
    }

    //buff大小不足,需要扩展
    uint32_t old_buffsize = m_unBuffSize;
    enum{resize_times = 2}; //需要扩展buff时的倍数
    uint32_t new_buffsize = (m_unLen+n)*resize_times;
    enum{ MIDDLE_SIZE = 4096, HIGH_SIZE = MIDDLE_SIZE * 16 };
    if(new_buffsize <= MIDDLE_SIZE)
    {
        m_unBuffSize = MIDDLE_SIZE;
    }
    else if(new_buffsize <= HIGH_SIZE)
    {
        m_unBuffSize = HIGH_SIZE;
    }
    else
    {
        m_unBuffSize = new_buffsize;
    }
    //LogWarning("CPluto::resize", "msg=%d;old=%u;new=%u", GetMsgId(), old_buffsize, m_unBuffSize);

    char* new_buff = new char[m_unBuffSize];

    memcpy(new_buff, m_szBuff, m_unLen);

    delete[] m_szBuff;
    m_szBuff = new_buff;
}

CPluto& CPluto::operator<< (uint8_t n)
{
    Resize(sizeof(n));

    uint8_to_sz(n, m_szBuff + m_unLen);
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (uint16_t n)
{
    Resize(sizeof(n));

    uint16_to_sz(n, m_szBuff + m_unLen);
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (uint32_t n)
{
    Resize(sizeof(n));

    uint32_to_sz(n, m_szBuff + m_unLen);
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (uint64_t n)
{
    Resize(sizeof(n));

    uint64_to_sz(n, m_szBuff + m_unLen);
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (int8_t n)
{
    uint8_t n2 = (uint8_t)n;
    (*this) << n2;
    return *this;
}

CPluto& CPluto::operator<< (int16_t n)
{
    uint16_t n2 = (uint16_t)n;
    (*this) << n2;
    return *this;
}

CPluto& CPluto::operator<< (int32_t n)
{
    uint32_t n2 = (uint32_t)n;
    (*this) << n2;
    return *this;
}

CPluto& CPluto::operator<< (int64_t n)
{
    uint64_t n2 = (uint64_t)n;
    (*this) << n2;
    return *this;
}

CPluto& CPluto::operator<< (float32_t f)
{
    Resize(sizeof(f));

    float32_to_sz(f, m_szBuff + m_unLen);
    m_unLen += sizeof(f);
    return *this;
}

CPluto& CPluto::operator<< (float64_t f)
{
    Resize(sizeof(f));

    float64_to_sz(f, m_szBuff + m_unLen);
    m_unLen += sizeof(f);
    return *this;
}

CPluto& CPluto::operator<< (const char* s)
{
    enum{ MAX_LEN = 65534, PRINT_LEN = 48, };
    size_t src_n = strlen(s);    //未转换为uint16的原始长度
    if(src_n >= MAX_LEN)
    {
        SetEncodeErr();            //设错误标记
        LogError("CPluto::operator<<", "error=len_ge_65535");
        PrintHex(s, PRINT_LEN);    //只记录前48个字符
    }

    uint16_t n = (uint16_t)src_n;

    Resize(sizeof(uint16_t)+n);

    (*this) << n;
    memcpy(m_szBuff+m_unLen, s, n);
    m_unLen += n;
    return *this;
}

CPluto& CPluto::operator<< (const string& s)
{
    enum{ MAX_LEN = 65534, PRINT_LEN = 48, };
    size_t src_n = s.size();    //未转换为uint16的原始长度
    if(src_n >= MAX_LEN)
    {
        SetEncodeErr();            //设错误标记
        LogError("CPluto::operator<<", "error=len_ge_65535");
        PrintHex(s.c_str(), PRINT_LEN);    //只记录前48个字符
    }

    uint16_t n = (uint16_t)src_n;

    Resize(sizeof(uint16_t)+n);

    (*this) << n;
    memcpy(m_szBuff+m_unLen, s.c_str(), n);
    m_unLen += n;
    return *this;
}

CPluto& CPluto::operator<< (pluto_op op)
{
    return (*op)(*this);
}

//输出
//包头里记录的包长度
uint32_t CPluto::GetMsgLen()
{
    return sz_to_uint32((unsigned char*)m_szBuff);
}

//去掉包头的剩下长度
uint32_t CPluto::GetMsgLeftLen()
{
    return GetMsgLen() - MSGLEN_HEAD;
}

//消息id
pluto_msgid_t CPluto::GetMsgId()
{
    return sz_to_msgid<pluto_msgid_t>((unsigned char*)(m_szBuff + MSGLEN_HEAD + MSGLEN_RESERVED));
}

CPluto& CPluto::Decode()
{
    if(GetMsgId() < MAX_CLIENT_SERVER_MSGID)
    {
        //客户端包需要解密
        sg_mycryto.Reset();
        for(uint32_t i=MSGLEN_TEXT_POS; i<m_unMaxLen; ++i)
        {
            m_szBuff[i] = sg_mycryto.Decode(m_szBuff[i]);
        }
    }

    //print_hex_pluto(*this);
    m_unLen = MSGLEN_HEAD + MSGLEN_RESERVED + MSGLEN_MSGID;
    return *this;
}

CPluto& CPluto::operator>>(uint8_t& n)
{
    uint32_t nNewLen = m_unLen + sizeof(n);
    if(nNewLen > m_unMaxLen)
    {
        //字符数不够解析
        m_nDecodeErrIdx = m_unLen;
    }
    else
    {
        n = sz_to_uint8((unsigned char*)m_szBuff + m_unLen);
        m_unLen = nNewLen;
    }

    return *this;
}

CPluto& CPluto::operator>>(uint16_t& n)
{
    uint32_t nNewLen = m_unLen + sizeof(n);
    if(nNewLen > m_unMaxLen)
    {
        //字符数不够解析
        m_nDecodeErrIdx = m_unLen;
    }
    else
    {
        n = sz_to_uint16((unsigned char*)m_szBuff + m_unLen);
        m_unLen = nNewLen;
    }

    return *this;
}

CPluto& CPluto::operator>>(uint32_t& n)
{
    uint32_t nNewLen = m_unLen + sizeof(n);
    if(nNewLen > m_unMaxLen)
    {
        //字符数不够解析
        m_nDecodeErrIdx = m_unLen;
    }
    else
    {
        n = sz_to_uint32((unsigned char*)m_szBuff + m_unLen);
        m_unLen = nNewLen;
    }

    return *this;
}

CPluto& CPluto::operator>>(uint64_t& n)
{
    uint32_t nNewLen = m_unLen + sizeof(n);
    if(nNewLen > m_unMaxLen)
    {
        //字符数不够解析
        m_nDecodeErrIdx = m_unLen;
    }
    else
    {
        n = sz_to_uint64((unsigned char*)m_szBuff + m_unLen);
        m_unLen = nNewLen;
    }

    return *this;
}

CPluto& CPluto::operator>>(int8_t& n)
{
    uint8_t n2;
    (*this) >> n2;
    n = (int8_t) n2;
    return *this;
}

CPluto& CPluto::operator>>(int16_t& n)
{
    uint16_t n2;
    (*this) >> n2;
    n = (int16_t) n2;
    return *this;
}

CPluto& CPluto::operator>>(int32_t& n)
{
    uint32_t n2;
    (*this) >> n2;
    n = (int32_t) n2;
    return *this;
}

CPluto& CPluto::operator>>(int64_t& n)
{
    uint64_t n2;
    (*this) >> n2;
    n = (int64_t) n2;
    return *this;
}

CPluto& CPluto::operator>>(float32_t& f)
{
    uint32_t nNewLen = m_unLen + sizeof(f);
    if(nNewLen > m_unMaxLen)
    {
        //字符数不够解析
        m_nDecodeErrIdx = m_unLen;
    }
    else
    {
        f = sz_to_float32((unsigned char*)m_szBuff + m_unLen);
        m_unLen = nNewLen;
    }

    return *this;
}

CPluto& CPluto::operator>>(float64_t& f)
{
    uint32_t nNewLen = m_unLen + sizeof(f);
    if(nNewLen > m_unMaxLen)
    {
        //字符数不够解析
        m_nDecodeErrIdx = m_unLen;
    }
    else
    {
        f = sz_to_float64((unsigned char*)m_szBuff + m_unLen);
        m_unLen = nNewLen;
    }

    return *this;
}

CPluto& CPluto::operator>> (string& s)
{
    uint16_t n = 0;
    (*this) >> n;

    if(this->GetDecodeErrIdx() == 0)
    {
        uint32_t nNewLen = m_unLen + n;
        if(n > m_unMaxLen)
        {
            m_nDecodeErrIdx = m_unLen;
        }
        else
        {
            s.assign(m_szBuff+m_unLen, n);
            m_unLen += n;
        }
    }

    return *this;
}

CPluto& EndPluto(CPluto& u)
{
    uint32_to_sz(u.GetLen(), u.GetRecvBuff());
    char *str = u.GetRecvBuff();
    str[MSGLEN_HEAD] = '\0';
    str[MSGLEN_HEAD + 1] = '\0';

    u.SetMaxLen(u.GetLen());

    if(u.GetMsgId() < MAX_CLIENT_SERVER_MSGID)
    {
        //客户端包需要加密
        sg_mycryto.Reset();
        for(uint32_t i = MSGLEN_TEXT_POS; i<u.GetLen(); ++i)
        {
            str[i] = sg_mycryto.Encode(str[i]);
        }
    }

    return u;
}

CPluto& CPluto::endPluto()
{
    return EndPluto(*this);
}

void CPluto::FillVObject(VTYPE_OJBECT* vt, VOBJECT& v)
{
    v.vt = vt->vt;
    switch(vt->vt)
    {
        case V_INT8:
            (*this) >> v.vv.i8;
            break;
        case V_INT16:
            (*this) >> v.vv.i16;
            break;
        case V_INT32:
            (*this) >> v.vv.i32;
            break;
        case V_INT64:
            (*this) >> v.vv.i64;
            break;
        case V_UINT8:
            (*this) >> v.vv.u8;
            break;
        case V_UINT16:
            (*this) >> v.vv.u16;
            break;
        case V_UINT32:
            (*this) >> v.vv.u32;
            break;
        case V_UINT64:
            (*this) >> v.vv.u64;
            break;
        case V_FLOAT32:
            (*this) >> v.vv.f32;
            break;
        case V_FLOAT64:
            (*this) >> v.vv.f64;
            break;
        case V_STR:
        {
            string* s = new string;
            (*this) >> (*s);
            v.vv.s = s;
            break;
        }
        case V_OBJ_ARY:
        {
            if(NULL == vt->o)
            {
                LogWarning("CPluto::FillVObject", "V_OBJ_ARY NULL == vt->o");
                return;
            }
            if(1 != vt->o->size())
            {
                LogWarning("CPluto::FillVObject", "V_OBJ_ARY 1 != vt->o->size()");
                return;
            }
            
            VTYPE_OJBECT* itemVt = (*vt->o)[0];
            uint16_t len = 0;
            (*this) >> len;
            // 解析每个元素
            v.vv.oOrAry = new T_VECTOR_OBJECT();
            v.vv.oOrAry->reserve(len);
            for(int i = 0; i < len; i++)
            {
                VOBJECT* pItem = new VOBJECT();
                v.vv.oOrAry->push_back(pItem);
                FillVObject(itemVt, *pItem);
            }
            break;
        }
        case V_OBJ_STRUCT:
        {
            if(NULL == vt->o)
            {
                LogWarning("CPluto::FillVObject", "V_OBJ_STRUCT NULL == vt->o");
                return;
            }
            int len = vt->o->size();
            if(len < 1)
            {
                LogWarning("CPluto::FillVObject", "V_OBJ_STRUCT vt->o->size() < 1");
                return;
            }

            // 解析每个元素
            VTYPE_OJBECT* itemVt = NULL;
            v.vv.oOrAry = new T_VECTOR_OBJECT();
            v.vv.oOrAry->reserve(len);
            for(int i = 0; i < len; i++)
            {
                VOBJECT* pItem = new VOBJECT();
                v.vv.oOrAry->push_back(pItem);

                itemVt = (*vt->o)[i];
                FillVObject(itemVt, *pItem);
            }

            break;
        }
        default:
            break;
    }
}

#ifdef __WEBSOCKET_CLIENT
bool CPluto::EncodeJsonToPluto(VTYPE_OJBECT* vt, cJSON* pJs, cJSON* pJsonFind, CPluto& u)
{
    if (NULL == pJsonFind)
        pJsonFind = FindJsonOjbectBy1Key(pJs, vt->vtName);
    if (NULL == pJsonFind)
    {
        LogWarning("EncodeJsonToPluto", "NULL == pJsonFind vt=%d, vtName=%s", vt->vt, vt->vtName.c_str());
        return false;
    }

    VOBJECT v;
    switch(vt->vt)
    {
        case V_INT8:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.i8 = pJsonFind->valueint;

            (*this) << v.vv.i8;
            break;
        }
        case V_INT16:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.i16 = pJsonFind->valueint;

            (*this) << v.vv.i16;
            break;
        }
        case V_INT32:
        {
            if (cJSON_Number != pJsonFind->type)
            {
                LogWarning("EncodeJsonToPluto", "cJSON_Number != pJsonFind->type vt=%d, vtName=%s", vt->vt, vt->vtName.c_str());
                return false;
            }
            v.vv.i32 = pJsonFind->valueint;

            (*this) << v.vv.i32;
            break;
        }
        case V_INT64:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.i64 = (int64_t)pJsonFind->valuedouble;

            (*this) << v.vv.i64;
            break;
        }
        case V_UINT8:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.u8 = pJsonFind->valueint;

            (*this) << v.vv.u8;
            break;
        }
        case V_UINT16:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.u16 = pJsonFind->valueint;

            (*this) << v.vv.u16;
            break;
        }
        case V_UINT32:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.u32 = pJsonFind->valueint;

            (*this) << v.vv.u32;
            break;
        }
        case V_UINT64:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.u64 = (uint64_t)pJsonFind->valuedouble;

            (*this) << v.vv.u64;
            break;
        }
        case V_FLOAT32:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.f32 = (float32_t)pJsonFind->valuedouble;

            (*this) << v.vv.f32;
            break;
        }
        case V_FLOAT64:
        {
            if (cJSON_Number != pJsonFind->type)
                return false;
            v.vv.f64 = pJsonFind->valuedouble;

            (*this) << v.vv.f64;
            break;
        }
        case V_STR:
        {
            if (cJSON_String != pJsonFind->type)
            {
                LogWarning("EncodeJsonToPluto", "cJSON_String != pJsonFind->type vt=%d, vtName=%s", vt->vt, vt->vtName.c_str());
                return false;
            }
            if (NULL == pJsonFind->valuestring)
            {
                LogWarning("EncodeJsonToPluto", "NULL == pJsonFind->valuestring vt=%d, vtName=%s", vt->vt, vt->vtName.c_str());
                return false;
            }

            string s = pJsonFind->valuestring;

            (*this) << s;
            break;
        }
        case V_OBJ_ARY:
        {
            if(NULL == vt->o)
            {
                LogWarning("CPluto::EncodeJsonToPluto", "V_OBJ_ARY NULL == vt->o");
                return false;
            }
            if(1 != vt->o->size())
            {
                LogWarning("CPluto::EncodeJsonToPluto", "V_OBJ_ARY 1 != vt->o->size()");
                return false;
            }

            if (cJSON_Array != pJsonFind->type)
            {
                LogWarning("EncodeJsonToPluto", "cJSON_Array != pJsonFind->type vt=%d, vtName=%s", vt->vt, vt->vtName.c_str());
                return false;
            }
            uint16_t len = cJSON_GetArraySize(pJsonFind);
            (*this) << len;

            VTYPE_OJBECT* itemVt = (*vt->o)[0];
            // 解析每个元素
            for(int i = 0; i < len; i++)
            {
                // 数组元素没有名称
                if (!EncodeJsonToPluto(itemVt, NULL, cJSON_GetArrayItem(pJsonFind, i), u))
                {
                    LogWarning("EncodeJsonToPluto", "!EncodeJsonToPluto(itemVt, NULL, cJSON_GetArrayItem(pJsonFind, i), u) vt=%d, vtName=%s", vt->vt, vt->vtName.c_str());
                    return false;
                }
            }
            break;
        }
        case V_OBJ_STRUCT:
        {
            if(NULL == vt->o)
            {
                LogWarning("CPluto::DecodeJsonToPluto", "V_OBJ_STRUCT NULL == vt->o");
                return false;
            }
            int len = vt->o->size();
            if(len < 1)
            {
                LogWarning("CPluto::DecodeJsonToPluto", "V_OBJ_STRUCT vt->o->size() < 1");
                return false;
            }
            if (cJSON_Object != pJsonFind->type)
            {
                LogWarning("EncodeJsonToPluto", "cJSON_Object != pJsonFind->type vt=%d, vtName=%s", vt->vt, vt->vtName.c_str());
                return false;
            }

            // 解析每个元素
            VTYPE_OJBECT* itemVt = NULL;
            for(int i = 0; i < len; i++)
            {
                itemVt = (*vt->o)[i];
                if (!EncodeJsonToPluto(itemVt, pJsonFind, NULL, u))
                {
                    LogWarning("EncodeJsonToPluto", "!EncodeJsonToPluto(itemVt, pJsonFind, NULL, u) vt=%d, vtName=%s", vt->vt, vt->vtName.c_str());
                    return false;
                }
            }

            break;
        }
    default:
        return false;
    }

    return true;
}

bool CPluto::DecodePlutoToJson(VTYPE_OJBECT* vt, cJSON* pJs, bool haveName, CPluto& u)
{
    if (NULL == pJs)
        return false;
    if (haveName && (vt->vtName.length() < 1))
        return false;

    VOBJECT v;
    switch(vt->vt)
    {
    case V_INT8:
        {
            (*this) >> v.vv.i8;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.i8));
            
            break;
        }
    case V_INT16:
        {
            (*this) >> v.vv.i16;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.i16));
            
            break;
        }
    case V_INT32:
        {
            (*this) >> v.vv.i32;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.i32));

            break;
        }
    case V_INT64:
        {
            (*this) >> v.vv.i64;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.i64));

            break;
        }
    case V_UINT8:
        {
            (*this) >> v.vv.u8;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.u8));
            
            break;
        }
    case V_UINT16:
        {
            (*this) >> v.vv.u16;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.u16));
            
            break;
        }
    case V_UINT32:
        {
            (*this) >> v.vv.u32;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.u32));

            break;
        }
    case V_UINT64:
        {
            (*this) >> v.vv.u64;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.u64));
            
            break;
        }
    case V_FLOAT32:
        {
            (*this) >> v.vv.f32;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.f32));
            
            break;
        }
    case V_FLOAT64:
        {
            (*this) >> v.vv.f64;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateNumber((double)v.vv.f64));
            
            break;
        }
    case V_STR:
        {
            string s = "";
            (*this) >> s;
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), cJSON_CreateString(s.c_str()));
            
            break;
        }
    case V_OBJ_ARY:
        {
            if(NULL == vt->o)
            {
                LogWarning("CPluto::DecodeJsonToPluto", "V_OBJ_ARY NULL == vt->o");
                return false;
            }
            if(1 != vt->o->size())
            {
                LogWarning("CPluto::DecodeJsonToPluto", "V_OBJ_ARY 1 != vt->o->size()");
                return false;
            }

            uint16_t len = 0;
            (*this) >> len;

            cJSON* pAry = cJSON_CreateArray();
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), pAry);

            VTYPE_OJBECT* itemVt = (*vt->o)[0];
            // 解析每个元素
            for(int i = 0; i < len; i++)
            {
                // 数组元素没有名称
                if (!DecodePlutoToJson(itemVt, pAry, false, u))
                    return false;
            }
            break;
        }
    case V_OBJ_STRUCT:
        {
            if(NULL == vt->o)
            {
                LogWarning("CPluto::DecodeJsonToPluto", "V_OBJ_STRUCT NULL == vt->o");
                return false;
            }
            int len = vt->o->size();
            if(len < 1)
            {
                LogWarning("CPluto::DecodeJsonToPluto", "V_OBJ_STRUCT vt->o->size() < 1");
                return false;
            }

            cJSON* pObj = cJSON_CreateObject();
            cJSON_AddItemToObject(pJs, vt->vtName.c_str(), pObj);

            // 解析每个元素
            VTYPE_OJBECT* itemVt = NULL;
            for(int i = 0; i < len; i++)
            {
                itemVt = (*vt->o)[i];
                if (!DecodePlutoToJson(itemVt, pObj, true, u))
                    return false;
            }

            break;
        }
    default:
        return false;
    }

    return true;
}
#endif

CPluto& CPluto::FillBuff(const char* s, uint32_t n)
{
    Resize(sizeof(uint16_t)+n);

    memcpy(m_szBuff + m_unLen, s, n);
    m_unLen += n;
    return *this;
}

#ifdef __WEBSOCKET_CLIENT
void CPluto::WsMask()
{
    if (m_wsMaskPos >= 0 && m_wsDataLen > 0)
    {
        uint8_t* dst = (uint8_t *)(m_szBuff + m_wsHeaderLen);
        uint8_t* msk = (uint8_t *)(m_szBuff + m_wsMaskPos);

        for(int i = 0; i < m_wsDataLen; i++)
        {
            dst[i] = dst[i] ^ msk[i % 4];
        }
    }
}
#endif

CPlutoList::CPlutoList() : m_init(false)
{

}

CPlutoList::~CPlutoList()
{
    ClearContainer(m_list);
    if(m_init)
    {
        pthread_mutex_destroy(&m_mutex_t);
    }
}

bool CPlutoList::InitMutex()
{
    if(!m_init)
    {
        m_init = pthread_mutex_init(&m_mutex_t, NULL) == 0;
    }
    return m_init;
}

void CPlutoList::PushPluto(CPluto* p)
{
    CMutexGuard g(m_mutex_t);
    m_list.push_back(p);
}

CPluto* CPlutoList::PopPluto()
{
    CMutexGuard g(m_mutex_t);
    if(!m_list.empty())
    {
        CPluto* p = m_list.front();
        m_list.pop_front();
        return p;
    }
    else
    {
        return NULL;
    }
}

bool CPlutoList::Empty()
{
    CMutexGuard g(m_mutex_t);
    return m_list.empty();
}
