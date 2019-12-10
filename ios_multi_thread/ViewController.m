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

@property (nonatomic, assign) NSInteger tickets;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"iOS 多线程";
    
    self.dataSourceArray = @[
        @{
            @"title":@"GCD",
            @"list":@[
                    @"串行队列-创建串行队列",
                    @"并行队列-获取系统系统的并行队列",
                    @"并行队列-创建并行队列",
                    @"获取主线程【队列】",
                    @"同步添加任务到主队列",
                    @"异步添加任务到主队列",
            ]
        }
        ,
        @{
            @"title":@"NSOperation",
            @"list":@[
                    @"NSOperation",
            ],
        },
        
        @{
            @"title":@"NSThread",
            @"list":@[
                    @"类方法创建-block",
                    @"类方法创建-selector",
                    @"实例方法创建",
                    @"退出线程",
                    @"线程同步-卖票问题",
                    @"线程同步-卖票问题-加锁",
                    @"线程同步-卖票问题-加锁优化-@sync",
                    @"线程同步-卖票问题-加锁优化-NSLock",
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


- (void)test_0_4 {
    NSLog(@"1");
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"2");
    });
    NSLog(@"3");
    
    /*
     Thread 1: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)
     
     同步添加任务到主队列会发生死锁。主队列是串行队列。同步执行。
     */
}

- (void)test_0_5 {
    /*
    2019-12-09 19:23:43.230735+0800 ios_multi_thread[10454:681091] 1
    2019-12-09 19:23:43.230969+0800 ios_multi_thread[10454:681091] 3
    2019-12-09 19:23:43.231978+0800 ios_multi_thread[10454:681897] 2
    */
    NSLog(@"1");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"2");
    });
    NSLog(@"3");
}


- (void)test_2_0 {
    /*
    2019-12-09 19:23:43.230735+0800 ios_multi_thread[10454:681091] 1
    2019-12-09 19:23:43.230969+0800 ios_multi_thread[10454:681091] 3
    2019-12-09 19:23:43.231978+0800 ios_multi_thread[10454:681897] 2
    */
    NSLog(@"1");
    [NSThread detachNewThreadWithBlock:^{
        NSLog(@"2");
    }];
    NSLog(@"3");
}

- (void)test_2_1 {
    /*
     2019-12-09 19:23:43.230735+0800 ios_multi_thread[10454:681091] 1
     2019-12-09 19:23:43.230969+0800 ios_multi_thread[10454:681091] 3
     2019-12-09 19:23:43.231978+0800 ios_multi_thread[10454:681897] 2
     */
    NSLog(@"1");
    [NSThread detachNewThreadSelector:@selector(log2) toTarget:self withObject:nil];
    NSLog(@"3");
}

- (void)log2 {
    NSLog(@"2");
}

- (void)test_2_2 {
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i<5; i++) {
            NSLog(@"%td",i);
            [NSThread sleepForTimeInterval:1];
        }
    }];
    
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        for (int i = 97; i<102; i++) {
            NSLog(@"%c",i);
            [NSThread sleepForTimeInterval:1];
        }
    }];
    
    [thread start];
 
    /*
     完全异步的两个线程
     
     2019-12-09 19:27:48.932318+0800 ios_multi_thread[10563:689707] 0
     2019-12-09 19:27:48.932367+0800 ios_multi_thread[10563:689708] a
     2019-12-09 19:27:49.936671+0800 ios_multi_thread[10563:689707] 1
     2019-12-09 19:27:49.936671+0800 ios_multi_thread[10563:689708] b
     2019-12-09 19:27:50.939938+0800 ios_multi_thread[10563:689707] 2
     2019-12-09 19:27:50.939927+0800 ios_multi_thread[10563:689708] c
     2019-12-09 19:27:51.942780+0800 ios_multi_thread[10563:689708] d
     2019-12-09 19:27:51.942780+0800 ios_multi_thread[10563:689707] 3
     2019-12-09 19:27:52.947346+0800 ios_multi_thread[10563:689708] e
     2019-12-09 19:27:52.947455+0800 ios_multi_thread[10563:689707] 4
     */
}

- (void)test_2_3 {
    [NSThread detachNewThreadWithBlock:^{
        for (NSInteger i = 0; i<5; i++) {
            NSLog(@"%td",i);
            if (i == 2) {
                [NSThread exit];
            }
            [NSThread sleepForTimeInterval:1];
        }
    }];
    
 
    /*
     2019-12-09 19:38:05.178310+0800 ios_multi_thread[10674:703735] 0
     2019-12-09 19:38:06.181506+0800 ios_multi_thread[10674:703735] 1
     2019-12-09 19:38:07.186879+0800 ios_multi_thread[10674:703735] 2
     */
}


- (void)test_2_4 {
 
    //初始有20张票
    self.tickets = 20;

    //创建两个线程来充当两个售票员
    [NSThread detachNewThreadWithBlock:^{
        while (self.tickets > 0) {
            [NSThread sleepForTimeInterval:1];
            self.tickets --;
            NSLog(@"还有%ld张票",(long)self.tickets);
        }
    }];
    [NSThread detachNewThreadWithBlock:^{
        while (self.tickets > 0) {
            [NSThread sleepForTimeInterval:1];
            self.tickets --;
            NSLog(@"还有%ld张票",(long)self.tickets);
        }
    }];

    
    /*
     一共花了10秒
     
     2019-12-09 19:44:18.338057+0800 ios_multi_thread[10758:713806] 还有19张票
     2019-12-09 19:44:18.338057+0800 ios_multi_thread[10758:713807] 还有19张票
     2019-12-09 19:44:19.341248+0800 ios_multi_thread[10758:713807] 还有17张票
     2019-12-09 19:44:19.341272+0800 ios_multi_thread[10758:713806] 还有18张票
     2019-12-09 19:44:20.346704+0800 ios_multi_thread[10758:713806] 还有15张票
     2019-12-09 19:44:20.346704+0800 ios_multi_thread[10758:713807] 还有16张票
     2019-12-09 19:44:21.348273+0800 ios_multi_thread[10758:713807] 还有13张票
     2019-12-09 19:44:21.348273+0800 ios_multi_thread[10758:713806] 还有14张票
     2019-12-09 19:44:22.353256+0800 ios_multi_thread[10758:713806] 还有12张票
     2019-12-09 19:44:22.353256+0800 ios_multi_thread[10758:713807] 还有11张票
     2019-12-09 19:44:23.357181+0800 ios_multi_thread[10758:713807] 还有9张票
     2019-12-09 19:44:23.357181+0800 ios_multi_thread[10758:713806] 还有10张票
     2019-12-09 19:44:24.358080+0800 ios_multi_thread[10758:713807] 还有8张票
     2019-12-09 19:44:24.358080+0800 ios_multi_thread[10758:713806] 还有8张票
     2019-12-09 19:44:25.362820+0800 ios_multi_thread[10758:713806] 还有7张票
     2019-12-09 19:44:25.362820+0800 ios_multi_thread[10758:713807] 还有7张票
     2019-12-09 19:44:26.364486+0800 ios_multi_thread[10758:713806] 还有6张票
     2019-12-09 19:44:26.364484+0800 ios_multi_thread[10758:713807] 还有5张票
     2019-12-09 19:44:27.368494+0800 ios_multi_thread[10758:713807] 还有3张票
     2019-12-09 19:44:27.368494+0800 ios_multi_thread[10758:713806] 还有4张票
     2019-12-09 19:44:28.369758+0800 ios_multi_thread[10758:713807] 还有2张票
     2019-12-09 19:44:28.369758+0800 ios_multi_thread[10758:713806] 还有2张票
     2019-12-09 19:44:29.371176+0800 ios_multi_thread[10758:713806] 还有1张票
     2019-12-09 19:44:29.371176+0800 ios_multi_thread[10758:713807] 还有0张票
     */
}


- (void)test_2_5 {
 
    //初始有20张票
    self.tickets = 20;

    //创建两个线程来充当两个售票员
    [NSThread detachNewThreadWithBlock:^{
        @synchronized (self) {
            while (self.tickets > 0) {
                [NSThread sleepForTimeInterval:1];
                self.tickets --;
                NSLog(@"还有%ld张票",(long)self.tickets);
            }
        }
    }];
    [NSThread detachNewThreadWithBlock:^{
        @synchronized (self) {
            while (self.tickets > 0) {
                [NSThread sleepForTimeInterval:1];
                self.tickets --;
                NSLog(@"还有%ld张票",(long)self.tickets);
            }
        }
    }];

    
    /*
     一共花了20秒
     
     2019-12-09 19:50:17.696865+0800 ios_multi_thread[10828:722053] 还有19张票
     2019-12-09 19:50:18.698891+0800 ios_multi_thread[10828:722053] 还有18张票
     2019-12-09 19:50:19.703745+0800 ios_multi_thread[10828:722053] 还有17张票
     2019-12-09 19:50:20.706849+0800 ios_multi_thread[10828:722053] 还有16张票
     2019-12-09 19:50:21.712073+0800 ios_multi_thread[10828:722053] 还有15张票
     2019-12-09 19:50:22.716613+0800 ios_multi_thread[10828:722053] 还有14张票
     2019-12-09 19:50:23.720630+0800 ios_multi_thread[10828:722053] 还有13张票
     2019-12-09 19:50:24.726039+0800 ios_multi_thread[10828:722053] 还有12张票
     2019-12-09 19:50:25.731539+0800 ios_multi_thread[10828:722053] 还有11张票
     2019-12-09 19:50:26.732603+0800 ios_multi_thread[10828:722053] 还有10张票
     2019-12-09 19:50:27.733891+0800 ios_multi_thread[10828:722053] 还有9张票
     2019-12-09 19:50:28.739311+0800 ios_multi_thread[10828:722053] 还有8张票
     2019-12-09 19:50:29.744752+0800 ios_multi_thread[10828:722053] 还有7张票
     2019-12-09 19:50:30.749186+0800 ios_multi_thread[10828:722053] 还有6张票
     2019-12-09 19:50:31.754605+0800 ios_multi_thread[10828:722053] 还有5张票
     2019-12-09 19:50:32.760014+0800 ios_multi_thread[10828:722053] 还有4张票
     2019-12-09 19:50:33.765474+0800 ios_multi_thread[10828:722053] 还有3张票
     2019-12-09 19:50:34.765782+0800 ios_multi_thread[10828:722053] 还有2张票
     2019-12-09 19:50:35.770490+0800 ios_multi_thread[10828:722053] 还有1张票
     2019-12-09 19:50:36.773979+0800 ios_multi_thread[10828:722053] 还有0张票
     */
}

- (void)test_2_6 {
 
    //初始有20张票
    self.tickets = 20;

    //创建两个线程来充当两个售票员
    [NSThread detachNewThreadWithBlock:^{
    while (true) {
        [NSThread sleepForTimeInterval:1];
            @synchronized (self) {
                self.tickets --;
                    if (self.tickets <= 0) {
                        break;
                    }
                    
                NSLog(@"还有%ld张票",(long)self.tickets);
            }
        }
    }];
    [NSThread detachNewThreadWithBlock:^{
        while (true) {
            [NSThread sleepForTimeInterval:1];
            @synchronized (self) {
            self.tickets --;
                if (self.tickets <= 0) {
                    break;
                }
                NSLog(@"还有%ld张票",(long)self.tickets);
            }
        }
    }];

    /*
     一共花了10秒
     
     2019-12-09 19:56:09.869978+0800 ios_multi_thread[10926:731995] 还有19张票
     2019-12-09  19:56:09.870196+0800 ios_multi_thread[10926:731996] 还有18张票
     2019-12-09 19:56:10.871314+0800 ios_multi_thread[10926:731996] 还有17张票
     2019-12-09 19:56:10.871530+0800 ios_multi_thread[10926:731995] 还有16张票
     2019-12-09 19:56:11.876755+0800 ios_multi_thread[10926:731996] 还有15张票
     2019-12-09 19:56:11.876973+0800 ios_multi_thread[10926:731995] 还有14张票
     2019-12-09 19:56:12.881562+0800 ios_multi_thread[10926:731996] 还有13张票
     2019-12-09 19:56:12.882163+0800 ios_multi_thread[10926:731995] 还有12张票
     2019-12-09 19:56:13.881946+0800 ios_multi_thread[10926:731996] 还有11张票
     2019-12-09 19:56:13.882402+0800 ios_multi_thread[10926:731995] 还有10张票
     2019-12-09 19:56:14.886758+0800 ios_multi_thread[10926:731995] 还有9张票
     2019-12-09 19:56:14.887024+0800 ios_multi_thread[10926:731996] 还有8张票
     2019-12-09 19:56:15.891519+0800 ios_multi_thread[10926:731995] 还有7张票
     2019-12-09 19:56:15.891824+0800 ios_multi_thread[10926:731996] 还有6张票
     2019-12-09 19:56:16.892027+0800 ios_multi_thread[10926:731996] 还有5张票
     2019-12-09 19:56:16.892438+0800 ios_multi_thread[10926:731995] 还有4张票
     2019-12-09 19:56:17.895495+0800 ios_multi_thread[10926:731996] 还有3张票
     2019-12-09 19:56:17.895726+0800 ios_multi_thread[10926:731995] 还有2张票
     2019-12-09 19:56:18.900948+0800 ios_multi_thread[10926:731996] 还有1张票
     */
}


- (void)test_2_7 {
    self.lock = [NSLock new];
    //初始有20张票
    self.tickets = 20;
    
    //创建两个线程来充当两个售票员
    [NSThread detachNewThreadWithBlock:^{
        while (true) {
            [NSThread sleepForTimeInterval:1];
            [self.lock lock];
            self.tickets --;
            if (self.tickets <= 0) {
                break;
            }
            NSLog(@"还有%ld张票",(long)self.tickets);
            [self.lock unlock];
        }
    }];
    
    [NSThread detachNewThreadWithBlock:^{
        while (true) {
            [NSThread sleepForTimeInterval:1];
            [self.lock lock];
            self.tickets --;
            if (self.tickets <= 0) {
                break;
            }
            NSLog(@"还有%ld张票",(long)self.tickets);
            [self.lock unlock];
        }
    }];
    /*
     一共花了10秒
     2019-12-09 19:56:09.869978+0800 ios_multi_thread[10926:731995] 还有19张票
     2019-12-09  19:56:09.870196+0800 ios_multi_thread[10926:731996] 还有18张票
     2019-12-09 19:56:10.871314+0800 ios_multi_thread[10926:731996] 还有17张票
     2019-12-09 19:56:10.871530+0800 ios_multi_thread[10926:731995] 还有16张票
     2019-12-09 19:56:11.876755+0800 ios_multi_thread[10926:731996] 还有15张票
     2019-12-09 19:56:11.876973+0800 ios_multi_thread[10926:731995] 还有14张票
     2019-12-09 19:56:12.881562+0800 ios_multi_thread[10926:731996] 还有13张票
     2019-12-09 19:56:12.882163+0800 ios_multi_thread[10926:731995] 还有12张票
     2019-12-09 19:56:13.881946+0800 ios_multi_thread[10926:731996] 还有11张票
     2019-12-09 19:56:13.882402+0800 ios_multi_thread[10926:731995] 还有10张票
     2019-12-09 19:56:14.886758+0800 ios_multi_thread[10926:731995] 还有9张票
     2019-12-09 19:56:14.887024+0800 ios_multi_thread[10926:731996] 还有8张票
     2019-12-09 19:56:15.891519+0800 ios_multi_thread[10926:731995] 还有7张票
     2019-12-09 19:56:15.891824+0800 ios_multi_thread[10926:731996] 还有6张票
     2019-12-09 19:56:16.892027+0800 ios_multi_thread[10926:731996] 还有5张票
     2019-12-09 19:56:16.892438+0800 ios_multi_thread[10926:731995] 还有4张票
     2019-12-09 19:56:17.895495+0800 ios_multi_thread[10926:731996] 还有3张票
     2019-12-09 19:56:17.895726+0800 ios_multi_thread[10926:731995] 还有2张票
     2019-12-09 19:56:18.900948+0800 ios_multi_thread[10926:731996] 还有1张票
     */
}


@end
