//
//  IPTableViewController.m
//  InstructionPatch_Example
//
//  Created by shouye on 3/10/18.
//  Copyright © 2018 intMax. All rights reserved.
//

#import "IPTableViewController.h"
#import "IPViewController.h"
#import "IPCustomPatchModel.h"
#import <InstructionPatch/IPIntructionPatch.h>

#define MyLog(frmt, ...) do{ NSLog((@"🌹🌹[Patch Example] "frmt), ##__VA_ARGS__); } while(0)

static NSString *kReuseIdentifier = @"_kReuseIdentifier";

@interface IPTableViewController ()

@property (nonatomic, copy) NSArray<NSString *> *dataSource;

@end

@implementation IPTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = @[@"InstanceMethod", @"ClassMethod", @"ExcuteBlock", @"BuildBlock"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kReuseIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kReuseIdentifier];
    }
    cell.textLabel.text = self.dataSource[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [IPIntructionPatch stop];
    NSString *fileName = self.dataSource[indexPath.row];
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:path];
    if (jsonData) {
        NSError *error;
        IPCustomPatchModel *model = [[IPCustomPatchModel alloc] initWithData:jsonData error:&error];
        if (!error) {
            [IPIntructionPatch run:model];
        }
        else {
            MyLog(@"serialize error:%@", error);
            return;
        }
    }
    else {
        MyLog(@"load data error");
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    IPViewController *vc = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([IPViewController class])];
    vc.patchString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
