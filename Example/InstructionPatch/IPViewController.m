//
//  IPViewController.m
//  InstructionPatch
//
//  Created by intMax on 03/10/2018.
//  Copyright (c) 2018 intMax. All rights reserved.
//

#define MyLog(frmt, ...) do{ \
NSString *_string_ = [NSString stringWithFormat:(@"🌹[Patch Example] "frmt@"\n"), ##__VA_ARGS__];\
self.logTextView.text = [self.logTextView.text?:@"" stringByAppendingString:_string_]; \
NSLog(_string_, nil); \
} while(0)


#import "IPViewController.h"

static NSString *globalString = @"";

@interface IPViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@end

@implementation IPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    globalString = @"";
    self.textView.text = self.patchString;
    [self doSomething];
    self.logTextView.text = [self.logTextView.text?:@"" stringByAppendingString:globalString];
}

- (void)doSomething {
    [self buildBlock];
    [self executeObjectParameterBlock:^(NSString *parameter) {
        MyLog(@"executeObjectParameterBlock:%@", parameter);
    }];
    [self executeBasicTypeParameterBlock:^(int parameter) {
        MyLog(@"executeBasicTypeParameterBlock:%d", parameter);
    }];
    [self executeReturnValueBlock:^NSString *(int parameter) {
        return [NSString stringWithFormat:@"executeReturnValueBlock:%d", parameter];
    }];
    [self instanceMethodArg1:@"instanceMethodArg1" arg2:888];
    [IPViewController classMethodArg1:@"classMethodArg1" arg2:666];
}

- (void)buildBlock {
}

- (void)block1:(void(^)(NSString *parameter))block1 block2:(void(^)(NSInteger parameter))block2 {
    block2(666);
    block1(@"build block success");
}

- (void)executeObjectParameterBlock:(void(^)(NSString *parameter))block {
}

- (void)executeBasicTypeParameterBlock:(void(^)(int parameter))block {
}

- (void)executeReturnValueBlock:(NSString *(^)(int parameter))block {
}

- (void)instanceMethodArg1:(NSString *)arg1 arg2:(NSInteger)arg2 {
}

+ (void)classMethodArg1:(NSString *)arg1 arg2:(NSInteger)arg2 {
}

- (void)logWithString:(NSString *)string {
    MyLog(@"logWithString:%@", string);
}

- (void)logWithInteger:(NSInteger)integer {
    MyLog(@"logWithInteger:%ld", integer);
}

+ (void)logWithString:(NSString *)string {
    NSString *logString = [NSString stringWithFormat:@"🌹[Patch Example] %@\n", string];
    globalString = [globalString stringByAppendingString:logString];
    NSLog(logString, nil);
}

+ (void)logWithInteger:(NSInteger)integer {
    NSString *logString = [NSString stringWithFormat:@"🌹[Patch Example] %ld\n", integer];
    globalString = [globalString stringByAppendingString:logString];
    NSLog(logString, nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
