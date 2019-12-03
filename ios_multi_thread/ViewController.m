//
//  ViewController.m
//  ios_multi_thread
//
//  Created by 丁玉松 on 2019/12/3.
//  Copyright © 2019 丁玉松. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSArray *dataSourceArray;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.dataSourceArray = @[
    @"正常对象方法执行",
    @"nil对象方法执行",
    @"消息转发机制-resolveInstanceMethod",
    @"消息转发机制-forwardingTargetForSelector",
    @"消息转发机制-forwardInvocation",
    @"消息转发机制-doesNotRecognizeSelector",
    ];
    
    self.tableView.tableFooterView = [UIView new];
}


#pragma mark -  tableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSourceArray.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (nil == cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    }
    NSString *text = [self.dataSourceArray objectAtIndex:indexPath.row];
    cell.textLabel.text = text;
    cell.textLabel.font = [UIFont systemFontOfSize:13];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        {
            DYSDog *dog = [DYSDog new];
            [dog dys_run];
        }
            break;
        case 1:
        {
            DYSDog *dog = nil;
            [dog dys_run];
        }
            break;
        case 2:
        {
            DYSDog *dog = [DYSDog new];
            [dog performSelector:@selector(wagDogTail)];
        }
            break;
        case 3:
        {
            DYSDog *dog = [DYSDog new];
            [dog performSelector:@selector(climbTree)];
        }
            break;
        case 4:
        {
            DYSDog *dog = [DYSDog new];
            [dog performSelector:@selector(playAlone)];
        }
            break;
        case 5:
        {
            DYSDog *dog = [DYSDog new];
            [dog performSelector:@selector(playWithPeople)];
        }
            break;
            
        default:
            break;
    }
}


@end
