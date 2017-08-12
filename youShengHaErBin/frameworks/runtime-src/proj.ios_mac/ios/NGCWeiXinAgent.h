//
//  NGCWeiXinAgent.h
//  TexasHoldem
//
//  Created by iSoundy on 15/12/10.
//
//

#ifndef NGCWeiXinAgent_h
#define NGCWeiXinAgent_h

#import <Foundation/Foundation.h>

@interface NGCWeiXinAgent : NSObject
@property (nonatomic, assign) UIViewController* viewController;
@property (nonatomic, strong) NSString *lastOrderId;

+ (instancetype) shareInstance ;
- (void)attemptDealloc;
- (BOOL)initWeiXinSDK: (UIViewController *) view;

+ (void)sendWXLoginRequest: (NSString *) userSession;
+ (BOOL)checkAppIsInstall: (NSString*) packetName;
+ (UIImage *)thumbnailWithImage:(UIImage *)image size:(CGSize)asize;
- (void)sendAuthRequest;

+(void)openBrowser: (NSString*)urlStr;

+ (BOOL)doOrder:(NSString *)ordId channelld: (NSString *)chId payInfo64: (NSString *)pInfo thirdOrderId: (NSString*)trdOId;
+ (void)doShare: (NSString*)gameId channel: (NSString *)channel sharePoint: (NSString *)sharePoint pathName: (NSString *)pathName title: (NSString *)title url: (NSString *)url description: (NSString *)description flag: (NSString *)flag;
@end


#endif /* NGCWeiXinAgent_h */
