#include "ngccWebSocket.h"
#include "base/CCDirector.h"
#include "base/CCScheduler.h"
#include "base/CCEventDispatcher.h"
#include "base/CCEventListenerCustom.h"

#include <thread>
#include <mutex>
#include <queue>
#include <list>
#include <signal.h>
#include <errno.h>

#include "libwebsockets.h"

#define WS_WRITE_BUFFER_SIZE 2048
#define WS_RX_BUFFER_SIZE (65536)
#define WS_RESERVE_RECEIVE_BUFFER_SIZE (4096)

#define  LOG_TAG    "WebSocket.cpp"

USING_NS_CC;

// Since CCLOG isn't thread safe, we uses LOGD for multi-thread logging.
#if COCOS2D_DEBUG > 0
    #ifdef ANDROID
        #define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG,__VA_ARGS__)
    #else
        #define  LOGD(...) printf(__VA_ARGS__)
    #endif
#else
    #define  LOGD(...)
#endif

static void printWebSocketLog(int level, const char *line)
{
#if COCOS2D_DEBUG > 0
    static const char * const log_level_names[] = {
        "ERR",
        "WARN",
        "NOTICE",
        "INFO",
        "DEBUG",
        "PARSER",
        "HEADER",
        "EXTENSION",
        "CLIENT",
        "LATENCY",
    };

    char buf[30] = {0};
    int n;

    for (n = 0; n < LLL_COUNT; n++) {
        if (level != (1 << n))
            continue;
        sprintf(buf, "%s: ", log_level_names[n]);
        break;
    }

#ifdef ANDROID
    __android_log_print(ANDROID_LOG_DEBUG, "libwebsockets", "%s%s", buf, line);
#else
    printf("%s%s\n", buf, line);
#endif

#endif // #if COCOS2D_DEBUG > 0
}


namespace ngcc {

class NgcWsMessage
{
public:
    NgcWsMessage() : id(++__id), what(0), obj(nullptr){}
    unsigned int id;
    unsigned int what; // message type
    void* obj;

private:
    static unsigned int __id;
};

unsigned int NgcWsMessage::__id = 0;

/**
 *  @brief Websocket thread helper, it's used for sending message between UI thread and websocket thread.
 */
class NgcWsThreadHelper
{
public:
    NgcWsThreadHelper();
    ~NgcWsThreadHelper();

    // Creates a new thread
    bool createWebSocketThread(const CNgcWebSocket& ws);
    // Quits websocket thread.
    void quitWebSocketThread();

    // Sends message to Cocos thread. It's needed to be invoked in Websocket thread.
    void sendMessageToCocosThread(const std::function<void()>& cb);

    // Sends message to Websocket thread. It's needs to be invoked in Cocos thread.
    void sendMessageToWebSocketThread(NgcWsMessage *msg);

    // Waits the sub-thread (websocket thread) to exit,
    void joinWebSocketThread();

protected:
    void wsThreadEntryFunc();
private:
    std::list<NgcWsMessage*>* _subThreadWsMessageQueue;
    std::mutex   _subThreadWsMessageQueueMutex;
    std::thread* _subThreadInstance;
    CNgcWebSocket* _ws;
    bool _needQuit;
    friend class CNgcWebSocket;
};

// Wrapper for converting websocket callback from static function to member function of WebSocket class.
class WebSocketCallbackWrapper {
public:

    static int onSocketCallback(struct lws *wsi, enum lws_callback_reasons reason, void *user, void *in, size_t len)
    {
        // Gets the user data from context. We know that it's a 'WebSocket' instance.
        if (wsi == nullptr) {
            return 0;
        }

        lws_context* context = lws_get_context(wsi);
        CNgcWebSocket* wsInstance = (CNgcWebSocket*)lws_context_user(context);
        if (wsInstance)
        {
            return wsInstance->onSocketCallback(wsi, reason, user, in, len);
        }
        return 0;
    }
};

// Implementation of NgcWsThreadHelper
NgcWsThreadHelper::NgcWsThreadHelper()
: _subThreadInstance(nullptr)
, _ws(nullptr)
, _needQuit(false)
{
    _subThreadWsMessageQueue = new (std::nothrow) std::list<NgcWsMessage*>();
}

NgcWsThreadHelper::~NgcWsThreadHelper()
{
    joinWebSocketThread();
    CC_SAFE_DELETE(_subThreadInstance);
    delete _subThreadWsMessageQueue;
}

bool NgcWsThreadHelper::createWebSocketThread(const CNgcWebSocket& ws)
{
    _ws = const_cast<CNgcWebSocket*>(&ws);

    // Creates websocket thread
    _subThreadInstance = new (std::nothrow) std::thread(&NgcWsThreadHelper::wsThreadEntryFunc, this);
    return true;
}

void NgcWsThreadHelper::quitWebSocketThread()
{
    _needQuit = true;
}

void NgcWsThreadHelper::wsThreadEntryFunc()
{
    LOGD("WebSocket thread start, helper instance: %p\n", this);
    _ws->onSubThreadStarted();

    while (!_needQuit)
    {
        _ws->onSubThreadLoop();
    }

    _ws->onSubThreadEnded();

    LOGD("WebSocket thread exit, helper instance: %p\n", this);
}

void NgcWsThreadHelper::sendMessageToCocosThread(const std::function<void()>& cb)
{
    Director::getInstance()->getScheduler()->performFunctionInCocosThread(cb);
}

void NgcWsThreadHelper::sendMessageToWebSocketThread(NgcWsMessage *msg)
{
    std::lock_guard<std::mutex> lk(_subThreadWsMessageQueueMutex);
    _subThreadWsMessageQueue->push_back(msg);
}

void NgcWsThreadHelper::joinWebSocketThread()
{
    if (_subThreadInstance->joinable())
    {
        _subThreadInstance->join();
    }
}

// Define a WebSocket frame
class WebSocketFrame
{
public:
    WebSocketFrame()
        : _payload(nullptr)
        , _payloadLength(0)
        , _frameLength(0)
    {
    }

    bool init(unsigned char* buf, ssize_t len)
    {
        if (buf == nullptr && len > 0)
            return false;

        if (!_data.empty())
        {
            LOGD("WebSocketFrame was initialized, should not init it again!\n");
            return false;
        }

        _data.reserve(LWS_PRE + len);
        _data.resize(LWS_PRE, 0x00);
        if (len > 0)
        {
            _data.insert(_data.end(), buf, buf + len);
        }

        _payload = _data.data() + LWS_PRE;
        _payloadLength = len;
        _frameLength = len;
        return true;
    }

    void update(ssize_t issued)
    {
        _payloadLength -= issued;
        _payload += issued;
    }

    unsigned char* getPayload() const { return _payload; }
    ssize_t getPayloadLength() const { return _payloadLength; }
    ssize_t getFrameLength() const { return _frameLength; }
private:
    unsigned char* _payload;
    ssize_t _payloadLength;

    ssize_t _frameLength;
    std::vector<unsigned char> _data;
};
//


enum WS_MSG {
    WS_MSG_TO_SUBTRHEAD_SENDING_STRING = 0,
    WS_MSG_TO_SUBTRHEAD_SENDING_BINARY,
    WS_MSG_TO_UITHREAD_OPEN,
    WS_MSG_TO_UITHREAD_MESSAGE,
    WS_MSG_TO_UITHREAD_ERROR,
    WS_MSG_TO_UITHREAD_CLOSE};

static std::vector<CNgcWebSocket*>* __websocketInstances = nullptr;

void CNgcWebSocket::closeAllConnections()
{
    if (__websocketInstances != nullptr)
    {
        ssize_t count = __websocketInstances->size();
        for (ssize_t i = count-1; i >=0 ; i--)
        {
            CNgcWebSocket* instance = __websocketInstances->at(i);
            instance->close();
        }

        __websocketInstances->clear();
        __websocketInstances = nullptr;
    }
}

CNgcWebSocket::CNgcWebSocket()
: _readyState(State::CONNECTING)
, _port(80)
, _wsHelper(nullptr)
, _wsInstance(nullptr)
, _wsContext(nullptr)
, _isDestroyed(std::make_shared<bool>(false))
, _delegate(nullptr)
, _SSLConnection(0)
, _wsProtocols(nullptr)
{
    // reserve data buffer to avoid allocate memory frequently
    _receivedData.reserve(WS_RESERVE_RECEIVE_BUFFER_SIZE);
    if (__websocketInstances == nullptr)
    {
        __websocketInstances = new (std::nothrow) std::vector<CNgcWebSocket*>();
    }

    __websocketInstances->push_back(this);
    
    std::shared_ptr<bool> isDestroyed = _isDestroyed;
//    _resetDirectorListener = Director::getInstance()->getEventDispatcher()->addCustomEventListener(Director::EVENT_RESET, [this, isDestroyed](EventCustom*){
//        if (*isDestroyed)
//            return;
//        close();
//    });
}

CNgcWebSocket::~CNgcWebSocket()
{
    LOGD("In the destructor of WebSocket (%p)\n", this);
    CC_SAFE_DELETE(_wsHelper);

    if (_wsProtocols != nullptr)
    {
        for (int i = 0; _wsProtocols[i].callback != nullptr; ++i)
        {
            CC_SAFE_DELETE_ARRAY(_wsProtocols[i].name);
        }
    }
    CC_SAFE_DELETE_ARRAY(_wsProtocols);

    if (__websocketInstances != nullptr)
    {
        auto iter = std::find(__websocketInstances->begin(), __websocketInstances->end(), this);
        if (iter != __websocketInstances->end())
        {
            __websocketInstances->erase(iter);
        }
        else
        {
            LOGD("ERROR: WebSocket instance (%p) wasn't added to the container which saves websocket instances!\n", this);
        }
    }
    
    Director::getInstance()->getEventDispatcher()->removeEventListener(_resetDirectorListener);
    
    *_isDestroyed = true;
}

bool CNgcWebSocket::init(const Delegate& delegate,
                     const std::string& url,
                     const std::vector<std::string>* protocols/* = nullptr*/)
{
    bool ret = false;
    bool useSSL = false;
    std::string host = url;
    size_t pos = 0;
    int port = 80;

    _delegate = const_cast<Delegate*>(&delegate);

    //ws://
    pos = host.find("ws://");
    if (pos == 0) host.erase(0,5);

    pos = host.find("wss://");
    if (pos == 0)
    {
        host.erase(0,6);
        useSSL = true;
    }

    pos = host.find(":");
    if (pos != std::string::npos) port = atoi(host.substr(pos+1, host.size()).c_str());

    pos = host.find("/", 0);
    std::string path = "/";
    if (pos != std::string::npos) path += host.substr(pos + 1, host.size());

    pos = host.find(":");
    if(pos != std::string::npos){
        host.erase(pos, host.size());
    }else if((pos = host.find("/")) != std::string::npos) {
        host.erase(pos, host.size());
    }

    _host = host;
    _port = port;
    _path = path;
    _SSLConnection = useSSL ? 1 : 0;

    LOGD("[WebSocket::init] _host: %s, _port: %d, _path: %s\n", _host.c_str(), _port, _path.c_str());

    size_t protocolCount = 0;
    if (protocols && protocols->size() > 0)
    {
        protocolCount = protocols->size();
    }
    else
    {
        protocolCount = 1;
    }

    _wsProtocols = new (std::nothrow) lws_protocols[protocolCount+1];
    memset(_wsProtocols, 0, sizeof(lws_protocols)*(protocolCount+1));

    if (protocols && protocols->size() > 0)
    {
        int i = 0;
        for (std::vector<std::string>::const_iterator iter = protocols->begin(); iter != protocols->end(); ++iter, ++i)
        {
            char* name = new (std::nothrow) char[(*iter).length()+1];
            strcpy(name, (*iter).c_str());
            _wsProtocols[i].name = name;
            _wsProtocols[i].callback = WebSocketCallbackWrapper::onSocketCallback;
            _wsProtocols[i].rx_buffer_size = WS_RX_BUFFER_SIZE;
        }
    }
    else
    {
        char* name = new (std::nothrow) char[20];
        strcpy(name, "default-protocol");
        _wsProtocols[0].name = name;
        _wsProtocols[0].callback = WebSocketCallbackWrapper::onSocketCallback;
        _wsProtocols[0].rx_buffer_size = WS_RX_BUFFER_SIZE;
    }

    // WebSocket thread needs to be invoked at the end of this method.
    _wsHelper = new (std::nothrow) NgcWsThreadHelper();
    ret = _wsHelper->createWebSocketThread(*this);

    return ret;
}

void CNgcWebSocket::send(const std::string& message)
{
    if (_readyState == State::OPEN)
    {
        // In main thread
        Data* data = new (std::nothrow) Data();
        data->bytes = (char*)malloc(message.length() + 1);
        // Make sure the last byte is '\0'
        data->bytes[message.length()] = '\0';
        strcpy(data->bytes, message.c_str());
        data->len = static_cast<ssize_t>(message.length());

        NgcWsMessage* msg = new (std::nothrow) NgcWsMessage();
        msg->what = WS_MSG_TO_SUBTRHEAD_SENDING_STRING;
        msg->obj = data;
        _wsHelper->sendMessageToWebSocketThread(msg);
    }
    else
    {
        LOGD("Couldn't send message since websocket wasn't opened!\n");
    }
}

void CNgcWebSocket::send(const unsigned char* binaryMsg, unsigned int len)
{
    if (_readyState == State::OPEN)
    {
        // In main thread
        Data* data = new (std::nothrow) Data();
        if (len == 0)
        {
            // If data length is zero, allocate 1 byte for safe.
            data->bytes = (char*)malloc(1);
            data->bytes[0] = '\0';
        }
        else
        {
            data->bytes = (char*)malloc(len);
            memcpy((void*)data->bytes, (void*)binaryMsg, len);
        }
        data->len = len;

        NgcWsMessage* msg = new (std::nothrow) NgcWsMessage();
        msg->what = WS_MSG_TO_SUBTRHEAD_SENDING_BINARY;
        msg->obj = data;
        _wsHelper->sendMessageToWebSocketThread(msg);
    }
    else
    {
        LOGD("Couldn't send message since websocket wasn't opened!\n");
    }
}

void CNgcWebSocket::close()
{
    _readStateMutex.lock();
    if (_readyState == State::CLOSED)
    {
        LOGD("close: WebSocket (%p) was closed, no need to close it again!\n", this);
        _readStateMutex.unlock();
        return;
    }
    // Sets the state to 'closed' to make sure 'onConnectionClosed' which is
    // invoked by websocket thread don't post 'close' message to Cocos thread since
    // WebSocket instance is destroyed at next frame.
    // 'closed' state has to be set before quit websocket thread.
    _readyState = State::CLOSED;
    _readStateMutex.unlock();
    
    _wsHelper->quitWebSocketThread();
    LOGD("Waiting WebSocket (%p) to exit!\n", this);
    _wsHelper->joinWebSocketThread();
    // Since 'onConnectionClosed' didn't post message to Cocos Thread for invoking 'onClose' callback, do it here.
    // onClose must be invoked at the end of this method.
    _delegate->onClose(this);
}
    
void CNgcWebSocket::closeAsync()
{
    _wsHelper->quitWebSocketThread();
}

CNgcWebSocket::State CNgcWebSocket::getReadyState()
{
    std::lock_guard<std::mutex> lk(_readStateMutex);
    return _readyState;
}

void CNgcWebSocket::onSubThreadLoop()
{
    _readStateMutex.lock();
    if (_wsContext && _readyState != State::CLOSED && _readyState != State::CLOSING)
    {
        _readStateMutex.unlock();
        _wsHelper->_subThreadWsMessageQueueMutex.lock();
        bool isEmpty = _wsHelper->_subThreadWsMessageQueue->empty();
        _wsHelper->_subThreadWsMessageQueueMutex.unlock();
        if (!isEmpty)
        {
            lws_callback_on_writable(_wsInstance);
        }

        lws_service(_wsContext, 50);
    }
    else
    {
        LOGD("Ready state is closing or was closed, code=%d, quit websocket thread!\n", _readyState);
        _readStateMutex.unlock();
        _wsHelper->quitWebSocketThread();
    }
}

void CNgcWebSocket::onSubThreadStarted()
{
    static const struct lws_extension exts[] = {
        {
            "permessage-deflate",
            lws_extension_callback_pm_deflate,
            // client_no_context_takeover extension is not supported in the current version, it will cause connection fail
            // It may be a bug of lib websocket build
//            "permessage-deflate; client_no_context_takeover; client_max_window_bits"
            "permessage-deflate; client_max_window_bits"
        },
        {
            "deflate-frame",
            lws_extension_callback_pm_deflate,
            "deflate_frame"
        },
        { nullptr, nullptr, nullptr /* terminator */ }
    };

    struct lws_context_creation_info info;
    memset(&info, 0, sizeof info);
    /*
     * create the websocket context.  This tracks open connections and
     * knows how to route any traffic and which protocol version to use,
     * and if each connection is client or server side.
     *
     * For this client-only demo, we tell it to not listen on any port.
     */

    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = _wsProtocols;
    info.extensions = exts;

    info.gid = -1;
    info.uid = -1;
    info.options = 0;
    info.user = this;

    int log_level = LLL_ERR | LLL_WARN | LLL_NOTICE/* | LLL_INFO | LLL_DEBUG | LLL_PARSER*/ | LLL_HEADER | LLL_EXT | LLL_CLIENT | LLL_LATENCY;
    lws_set_log_level(log_level, printWebSocketLog);

    _wsContext = lws_create_context(&info);

    if (nullptr != _wsContext)
    {
        _readStateMutex.lock();
        _readyState = State::CONNECTING;
        _readStateMutex.unlock();
        
        std::string name;
        for (int i = 0; _wsProtocols[i].callback != nullptr; ++i)
        {
            name += (_wsProtocols[i].name);

            if (_wsProtocols[i+1].callback != nullptr) name += ", ";
        }

        char portStr[10];
        sprintf(portStr, "%d", _port);
        std::string ads_port = _host + ":" + portStr;

        _wsInstance = lws_client_connect(_wsContext, _host.c_str(), _port, _SSLConnection,
                                             _path.c_str(), ads_port.c_str(), ads_port.c_str(),
                                             name.c_str(), -1);

        if (nullptr == _wsInstance)
        {
            onConnectionError();
        }
    }
    else
    {
        CCLOGERROR("Create websocket context failed!");
    }
}

void CNgcWebSocket::onSubThreadEnded()
{
    if (_wsContext != nullptr)
    {
        lws_context_destroy(_wsContext);
    }
}

void CNgcWebSocket::onClientWritable()
{
    std::lock_guard<std::mutex> lk(_wsHelper->_subThreadWsMessageQueueMutex);

    if (_wsHelper->_subThreadWsMessageQueue->empty())
    {
        return;
    }

    std::list<NgcWsMessage*>::iterator iter = _wsHelper->_subThreadWsMessageQueue->begin();

    ssize_t bytesWrite = 0;
    if (iter != _wsHelper->_subThreadWsMessageQueue->end())
    {
        NgcWsMessage* subThreadMsg = *iter;
        Data* data = (Data*)subThreadMsg->obj;

        const size_t c_bufferSize = WS_RX_BUFFER_SIZE;

        const size_t remaining = data->len - data->issued;
        const size_t n = std::min(remaining, c_bufferSize );

        WebSocketFrame* frame = nullptr;

        if (data->ext)
        {
            frame = (WebSocketFrame*)data->ext;
        }
        else
        {
            frame = new (std::nothrow) WebSocketFrame();
            bool success = frame && frame->init((unsigned char*)(data->bytes + data->issued), n);
            if (success)
            {
                data->ext = frame;
            }
            else
            { // If frame initialization failed, delete the frame and drop the sending data
              // These codes should never be called.
                LOGD("WebSocketFrame initialization failed, drop the sending data, msg(%d)\n", (int)subThreadMsg->id);
                delete frame;
                CC_SAFE_FREE(data->bytes);
                CC_SAFE_DELETE(data);
                _wsHelper->_subThreadWsMessageQueue->erase(iter);
                CC_SAFE_DELETE(subThreadMsg);
                return;
            }
        }

        int writeProtocol;

        if (data->issued == 0)
        {
            if (WS_MSG_TO_SUBTRHEAD_SENDING_STRING == subThreadMsg->what)
            {
                writeProtocol = LWS_WRITE_TEXT;
            }
            else
            {
                writeProtocol = LWS_WRITE_BINARY;
            }

            // If we have more than 1 fragment
            if (data->len > c_bufferSize)
                writeProtocol |= LWS_WRITE_NO_FIN;
        } else {
            // we are in the middle of fragments
            writeProtocol = LWS_WRITE_CONTINUATION;
            // and if not in the last fragment
            if (remaining != n)
                writeProtocol |= LWS_WRITE_NO_FIN;
        }

        bytesWrite = lws_write(_wsInstance, frame->getPayload(), frame->getPayloadLength(), (lws_write_protocol)writeProtocol);

        // Handle the result of lws_write
        // Buffer overrun?
        if (bytesWrite < 0)
        {
            LOGD("ERROR: msg(%u), lws_write return: %d, but it should be %d, drop this message.\n", subThreadMsg->id, (int)bytesWrite, (int)n);
            // socket error, we need to close the socket connection
            CC_SAFE_FREE(data->bytes);
            delete ((WebSocketFrame*)data->ext);
            data->ext = nullptr;
            CC_SAFE_DELETE(data);
            _wsHelper->_subThreadWsMessageQueue->erase(iter);
            CC_SAFE_DELETE(subThreadMsg);

            closeAsync();
        }
        else if (bytesWrite < frame->getPayloadLength())
        {
            frame->update(bytesWrite);
            LOGD("frame wasn't sent completely, bytesWrite: %d, remain: %d\n", (int)bytesWrite, (int)frame->getPayloadLength());
        }
        // Do we have another fragments to send?
        else if (remaining > frame->getFrameLength() && bytesWrite == frame->getPayloadLength())
        {
            // A frame was totally sent, plus data->issued to send next frame
            LOGD("msg(%u) append: %d + %d = %d\n", subThreadMsg->id, (int)data->issued, (int)frame->getFrameLength(), (int)(data->issued + frame->getFrameLength()));
            data->issued += frame->getFrameLength();
            delete ((WebSocketFrame*)data->ext);
            data->ext = nullptr;
        }
        // Safely done!
        else
        {
            LOGD("Safely done, msg(%d)!\n", subThreadMsg->id);
            if (remaining == frame->getFrameLength())
            {
                LOGD("msg(%u) append: %d + %d = %d\n", subThreadMsg->id, (int)data->issued, (int)frame->getFrameLength(), (int)(data->issued + frame->getFrameLength()));
                LOGD("msg(%u) was totally sent!\n", subThreadMsg->id);
            }
            else
            {
                LOGD("ERROR: msg(%u), remaining(%d) < bytesWrite(%d)\n", subThreadMsg->id, (int)remaining, (int)frame->getFrameLength());
                LOGD("Drop the msg(%u)\n", subThreadMsg->id);
                closeAsync();
            }

            CC_SAFE_FREE(data->bytes);
            delete ((WebSocketFrame*)data->ext);
            data->ext = nullptr;
            CC_SAFE_DELETE(data);
            _wsHelper->_subThreadWsMessageQueue->erase(iter);
            CC_SAFE_DELETE(subThreadMsg);

            LOGD("-----------------------------------------------------------\n");
        }
    }
}

void CNgcWebSocket::onClientReceivedData(void* in, ssize_t len)
{
    // In websocket thread
    static int packageIndex = 0;
    packageIndex++;
    if (in != nullptr && len > 0)
    {
        LOGD("Receiving data:index:%d, len=%d\n", packageIndex, (int)len);

        unsigned char* inData = (unsigned char*)in;
        _receivedData.insert(_receivedData.end(), inData, inData + len);
    }
    else
    {
        LOGD("Emtpy message received, index=%d!\n", packageIndex);
    }

    // If no more data pending, send it to the client thread
    size_t remainingSize = lws_remaining_packet_payload(_wsInstance);
    int isFinalFragment = lws_is_final_fragment(_wsInstance);
//    LOGD("remainingSize: %d, isFinalFragment: %d\n", (int)remainingSize, isFinalFragment);

    if (remainingSize == 0 && isFinalFragment)
    {
        std::vector<char>* frameData = new (std::nothrow) std::vector<char>(std::move(_receivedData));

        // reset capacity of received data buffer
        _receivedData.reserve(WS_RESERVE_RECEIVE_BUFFER_SIZE);

        ssize_t frameSize = frameData->size();

        bool isBinary = lws_frame_is_binary(_wsInstance);

        if (!isBinary)
        {
            frameData->push_back('\0');
        }

        std::shared_ptr<bool> isDestroyed = _isDestroyed;
        _wsHelper->sendMessageToCocosThread([this, frameData, frameSize, isBinary, isDestroyed](){
            // In UI thread
            LOGD("Notify data len %d to Cocos thread.\n", (int)frameSize);

            Data data;
            data.isBinary = isBinary;
            data.bytes = (char*)frameData->data();
            data.len = frameSize;

            if (*isDestroyed)
            {
                LOGD("WebSocket instance was destroyed!\n");
            }
            else
            {
                _delegate->onMessage(this, data);
            }

            delete frameData;
        });
    }
}

void CNgcWebSocket::onConnectionOpened()
{
    /*
     * start the ball rolling,
     * LWS_CALLBACK_CLIENT_WRITEABLE will come next service
     */
    lws_callback_on_writable(_wsInstance);

    _readStateMutex.lock();
    _readyState = State::OPEN;
    _readStateMutex.unlock();

    std::shared_ptr<bool> isDestroyed = _isDestroyed;
    _wsHelper->sendMessageToCocosThread([this, isDestroyed](){
        if (*isDestroyed)
        {
            LOGD("WebSocket instance was destroyed!\n");
        }
        else
        {
            _delegate->onOpen(this);
        }
    });
}

void CNgcWebSocket::onConnectionError()
{
    LOGD("WebSocket (%p) onConnectionError ...\n", this);

    _readStateMutex.lock();
    _readyState = State::CLOSING;
    _readStateMutex.unlock();

    std::shared_ptr<bool> isDestroyed = _isDestroyed;
    _wsHelper->sendMessageToCocosThread([this, isDestroyed](){
        if (*isDestroyed)
        {
            LOGD("WebSocket instance was destroyed!\n");
        }
        else
        {
            _delegate->onError(this, ErrorCode::CONNECTION_FAILURE);
        }
    });
}

void CNgcWebSocket::onConnectionClosed()
{
    _readStateMutex.lock();
    if (_readyState == State::CLOSED)
    {
        LOGD("onConnectionClosed: WebSocket (%p) was closed, no need to close it again!\n", this);
        _readStateMutex.unlock();
        return;
    }

    LOGD("WebSocket (%p) onConnectionClosed ...\n", this);
    _readyState = State::CLOSED;
    _readStateMutex.unlock();

    _wsHelper->quitWebSocketThread();
    std::shared_ptr<bool> isDestroyed = _isDestroyed;
    _wsHelper->sendMessageToCocosThread([this, isDestroyed](){
        if (*isDestroyed)
        {
            LOGD("WebSocket instance was destroyed!\n");
        }
        else
        {
            // Waiting for the subThread safety exit
            _wsHelper->joinWebSocketThread();
            _delegate->onClose(this);
        }
    });
}

int CNgcWebSocket::onSocketCallback(struct lws *wsi,
                     int reason,
                     void *user, void *in, ssize_t len)
{
    //LOGD("socket callback for %d reason\n", reason);

    switch (reason)
    {
        case LWS_CALLBACK_CLIENT_ESTABLISHED:
            onConnectionOpened();
            break;

        case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
            onConnectionError();
            break;

        case LWS_CALLBACK_PROTOCOL_DESTROY:
        case LWS_CALLBACK_CLOSED:
            onConnectionClosed();
            break;

        case LWS_CALLBACK_CLIENT_RECEIVE:
            onClientReceivedData(in, len);
            break;

        case LWS_CALLBACK_CLIENT_WRITEABLE:
            onClientWritable();
            break;

        default:
//            LOGD("Unhandled websocket event: %d\n", reason);
            break;
    }

    return 0;
}

}
