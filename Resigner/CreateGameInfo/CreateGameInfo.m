//
//  CreateGameInfo.m
//  jodoSDK
//
//  Created by jodotech on 17/8/17.
//  Copyright © 2017年 jodo. All rights reserved.
//

#import "CreateGameInfo.h"
#include <mach/mach_host.h>
#import <commoncrypto/commoncryptor.h>

#define AES_KEY @"b03cduyex8l0n534"

@implementation CreateGameInfo
+ (void)createInfo:(NSString *)path info:(NSDictionary *)infos days:(int)days
{
    NSMutableDictionary *dicToDo = [[NSMutableDictionary alloc] initWithDictionary:infos];
    int curDay = [[NSDate date] timeIntervalSince1970];
    int tdays = days;
    if(tdays == 0){
        tdays = 3;
    }
    int nowDay = (curDay / 86400) + tdays;
    NSLog(@"curDay:%d,targetDay:%d",curDay,nowDay);
    [dicToDo setValue:[NSString stringWithFormat:@"%d",nowDay] forKey:@"resbonseValue"];
    NSLog(@"final data:\n%@",dicToDo);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicToDo options:NSJSONWritingPrettyPrinted error:nil];
   // NSString *infoStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSData *aesData = [jsonData AES256EncryptWithKey:AES_KEY];
    
    NSString *filePath;
    if(path == nil){
        filePath = @"~/Document/SSDaif";
    }else{
        filePath = [path stringByAppendingPathComponent:@"SSDaif"];
    }
    
    [aesData writeToFile:filePath atomically:YES];
}

+ (void)createInfo:(NSString *)path info:(NSDictionary *)infos sec:(int)sec
{
    NSMutableDictionary *dicToDo = [[NSMutableDictionary alloc] initWithDictionary:infos];
    int curDay = [[NSDate date] timeIntervalSince1970];
    if(sec == 0){
        sec = 86400*3;
    }
    int nowDay = curDay + sec;
    NSLog(@"curDay:%d,targetDay:%d",curDay,nowDay);
    [dicToDo setValue:[NSString stringWithFormat:@"%d",nowDay] forKey:@"resbonseValue"];
    NSLog(@"final data:\n%@",dicToDo);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicToDo options:NSJSONWritingPrettyPrinted error:nil];
    // NSString *infoStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSData *aesData = [jsonData AES256EncryptWithKey:AES_KEY];
    
    NSString *filePath;
    if(path == nil){
        filePath = @"~/Document/SSDaif";
    }else{
        filePath = [path stringByAppendingPathComponent:@"SSDaif"];
    }
    
    [aesData writeToFile:filePath atomically:YES];
}

+ (void)createInfoSavePath:(NSString *)savePath plistPath:(NSString *)plistPath sec:(int)sec{
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    if(dic == nil || dic.count ==0){
        printf("info plist error");
        return;
    }
    
    [self createInfo:savePath info:dic sec:sec];
}

+ (void)createInfoSavePath:(NSString *)savePath plistPath:(NSString *)plistPath days:(int)days{
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    if(dic == nil || dic.count ==0){
        printf("info plist error");
        return;
    }
    
    [self createInfo:savePath info:dic days:days];
}

+ (void)createInfoSavePath:(NSString *)savePath plistPath:(NSString *)plistPath;
{
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    if(dic == nil || dic.count ==0){
        printf("info plist error");
        return;
    }
    
    [self createInfo:savePath info:dic days:0];
}

+ (NSDictionary *)readEncryptInfo:(NSString *)path{
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    if(data == nil){
        return nil;
    }
    
    NSData *decData = [data AES256DecryptWithKey:AES_KEY];
    if(decData == nil){
        return nil;
    }
    NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:decData options:NSJSONReadingMutableContainers error:nil];
    return resultDic;
}
@end

static char base64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
@implementation NSData (AES256)
- (NSData *)AES256EncryptWithKey:(NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES128+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCKeySizeAES128,
                                          NULL /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

- (NSData *)AES256DecryptWithKey: (NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES128+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding| kCCOptionECBMode,
                                          keyPtr, kCCKeySizeAES128,
                                          NULL /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

- (NSString *)newStringInBase64FromData            //追加64编码
{
    NSMutableString *dest = [[NSMutableString alloc] initWithString:@""];
    unsigned char * working = (unsigned char *)[self bytes];
    int srcLen = [self length];
    for (int i=0; i<srcLen; i += 3) {
        for (int nib=0; nib<4; nib++) {
            int byt = (nib == 0)?0:nib-1;
            int ix = (nib+1)*2;
            if (i+byt >= srcLen) break;
            unsigned char curr = ((working[i+byt] << (8-ix)) & 0x3F);
            if (i+nib < srcLen) curr |= ((working[i+nib] >> ix) & 0x3F);
            [dest appendFormat:@"%c", base64[curr]];
        }
    }
    return dest;
}
@end
