//
//  NGCWeiXinAgent.m
//  TexasHoldem
//
//  Created by iSoundy on 15/12/10.
//
//
#import "NGCWeiXinAgent.h"

#import "WXApi.h"
#import "Constant.h"
#import "WXApiManager.h"
#import "WXApiRequestHandler.h"
#import <UIKit/UIKit.h>

@interface NGCWeiXinAgent ()<WXApiManagerDelegate,UITextViewDelegate>

@property (nonatomic) enum WXScene currentScene;
@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) UIScrollView *footView;

@end

@implementation NGCWeiXinAgent

static NGCWeiXinAgent* _instance = nil;

//
+ (instancetype) shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[NGCWeiXinAgent alloc] init] ;
    }) ;
    
    return _instance ;
}

- (void)attemptDealloc
{
    if ([_instance retainCount] != 1)
    return;
    
    [_instance release];
    _instance = nil;
    
}


- (BOOL)initWeiXinSDK: (UIViewController *) view
{
    //向微信注册
    //    BOOL bIsExitWX = [NGCWeiXinAgent checkAppIsInstall:@""];
    //    if(bIsExitWX){
    [WXApi registerApp:@"wx920c6356b8315bb5"];
    self.viewController = view;
    [WXApiManager sharedManager].delegate = view;
    return TRUE;
    //}
    
    return FALSE;
}

/*
 * fun: 微信请求登陆
 * @params: userSession
 * 防止跨战
 */
+ (void)sendWXLoginRequest:(NSString *)userSession
{
    kAuthScope = @"snsapi_userinfo";
    kAuthState = [NSString stringWithFormat:@"%@",userSession];
    NSLog(@"sendWxloginRequest %@",userSession);
    [[NGCWeiXinAgent shareInstance] sendAuthRequest];
}

/*
 * fun: 检测是否安装微信应用
 * @params: packetName
 * 固定写死包名，方法与安卓统一
 */
+ (BOOL)checkAppIsInstall:(NSString *)packetName
{
    NSLog(@"checkAppIsInstall %@",packetName);
    BOOL bRet = [WXApi isWXAppInstalled];;
    NSLog(@"bRetIsinstall: %@" ,bRet?@"YES":@"NO");
    return bRet;
}

/*
 * fun: 微信下定单
 * @param {int} goodsId 物品编号,如果是游戏豆，goodsId为-1
 * @param {int} channelId 支付渠道号 1为支付宝,2为微信,3为易宝银行卡支付,4为渠道的短代
 * @param {int} goodsCount 购买数量(如果有赠送不包含赠送数量)
 * @param {number}	totalValue 总价值
 * @param {String}	goodsDesc 物品描述，没有传空符串
 * @param {String} otherParams 其他被充参数,对于易宝支付这里可以填银行卡账号(银行卡账号也可以不填)
 * 固定写死包名，方法与安卓统一
 */
+ (BOOL)doOrder:(NSString *)ordId channelld: (NSString *)chId payInfo64: (NSString *)pInfo thirdOrderId: (NSString*)trdOId
{
    if( [@"" isEqual:pInfo]){
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"支付失败" message:pInfo delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alter show];
        [alter release];
        return false;
    }
    NSString *newOrdId = [NSString stringWithFormat:@"%@",ordId];
    NSString *newChId = [NSString stringWithFormat:@"%@",chId];
    NSString *newTrdOId = [NSString stringWithFormat:@"%@",trdOId];
    
    [[NGCWeiXinAgent shareInstance] setLastOrderId:newOrdId];//保存当前微信所下的定单ID
    
    NSString *newInfo = [NSString stringWithFormat:@"%@",pInfo];
    NSData* dataFromString = [[NSData alloc] initWithBase64EncodedString:pInfo options:0];
    NSString* retStr = [[NSString alloc] initWithData:dataFromString encoding:NSASCIIStringEncoding];
    NSLog(@"serviceRetStr:%@",retStr);
    NSDictionary *dict;
    NSError* error = nil;
    dict = [NSJSONSerialization JSONObjectWithData: dataFromString
                                           options: NSJSONReadingMutableContainers
                                             error: &error];
    
    if (error)
    {
        NSLog(@"Error: %@",error);
        return false;
    }
    
    //调起微信支付
    PayReq* req             = [[[PayReq alloc] init]autorelease];
    req.partnerId           = [dict objectForKey:@"partnerId"];
    req.prepayId            = [dict objectForKey:@"prepayId"];
    req.nonceStr            = [dict objectForKey:@"nonceStr"];
    req.timeStamp           = [dict objectForKey:@"timeStamp"];
    req.sign                = [dict objectForKey:@"sign"];
    req.package              = @"Sign=WXPay";
    
    
    [WXApi sendReq:req];
    
    
    return true;
}

/*
 * fun: 微信分享
 * 字符串参数如果没有的就传空字符串
 * @param {int} channel 分享渠道,目前只有微信(为1)
 * @param {int} sharePoint 分享点，要与服务端设置相对应，不同的分享点分享奖励不一样
 * @param {String} pathName 分享图片的本地路径
 * @param {String} title 分享标题
 * @param {String} url 分享的url地址
 * @param {String} description 分享的具体描述
 * @param {int} 分享方式,对于微信而言 0:分享到微信好友，1：分享到微信朋友圈
 * @param {Function} 分享结果的回调方法,参数为channel(渠道),sharePoint(分享点),shareResult(分享结果),awardBean(奖励的游戏豆)
 */
+ (void)doShare:  (NSString*)gameId channel: (NSString *)channel sharePoint: (NSString *)sharePoint pathName: (NSString *)pathName title: (NSString *)title url: (NSString *)url description: (NSString *)description flag: (NSString *)flag
{
   
    NSString *newGameId = [NSString stringWithFormat:@"%@",gameId];
    NSString *newChannel = [NSString stringWithFormat:@"%@",channel];
    NSString *newSharePoint = [NSString stringWithFormat:@"%@",sharePoint];
    NSString *newPathName = [NSString stringWithFormat:@"%@",pathName];
    NSString *newTitle = [NSString stringWithFormat:@"%@",title];
    NSString *newUrl = [NSString stringWithFormat:@"%@",url];
    NSString *newDescription = [NSString stringWithFormat:@"%@",description];
    NSString *newFlag = [NSString stringWithFormat:@"%@",flag];
//     NSLog(@"doSharexxxxxxx:%@,%@,%@,%@,%@,%@,%@,%@",gameId,channel,sharePoint,pathName,title,url,description, newFlag);
    
    
   
    
    //By Dongenlai
    NSString* filePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", pathName];
    NSLog(@"%@",filePath);
    NSData *imageData = [NSData dataWithContentsOfFile:filePath];
    UIImage *img;
    NSObject *sharExt = nil;
    if(imageData){
        WXImageObject *ext = [WXImageObject object];
        ext.imageData = imageData;
        sharExt = ext;
        img = [self thumbnailWithImage:[UIImage imageWithContentsOfFile:filePath] size:CGSizeMake(120, 120)];
        
    }
    else if(url){
        WXWebpageObject *ext = [WXWebpageObject object];
        ext.webpageUrl = newUrl;
        sharExt = ext;
        img = [UIImage imageNamed:@"Icon-100.png"];
    }
    
//    NSNumber * flag = flag == 0 ? WXSceneSession:WXSceneTimeline;
    
    
    /*WXMediaMessage *message = [WXMediaMessage messageWithTitle:newTitle
                                                   Description:newDescription
                                                        Object:sharExt
                                                    MessageExt:nil
                                                 MessageAction:1
                                                    ThumbImage:img
                                                      MediaTag:nil];
    
    GetMessageFromWXResp* resp = [GetMessageFromWXResp responseWithText:nil
                                                         OrMediaMessage:message
                                                                  bText:NO];*/
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = newTitle;
    message.description = newDescription;
    [message setThumbImage:img];
    
    WXWebpageObject * webpageObject = [WXWebpageObject object];
    webpageObject.webpageUrl = newUrl;
    message.mediaObject = webpageObject;
    
    SendMessageToWXReq * req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    if([newFlag intValue] == 0){
        req.scene = WXSceneSession;
    }else{
        req.scene = WXSceneTimeline;
    }
   
    
//    [WXApi sendResp:resp];
    [WXApi sendReq:req];
}


+(void)openBrowser: (NSString *)urlStr{
    NSString *url = [NSString stringWithFormat:@"%@",urlStr];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    
}


+ (UIImage *)thumbnailWithImage:(UIImage *)image size:(CGSize)asize

{
    
    UIImage *newimage;
    
    if (nil == image) {
        
        newimage = nil;
        
    }
    
    else{
        
        UIGraphicsBeginImageContext(asize);
        
        [image drawInRect:CGRectMake(0, 0, asize.width, asize.height)];
        
        newimage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
    }
    
    return newimage;
    
}

- (void)sendAuthRequest {
    SendAuthReq* req =[[[SendAuthReq alloc ] init ] autorelease ];
    req.scope = @"snsapi_userinfo" ;
    req.state = @"" ;
    [WXApi sendReq:req];
}

@end
