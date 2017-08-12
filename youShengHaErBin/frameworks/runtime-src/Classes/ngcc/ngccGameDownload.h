#ifndef __NGCC_GAMEDOWNLOAD_H__
#define __NGCC_GAMEDOWNLOAD_H__

#include <thread>
#include <mutex>
#include <chrono>
#include "cocos2d.h"
#include "network/CCDownloader.h"
#include "ScriptingCore.h"
#include "cocos2d_specifics.hpp"
#include "platform/CCFileUtils.h"

using namespace cocos2d::network;

namespace ngcc{
	class ngccGameDownloader;

    class ngccGameloadDelegate{
    public:
		virtual void onError(ngccGameDownloader* gameloader, int errorCode, int errorCodeInternal, const std::string& errorStr){};
		virtual void onProgress(ngccGameDownloader* gameloader, int64_t bytesReceived, int64_t totalBytesReceived, int64_t totalBytesExpected){};
		virtual void onSuccess(ngccGameDownloader* gameloader){};
	};


    class ngccGameDownloader{

    public:
        ngccGameDownloader(const std::string& gameName);
        ~ngccGameDownloader();

		inline std::string getLoadingGameName(){ return this->_gameName; };

        void startDownloadAsync(const std::string& packageUrl);

        void setDelegate(ngccGameloadDelegate* delegate);
    private:
        std::string _gameName;
        std::string _packageUrl;
        std::string _storagePath;
        std::string _downLoadedFileName;

		std::mutex _progressMutex;

		int64_t _bytesReceived;
		int64_t _totalBytesReceived;
		int64_t _totalBytesExpected;

		bool _succeeded;
		int _errorCode;
		int _errorCodeInternal;
		std::string _errorStr;

        cocos2d::network::Downloader* _downloader;
        ngccGameloadDelegate* _delegate;
    private:
        void onError(const DownloadTask& task,int errorCode, int errorCodeInternal, const std::string& errorStr);
        void onProgress(const DownloadTask& task, int64_t bytesReceived, int64_t totalBytesReceived, int64_t totalBytesExpected);
		void executeProgressCall();
        void onSuccess(const DownloadTask& task);
        void startDownloadTask();
        bool uncompressDownloadedFile();  //解压
	};

    class ngccGameDownloadJsDelegate:ngccGameloadDelegate
    {
    public:
		virtual void onError(ngccGameDownloader* gameloader, int errorCode, int errorCodeInternal, const std::string& errorStr) override;
		virtual void onProgress(ngccGameDownloader* gameloader, int64_t bytesReceived, int64_t totalBytesReceived, int64_t totalBytesExpected) override;
		virtual void onSuccess(ngccGameDownloader* gameloader) override;
        void setJSObj(JSObject* jobj);
    private:
        JS::Heap<JSObject*> _JSObject;
	};
};
#endif