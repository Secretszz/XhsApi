//
//  XhsApiManager.mm
//  UnityFramework
//
//  Created by 晴天 on 2023/10/10.
//

#import <XiaoHongShuOpenSDK/XHSApi.h>
#import "XhsApiManager.h"

@implementation XhsApiManager

static XhsApiManager* _instance;

+ (XhsApiManager *) instance {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if(_instance == nil)
        {
            _instance = [[self alloc] init];
        }
    });
    return _instance;
}

- (void)registerApp{
    NSString * appKey = **APPID**;
    NSString * universalLink = **UNILINK**;
    [XHSApi registerApp:appKey universalLink:universalLink delegate:self];
}

- (BOOL)application:(UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if([XHSApi handleOpenURL:url]) {
        return YES;
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    if([XHSApi handleOpenUniversalLink:userActivity]) {
        return YES;
    }

    return YES;
}

/**
 *  发送一个request后，收到小红书终端的回应
 *  @param response 具体的回应内容，回应类型详见XHSApiObject.h
 */
- (void)XHSApiDidReceiveResponse:(__kindof XHSOpenSDKBaseResponse *)response{
    if ([response isKindOfClass:[XHSOpenSDKShareResponse class]]){
        XHSOpenSDKShareResponse* shareResponse = (XHSOpenSDKShareResponse*)response;
        if (self.shareCallback != nil){
            int state = (NSInteger)shareResponse.shareState;
            self.shareCallback(state, [shareResponse.errorString UTF8String]);
        }
        self.shareCallback = nil;
    }
}

/**
 *  分享图片列表
 *  @param title
 *  @param content
 *  @param datas
 *  @param callback
 */
- (void)shareImage:(NSString *)title
           content:(NSString *)content
    imageResources:(NSMutableArray<XHSShareInfoImageItem *>*)imageResources
          callback:(U3DBridgeCallback_Share)callback{
    self.shareCallback = callback;

    XHSShareInfoTextContentItem *messageObject = [[XHSShareInfoTextContentItem alloc] init];
    messageObject.title = title;
    messageObject.content = content;
    XHSOpenSDKShareRequest *shareRequest = [[XHSOpenSDKShareRequest alloc] init];
    shareRequest.mediaType = XHSOpenSDKShareMediaTypeImage;
    shareRequest.textContentItem = messageObject;
    shareRequest.imageInfoItems = imageResources;
    [XHSApi sendRequest:shareRequest completion:^(BOOL success) {
        if (!success){
            self.shareCallback(-1000, "打开小红书失败");
            self.shareCallback = nil;
        }
    }];
}

/**
 *  分享视频图片列表
 *  @param title
 *  @param content
 *  @param datas
 *  @param callback
 */
- (void)shareVideo:(NSString *)title
           content:(NSString *)content
    videoResources:(NSMutableArray<XHSShareInfoVideoItem *> *)videoResources
          callback:(U3DBridgeCallback_Share)callback{
    self.shareCallback = callback;
    XHSShareInfoTextContentItem *messageObject = [[XHSShareInfoTextContentItem alloc] init];
    messageObject.title = title;
    messageObject.content = content;
    XHSOpenSDKShareRequest *shareRequest = [[XHSOpenSDKShareRequest alloc] init];
    shareRequest.mediaType = XHSOpenSDKShareMediaTypeVideo;
    shareRequest.textContentItem = messageObject;
    shareRequest.videoInofoItems = videoResources;
    [XHSApi sendRequest:shareRequest completion:^(BOOL success) {
        if (!success){
            self.shareCallback(-1000, "打开小红书失败");
            self.shareCallback = nil;
        }
    }];
}

- (void)openUrlInXhs:(NSString *)url
			callback:(U3DBridgeCallback_OpenUrl)callback{
    self.openUrlCallback = callback;
	[XHSApi openActivityWebViewWithUrl:url completion:^(BOOL success, NSString *errorMsg) {
	    if (!success){
	        NSLog(@"打开小红书失败:%@", errorMsg);
	    }
	    self.openUrlCallback(success, [errorMsg UTF8String]);
	}];
}
@end

#if defined (__cplusplus)
extern "C"
{
#endif
    
    void xhs_initSDK(){
        [XhsApiManager.instance registerApp];
    }
    
    void xhs_shareImageByData(const char* title,
                        const char* content,
                        const Byte* bytes,
                        int length,
                        U3DBridgeCallback_Share callback){
        NSString* nstitle = [NSString stringWithUTF8String:title];
        NSString* nscontent = [NSString stringWithUTF8String:content];
        NSData * data = [NSData dataWithBytes:bytes length:length];
        NSMutableArray<XHSShareInfoImageItem *> *imageResources = [NSMutableArray array];
        XHSShareInfoImageItem *imageObject = [[XHSShareInfoImageItem alloc] init];
        imageObject.imageData = data;
        [imageResources addObject:imageObject];
        [XhsApiManager.instance shareImage:nstitle
                                   content:nscontent
                            imageResources:imageResources
                                  callback:callback];
    }

    void xhs_shareImage(const char* title,
                              const char* content,
                              const char* imagePaths,
                              U3DBridgeCallback_Share callback){
        NSString* json = [NSString stringWithUTF8String:imagePaths];
        NSData* jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSError* error = nil;
        NSArray<NSString*>* array = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        if (error) {
            callback(-1001, "解析json字符串出错");
        } else{
            NSString* nstitle = [NSString stringWithUTF8String:title];
            NSString* nscontent = [NSString stringWithUTF8String:content];
            NSMutableArray<XHSShareInfoImageItem *> *imageResources = [NSMutableArray array];
            for (int i = 0; i < array.count; i++) {
                NSString* path = [array objectAtIndex:i];
                XHSShareInfoImageItem *imageObject = [[XHSShareInfoImageItem alloc] init];
                imageObject.imageUrl = path;
                [imageResources addObject:imageObject];
            }
            [XhsApiManager.instance shareImage:nstitle
                                       content:nscontent
                                imageResources:imageResources
                                      callback:callback];
        }
    }
    
    void xhs_shareVideoByData(const char* title,
                              const char* content,
                              const char* videoPaths,
                              const Byte* bytes,
                              int length,
                              U3DBridgeCallback_Share callback){
        NSString* nstitle = [NSString stringWithUTF8String:title];
        NSString* nscontent = [NSString stringWithUTF8String:content];
        NSString* nsvideoPaths = [NSString stringWithUTF8String:videoPaths];
        NSData * data = [NSData dataWithBytes:bytes length:length];
        NSMutableArray<XHSShareInfoVideoItem *> *videoResources = [NSMutableArray array];
        XHSShareInfoVideoItem *videoObject = [[XHSShareInfoVideoItem alloc] init];
        videoObject.videoUrl = nsvideoPaths; // 视频
        videoObject.coverImageData = data; // 视频封面
        [videoResources addObject:videoObject];
        [XhsApiManager.instance shareVideo:nstitle
                                   content:nscontent
                            videoResources:videoResources
                                  callback:callback];
    }

    void xhs_shareVideo(const char* title,
                        const char* content,
                        const char* videoPaths,
                        const char* imagePath,
                        int length,
                        U3DBridgeCallback_Share callback){
        NSString* nstitle = [NSString stringWithUTF8String:title];
        NSString* nscontent = [NSString stringWithUTF8String:content];
        NSString* nsvideoPaths = [NSString stringWithUTF8String:videoPaths];
        NSString * nsimagePath = [NSString stringWithUTF8String:imagePath];
        NSMutableArray<XHSShareInfoVideoItem *> *videoResources = [NSMutableArray array];
        XHSShareInfoVideoItem *videoObject = [[XHSShareInfoVideoItem alloc] init];
        videoObject.videoUrl = nsvideoPaths; // 视频
        videoObject.coverUrl = nsimagePath; // 视频封面
        [videoResources addObject:videoObject];
        [XhsApiManager.instance shareVideo:nstitle
                                   content:nscontent
                            videoResources:videoResources
                                  callback:callback];
    }
    
    void xhs_openUrlInXhs(const char* url, U3DBridgeCallback_OpenUrl callback){
        [XhsApiManager.instance openUrlInXhs:[NSString stringWithUTF8String:url] callback:callback];
    }
    
    BOOL xhs_isInstalled(){
        return [XHSApi isXHSAppInstalled];
    }

#if defined (__cplusplus)
}
#endif
