#include "ngccGameDownload.h"

using namespace std;
using namespace cocos2d;
using namespace cocos2d::network;
#ifdef MINIZIP_FROM_SYSTEM
#include <minizip/unzip.h>
#else // from our embedded sources
#include "unzip.h"
#endif

#define TEMP_DOWNLOADGAME_PATH          "/"
#define BUFFER_SIZE    8192
#define MAX_FILENAME   512

namespace ngcc{
    ngccGameDownloader::ngccGameDownloader( const std::string& gameName)
    :_gameName(gameName)
    ,_downloader(new Downloader())
	, _bytesReceived(0)
	, _totalBytesReceived(0)
	, _totalBytesExpected(0)
	, _succeeded(false)
	, _errorCode(0)
	, _errorCodeInternal(0)
	, _delegate(nullptr)
    {
		_downloader->onTaskError = std::bind(&ngccGameDownloader::onError, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3, std::placeholders::_4);
		_downloader->onTaskProgress = std::bind(&ngccGameDownloader::onProgress, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3, std::placeholders::_4);
		_downloader->onFileTaskSuccess = std::bind(&ngccGameDownloader::onSuccess, this, std::placeholders::_1);
    }

    ngccGameDownloader::~ngccGameDownloader()
    {
        CC_SAFE_DELETE(this->_downloader);
        CC_SAFE_DELETE(this->_delegate);
    }

    void ngccGameDownloader::startDownloadAsync(const std::string& packageUrl)
    {
        if(this->_delegate == nullptr)
        {
            CCLOG("game loader not set delegate!");
            return;
        }
        this->_packageUrl = packageUrl;
        this->_storagePath.append(FileUtils::getInstance()->getWritablePath()).append(TEMP_DOWNLOADGAME_PATH);
        this->_downLoadedFileName.append(this->_storagePath).append(this->_gameName).append(".zip");

        if(FileUtils::getInstance()->isFileExist(this->_downLoadedFileName))
        {
            if(!FileUtils::getInstance()->removeFile(this->_downLoadedFileName))
            {
                std::string errorStr("file already existed and can not be removed: ");
                errorStr.append(this->_downLoadedFileName);
                if(this->_delegate != nullptr)
                    this->_delegate->onError(this, 100,100,errorStr);

                return;
            }
        }
		std::thread(&ngccGameDownloader::startDownloadTask, this).detach();
		std::thread(&ngccGameDownloader::executeProgressCall, this).detach();
    }
    void ngccGameDownloader::startDownloadTask()
    {
        _downloader->createDownloadFileTask(this->_packageUrl, this->_downLoadedFileName);
    }

    void ngccGameDownloader::setDelegate(ngccGameloadDelegate* delegate)
    {
        if(this->_delegate == nullptr)
        {
            this->_delegate = delegate;
        }
    }

    void ngccGameDownloader::onError(const DownloadTask& task,int errorCode, int errorCodeInternal, const std::string& errorStr)
    {
		this->_progressMutex.lock();
		this->_errorCode = errorCode;
		this->_errorCodeInternal = errorCodeInternal;
		this->_errorStr = errorStr;
		this->_progressMutex.unlock();
		
        /*Director::getInstance()->getScheduler()->performFunctionInCocosThread([&]
        {
            if(this->_delegate !=nullptr )
                this->_delegate->onError(this, errorCode,errorCodeInternal,errorStr);
        });*/
    }

    void ngccGameDownloader::onProgress(const DownloadTask& task, int64_t bytesReceived, int64_t totalBytesReceived, int64_t totalBytesExpected)
    {
		this->_progressMutex.lock();

		this->_bytesReceived += bytesReceived;
		this->_totalBytesReceived = totalBytesReceived;
		this->_totalBytesExpected = totalBytesExpected;

		this->_progressMutex.unlock();
		/*
        Director::getInstance()->getScheduler()->performFunctionInCocosThread([this,bytesReceived,totalBytesReceived,totalBytesExpected]
        {
            if(this->_delegate !=nullptr )
                this->_delegate->onProgress(this, bytesReceived,totalBytesReceived,totalBytesExpected);
        });*/
    }

	void ngccGameDownloader::executeProgressCall()
	{
		while (true){
			this->_progressMutex.lock();

			int64_t bytesReceived = this->_bytesReceived;
			int64_t totalBytesReceived = this->_totalBytesReceived;
			int64_t totalBytesExpected = this->_totalBytesExpected;
			this->_bytesReceived = 0;

			bool succeeded = this->_succeeded;

			int errorCode = this->_errorCode;

			this->_progressMutex.unlock();
			
			if (bytesReceived > 0){
				Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, bytesReceived, totalBytesReceived, totalBytesExpected]
				{
					if (this->_delegate != nullptr){
						this->_delegate->onProgress(this, bytesReceived, totalBytesReceived, totalBytesExpected);
					}
				});
			}

			if (succeeded){
				Director::getInstance()->getScheduler()->performFunctionInCocosThread([this]
				{
					if (this->_delegate != nullptr)
						this->_delegate->onSuccess(this);
				});
				break;
			}

			if (errorCode != 0){
				int errorCodeInternal = this->_errorCodeInternal;
				string errorStr = this->_errorStr;
				Director::getInstance()->getScheduler()->performFunctionInCocosThread([&,errorCode,errorCodeInternal,errorStr]
				{
					if (this->_delegate != nullptr)
						this->_delegate->onError(this, errorCode, errorCodeInternal, errorStr);
				});

				if (FileUtils::getInstance()->isFileExist(this->_downLoadedFileName))
				{
					std::string newName = this->_downLoadedFileName;
					newName.append(".tmp");
					FileUtils::getInstance()->renameFile(this->_downLoadedFileName, newName);
				}

				break;
			}


			std::this_thread::sleep_for(std::chrono::milliseconds(100));////<=1/60��������
		}
	}

    void ngccGameDownloader::onSuccess(const DownloadTask& task)
    {
		std::thread([&]()
		{
			if (!this->uncompressDownloadedFile())
			{
				
				this->_progressMutex.lock();
				this->_errorCode = 101;
				this->_errorCodeInternal = 101;
				this->_errorStr = "uncompress file failed: ";
				this->_progressMutex.unlock();

				// Delete unloaded zip file.
                if (!FileUtils::getInstance()->removeFile(this->_downLoadedFileName))
                {
                    CCLOG("can not remove downloaded zip file %s", this->_downLoadedFileName.c_str());
                }
				/*Director::getInstance()->getScheduler()->performFunctionInCocosThread([this]
				{
					std::string errorStr("uncompress file failed: ");
					errorStr.append(this->_downLoadedFileName);
					if (this->_delegate != nullptr)
						this->_delegate->onError(this, 101, 101, errorStr);
				});*/
			}
			else{
				// Delete unloaded zip file.
				if (!FileUtils::getInstance()->removeFile(this->_downLoadedFileName))
				{
					CCLOG("can not remove downloaded zip file %s", this->_downLoadedFileName.c_str());
				}
				this->_progressMutex.lock();
				this->_succeeded = true;
				this->_progressMutex.unlock();
				/*Director::getInstance()->getScheduler()->performFunctionInCocosThread([this]
				{
					if (this->_delegate != nullptr)
						this->_delegate->onSuccess(this);
				});*/
			}
		}).detach();
    }

    bool ngccGameDownloader::uncompressDownloadedFile()
    {
        // Open the zip file
        unzFile zipfile = unzOpen(this->_downLoadedFileName.c_str());
        if (! zipfile)
        {
            CCLOG("can not open downloaded zip file %s", _downLoadedFileName.c_str());
            return false;
        }

        // Get info about the zip file
        unz_global_info global_info;
        if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK)
        {
            CCLOG("can not read file global info of %s", _downLoadedFileName.c_str());
            unzClose(zipfile);
            return false;
        }

        // Buffer to hold data read from the zip file
        char readBuffer[BUFFER_SIZE];

        CCLOG("start uncompressing");

        // Loop to extract all files.
        uLong i;
        for (i = 0; i < global_info.number_entry; ++i)
        {
            // Get info about current file.
            unz_file_info fileInfo;
            char fileName[MAX_FILENAME];
            if (unzGetCurrentFileInfo(zipfile,
                                      &fileInfo,
                                      fileName,
                                      MAX_FILENAME,
                                      nullptr,
                                      0,
                                      nullptr,
                                      0) != UNZ_OK)
            {
                CCLOG("can not read file info");
                unzClose(zipfile);
                return false;
            }

            const string fullPath = _storagePath + fileName;

            // Check if this entry is a directory or a file.
            const size_t filenameLength = strlen(fileName);
            if (fileName[filenameLength-1] == '/')
            {
                // Entry is a direcotry, so create it.
                // If the directory exists, it will failed scilently.
                if (!FileUtils::getInstance()->createDirectory(fullPath))
                {
                    CCLOG("can not create directory %s", fullPath.c_str());
                    unzClose(zipfile);
                    return false;
                }
            }
            else
            {
                //There are not directory entry in some case.
                //So we need to test whether the file directory exists when uncompressing file entry
                //, if does not exist then create directory
                const string fileNameStr(fileName);

                size_t startIndex=0;

                size_t index=fileNameStr.find("/",startIndex);

                while(index != std::string::npos)
                {
                    const string dir=_storagePath+fileNameStr.substr(0,index);

                    FILE *out = fopen(FileUtils::getInstance()->getSuitableFOpen(dir).c_str(), "r");

                    if(!out)
                    {
                        if (!FileUtils::getInstance()->createDirectory(dir))
                        {
                            CCLOG("can not create directory %s", dir.c_str());
                            unzClose(zipfile);
                            return false;
                        }
                        else
                        {
                            CCLOG("create directory %s",dir.c_str());
                        }
                    }
                    else
                    {
                        fclose(out);
                    }

                    startIndex=index+1;

                    index=fileNameStr.find("/",startIndex);

                }

                // Entry is a file, so extract it.

                // Open current file.
                if (unzOpenCurrentFile(zipfile) != UNZ_OK)
                {
                    CCLOG("can not open file %s", fileName);
                    unzClose(zipfile);
                    return false;
                }

                // Create a file to store current file.
                FILE *out = fopen(FileUtils::getInstance()->getSuitableFOpen(fullPath).c_str(), "wb");
                if (! out)
                {
                    CCLOG("can not open destination file %s", fullPath.c_str());
                    unzCloseCurrentFile(zipfile);
                    unzClose(zipfile);
                    return false;
                }

                // Write current file content to destinate file.
                int error = UNZ_OK;
                do
                {
                    error = unzReadCurrentFile(zipfile, readBuffer, BUFFER_SIZE);
                    if (error < 0)
                    {
                        CCLOG("can not read zip file %s, error code is %d", fileName, error);
                        unzCloseCurrentFile(zipfile);
                        unzClose(zipfile);
                        return false;
                    }

                    if (error > 0)
                    {
                        fwrite(readBuffer, error, 1, out);
                    }
                } while(error > 0);

                fclose(out);
            }

            unzCloseCurrentFile(zipfile);

            // Goto next entry listed in the zip file.
            if ((i+1) < global_info.number_entry)
            {
                if (unzGoToNextFile(zipfile) != UNZ_OK)
                {
                    CCLOG("can not read next file");
                    unzClose(zipfile);
                    return false;
                }
            }
        }

        CCLOG("end uncompressing");
        unzClose(zipfile);

        return true;
    }


    ////////////JS Delegate
	void ngccGameDownloadJsDelegate::onError(ngccGameDownloader* gameloader, int errorCode, int errorCodeInternal, const std::string& errorStr)
    {
        js_proxy_t * p = jsb_get_native_proxy(gameloader);
            if (!p) return;

		JSContext* cx = ScriptingCore::getInstance()->getGlobalContext();

		jsval val = OBJECT_TO_JSVAL(this->_JSObject);
		JS::RootedObject obj(cx, JS::RootedValue(cx, val).toObjectOrNull());
		JSAutoCompartment ac(cx, obj);
		bool hasAction;
		if (!(JS_HasProperty(cx, obj, "onError", &hasAction) && hasAction))
		{
			CCLOG("not found onError function callback! Down load task will be stopped!");
			CC_SAFE_DELETE(gameloader);
			return;
		}

		JSB_AUTOCOMPARTMENT_WITH_GLOBAL_OBJCET

        jsval args[3];
        args[0] = int32_to_jsval(cx, errorCode);
		args[1] = int32_to_jsval(cx, errorCodeInternal);
		args[2] = std_string_to_jsval(cx, errorStr);

        ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(this->_JSObject), "onError", 3, args);

        CC_SAFE_DELETE(gameloader);
    }

	void ngccGameDownloadJsDelegate::onProgress(ngccGameDownloader* gameloader, int64_t bytesReceived, int64_t totalBytesReceived, int64_t totalBytesExpected)
    {
        js_proxy_t * p = jsb_get_native_proxy(gameloader);
            if (!p) return;

		JSContext* cx = ScriptingCore::getInstance()->getGlobalContext();

		jsval val = OBJECT_TO_JSVAL(this->_JSObject);
		JS::RootedObject obj(cx, JS::RootedValue(cx, val).toObjectOrNull());
		JSAutoCompartment ac(cx, obj);
		bool hasAction;
		if (!(JS_HasProperty(cx, obj, "onProgress", &hasAction) && hasAction))
		{
			CCLOG("not found onProgress function callback! Down load task will run to end!");
			return;
		}

		JSB_AUTOCOMPARTMENT_WITH_GLOBAL_OBJCET

        jsval args[3];
		args[0] = long_long_to_jsval(cx, bytesReceived);
		args[1] = long_long_to_jsval(cx, totalBytesReceived);
		args[2] = long_long_to_jsval(cx, totalBytesExpected);

        ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(this->_JSObject), "onProgress", 3, args);
    }

	void ngccGameDownloadJsDelegate::onSuccess(ngccGameDownloader* gameloader)
    {
        js_proxy_t * p = jsb_get_native_proxy(gameloader);
            if (!p) return;

		JSContext* cx = ScriptingCore::getInstance()->getGlobalContext();

		jsval val = OBJECT_TO_JSVAL(this->_JSObject);
		JS::RootedObject obj(cx, JS::RootedValue(cx, val).toObjectOrNull());
		JSAutoCompartment ac(cx, obj);
		bool hasAction;
		if (!(JS_HasProperty(cx, obj, "onSuccess", &hasAction) && hasAction))
		{
			CCLOG("Down load task has finished,but not found onSuccess function callback!");
			CC_SAFE_DELETE(gameloader);
			return;
		}

        JSB_AUTOCOMPARTMENT_WITH_GLOBAL_OBJCET

        jsval args;
		args = BOOLEAN_TO_JSVAL(true);
        ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(this->_JSObject), "onSuccess", 1, &args);

        CC_SAFE_DELETE(gameloader);
    }

    void ngccGameDownloadJsDelegate::setJSObj(JSObject* jobj)
    {
        this->_JSObject = jobj;
    }
}