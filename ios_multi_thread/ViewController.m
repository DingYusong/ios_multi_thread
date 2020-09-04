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
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDate *date;


/*
 异步请求回来长宽高算体积
 1.
 dispatch_group_async
 dispatch_group_notify
 
 2.
 dispatch_group_enter
 dispatch_group_leave
 
 dispatch_group_wait
 */
@property (nonatomic ,assign) NSInteger length;
@property (nonatomic ,assign) NSInteger width;
@property (nonatomic ,assign) NSInteger height;
@property (nonatomic, strong) NSThread *thread;

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
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
                    @"1.串行队列-创建串行队列",
                    @"2.并发队列-获取系统的并发队列",
                    @"3.并发队列-创建并发队列",
                    @"4.获取主线程【队列】",
                    @"5.在主线程同步添加任务到主队列-会造成死锁",
                    @"6.异步添加任务到主队列",
                    @"7.串行队列里面添加同步执行任务会造成死锁",
                    
                    @"8.同步执行串行队列",
                    @"9.同步执行并发队列",
                    @"10.异步执行串行队列",
                    @"11.异步执行并发队列",
                    
                    @"12.group-线程同步",
                    @"13.group-dispatch_group_enter线程同步",
                    @"14.控制最大并发数",
                    @"15.dispatch_once",
                    @"16.串行队列先异步后同步",
                    @"17.栅栏函数",
                    @"18.栅栏函数多读",
                    @"19.栅栏函数单写",
                    @"20.信号量加锁",
                    @"21.延时任务执行",
                    @"22.常驻子线程",
            ]
        },
        @{
            @"title":@"NSOperation",
            @"list":@[
                    @"NSBlockOperation",
                    @"NSInvocationOperation",
                    @"NSOperationQueue",
                    @"addDependency-线程同步",
                    @"addDependency-线程同步2"
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

 Concurrent（并发队列） 并发队列，也叫 global dispatch queue，可以并发地执行多个任务，但是任务开始的顺序仍然是按照被添加到队列中的顺序。具体任务执行的线程和任务执行的并发数，都是由 GCD 进行管理的。

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
 并发队列：
 系统默认提供了四个全局可用的并发队列，其优先级不同，分别为 DISPATCH_QUEUE_PRIORITY_HIGH，DISPATCH_QUEUE_PRIORITY_DEFAULT， DISPATCH_QUEUE_PRIORITY_LOW， DISPATCH_QUEUE_PRIORITY_BACKGROUND ，优先级依次降低。优先级越高的队列中的任务会更早执行：
 
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


- (void)test_0_6 {
    /*
     Thread 3: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)
     */

    dispatch_queue_t queue = dispatch_queue_create("com.demo.serialqueue", DISPATCH_QUEUE_SERIAL);
    
    NSLog(@"0");
    dispatch_async(queue, ^{
        
        NSLog(@"1");
        
        dispatch_sync(queue, ^{
            NSLog(@"2");
        });
        
        NSLog(@"3");
    });
    NSLog(@"4");
    
    /*
     2020-09-01 10:14:31.410791+0800 ios_multi_thread[27912:829436] 0
     2020-09-01 10:14:31.411044+0800 ios_multi_thread[27912:829436] 4
     2020-09-01 10:14:31.411065+0800 ios_multi_thread[27912:829602] 1

     分析：
     1. 输出0。
     2. 异步执行，立即返回。
     3. 输出4。
     4. 执行串行队列任务
     如下：
     ^{
         NSLog(@"1");
         dispatch_sync(queue, ^{
             NSLog(@"2");
         });
         NSLog(@"3");
     }
     串行队列的任务按照加入顺序执行，而同步执行是立即执行阻塞线程。形成死锁。
     
     
     */
    
    
}

/// 同步执行串行队列
- (void)test_0_7 {
    dispatch_queue_t queue = dispatch_queue_create("com.demo.myqueue", DISPATCH_QUEUE_SERIAL);
    
    NSLog(@"Start");
    
    for (NSInteger i = 0; i<10; i++) {
        dispatch_sync(queue, ^{
            [NSThread sleepForTimeInterval:1];
            NSLog(@"%tu",i);
        });
    }
    
    NSLog(@"End");
    /*
     2019-12-13 18:18:19.359274+0800 ios_multi_thread[14121:502143] Start
     2019-12-13 18:18:20.360612+0800 ios_multi_thread[14121:502143] 0
     2019-12-13 18:18:21.361990+0800 ios_multi_thread[14121:502143] 1
     2019-12-13 18:18:22.363110+0800 ios_multi_thread[14121:502143] 2
     2019-12-13 18:18:23.364299+0800 ios_multi_thread[14121:502143] 3
     2019-12-13 18:18:24.364771+0800 ios_multi_thread[14121:502143] 4
     2019-12-13 18:18:25.365055+0800 ios_multi_thread[14121:502143] 5
     2019-12-13 18:18:26.366307+0800 ios_multi_thread[14121:502143] 6
     2019-12-13 18:18:27.367616+0800 ios_multi_thread[14121:502143] 7
     2019-12-13 18:18:28.368980+0800 ios_multi_thread[14121:502143] 8
     2019-12-13 18:18:29.370336+0800 ios_multi_thread[14121:502143] 9
     2019-12-13 18:18:29.370518+0800 ios_multi_thread[14121:502143] End
     */
}


/// 同步执行并发队列
- (void)test_0_8 {
    dispatch_queue_t queue = dispatch_queue_create("com.demo.myqueue", DISPATCH_QUEUE_CONCURRENT);
    
    NSLog(@"Start");
    
    for (NSInteger i = 0; i<10; i++) {
        dispatch_sync(queue, ^{
            [NSThread sleepForTimeInterval:1];
            NSLog(@"%tu",i);
        });
    }
    
    NSLog(@"End");
    
    /*
     2019-12-13 18:18:19.359274+0800 ios_multi_thread[14121:502143] Start
     2019-12-13 18:18:20.360612+0800 ios_multi_thread[14121:502143] 0
     2019-12-13 18:18:21.361990+0800 ios_multi_thread[14121:502143] 1
     2019-12-13 18:18:22.363110+0800 ios_multi_thread[14121:502143] 2
     2019-12-13 18:18:23.364299+0800 ios_multi_thread[14121:502143] 3
     2019-12-13 18:18:24.364771+0800 ios_multi_thread[14121:502143] 4
     2019-12-13 18:18:25.365055+0800 ios_multi_thread[14121:502143] 5
     2019-12-13 18:18:26.366307+0800 ios_multi_thread[14121:502143] 6
     2019-12-13 18:18:27.367616+0800 ios_multi_thread[14121:502143] 7
     2019-12-13 18:18:28.368980+0800 ios_multi_thread[14121:502143] 8
     2019-12-13 18:18:29.370336+0800 ios_multi_thread[14121:502143] 9
     2019-12-13 18:18:29.370518+0800 ios_multi_thread[14121:502143] End
     */
}

/// 异步执行串行队列
- (void)test_0_9 {
    dispatch_queue_t queue = dispatch_queue_create("com.demo.myqueue", DISPATCH_QUEUE_SERIAL);
    
    NSLog(@"Start");
    
    for (NSInteger i = 0; i<10; i++) {
        dispatch_async(queue, ^{
            [NSThread sleepForTimeInterval:1];
            NSLog(@"%tu",i);
        });
    }
    
    NSLog(@"End");
    
    /*
     2019-12-13 18:16:52.485461+0800 ios_multi_thread[14121:502143] Start
     2019-12-13 18:16:52.485680+0800 ios_multi_thread[14121:502143] End
     2019-12-13 18:16:53.486886+0800 ios_multi_thread[14121:502317] 0
     2019-12-13 18:16:54.487519+0800 ios_multi_thread[14121:502317] 1
     2019-12-13 18:16:55.489131+0800 ios_multi_thread[14121:502317] 2
     2019-12-13 18:16:56.491174+0800 ios_multi_thread[14121:502317] 3
     2019-12-13 18:16:57.496256+0800 ios_multi_thread[14121:502317] 4
     2019-12-13 18:16:58.496718+0800 ios_multi_thread[14121:502317] 5
     2019-12-13 18:16:59.498078+0800 ios_multi_thread[14121:502317] 6
     2019-12-13 18:17:00.499086+0800 ios_multi_thread[14121:502317] 7
     2019-12-13 18:17:01.499483+0800 ios_multi_thread[14121:502317] 8
     2019-12-13 18:17:02.500397+0800 ios_multi_thread[14121:502317] 9
     */
}


/// 异步执行并发队列
- (void)test_0_10 {
    dispatch_queue_t queue = dispatch_queue_create("com.demo.myqueue", DISPATCH_QUEUE_CONCURRENT);
    
    NSLog(@"Start");
    
    for (NSInteger i = 0; i<50; i++) {
        dispatch_async(queue, ^{
            [NSThread sleepForTimeInterval:1];
            NSLog(@"%tu",i);
            [self test_0_17];
        });
    }
    
    NSLog(@"End");
    
    /*
     2019-12-13 18:17:09.246562+0800 ios_multi_thread[14121:502143] Start
     2019-12-13 18:17:09.246893+0800 ios_multi_thread[14121:502143] End
     2019-12-13 18:17:10.249059+0800 ios_multi_thread[14121:502815] 2
     2019-12-13 18:17:10.249062+0800 ios_multi_thread[14121:502812] 3
     2019-12-13 18:17:10.249059+0800 ios_multi_thread[14121:502817] 1
     2019-12-13 18:17:10.249102+0800 ios_multi_thread[14121:502811] 4
     2019-12-13 18:17:10.249103+0800 ios_multi_thread[14121:502814] 5
     2019-12-13 18:17:10.249102+0800 ios_multi_thread[14121:502816] 0
     2019-12-13 18:17:10.249113+0800 ios_multi_thread[14121:502319] 6
     2019-12-13 18:17:10.249115+0800 ios_multi_thread[14121:502813] 7
     2019-12-13 18:17:10.249116+0800 ios_multi_thread[14121:502317] 8
     2019-12-13 18:17:10.249146+0800 ios_multi_thread[14121:502819] 9
     */
}

/*
 调度组
 */
- (void)test_0_11 {
    //调度组
    dispatch_group_t group = dispatch_group_create();
    
    //全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    
//    NSString *name = nil;
    dispatch_group_async(group, queue, ^{
        [NSThread sleepForTimeInterval:3];
        NSLog(@"任务1");
        self.name = @"任务";
        
        //请求长度
        NSLog(@"长度返回");
        self.length = 10;
        
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"任务2");

        //请求宽度
        NSLog(@"宽度返回");
        self.width = 10;
    });
    dispatch_group_async(group, queue, ^{
        [NSThread sleepForTimeInterval:5];
        NSLog(@"任务3");

        //请求高度
        NSLog(@"高度返回");
        self.height = 10;
    });
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"所有的任务都执行完毕");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"更新UI");
            
            NSLog(@"得到长宽高后计算得到立方体的体积：%ld",self.length*self.width*self.height);
            
        });
    });
    
}

- (void)test_0_12 {
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:3];
        NSLog(@"任务1");
        
        //请求长度
        NSLog(@"长度返回");
        self.length = 10;

        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"任务2");
        
        //请求宽度
        NSLog(@"宽度返回");
        self.width = 10;

        dispatch_group_leave(group);
    });
    
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:5];
        NSLog(@"任务3");

        //请求高度
        NSLog(@"高度返回");
        self.height = 10;

        dispatch_group_leave(group);
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_async(queue, ^{
        NSLog(@"所有的任务都执行完毕");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"更新UI");
            
            NSLog(@"得到长宽高后计算得到立方体的体积：%ld",self.length*self.width*self.height);
        });
    });
}


/// 控制最大并发数
- (void)test_0_13 {
    
    NSLog(@"000");
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
    
    for (NSInteger i = 0; i < 100; i++) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group, queue, ^{
            sleep(2);
            NSLog(@"%tu :%@",i,[NSThread currentThread]);
            dispatch_semaphore_signal(semaphore);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"101");
}

- (void)test_0_14 {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"只执行1次");
    });
    
    NSLog(@"11");
    
    /*
     同步：阻塞主线程
     
     2019-12-16 17:27:12.503707+0800 ios_multi_thread[74576:3092042] 只执行1次
     2019-12-16 17:27:12.503919+0800 ios_multi_thread[74576:3092042] 11
     */
}


- (void)test_0_15 {
    dispatch_queue_t queue = dispatch_queue_create("com.dys.demo", DISPATCH_QUEUE_SERIAL);
    
    NSLog(@"1");
    dispatch_async(queue, ^{
        NSLog(@"2");
    });
    
    NSLog(@"3");
    
    dispatch_sync(queue, ^{
        NSLog(@"4");
    });
    
    NSLog(@"5");
    
}

//栅栏函数
- (void)test_0_16 {
    dispatch_queue_t queue = dispatch_queue_create("com.dys.demo", DISPATCH_QUEUE_CONCURRENT);
    
    for (NSInteger i = 0; i<10; i++) {
        dispatch_sync(queue, ^{
            [NSThread sleepForTimeInterval:0.5];
            NSLog(@"%tu",i);
        });
    }
    
    dispatch_barrier_sync(queue, ^{
        NSLog(@"前面先执行完，执行我   ----  在我后面");
    });
    
//    dispatch_barrier_async(queue, ^{
//        NSLog(@"前面先执行完，执行我   ----  在我前面");
//    });
    
    NSLog(@"-------------");
    
    for (NSInteger i = 10; i<20; i++) {
        dispatch_sync(queue, ^{
            [NSThread sleepForTimeInterval:0.5];
            NSLog(@"%tu",i);
        });
    }
}

-(dispatch_queue_t)queue {
    if (!_queue) {
        dispatch_queue_t queue = dispatch_queue_create("com.dys.demo", DISPATCH_QUEUE_CONCURRENT);
        _queue = queue;
    }
    return _queue;
}

- (dispatch_semaphore_t)semaphore {
    if (!_semaphore) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
        _semaphore = semaphore;
    }
    
    return _semaphore;
}

//栅栏函数读
- (void)test_0_17 {
    
    __block NSString *result;
    dispatch_sync(self.queue, ^{
//        [NSThread sleepForTimeInterval:5];
        
        result = [self valueForKey:@"date"];
    });
    
    NSLog(@"result:%@",result);
}

//栅栏函数写
- (void)test_0_18 {
    
    dispatch_barrier_async(self.queue, ^{
        _date = [NSDate date];
    });
    
}


- (void)test_0_19 {
    
    for (NSInteger i = 0; i<100; i++) {
        dispatch_async(self.queue, ^{
            [self syncTask];
        });
    }
    
    /*
     
     dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
     
     _length++;
     sleep(1);
     
     dispatch_semaphore_signal(_semaphore);
     
     */
}


- (void)test_0_20 {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), self.queue, ^{
        NSLog(@"2秒后打印");
    });
    //其内部使用的是 dispatch_time_t 管理时间，而不是 NSTimer。在指定时间追加处理到 dispatch_queue
    
    dispatch_async(self.queue, ^{
        [self performSelector:@selector(log6) withObject:nil afterDelay:2];
        [[NSRunLoop currentRunLoop] run];
        
//        在子线程中调用performSelector:afterDelay,要开启runloop，而使用dispatch_after 则无需关系runloop
    });

}


#pragma mark - 常驻子线程


- (NSThread *)shareThread {
    static dispatch_once_t onceToken;
    static NSThread *thread = nil;
    
    dispatch_once(&onceToken, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadStart) object:nil];
        [thread setName:@"com.dys.demo"];
        [thread start];
    });
    
    return thread;
}

- (void)threadStart {
    NSLog(@"threadStart");

    //添加runloop后在再次调用即可执行threadTest
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    [runloop addPort:[NSPort port] forMode:NSRunLoopCommonModes];
    [runloop run];
}

- (void)threadTest {
    
    NSLog(@"threadTest");
}

- (void)test_0_21 {
    
    
    [self performSelector:@selector(threadTest) onThread:[self shareThread] withObject:nil waitUntilDone:NO];

    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), self.queue, ^{
//        NSLog(@"2秒后打印");
//    });
//    //其内部使用的是 dispatch_time_t 管理时间，而不是 NSTimer。在指定时间追加处理到 dispatch_queue
//
//    dispatch_async(self.queue, ^{
//        [self performSelector:@selector(log6) withObject:nil afterDelay:2];
//        [[NSRunLoop currentRunLoop] run];
//
////        在子线程中调用performSelector:afterDelay,要开启runloop，而使用dispatch_after 则无需关系runloop
//    });

}



- (void)syncTask {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    _length++;
    sleep(1);
    NSLog(@"_length:%tu",self.length);
    dispatch_semaphore_signal(self.semaphore);
}


- (void)test_1_0 {
    NSLog(@"1%@",[NSThread currentThread]);
    NSBlockOperation *operate = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"2%@",[NSThread currentThread]);
    }];
    NSLog(@"3%@",[NSThread currentThread]);

    NSOperationQueue *queue = [NSOperationQueue new];
    [queue addOperation:operate];
    /*
     2019-12-16 16:08:42.409794+0800 ios_multi_thread[73177:2956105] 1<NSThread: 0x6000022ca140>{number = 1, name = main}
     2019-12-16 16:08:42.410550+0800 ios_multi_thread[73177:2956105] 3<NSThread: 0x6000022ca140>{number = 1, name = main}
     2019-12-16 16:08:42.411184+0800 ios_multi_thread[73177:2956197] 2<NSThread: 0x6000022beac0>{number = 6, name = (null)}
     */
}

- (void)test_1_1 {
    NSLog(@"1%@",[NSThread currentThread]);
    NSInvocationOperation *operate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(test_1_1_selector) object:nil];
    NSLog(@"3%@",[NSThread currentThread]);

    NSOperationQueue *queue = [NSOperationQueue new];
    [queue addOperation:operate];
    /*
     2019-12-16 16:08:51.349342+0800 ios_multi_thread[73177:2956105] 1<NSThread: 0x6000022ca140>{number = 1, name = main}
     2019-12-16 16:08:51.349845+0800 ios_multi_thread[73177:2956105] 3<NSThread: 0x6000022ca140>{number = 1, name = main}
     2019-12-16 16:08:51.351332+0800 ios_multi_thread[73177:2956202] 2<NSThread: 0x6000022be600>{number = 7, name = (null)}
     */
}

- (void)test_1_1_selector {
    NSLog(@"2%@",[NSThread currentThread]);
}

- (void)test_1_2 {
    NSOperationQueue *queue = [NSOperationQueue new];
    [queue addOperationWithBlock:^{
        NSLog(@"执行子任务%@",[NSThread currentThread]);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"更新主线程UI%@",[NSThread currentThread]);
        }];
    }];
}


/// 线程同步
- (void)test_1_3 {
    NSLog(@"任务0%@",[NSThread currentThread]);
    
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        [NSThread sleepForTimeInterval:3];
        NSLog(@"任务1%@",[NSThread currentThread]);
        
        //请求长度
        NSLog(@"长度返回");
        self.length = 10;

    }];
    
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        [NSThread sleepForTimeInterval:1];
        NSLog(@"任务2%@",[NSThread currentThread]);
        
        
        //请求宽度
        NSLog(@"宽度返回");
        self.width = 10;

    }];
    
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        [NSThread sleepForTimeInterval:5];
        NSLog(@"任务3%@",[NSThread currentThread]);
        
        //请求高度
        NSLog(@"高度返回");
        self.width = 10;

    }];
    
    NSBlockOperation *op4 = [NSBlockOperation blockOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"更新主线程UI%@",[NSThread currentThread]);
            
            NSLog(@"得到长宽高后计算得到立方体的体积：%ld",self.length*self.width*self.height);
        }];
    }];
    
    [op4 addDependency:op1];
    [op4 addDependency:op2];
    [op4 addDependency:op3];
    
    NSOperationQueue *queue = [NSOperationQueue new];
//    [queue addOperation:op1];
//    [queue addOperation:op2];
//    [queue addOperation:op3];
    
    [queue addOperations:@[op1,op2,op3,op4] waitUntilFinished:YES];
    
    NSLog(@"任务4%@",[NSThread currentThread]);
    
    /*
     卡主主线程了
     
     2019-12-16 16:30:15.184038+0800 ios_multi_thread[73595:2995480] 任务0<NSThread: 0x600003f94440>{number = 1, name = main}
     2019-12-16 16:30:16.186859+0800 ios_multi_thread[73595:2995674] 任务2<NSThread: 0x600003ffd600>{number = 7, name = (null)}
     2019-12-16 16:30:18.189711+0800 ios_multi_thread[73595:2995619] 任务1<NSThread: 0x600003fa21c0>{number = 6, name = (null)}
     2019-12-16 16:30:20.189257+0800 ios_multi_thread[73595:2996322] 任务3<NSThread: 0x600003ffd480>{number = 8, name = (null)}
     2019-12-16 16:30:20.189590+0800 ios_multi_thread[73595:2995480] 任务4<NSThread: 0x600003f94440>{number = 1, name = main}
     2019-12-16 16:30:20.191507+0800 ios_multi_thread[73595:2995480] 更新主线程UI<NSThread: 0x600003f94440>{number = 1, name = main}
*/
}
- (void)test_1_4 {
    
    NSLog(@"任务0%@",[NSThread currentThread]);

    NSOperationQueue *queue = [NSOperationQueue new];
    [queue addOperationWithBlock:^{
        
        NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
            [NSThread sleepForTimeInterval:3];
            NSLog(@"任务1%@",[NSThread currentThread]);
        }];
        
        NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
            [NSThread sleepForTimeInterval:1];
            NSLog(@"任务2%@",[NSThread currentThread]);
        }];
        
        NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
            [NSThread sleepForTimeInterval:5];
            NSLog(@"任务3%@",[NSThread currentThread]);
        }];
        
        NSOperationQueue *queue2 = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = 5;
        
        [queue2 addOperations:@[op1,op2,op3] waitUntilFinished:YES];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"更新主线程UI%@",[NSThread currentThread]);
        }];
    }];
    
    NSLog(@"任务4%@",[NSThread currentThread]);

    /*
     不会卡主线程
     
     2019-12-16 16:29:47.537824+0800 ios_multi_thread[73595:2995480] 任务0<NSThread: 0x600003f94440>{number = 1, name = main}
     2019-12-16 16:29:47.538394+0800 ios_multi_thread[73595:2995480] 任务4<NSThread: 0x600003f94440>{number = 1, name = main}
     2019-12-16 16:29:48.540179+0800 ios_multi_thread[73595:2995622] 任务2<NSThread: 0x600003fde380>{number = 5, name = (null)}
     2019-12-16 16:29:50.541964+0800 ios_multi_thread[73595:2995619] 任务1<NSThread: 0x600003fa21c0>{number = 6, name = (null)}
     2019-12-16 16:29:52.542651+0800 ios_multi_thread[73595:2995627] 任务3<NSThread: 0x600003fd3d80>{number = 3, name = (null)}
     2019-12-16 16:29:52.542940+0800 ios_multi_thread[73595:2995480] 更新主线程UI<NSThread: 0x600003f94440>{number = 1, name = main}

     */
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

     1. 构造器(类方法)方式创建子线程会自动启动，不需要管理比如：启动和取消。
     2. performSelector方法如果是带 afterDelay 的延时函数，会在内部创建一个 NSTimer，然后添加到当前线程的 Runloop 中。也就是如果当前线程没有开启 runloop，该方法会失效。在子线程中，需要启动 runloop(注意调用顺序)。
     
     + (void)detachNewThreadWithBlock:(void (^)(void))block API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
     + (void)detachNewThreadSelector:(SEL)selector toTarget:(id)target withObject:(nullable id)argument;

     
     */
#if 0
    
    NSLog(@"1");
    [NSThread detachNewThreadSelector:@selector(log2) toTarget:self withObject:nil];
    NSLog(@"3");
    
#endif

    NSLog(@"1");

    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(log2) object:nil];
    
    thread.name = @"com.dys.thread";
    NSLog(@"3");

    [thread start];
    
    NSLog(@"4");
    

//    [thread cancel];
    NSLog(@"5");
    
    
    self.thread = thread;

}

- (void)log6 {
    NSLog(@"6");
}

- (void)log2 {
    NSLog(@"2");
    [self performSelector:@selector(log6) withObject:nil afterDelay:2];
    [[NSRunLoop currentRunLoop] run];
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
