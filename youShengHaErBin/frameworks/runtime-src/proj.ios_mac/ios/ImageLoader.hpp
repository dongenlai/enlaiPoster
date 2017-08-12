//
//  ImageLoader.hpp
//  epoker
//
//  Created by admin on 16/6/28.
//
//

#ifndef ImageLoader_hpp
#define ImageLoader_hpp

#include <stdio.h>
#include "cocos2d.h"
#include "network/WebSocket.h"
#include "network/CCDownloader.h"

USING_NS_CC;

class ImageLoader : public Ref
{
public:
    ImageLoader();
    static ImageLoader* getInstance();
    void load(const std::string &filepath);
    void callback(Texture2D* obj);
    
private:
    std::unique_ptr<cocos2d::network::Downloader> _downLoader;
    unsigned int _imageCount;
};

#endif /* ImageLoader_hpp */
