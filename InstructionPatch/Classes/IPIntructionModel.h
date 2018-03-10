//
//  IPIntructionModel.h
//  InstructionalPatch
//
//  Created by intMax on 12/31/17.
//  Copyright © 2017 intMax. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IPIntructionArgumentModelPropertySynthesize \
synthesize \
type = _type, \
valueKey = _valueKey, \
stringValue = _stringValue, \
digital = _digital, \
digitalType = _digitalType, \
blockParameterTypes = _blockParameterTypes, \
blockParameterPrefix = _blockParameterPrefix, \
innerMessage = _innerMessage;

#define IPIntructionMessageModelProtocolPropertySynthesize \
synthesize \
returnType = _returnType, \
returnObj = _returnObj, \
receiver = _receiver, \
message = _message, \
isStatic = _isStatic, \
isBlock = _isBlock, \
isIfSnippet = _isIfSnippet, \
isWhileSnippet = _isWhileSnippet, \
isReturnSnippet = _isReturnSnippet, \
environmentPoolRefCount = _environmentPoolRefCount, \
blockKey = _blockKey, \
args = _args;

#define IPIntructionMethodModelPropertySynthesize \
synthesize \
method = _method, \
isStatic = _isStatic, \
isMsgForwardStret = _isMsgForwardStret, \
messages = _messages;

#define IPIntructionClassModelPropertySynthesize \
synthesize \
cls = _cls, \
methodList = _methodList;

#define IPIntructionModelPropertySynthesize \
synthesize instructions = _instructions;

@protocol IPIntructionMessageModelProtocol;
@protocol IPIntructionArgumentModelProtocol<NSObject>

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *valueKey;
@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, assign) double digital;
@property (nonatomic, copy) NSString *digitalType;
@property (nonatomic, copy) NSArray *blockParameterTypes;
// one method has mutiple blocks arguments, It can be used to distinguish
@property (nonatomic, copy) NSString *blockParameterPrefix;
@property (nonatomic, copy) NSArray<id<IPIntructionMessageModelProtocol>> *innerMessage;

@end

@protocol IPIntructionMessageModelProtocol<NSObject>

@property (nonatomic, copy) NSString *returnType;
@property (nonatomic, copy) NSString *returnObj;
@property (nonatomic, copy) NSString *receiver;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) BOOL isStatic;
@property (nonatomic, assign) BOOL isBlock;
@property (nonatomic, assign) BOOL isIfSnippet;
@property (nonatomic, assign) BOOL isWhileSnippet;
@property (nonatomic, assign) BOOL isReturnSnippet;
/**
 When a method or block starts to be executed, the reference will add 1,
 and the reference will be reduced by 1 after the execution.
 and the parameter pool will be emptied when the reference is reduced to 0.
 So, if a method has 2 blocks, but only one will be executed, it should be 1
 */
@property (nonatomic, assign) NSInteger environmentPoolRefCount;
// If `isBlock` is true, you must provide the blockKey, usually is `ARG_x`
@property (nonatomic, copy) NSString *blockKey;
@property (nonatomic, copy) NSArray<id<IPIntructionArgumentModelProtocol>> *args;

@end

@protocol IPIntructionMethodModelProtocol<NSObject>

@property (nonatomic, copy) NSString *method;
@property (nonatomic, assign) BOOL isStatic;
@property (nonatomic, assign) BOOL isMsgForwardStret;
@property (nonatomic, copy) NSArray<id<IPIntructionMessageModelProtocol>> *messages;

@end

@protocol IPIntructionClassModelProtocol<NSObject>

@property (nonatomic, copy) NSString *cls;
@property (nonatomic, copy) NSArray<id<IPIntructionMethodModelProtocol>> *methodList;

@end

@protocol IPIntructionModelProtocol<NSObject>

@property (nonatomic, copy) NSArray<id<IPIntructionClassModelProtocol>> *instructions;

@end


@interface IPIntructionArgumentModel : NSObject<IPIntructionArgumentModelProtocol>
@end
@interface IPIntructionMessageModel : NSObject <IPIntructionMessageModelProtocol>
@end
@interface IPIntructionMethodModel : NSObject<IPIntructionMethodModelProtocol>
@end
@interface IPIntructionClassModel : NSObject<IPIntructionClassModelProtocol>
@end
@interface IPIntructionModel : NSObject<IPIntructionModelProtocol>
@end




@protocol IPBlockBasicTypeWapper<NSObject>

@required
+ (id<IPBlockBasicTypeWapper>)generateWapper:(void *)p;
- (void *)valuePoint;

@end

@interface IPBlockIntegerWapper : NSObject<IPBlockBasicTypeWapper>

#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
@property (nonatomic, assign) long value;
#else
@property (nonatomic, assign) int value;
#endif

+ (id<IPBlockBasicTypeWapper>)generateWapper:(void *)p;
- (void *)valuePoint;

@end

@interface IPBlockUIntegerWapper : NSObject<IPBlockBasicTypeWapper>

#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
@property (nonatomic, assign) unsigned long value;
#else
@property (nonatomic, assign) unsigned int value;
#endif

+ (id<IPBlockBasicTypeWapper>)generateWapper:(void *)p;
- (void *)valuePoint;

@end

@interface IPBlockFloatWapper : NSObject<IPBlockBasicTypeWapper>

#if defined(__LP64__) && __LP64__
@property (nonatomic, assign) double value;
#else
@property (nonatomic, assign) float value;
#endif

+ (id<IPBlockBasicTypeWapper>)generateWapper:(void *)p;
- (void *)valuePoint;

@end

@interface IPBasicTypeWrapper : NSObject

@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic, strong) NSValue *structValue;
@property (nonatomic, assign) const char *encode;

@end

@interface NSObject (IPInstructionalPatch)

- (IPBasicTypeWrapper *)generateNSRange:(NSInteger)loc len:(NSInteger)len;
- (IPBasicTypeWrapper *)generateCGRect:(double)x y:(double)y w:(double)w h:(double)h;
- (IPBasicTypeWrapper *)generateCGSize:(double)w h:(double)h;
- (IPBasicTypeWrapper *)generateCGPoint:(double)x y:(double)y;

@end

