//
//  IPIntructionPatcher.h
//  InstructionalPatch
//
//  Created by intMax on 12/31/17.
//  Copyright © 2017 intMax. All rights reserved.
//

#import "IPIntructionModel.h"

@interface IPIntructionPatch : NSObject

+ (void)run:(id<IPIntructionModelProtocol>)model;
+ (void)stop;

@end
