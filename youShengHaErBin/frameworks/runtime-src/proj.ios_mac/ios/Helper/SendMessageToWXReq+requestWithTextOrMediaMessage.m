//
//  SendMessageToWXReq+requestWithTextOrMediaMessage.m
//  Created by Jeason on 15/7/14.
//
//

#import "SendMessageToWXReq+requestWithTextOrMediaMessage.h"

@implementation SendMessageToWXReq (requestWithTextOrMediaMessage)

+ (SendMessageToWXReq *)requestWithText:(NSString *)text
                         OrMediaMessage:(WXMediaMessage *)message
                                  bText:(BOOL)bText
                                InScene:(enum WXScene)scene {
    SendMessageToWXReq *req = [[[SendMessageToWXReq alloc] init] autorelease];
    req.bText = bText;
    req.scene = scene;
    if (bText)
        req.text = text;
    else
        req.message = message;
    return req;
}

@end