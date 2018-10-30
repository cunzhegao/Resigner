//
//  CreateGameInfo.h
//  jodoSDK
//
//  Created by jodotech on 17/8/17.
//  Copyright © 2017年 jodo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CreateGameInfo : NSObject

+ (void)createInfo:(NSString *)path info:(NSDictionary *)infos days:(int)days;
+ (void)createInfoSavePath:(NSString *)savePath plistPath:(NSString *)plistPath;
+ (void)createInfoSavePath:(NSString *)savePath plistPath:(NSString *)plistPath days:(int)days;
+ (void)createInfoSavePath:(NSString *)savePath plistPath:(NSString *)plistPath sec:(int)sec;
+ (void)createInfo:(NSString *)path info:(NSDictionary *)infos sec:(int)sec;
+ (NSDictionary *)readEncryptInfo:(NSString *)path;
@end

@interface NSData (AES256)
- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey: (NSString *)key;
- (NSString *)newStringInBase64FromData  ;
@end
