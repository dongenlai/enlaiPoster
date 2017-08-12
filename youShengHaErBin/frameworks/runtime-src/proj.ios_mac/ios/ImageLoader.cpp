//
//  ImageLoader.cpp
//  epoker
//
//  Created by admin on 16/6/28.
//
//

#include "ImageLoader.hpp"
#include "ScriptingCore.h"

static ImageLoader* _imageLoader = nullptr;

ImageLoader::ImageLoader(){
    
    _downLoader.reset(new network::Downloader());
};
ImageLoader* ImageLoader::getInstance(){
    if(_imageLoader == nullptr){
        _imageLoader = new ImageLoader();
        _imageLoader->_imageCount = 0;
    }
    return _imageLoader;
}

void ImageLoader::load(const std::string &filepath)
{
    
    this->_imageCount++;
    CCLOG("%s%d","load",this->_imageCount);
    std::string path = CCString::createWithFormat("%s%d.png",FileUtils::getInstance()->getWritablePath().c_str(),this->_imageCount)->getCString();
    this->_downLoader->createDownloadFileTask(filepath,path,path);
    this->_downLoader->onFileTaskSuccess = [this,filepath](const cocos2d::network::DownloadTask& task)
    {
        std::string temp = task.storagePath;
        const char * a = CCString::createWithFormat("JsbBZ.callBack('%d.png','%s')",this->_imageCount,filepath.c_str())->getCString();
        ScriptingCore::getInstance()->evalString(a, nullptr);
        CCLOG("download OK ");
    };
    this->_downLoader->onTaskError = [this](const cocos2d::network::DownloadTask& task,
                             int errorCode,
                             int errorCodeInternal,
                             const std::string& errorStr)
    {
        CCLOG("%s","onTaskError");
        
    };
    this->_downLoader->onTaskProgress = [this](const cocos2d::network::DownloadTask& task,
                                int64_t bytesReceived,
                                int64_t totalBytesReceived,
                                int64_t totalBytesExpected)
    {
        //CCLOG("%s","onTaskProgress");
    };
    
}

void ImageLoader::callback(Texture2D* obj){
    CCLOG("%s","callback OK");
    if(obj){
        auto sp1 = new Sprite();
        sp1->initWithTexture(obj);
        sp1->setPosition(100, 100);
        cocos2d::Director::getInstance()->getRunningScene()->addChild(sp1,1000);
    }
}