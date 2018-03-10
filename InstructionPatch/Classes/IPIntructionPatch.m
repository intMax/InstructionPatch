//
//  IPIntructionPatcher.m
//  InstructionalPatch
//
//  Created by intMax on 12/31/17.
//  Copyright © 2017 intMax. All rights reserved.
//

#import "IPIntructionPatch.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#define BOOL_TYPE(type) (!strcmp(type, @encode(BOOL)))
#define INT_TYPE(type) (!strcmp(type, @encode(int)))
#define UNSIGNED_INT_TYPE(type) (!strcmp(type, @encode(unsigned int)))
#define LONG_TYPE(type) (!strcmp(type, @encode(long)))
#define UNSIGNED_LONG_TYPE(type) (!strcmp(type, @encode(unsigned long)))
#define LONG_LONG_TYPE(type) (!strcmp(type, @encode(long long)))
#define UNSIGNED_LONG_LONG_TYPE(type) (!strcmp(type, @encode(unsigned long long)))
#define DOUBLE_TYPE(type) (!strcmp(type, @encode(double)))
#define FLOAT_TYPE(type) (!strcmp(type, @encode(float)))
#define SHORT_TYPE(type) (!strcmp(type, @encode(short)))
#define UNSIGNED_SHORT_TYPE(type) (!strcmp(type, @encode(unsigned short)))
#define CHAR_TYPE(type) (!strcmp(type, @encode(char)))
#define UNSIGNED_CHAR_TYPE(type) (!strcmp(type, @encode(unsigned char)))
#define CGRECT_TYPE(type) ([[NSString stringWithUTF8String:type] rangeOfString:@"CGRect"].location != NSNotFound)
#define CGPOINT_TYPE(type) ([[NSString stringWithUTF8String:type] rangeOfString:@"CGPoint"].location != NSNotFound)
#define CGSIZE_TYPE(type) ([[NSString stringWithUTF8String:type] rangeOfString:@"CGSize"].location != NSNotFound)
#define NSRANGE_TYPE(type) ([[NSString stringWithUTF8String:type] rangeOfString:@"NSRange"].location != NSNotFound)
#define OBJECT_TYPE(type) (!strncmp(type, @encode(id), 1))

#define UnPack(unpackingObj, valuePoint) \
void *argPoint = NULL; \
if ([unpackingObj isKindOfClass:[IPBasicTypeWrapper class]]) { \
    IPBasicTypeWrapper *obj = (IPBasicTypeWrapper *)unpackingObj; \
    const char *type = obj.encode; \
    if (INT_TYPE(type)) { \
        int ret = obj.numberValue.intValue; \
        argPoint = &ret; \
    } \
    else if (BOOL_TYPE(type)) { \
        BOOL ret = obj.numberValue.boolValue; \
        argPoint = &ret; \
    } \
    else if (UNSIGNED_INT_TYPE(type)) { \
        unsigned int ret = obj.numberValue.unsignedIntValue; \
        argPoint = &ret; \
    } \
    else if (LONG_TYPE(type)) { \
        long ret = obj.numberValue.longValue; \
        argPoint = &ret; \
    } \
    else if (UNSIGNED_LONG_TYPE(type)) { \
        unsigned long ret = obj.numberValue.unsignedLongValue; \
        argPoint = &ret; \
    } \
    else if (LONG_LONG_TYPE(type)) { \
        long long ret = obj.numberValue.longLongValue; \
        argPoint = &ret; \
    } \
    else if (UNSIGNED_LONG_LONG_TYPE(type)) { \
        unsigned long long ret = obj.numberValue.unsignedLongLongValue; \
        argPoint = &ret; \
    } \
    else if (DOUBLE_TYPE(type)) { \
        double ret = obj.numberValue.doubleValue; \
        argPoint = &ret; \
    } \
    else if (FLOAT_TYPE(type)) { \
        float ret = obj.numberValue.floatValue; \
        argPoint = &ret; \
    } \
    else if (SHORT_TYPE(type)) { \
        short ret = obj.numberValue.shortValue; \
        argPoint = &ret; \
    } \
    else if (UNSIGNED_SHORT_TYPE(type)) { \
        unsigned short ret = obj.numberValue.unsignedShortValue; \
        argPoint = &ret; \
    } \
    else if (CHAR_TYPE(type)) { \
        char ret = obj.numberValue.charValue; \
        argPoint = &ret; \
    } \
    else if (UNSIGNED_CHAR_TYPE(type)) { \
        unsigned char ret = obj.numberValue.unsignedCharValue; \
        argPoint = &ret; \
    } \
    else if (CGRECT_TYPE(type)) { \
        CGRect ret = obj.structValue.CGRectValue; \
        argPoint = &ret; \
    } \
    else if (CGPOINT_TYPE(type)) { \
        CGPoint ret = obj.structValue.CGPointValue; \
        argPoint = &ret; \
    } \
    else if (CGSIZE_TYPE(type)) { \
        CGSize ret = obj.structValue.CGSizeValue; \
        argPoint = &ret; \
    } \
    else if (NSRANGE_TYPE(type)) { \
        NSRange ret = obj.structValue.rangeValue; \
        argPoint = &ret; \
    } \
} \
else { \
    argPoint = (void *)(&unpackingObj); \
} \
valuePoint = argPoint; \

static IPIntructionModel *intructionModel = nil;
// every method has it's own space to store variable,
// when the method is executed, the pool will be released
static NSMutableDictionary *environmentPool = nil;
static NSDictionary *blockParameterWapperMap = nil;
static NSDictionary *encodeMap = nil;

struct IPBlockLayout {
    void *isa; 
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct IPBlockDescriptor *descriptor;
};

struct IPBlockDescriptor {
    unsigned long int reserved;
    unsigned long int size;
    void (*copy)(void *dst, void *src);
    void (*dispose)(void *src);
    const char *signature;
};

enum {
  IP_BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
  IP_BLOCK_HAS_SIGNATURE  =    (1 << 30)
};

@interface IPIntructionPatch()

@end

@implementation IPIntructionPatch

+ (void)stop {
    for (IPIntructionClassModel *clazz in intructionModel.instructions) {
        Class cls = NSClassFromString(clazz.cls);
        for (IPIntructionMethodModel *method in clazz.methodList) {
            Method m;
            Method oriM;
            if (method.isStatic) {
                oriM = class_getClassMethod(cls, NSSelectorFromString([NSString stringWithFormat:@"IPORI_%@", method.method]));
                m = class_getClassMethod(cls, NSSelectorFromString(method.method));
            }
            else {
                oriM = class_getInstanceMethod(cls, NSSelectorFromString([NSString stringWithFormat:@"IPORI_%@", method.method]));
                m = class_getInstanceMethod(cls, NSSelectorFromString(method.method));
            }
            if (m && oriM) {
                method_setImplementation(m, method_getImplementation(oriM));
            }
        }
    }
}

+ (void)run:(IPIntructionModel *)model {
    if (![model conformsToProtocol:@protocol(IPIntructionModelProtocol)]) {
        NSAssert(NO, @"model'class illegal");
        return;
    }
#if DEBUG
    NSLog(@"environmentPool's data:%@", environmentPool);
#endif
    intructionModel = model;
    environmentPool = [@{} mutableCopy];
    blockParameterWapperMap = @{
                  @"NSInteger":[IPBlockIntegerWapper class],
                  @"NSUInteger":[IPBlockUIntegerWapper class],
                  @"CGFloat":[IPBlockFloatWapper class],
                  };
    encodeMap = @{
                  @"NSInteger":[NSString stringWithUTF8String:@encode(NSInteger)],
                  @"NSUInteger":[NSString stringWithUTF8String:@encode(NSUInteger)],
                  @"CGFloat":[NSString stringWithUTF8String:@encode(CGFloat)],
                  @"int":[NSString stringWithUTF8String:@encode(int)],
                  @"double":[NSString stringWithUTF8String:@encode(double)],
                  @"float":[NSString stringWithUTF8String:@encode(float)],
                  };
    for (IPIntructionClassModel *clazzModel in intructionModel.instructions) {
        Class cls = NSClassFromString(clazzModel.cls);
        for (IPIntructionMethodModel *methodModel in clazzModel.methodList) {
            Method method;
            NSMethodSignature *signature = nil;
            if (methodModel.isStatic) {
                signature = [cls methodSignatureForSelector:NSSelectorFromString(methodModel.method)];
                method = class_getClassMethod(cls, NSSelectorFromString(methodModel.method));
                cls = object_getClass(cls);
            }
            else {
                signature = [cls methodSignatureForSelector:NSSelectorFromString(methodModel.method)];
                method = class_getInstanceMethod(cls, NSSelectorFromString(methodModel.method));
            }
            IMP oriImp = method_getImplementation(method);
            class_addMethod(cls, NSSelectorFromString([NSString stringWithFormat:@"IPORI_%@", methodModel.method]), oriImp, method_getTypeEncoding(method));
            
            IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
            const char *encoding = method_getTypeEncoding(method);
            BOOL methodReturnsStructValue = encoding[0] == _C_STRUCT_B;
            if (methodReturnsStructValue) {
                @try {
                    NSUInteger valueSize = 0;
                    NSGetSizeAndAlignment(encoding, &valueSize, NULL);
                    
                    if (valueSize == 1 || valueSize == 2 || valueSize == 4 || valueSize == 8) {
                        methodReturnsStructValue = NO;
                    }
                } @catch (__unused NSException *e) {}
            }
            if (methodReturnsStructValue || methodModel.isMsgForwardStret) {
                msgForwardIMP = (IMP)_objc_msgForward_stret;
            }
#endif
            method_setImplementation(method, msgForwardIMP);
        }
        if (class_getMethodImplementation(cls, @selector(forwardInvocation:)) != (IMP)_IPForwardInvocation) {
            IMP oriImp = class_replaceMethod(cls, @selector(forwardInvocation:),(IMP) _IPForwardInvocation, "v@:@");
            if (oriImp) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                class_addMethod(cls, @selector(IPORI_forwardInvocation:), oriImp, "v@:@");
#pragma clang diagnostic pop
            }
        }
    }
}

+ (IPIntructionModel *)instructionModel {
    return intructionModel;
}

static void _IPForwardInvocation(__weak id _self, SEL selector, NSInvocation *invocation) {
    NSString *space;
    for (IPIntructionClassModel *clazzModel in intructionModel.instructions) {
        Class cls = NSClassFromString(clazzModel.cls);
        if ([_self class] != cls) {
            continue;
        }
        for (IPIntructionMethodModel *methodModel in clazzModel.methodList) {
            if ([methodModel.method isEqualToString:NSStringFromSelector(invocation.selector)]) {
                space = [NSString stringWithFormat:@"%@_%@", clazzModel.cls, methodModel.method];
                for (int i = 2; i<invocation.methodSignature.numberOfArguments; i++) {
                    const char *argType = [invocation.methodSignature getArgumentTypeAtIndex:i];
                    id arg;
                    if (!strncmp(argType, @encode(id), 1)) {
                        void *result;
                        [invocation getArgument:&result atIndex:i];
                        arg = (__bridge id)result;
                    }
                    else {
                        arg = _IPGetObjectFromInvocation(argType, invocation, false, i);
                    }
                    NSString *key = [NSString stringWithFormat:@"ARG_%d", i-2];
                    _IPWriteToEnvironmentPool(arg, space, key);
                }
                _IPAddEnvironmentPoolRefCount(space);
                _IPExecuteMessage(_self, selector, invocation, clazzModel, methodModel);
                break;
            }
        }
    }
    _IPReduceEnvironmentPoolRefCount(space);
}

static void _IPExecuteMessage(__weak id _self, SEL selector, NSInvocation *invocation, IPIntructionClassModel *clazz, IPIntructionMethodModel *method) {
    Class cls = NSClassFromString(clazz.cls);
    for (IPIntructionMessageModel *messageModel in method.messages) {
        BOOL hasReturn = [messageModel.returnType isKindOfClass:[NSString class]] && messageModel.returnType.length>0;
        NSMutableArray *args = [@[] mutableCopy];
        IPIntructionArgumentModel *ifArg = nil;
        IPIntructionArgumentModel *elseArg = nil;
        IPIntructionArgumentModel *whileArg = nil;
        NSString *space = [NSString stringWithFormat:@"%@_%@", clazz.cls, method.method];
        for (int i=0; i<messageModel.environmentPoolRefCount; i++) {
            _IPAddEnvironmentPoolRefCount(space);
        }
        // generate arguments
        for (IPIntructionArgumentModel *argModel in messageModel.args) {
            NSString *completedKey = [NSString stringWithFormat:@"%@", argModel.valueKey];
            NSString *blockCompletedKey = [NSString stringWithFormat:@"%@_%@", argModel.blockParameterPrefix, argModel.valueKey];
            if (_IPContainsObjectInSpace(space, completedKey)) {
                id obj = _IPReadFromEnvironmentPool(space, completedKey);
                [args addObject:obj];
            }
            else if (_IPContainsObjectInSpace(space, blockCompletedKey)) {
                id obj = _IPReadFromEnvironmentPool(space, blockCompletedKey);
                [args addObject:obj];
            }
            else if ([argModel.type isEqualToString:@"block"]) {
                id block = nil;
                if (argModel.blockParameterTypes.count == 0) {
                    block = [^() {
                        __strong id sself = _self;
                        NSString *key = [NSString stringWithFormat:@"%@_BLOCK_ARG", argModel.blockParameterPrefix];
                        _IPBlockImp(sself, selector, invocation, clazz, method, argModel, key, 0, NULL, NULL, NULL, NULL);
                    } copy];
                }
                else if (argModel.blockParameterTypes.count == 1) {
                    block = [^(void *p0) {
                        __strong id sself = _self;
                        NSString *key = [NSString stringWithFormat:@"%@_BLOCK_ARG", argModel.blockParameterPrefix];
                        _IPBlockImp(sself, selector, invocation, clazz, method, argModel, key, 1, p0, NULL, NULL, NULL);
                    } copy];
                }
                else if (argModel.blockParameterTypes.count == 2) {
                    block = [^(void *p0, void *p1) {
                        __strong id sself = _self;
                        NSString *key = [NSString stringWithFormat:@"%@_BLOCK_ARG", argModel.blockParameterPrefix];
                        _IPBlockImp(sself, selector, invocation, clazz, method, argModel, key, 2, p0, p1, NULL, NULL);
                    } copy];
                }
                else if (argModel.blockParameterTypes.count == 3) {
                    block = [^(void *p0, void *p1, void *p2) {
                        __strong id sself = _self;
                        NSString *key = [NSString stringWithFormat:@"%@_BLOCK_ARG", argModel.blockParameterPrefix];
                        _IPBlockImp(sself, selector, invocation, clazz, method, argModel, key, 3, p0, p1, p2, NULL);
                    } copy];
                }
                else if (argModel.blockParameterTypes.count == 4) {
                    block = [^(void *p0, void *p1, void *p2, void *p3) {
                        __strong id sself = _self;
                        NSString *key = [NSString stringWithFormat:@"%@_BLOCK_ARG", argModel.blockParameterPrefix];
                        _IPBlockImp(sself, selector, invocation, clazz, method, argModel, key, 4, p0, p1, p2, p3);
                    } copy];
                }
                else {
                    _IPReduceEnvironmentPoolRefCount(space);
                }
                if (block) {
                    [args addObject:block];
                }
            }
            else if ([argModel.type isEqualToString:@"if"]) {
                ifArg = argModel;
            }
            else if ([argModel.type isEqualToString:@"else"]) {
                elseArg = argModel;
            }
            else if ([argModel.type isEqualToString:@"while"]) {
                whileArg = argModel;
            }
            else if ([argModel.type isEqualToString:@"breakWhile"]) {
                _IPWriteToEnvironmentPool(@(YES), space, @"_breakWhile");
            }
            else {
                // TODO: support more arg type here
            }
            
            if (!argModel.valueKey && !argModel.stringValue && argModel.digitalType.length > 0) {
                IPBasicTypeWrapper *upn = [IPBasicTypeWrapper new];
                // fix numberWithDouble:
                upn.numberValue = [NSNumber numberWithDouble:argModel.digital];
                NSString *encodeString = [encodeMap objectForKey:argModel.digitalType];
                upn.encode = [encodeString UTF8String];
                [args addObject:upn];
            }
            else if (!argModel.valueKey && argModel.stringValue.length > 0) {
                [args addObject:argModel.stringValue];
            }
        }
        SEL msgSelector;
        id target;
        if ([messageModel.receiver isEqualToString:@"super"]) {
            NSString *superSelectorName = [NSString stringWithFormat:@"IPSUPER_%@", messageModel.message];
            SEL superSelector = NSSelectorFromString(superSelectorName);
            Class superCls = [cls superclass];
            Method superMethod = class_getInstanceMethod(superCls, invocation.selector);
            IMP superIMP = method_getImplementation(superMethod);
            class_addMethod(cls, superSelector, superIMP, method_getTypeEncoding(superMethod));
            msgSelector = NSSelectorFromString(superSelectorName);
            target = _self;
        }
        else if ([messageModel.receiver isEqualToString:@"self"]) {
            msgSelector = NSSelectorFromString(messageModel.message);
            target = _self;
        }
        else if (messageModel.isStatic) {
            msgSelector = NSSelectorFromString(messageModel.message);
            target = NSClassFromString(messageModel.receiver);
        }
        else if (messageModel.isBlock) {
            NSString *key = [NSString stringWithFormat:@"%@", messageModel.blockKey];
            id block = _IPReadFromEnvironmentPool(space, key);
            NSMethodSignature *blockSignature = _IPBlockSignature(block);
            if (blockSignature) {
                NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:blockSignature];
                blockInvocation.target = block;
                for (int i = 1; i<blockSignature.numberOfArguments; i++) {
                    const char *blockArgType = [blockSignature getArgumentTypeAtIndex:i];
                    NSString *blockArgTypeString = [NSString stringWithUTF8String:blockArgType];
                    IPIntructionArgumentModel *blockArgModel = messageModel.args[i-1];
                    id blockArg = nil;
                    if ([blockArgTypeString rangeOfString:@"@"].location != NSNotFound ||
                        /* if the block created by IPIntructionalPatcher, its parameter type is `void *`  */
                        [blockArgTypeString rangeOfString:@"^v"].location != NSNotFound) {
                        if (blockArgModel.valueKey.length > 0) {
                            NSString *key = [NSString stringWithFormat:@"%@", blockArgModel.valueKey];
                            blockArg = _IPReadFromEnvironmentPool(space, key);
                        }
                        else if (blockArgModel.stringValue.length > 0){
                            blockArg = blockArgModel.stringValue;
                        }
                    }
                    else {
                        NSString *encodeString = [encodeMap objectForKey:blockArgModel.digitalType];
                        if (encodeString.length > 0) {
                            const char *encode = [encodeString UTF8String];
                            IPBasicTypeWrapper *tmp = [IPBasicTypeWrapper new];
                            tmp.encode = encode;
                            tmp.numberValue = [NSNumber numberWithDouble:blockArgModel.digital];
                            blockArg = tmp;
                        }
                    }
                    void *valuePoint = NULL;
                    UnPack(blockArg, valuePoint);
                    [blockInvocation setArgument:valuePoint atIndex:i];
                }
                [blockInvocation invoke];
                id returnValue = _IPGetReturnValue(blockInvocation, blockSignature);
                if (returnValue) {
                    NSString *space = [NSString stringWithFormat:@"%@_%@", clazz.cls, method.method];
                    NSString *key = [NSString stringWithFormat:@"%@", messageModel.returnObj];
                    _IPWriteToEnvironmentPool(returnValue, space, key);
                }
            }
            continue;
        }
        else {
            msgSelector = NSSelectorFromString(messageModel.message);
            NSString *key = [NSString stringWithFormat:@"%@", messageModel.receiver];
            target = _IPReadFromEnvironmentPool(space, key);
        }
        id ret = nil;
        if (msgSelector && target) {
            ret = _IPInvoke(msgSelector, target, messageModel.isStatic, [args copy]);
            if (hasReturn) {
                NSString *key = [NSString stringWithFormat:@"%@", messageModel.returnObj];
                _IPWriteToEnvironmentPool(ret, space, key);
            }
        }
        // TODO: variable scope
        if (messageModel.isWhileSnippet) {
            BOOL condition = _IPCondition(ret, [args copy]);
            BOOL shouldBreak = NO;
            _IPWriteToEnvironmentPool(@(shouldBreak), space, @"_breakWhile");
            while (condition && !shouldBreak) {
                _IPInnerMessageImp(_self, selector, invocation, clazz, method, whileArg);
                shouldBreak = [_IPReadFromEnvironmentPool(space, @"_breakWhile") boolValue];
            }
        }
        else if (messageModel.isIfSnippet) {
            BOOL condition = _IPCondition(ret, [args copy]);
            if (condition) {
                _IPInnerMessageImp(_self, selector, invocation, clazz, method, ifArg);
            }
            else {
                _IPInnerMessageImp(_self, selector, invocation, clazz, method, elseArg);
            }
        }
        else if (messageModel.isReturnSnippet) {
            void *returnValue = NULL;
            id arg = args.firstObject;
            if (ret) {
                arg = ret;
            }
            UnPack(arg, returnValue);
            if (returnValue) {
                [invocation setReturnValue:returnValue];
            }
        }
        else {
            // TODO: support more keyword here
        }
    }
}

static NSMethodSignature * _IPBlockSignature(id block) {
    struct IPBlockLayout *bp = (__bridge struct IPBlockLayout *)block;
    if (bp && (bp->flags & IP_BLOCK_HAS_SIGNATURE)) {
        void *signatureLocation = bp->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (bp->flags & IP_BLOCK_HAS_COPY_DISPOSE) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        const char *signature = (*(const char **)signatureLocation);
        NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:signature];
        return blockSignature;
    }
    return nil;
}

static BOOL _IPCondition(IPBasicTypeWrapper *ret, NSArray *args) {
    BOOL condition = NO;
    if ([ret isKindOfClass:[IPBasicTypeWrapper class]]) {
        condition = [ret.numberValue boolValue];
    }
    else {
        BOOL c = YES;
        for (IPBasicTypeWrapper *obj in args) {
            c = c && [obj.numberValue boolValue];
        }
        condition = c;
    }
    return condition;
}

static void _IPBlockImp(__weak id _self, SEL selector, NSInvocation *invocation, IPIntructionClassModel *clazz, IPIntructionMethodModel *method, IPIntructionArgumentModel *arg, NSString *key, int c, void *p0, void *p1, void *p2, void *p3) {
    NSString *space = [NSString stringWithFormat:@"%@_%@", clazz.cls, method.method];
    for (int i = 0; i<c; i++) {
        id ret = nil;
        void *p = NULL;
        if (i==0)      p = p0;
        else if (i==1) p = p1;
        else if (i==2) p = p2;
        else if (i==3) p = p3;
        NSString *argClsStr =arg.blockParameterTypes[i];
        NSString *innerKey = [key stringByAppendingString:[NSString stringWithFormat:@"_%d", i]];
        Class argCls = NSClassFromString(argClsStr);
        if (argCls) {
            ret = (__bridge id)p;
        }
        else {
            Class wapperCls = [blockParameterWapperMap objectForKey:argClsStr];
            if ([wapperCls conformsToProtocol:@protocol(IPBlockBasicTypeWapper)]) {
                ret = [wapperCls generateWapper:p];
            }
        }
        _IPWriteToEnvironmentPool(ret, space, innerKey);
    }
    
    IPIntructionMethodModel *m = [IPIntructionMethodModel new];
    m.messages = arg.innerMessage;
    m.method = method.method;
    m.isStatic = method.isStatic;
    _IPExecuteMessage(_self, selector, invocation, clazz, m);
    _IPReduceEnvironmentPoolRefCount(space);
}

static void _IPInnerMessageImp(__weak id _self, SEL selector, NSInvocation *invocation, IPIntructionClassModel *clazz, IPIntructionMethodModel *method, IPIntructionArgumentModel *arg) {
    IPIntructionMethodModel *m = [IPIntructionMethodModel new];
    m.messages = arg.innerMessage;
    m.method = method.method;
    m.isStatic = method.isStatic;
    _IPExecuteMessage(_self, selector, invocation, clazz, m);
}

static id _IPInvoke(SEL selector, id target, BOOL isStatic, NSArray *args) {
    Method method;
    if (isStatic) {
        method = class_getClassMethod([target class], selector);
    }
    else {
        method = class_getInstanceMethod([target class], selector);
    }
    if (!target || !method) {
        return nil;
    }
    if (![target respondsToSelector:selector]) {
        return nil;
    }
    const char * objcTypes = method_getTypeEncoding(method);
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:objcTypes];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = selector;
    invocation.target = target;
    int i = 2;
    for (id arg in args) {
        void *valuePoint = NULL;
        if ([arg conformsToProtocol:@protocol(IPBlockBasicTypeWapper)]) {
            id<IPBlockBasicTypeWapper> obj = (id<IPBlockBasicTypeWapper>)arg;
            valuePoint = [obj valuePoint];
            [invocation setArgument:valuePoint atIndex:i];
        }
        else {
            UnPack(arg, valuePoint);
            [invocation setArgument:valuePoint atIndex:i];
        }
        i++;
    }
    [invocation invoke];
    return _IPGetReturnValue(invocation, signature);
}

static id _IPGetReturnValue(NSInvocation *invocation, NSMethodSignature *signature) {
    const char *returnType = signature.methodReturnType;
    id returnValue;
    if (!strcmp(returnType, @encode(void))) {
        returnValue =  nil;
    }
    else if (!strncmp(returnType, @encode(id), 1) || !strncmp(returnType, @encode(Class), 1)) {
        // avoid double release
        void *result;
        [invocation getReturnValue:&result];
        returnValue = (__bridge id)result;
    }
    else {
        returnValue = _IPGetObjectFromInvocation(returnType, invocation, true, 0);
    }
    return returnValue;
}

static id _IPGetObjectFromInvocation(const char *type, NSInvocation *invocation, BOOL isReturnValue, int idx) {
    id returnValue = nil;
    IPBasicTypeWrapper *upn = [IPBasicTypeWrapper new];
    upn.encode = type;
#define GET_VALUE \
if (isReturnValue) { \
    [invocation getReturnValue:&ret]; \
} \
else { \
    [invocation getArgument:&ret atIndex:idx]; \
}
    if (INT_TYPE(type)) {
        int ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithInt:ret];
        returnValue = upn;
    }
    else if (BOOL_TYPE(type)) {
        BOOL ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithBool:ret];
        returnValue = upn;
    }
    else if (UNSIGNED_INT_TYPE(type)) {
        unsigned int ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithInt:ret];
        returnValue = upn;
    }
    else if (LONG_TYPE(type)) {
        long ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithLong:ret];
        returnValue = upn;
    }
    else if (UNSIGNED_LONG_TYPE(type)) {
        unsigned long ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithUnsignedLong:ret];
        returnValue = upn;
    }
    else if (LONG_LONG_TYPE(type)) {
        long long ret;
        [invocation getReturnValue:&ret];
        upn.numberValue = [NSNumber numberWithLongLong:ret];
        returnValue = upn;
    }
    else if (UNSIGNED_LONG_LONG_TYPE(type)) {
        unsigned long long ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithUnsignedLongLong:ret];
        returnValue = upn;
    }
    else if (DOUBLE_TYPE(type)) {
        double ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithDouble:ret];
        returnValue = upn;
    }
    else if (FLOAT_TYPE(type)) {
        float ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithFloat:ret];
        returnValue = upn;
    }
    else if (SHORT_TYPE(type)) {
        short ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithShort:ret];
        returnValue = upn;
    }
    else if (UNSIGNED_SHORT_TYPE(type)) {
        unsigned short ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithUnsignedShort:ret];
        returnValue = upn;
    }
    else if (CHAR_TYPE(type)) {
        char ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithChar:ret];
        returnValue = upn;
    }
    else if (UNSIGNED_CHAR_TYPE(type)) {
        unsigned char ret;
        GET_VALUE;
        upn.numberValue = [NSNumber numberWithUnsignedChar:ret];
        returnValue = upn;
    }
    else if (OBJECT_TYPE(type)) {
        void *ret;
        GET_VALUE;
        returnValue = (__bridge id)ret;
    }
    // because the `CGRect` type contains `CGPoint\CGSize`, this case should be in front of CGPoint\CGSize
    else if (CGRECT_TYPE(type)) {
        CGRect ret;
        GET_VALUE;
        upn.structValue = [NSValue valueWithCGRect:ret];
        returnValue = upn;
    }
    else if (CGPOINT_TYPE(type)) {
        CGPoint ret;
        GET_VALUE;
        upn.structValue = [NSValue valueWithCGPoint:ret];
        returnValue = upn;
    }
    else if (CGSIZE_TYPE(type)) {
        CGSize ret;
        GET_VALUE;
        upn.structValue = [NSValue valueWithCGSize:ret];
        returnValue = upn;
    }
    else if (NSRANGE_TYPE(type)) {
        NSRange ret;
        GET_VALUE;
        upn.structValue = [NSValue valueWithRange:ret];
        returnValue = upn;
    }
#undef GET_VALUE
    return returnValue;
}

static void _IPWriteToEnvironmentPool(id obj, NSString *space, NSString *key) {
    if (obj && key && space) {
        NSMutableDictionary *spaceObj = [environmentPool objectForKey:space];
        if (!spaceObj) {
            spaceObj = @{}.mutableCopy;
            [environmentPool setObject:spaceObj forKey:space];
        }
        [spaceObj setObject:obj forKey:key];
    }
}

static id _IPReadFromEnvironmentPool(NSString *space, NSString *key) {
    if (space && key) {
        return [[environmentPool objectForKey:space] objectForKey:key];
    }
    return nil;
}

static BOOL _IPContainsObjectInSpace(NSString *space, NSString *key) {
    if (space && key) {
        NSMutableDictionary *spaceObj = [environmentPool objectForKey:space];
        return [spaceObj.allKeys containsObject:key];
    }
    return NO;
}

static void _IPAddEnvironmentPoolRefCount(NSString *space) {
    NSNumber *count = _IPReadFromEnvironmentPool(space, @"_refCount");
    if (!count) {
        count = @(1);
    }
    else {
        NSInteger c = count.integerValue+1;
        count = [NSNumber numberWithInteger:c];
    }
    _IPWriteToEnvironmentPool(count, space, @"_refCount");
}

static void _IPReduceEnvironmentPoolRefCount(NSString *space) {
    NSNumber *count = _IPReadFromEnvironmentPool(space, @"_refCount");
    if (!count) {
        [environmentPool removeObjectForKey:space];
    }
    else {
        NSInteger c = count.integerValue-1;
        if (c <= 0) {
            [environmentPool removeObjectForKey:space];
        }
        else {
            count = [NSNumber numberWithInteger:c];
            _IPWriteToEnvironmentPool(count, space, @"_refCount");
        }
    }
}

@end
