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
    self.title = @"iOS 多线程";
    
    self.dataSourceArray = @[@{
                                 @"title":@"GCD",
                                 @"list":@[
                                         @"串行队列-创建串行队列",
                                         @"并行队列-获取系统系统的并行队列",
                                         @"并行队列-创建并行队列",
                                         @"获取主线程【队列】",
                                         @"同步添加任务到主队列",
                                         @"异步添加任务到主队列",
                                 ]
                                 ,
                                 @"title":@"NSOperation",
                                 @"list":@[
                                 ],
                                 @"title":@"NSThread",
                                 @"list":@[
                                 ]
                                 
    }
    ];
    
    self.tableView.tableFooterView = [UIView new];
}


#pragma mark -  tableViewDelegate

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *dict = [self.dataSourceArray objectAtIndex:section];
    NSString *title = [dict objectForKey:@"title"];
    return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSourceArray.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dict = [self.dataSourceArray objectAtIndex:section];
    NSArray *list = [dict objectForKey:@"list"];
    return list.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (nil == cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    }
    NSDictionary *dict = [self.dataSourceArray objectAtIndex:indexPath.section];
    NSArray *list = [dict objectForKey:@"list"];
    cell.textLabel.text = [list objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"test_%td_%td",indexPath.section,indexPath.row]);
    if ([self respondsToSelector:sel]) {
        [self performSelector:sel];
    }
}

/*
 GCD 中的队列有下面三种：

 Serial （串行队列） 串行队列中任务会按照添加到 queue 中的顺序一个一个执行。串行队列在前一个任务执行之前，后一个任务是被阻塞的，可以利用这个特性来进行同步操作。

 我们可以创建多个串行队列，这些队列中的任务是串行执行的，但是这些队列本身可以并发执行。例如有四个串行队列，有可能同时有四个任务在并行执行，分别来自这四个队列。

 Concurrent（并行队列） 并行队列，也叫 global dispatch queue，可以并发地执行多个任务，但是任务开始的顺序仍然是按照被添加到队列中的顺序。具体任务执行的线程和任务执行的并发数，都是由 GCD 进行管理的。

 在 iOS 5 之后，我们可以创建自己的并发队列。系统已经提供了四个全局可用的并发队列，后面会讲到。

 Main Dispatch Queue（主队列） 主队列是一个全局可见的串行队列，其中的任务会在主线程中执行。主队列通过与应用程序的 runloop 交互，把任务安插到 runloop 当中执行。因为主队列比较特殊，其中的任务确定会在主线程中执行，通常主队列会被用作同步的作用。
 */

/*
 串行队列： 系统默认并不提供串行队列，需要我们手动创建
 */
- (void)test_0_0 {
    dispatch_queue_t queue = dispatch_queue_create("com.demo.myqueue", DISPATCH_QUEUE_SERIAL);
    NSLog(@"%@",queue);
}

/*
 并行队列：
 系统默认提供了四个全局可用的并行队列，其优先级不同，分别为 DISPATCH_QUEUE_PRIORITY_HIGH，DISPATCH_QUEUE_PRIORITY_DEFAULT， DISPATCH_QUEUE_PRIORITY_LOW， DISPATCH_QUEUE_PRIORITY_BACKGROUND ，优先级依次降低。优先级越高的队列中的任务会更早执行：
 
 一般情况下我们使用系统提供的 Default 优先级的 queue 就足够了
*/
- (void)test_0_1 {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSLog(@"%@",queue);
}
- (void)test_0_2 {
    dispatch_queue_t queue = dispatch_queue_create("com.demo.myconqueue", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"%@",queue);
}
- (void)test_0_3 {
/*
 Main Dispatch Queue（主队列） 主队列是一个全局可见的串行队列，其中的任务会在主线程中执行。主队列通过与应用程序的 runloop 交互，把任务安插到 runloop 当中执行。因为主队列比较特殊，其中的任务确定会在主线程中执行，通常主队列会被用作同步的作用。

 获取主线程队列。
 */
    dispatch_queue_t queue = dispatch_get_main_queue();
    NSLog(@"%@",queue);

}


- (void)test_0_4 {}

- (void)test_0_5 {}



@end
