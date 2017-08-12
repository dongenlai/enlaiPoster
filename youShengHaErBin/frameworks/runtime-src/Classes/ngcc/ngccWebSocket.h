#ifndef __NGCC_WEBSOCKET_H__
#define __NGCC_WEBSOCKET_H__
#include <string>
#include <vector>
#include "network/websocket.h"

USING_NS_CC;
/**
 * @addtogroup network
 * @{
 */
namespace ngcc {
class NgcWsThreadHelper;
class NgcWsMessage;
class CNgcWebSocket
{
public:
    static void closeAllConnections();
    
        CNgcWebSocket();

    virtual ~CNgcWebSocket();

    struct Data
    {
        Data():bytes(nullptr), len(0), issued(0), isBinary(false), ext(nullptr){}
        char* bytes;
        ssize_t len, issued;
        bool isBinary;
        void* ext;
    };

    /**
     * ErrorCode enum used to represent the error in the websocket.
     */
    enum class ErrorCode
    {
        TIME_OUT,           /** &lt; value 0 */
        CONNECTION_FAILURE, /** &lt; value 1 */
        UNKNOWN,            /** &lt; value 2 */
    };

    /**
     *  State enum used to represent the Websocket state.
     */
    enum class State
    {
        CONNECTING,  /** &lt; value 0 */
        OPEN,        /** &lt; value 1 */
        CLOSING,     /** &lt; value 2 */
        CLOSED,      /** &lt; value 3 */
    };

    /**
     * The delegate class is used to process websocket events.
     *
     * The most member function are pure virtual functions,they should be implemented the in subclass.
     * @lua NA
     */
    class Delegate
    {
    public:
        /** Destructor of Delegate. */
        virtual ~Delegate() {}

        virtual void onOpen(CNgcWebSocket* ws) = 0;
        virtual void onMessage(CNgcWebSocket* ws, const Data& data) = 0;
        virtual void onClose(CNgcWebSocket* ws) = 0;
        virtual void onError(CNgcWebSocket* ws, const ErrorCode& error) = 0;
    };


    /**
     *  @brief  The initialized method for websocket.
     *          It needs to be invoked right after websocket instance is allocated.
     *  @param  delegate The delegate which want to receive event from websocket.
     *  @param  url      The URL of websocket server.
     *  @return true: Success, false: Failure.
     *  @lua NA
     */
    bool init(const Delegate& delegate,
              const std::string& url,
              const std::vector<std::string>* protocols = nullptr);

    /**
     *  @brief Sends string data to websocket server.
     *  
     *  @param message string data.
     *  @lua sendstring
     */
    void send(const std::string& message);

    /**
     *  @brief Sends binary data to websocket server.
     *  
     *  @param binaryMsg binary string data.
     *  @param len the size of binary string data.
     *  @lua sendstring
     */
    void send(const unsigned char* binaryMsg, unsigned int len);

    /**
     *  @brief Closes the connection to server synchronously.
     *  @note It's a synchronous method, it will not return until websocket thread exits.
     */
    void close();

    void closeAsync();

    /**
     *  @brief Gets current state of connection.
     *  @return State the state value could be State::CONNECTING, State::OPEN, State::CLOSING or State::CLOSED
     */
    State getReadyState();

private:
    void onSubThreadStarted();
    void onSubThreadLoop();
    void onSubThreadEnded();
    void onUIThreadReceiveMessage(NgcWsMessage* msg);
    // The following callback functions are invoked in websocket thread
    int onSocketCallback(struct lws *wsi, int reason, void *user, void *in, ssize_t len);

    void onClientWritable();
    void onClientReceivedData(void* in, ssize_t len);
    void onConnectionOpened();
    void onConnectionError();
    void onConnectionClosed();

    friend class WebSocketCallbackWrapper;
    int onSocketCallback(struct libwebsocket_context *ctx,
                         struct libwebsocket *wsi,
                         int reason,
                         void *user, void *in, ssize_t len);

private:
    std::mutex   _readStateMutex;
    State        _readyState;
    std::string  _host;
    unsigned int _port;
    std::string  _path;

    std::vector<char> _receivedData;

    friend class NgcWsThreadHelper;
    friend class WebSocketCallbackWrapper;
    NgcWsThreadHelper* _wsHelper;

    struct lws*         _wsInstance;
    struct lws_context* _wsContext;
    std::shared_ptr<bool> _isDestroyed;
    Delegate* _delegate;
    int _SSLConnection;
    struct lws_protocols* _wsProtocols;
    EventListenerCustom* _resetDirectorListener;
};

}

#endif /* defined(__CC_JSB_WEBSOCKET_H__) */
