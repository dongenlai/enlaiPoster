//
//  GetMessageFromWXResp+responseWithTextOrMediaMessage.h
//  Created by Jeason on 15/7/14.
//
//

#import "WXApiObject.h"

@interface GetMessageFromWXResp (responseWithTextOrMediaMessage)

+ (GetMessageFromWXResp *)responseWithText:(NSString *)text
                            OrMediaMessage:(WXMediaMessage *)message
                                     bText:(BOOL)bText;
@end
