//
//  IPCustomPatchModel.h
//  InstructionPatch_Example
//
//  Created by shouye on 3/10/18.
//  Copyright © 2018 intMax. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import <InstructionPatch/IPIntructionModel.h>

@interface IPCustomArgumentModel : JSONModel<IPIntructionArgumentModelProtocol>
@end
@interface IPCustomMessageModel : JSONModel<IPIntructionMessageModelProtocol>
@end
@interface IPCustomMethodModel : JSONModel<IPIntructionMethodModelProtocol>
@end
@interface IPCustomClassModel : JSONModel<IPIntructionClassModelProtocol>
@end
@interface IPCustomPatchModel : JSONModel<IPIntructionModelProtocol>
@end
