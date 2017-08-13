#ifndef __PLUTO__HEAD__
#define __PLUTO__HEAD__


//pluto:冥王星,离太阳最远的行星,跑得最慢
//Mercury:水星,离太阳最近的行星,公转最快


#include "type_mogo.h"
#include "bitcryto.h"
#include "memory_pool.h"
#include <ctype.h>
#include "util.h"
#include "mutex.h"
#include "json_helper.h"

enum
{
    MSGLEN_HEAD             = 4,                                              //消息包头长度
    MSGLEN_RESERVED         = 2,                                              //保留2位,可用作版本或其他
    MSGLEN_MSGID            = 2,                                              //消息id长度
    MSGLEN_TEXT_POS         = MSGLEN_HEAD + MSGLEN_RESERVED + MSGLEN_MSGID,   //正文开始的位置
    MSGLEN_MAX              = 65000,                                          //消息包最大长度
    HTTP_MSGLEN_MAX         = 1024-1,                                         //websocket第一个包，最大长度1023
    WS_PLUTO_MSGLEN_HEAD    = 2,                                              //websocket预收包头大小，根据这里来计算包头大小

    PLUTO_CLIENT_MSGLEN_MAX = 65000,                                          //客户端包的最大长度
    PLUTO_MSGLEN_HEAD       = MSGLEN_HEAD,                                    //便于其他模块引用
    PLUTO_FILED_BEGIN_POS   = MSGLEN_HEAD + MSGLEN_RESERVED + MSGLEN_MSGID,   //字段开始的位置,此前的位置都是协议自己需要的
};


#define REVERSE_CONVERT     0           //针对数据类型是否做大小端转换(Big/Little Endian Convert)


enum
{
    SERVER_NONE          = 0,
    SERVER_AREAMGR       = 1,
    SERVER_DBMGR         = 2,
    SERVER_AREA          = 3,

    SERVER_MAILBOX_RESERVE_SIZE = 3,
};

enum
{
    MSGTYPE_AREAMGR      = SERVER_AREAMGR << 12,        //0x1000
    MSGTYPE_DBMGR        = SERVER_DBMGR << 12,          //0x2000
    MSGTYPE_AREA         = SERVER_AREA << 12,           //0x3000
};

enum
{
    WS_OPCODE_NONE      = -100,                         //空白
    WS_OPCODE_DATA_END  = -2,                           //websocket帧数据帧【text或bin】结束包
    WS_OPCODE_GET       = -1,                           //websocket第一个get包
    WS_OPCODE_DATA_NEXT = 0,                            //websocket第一帧的后面的帧，也就是分片的第1个以上的帧
    WS_OPCODE_DATA      = 1,                            //websocket的text帧或二进制帧
    WS_OPCODE_CLOSE     = 0x8,                          //websocket关闭连接帧，只有1帧
    WS_OPCODE_PING      = 0x9,                          //websocket客户端请求ping
    WS_OPCODE_PONG      = 0xA,                          //websocket服务端回应ping的pong
};

extern void uint8_to_sz(uint8_t n, char* s);
extern void uint16_to_sz(uint16_t n, char* s);
extern void uint16_to_sz_big_endian(uint16_t n, char* s);
extern void uint32_to_sz(uint32_t n, char* s);
extern void uint64_to_sz(uint64_t n, char* s);
extern void float32_to_sz(float32_t n, char* s);
extern void float64_to_sz(float64_t n, char* s);
extern uint8_t sz_to_uint8(unsigned char* s);
extern uint16_t sz_to_uint16(unsigned char* s);
extern uint16_t sz_to_uint16_big_endian(unsigned char* s);
extern uint32_t sz_to_uint32(unsigned char* s);
extern uint64_t sz_to_uint64(unsigned char* s);
extern float32_t sz_to_float32(unsigned char* s);
extern float64_t sz_to_float64(unsigned char* s);
//将值如0x12的char转换为字符串"12"
extern void char_to_sz(unsigned char c, char* s);
//将形如"12"的字符创转换为值为0x12的char
extern unsigned char sz_to_char(char* s);
extern void PrintHex16(const char* s, size_t n);
extern void PrintHex(const char* s, size_t n);

class CMailBox;

template<typename T>
T sz_to_msgid(unsigned char* s);

template<>
inline uint16_t sz_to_msgid<uint16_t>(unsigned char* s)
{
    return sz_to_uint16(s);
}


//从pluto中解析出来的entity prop数据集合
struct SEntityPropFromPluto
{
    TENTITYTYPE etype;
    map<string, VOBJECT*> data;

    ~SEntityPropFromPluto();
};

class CPluto
{
    public:
        // 发送的包默认大小1024，超过大小<<操作符号会自动调整
        CPluto(uint32_t buff_size = 1024);
        void OverrideBuffer(const char* buffer, uint16_t len);
#ifdef __WEBSOCKET_CLIENT
        CPluto(uint8_t opCode, const char* wsDataBuffer, uint16_t dataLen);
#endif
        ~CPluto();
    public:
        //输入
        CPluto& Encode(pluto_msgid_t msgid);
        CPluto& operator<< (uint8_t n);
        CPluto& operator<< (uint16_t n);
        CPluto& operator<< (uint32_t n);
        CPluto& operator<< (uint64_t n);
        CPluto& operator<< (int8_t n);
        CPluto& operator<< (int16_t n);
        CPluto& operator<< (int32_t n);
        CPluto& operator<< (int64_t n);
        CPluto& operator<< (float32_t f);
        CPluto& operator<< (float64_t f);
        CPluto& operator<< (const char* s);
        CPluto& operator<< (const string& s);
        typedef CPluto& (*pluto_op) (CPluto&);
        CPluto& operator<< (pluto_op op);
        friend CPluto& endPluto(CPluto& p);
    private:
        //encode时自动调整buff大小
        void Resize(uint32_t n);

    public:
        //这个方法类似于operator<<,可用于实现链式表达式
        template<typename T>
        CPluto& FillField(const T& value);
        //不输入buff的长度,只输入buff内容
        CPluto& FillBuff(const char* s, uint32_t n);
        //类似于EndPluto
        CPluto& endPluto();

    public:
        //替换掉某个位置开始的一个字段的值
        template<typename T>
        void ReplaceField(uint32_t nIdx, const T& value);

    public:
        //输出
        //包头里记录的包长度
        uint32_t GetMsgLen();
        //去掉包头的剩下长度
        uint32_t GetMsgLeftLen();
        //消息id
        pluto_msgid_t GetMsgId();
        CPluto& Decode();
        CPluto& operator>> (uint8_t& n);
        CPluto& operator>> (uint16_t& n);
        CPluto& operator>> (uint32_t& n);
        CPluto& operator>> (uint64_t& n);
        CPluto& operator>> (int8_t& n);
        CPluto& operator>> (int16_t& n);
        CPluto& operator>> (int32_t& n);
        CPluto& operator>> (int64_t& n);
        CPluto& operator>> (float32_t& f);
        CPluto& operator>> (float64_t& f);
        CPluto& operator>> (string& s);
        void FillVObject(VTYPE_OJBECT* vt, VOBJECT& v);
#ifdef __WEBSOCKET_CLIENT
        bool EncodeJsonToPluto(VTYPE_OJBECT* vt, cJSON* pJs, cJSON* pJsonFind, CPluto& u);
        bool DecodePlutoToJson(VTYPE_OJBECT* vt, cJSON* pJs, bool haveName, CPluto& u);
#endif
    public:
        inline const char* GetBuff() const
        {
            return m_szBuff;
        }

        inline char* GetRecvBuff()
        {
            return m_szBuff;
        }

        inline void SetLen(uint32_t n)
        {
            m_unLen = n;
        }
        inline void SetMaxLen(uint32_t n)
        {
            m_unMaxLen = n;
        }

        inline void EndRecv(uint32_t n)
        {
            m_unLen = n;
            m_unMaxLen = n;
        }

        inline uint32_t GetBuffSize() const
        {
            return m_unBuffSize;
        }

        inline uint32_t GetLen() const
        {
            return m_unLen;
        }

        inline uint32_t GetMaxLen() const
        {
            return m_unMaxLen;
        }

        inline CMailBox* GetMailbox()
        {
            return m_mb;
        }

        inline void SetMailbox(CMailBox* mb)
        {
            m_mb = mb;
        }

        inline bool IsEnd() const
        {
            return m_unLen >= m_unMaxLen;
        }

        inline uint32_t GetDecodeErrIdx() const
        {
            return m_nDecodeErrIdx;
        }

        inline bool IsEncodeErr() const
        {
            return m_bEncodeErr;
        }

        inline void SetEncodeErr()
        {
            m_bEncodeErr = true;
        }

        inline int GetSrcFd() const
        {
            return m_srcFd;
        }

        inline void SetSrcFd(int fd)
        {
            m_srcFd = fd;
        }

        inline int GetDstFd() const
        {
            return m_dstFd;
        }

        inline void SetDstFd(int fd)
        {
            m_dstFd = fd;
        }
#ifdef __WEBSOCKET_CLIENT
        inline int GetWsOpCode() const
        {
            return m_wsOpcode;
        }

        inline void SetWsOpCode(int opCode)
        {
            m_wsOpcode = opCode;
        }

        inline int GetWsHeaderLen() const
        {
            return m_wsHeaderLen;
        }

        inline void SetWsHeaderLen(int len)
        {
            m_wsHeaderLen = len;
        }

        inline int GetWsMaskPos() const
        {
            return m_wsMaskPos;
        }

        inline void SetWsMaskPos(int pos)
        {
            m_wsMaskPos = pos;
        }

        inline int GetWsDataLen() const
        {
            return m_wsDataLen;
        }

        inline void SetWsDataLen(int len)
        {
            m_wsDataLen = len;
        }

        // websocket加密或解密data
        void WsMask();
#endif
    private:
        char* m_szBuff;
        uint32_t m_unBuffSize;
        uint32_t m_unLen;
        uint32_t m_unMaxLen;
        uint32_t m_nDecodeErrIdx;
        CMailBox* m_mb;
        int m_srcFd;                    //数据包的接收来源fd
        int m_dstFd;                    //数据包的发送目标 该字段仅用于多线程的服务，dbmgr
        bool m_bEncodeErr;              //编码是否出错
#ifdef __WEBSOCKET_CLIENT
        int m_wsOpcode;                 //底层的opcode经过处理了
        uint16_t m_wsHeaderLen;         //实际的header大小
        int m_wsMaskPos;                //websocket的mask位置，-1表示没有mask
        int m_wsDataLen;                //数据大小，-1表示还没解析出来
#endif

        CPluto(const CPluto&);
        CPluto& operator=(const CPluto&);
};

template<typename T>
CPluto& CPluto::FillField(const T& value)
{
    (*this) << value;
    return *this;
}

template<typename T>
void CPluto::ReplaceField(uint32_t nIdx, const T& value)
{
    uint32_t old_len = m_unLen;
    m_unLen = nIdx;
    (*this) << value;
    m_unLen = old_len;
}

CPluto& EndPluto(CPluto& p);

extern void PrintHexPluto(CPluto& c);



class CPlutoList
{
public:
    CPlutoList();
    ~CPlutoList();

public:
    bool InitMutex();
    void PushPluto(CPluto* p);
    CPluto* PopPluto();
    bool Empty();

private:
    pthread_mutex_t m_mutex_t;
    bool m_init;
    std::list<CPluto*> m_list;
};

#endif
