//
//  IPCustomPatchModel.m
//  InstructionPatch_Example
//
//  Created by shouye on 3/10/18.
//  Copyright © 2018 intMax. All rights reserved.
//

#import "IPCustomPatchModel.h"

@implementation IPCustomArgumentModel
@IPIntructionArgumentModelPropertySynthesize

+ (Class)classForCollectionProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"innerMessage"]) {
        return [IPCustomMessageModel class];
    }
    return [super classForCollectionProperty:propertyName];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
@implementation IPCustomMessageModel
@IPIntructionMessageModelProtocolPropertySynthesize

+ (Class)classForCollectionProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"args"]) {
        return [IPCustomArgumentModel class];
    }
    return [super classForCollectionProperty:propertyName];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
@implementation IPCustomMethodModel
@IPIntructionMethodModelPropertySynthesize

+ (Class)classForCollectionProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"messages"]) {
        return [IPCustomMessageModel class];
    }
    return [super classForCollectionProperty:propertyName];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation IPCustomClassModel
@IPIntructionClassModelPropertySynthesize

+ (Class)classForCollectionProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"methodList"]) {
        return [IPCustomMethodModel class];
    }
    return [super classForCollectionProperty:propertyName];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end


@implementation IPCustomPatchModel
@IPIntructionModelPropertySynthesize

+ (Class)classForCollectionProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"instructions"]) {
        return [IPCustomClassModel class];
    }
    return [super classForCollectionProperty:propertyName];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
