//
//  IPIntructionModel.m
//  InstructionalPatch
//
//  Created by intMax on 12/31/17.
//  Copyright © 2017 intMax. All rights reserved.
//

#import "IPIntructionModel.h"

@implementation IPIntructionArgumentModel
@IPIntructionArgumentModelPropertySynthesize
@end

@implementation IPIntructionMessageModel
@IPIntructionMessageModelProtocolPropertySynthesize
@end

@implementation IPIntructionMethodModel
@IPIntructionMethodModelPropertySynthesize
@end

@implementation IPIntructionClassModel
@IPIntructionClassModelPropertySynthesize
@end

@implementation IPIntructionModel
@IPIntructionModelPropertySynthesize
@end

@implementation IPBlockIntegerWapper

+ (id<IPBlockBasicTypeWapper>)generateWapper:(void *)p {
    IPBlockIntegerWapper *wapper = [IPBlockIntegerWapper new];
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
    wapper.value = *((long*)&p);
#else
    wapper.value = *((int*)&p);
#endif
    return wapper;
}

- (void *)valuePoint {
    return (void *)(&_value);
}

@end

@implementation IPBlockUIntegerWapper

+ (id<IPBlockBasicTypeWapper>)generateWapper:(void *)p {
    IPBlockIntegerWapper *wapper = [IPBlockIntegerWapper new];
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
    wapper.value = *((unsigned long*)&p);
#else
    wapper.value = *((unsigned int*)&p);
#endif
    return wapper;
}

- (void *)valuePoint {
    return (void *)(&_value);
}

@end

@implementation IPBlockFloatWapper

+ (id<IPBlockBasicTypeWapper>)generateWapper:(void *)p {
    IPBlockFloatWapper *wapper = [IPBlockFloatWapper new];
#if defined(__LP64__) && __LP64__
    // can not be converted on 64bit device
    NSAssert(NO, @"can not be converted on 64bit device");
    wapper.value = 0;
#else
    wapper.value = *((float*)&p);
#endif
    return wapper;
}

- (void *)valuePoint {
    return (void *)(&_value);
}

@end

@implementation IPBasicTypeWrapper
@end

@implementation NSObject (IPInstructionalPatch)

- (IPBasicTypeWrapper *)generateNSRange:(NSInteger)loc len:(NSInteger)len {
    IPBasicTypeWrapper *obj = [IPBasicTypeWrapper new];
    NSRange range = NSMakeRange(loc, len);
    obj.structValue = [NSValue valueWithRange:range];
    return obj;
}

- (IPBasicTypeWrapper *)generateCGRect:(double)x y:(double)y w:(double)w h:(double)h {
    IPBasicTypeWrapper *obj = [IPBasicTypeWrapper new];
    CGRect rect = CGRectMake(x, y, w, h);
    obj.structValue = [NSValue valueWithCGRect:rect];
    return obj;
}

- (IPBasicTypeWrapper *)generateCGSize:(double)w h:(double)h {
    IPBasicTypeWrapper *obj = [IPBasicTypeWrapper new];
    CGSize size = CGSizeMake(w, h);
    obj.structValue = [NSValue valueWithCGSize:size];
    return obj;
}

- (IPBasicTypeWrapper *)generateCGPoint:(double)x y:(double)y {
    IPBasicTypeWrapper *obj = [IPBasicTypeWrapper new];
    CGPoint point = CGPointMake(x, y);
    obj.structValue = [NSValue valueWithCGPoint:point];
    return obj;
}

@end
