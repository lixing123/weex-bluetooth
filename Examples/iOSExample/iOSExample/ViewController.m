//
//  ViewController.m
//  iOSExample
//
//  Created by 李 行 on 17/05/2017.
//  Copyright © 2017 lixing123.com. All rights reserved.
//

#import "ViewController.h"
#import <WeexSDK/WeexSDK.h>

@interface ViewController ()

@property(nonatomic,strong)WXSDKInstance *instance;
@property(nonatomic,strong)UIView *weexView;
@property(nonatomic,strong)NSURL *url;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.instance = [[WXSDKInstance alloc] init];
    self.instance.viewController = self;
    self.instance.frame = self.view.frame;
    
    __weak typeof(self) weakSelf = self;
    self.instance.onCreate = ^(UIView *view) {
        NSLog(@"on create");
        weakSelf.weexView = view;
        [weakSelf.weexView removeFromSuperview];
        [weakSelf.view addSubview:weakSelf.weexView];
    };
    
    self.instance.onFailed = ^(NSError *error) {
        NSLog(@"on failed");
        NSLog(@"error:%@", error);
    };
    
    self.instance.renderFinish = ^(UIView *view) {
        NSLog(@"render finish");
    };
    
    //下面是错误的，会导致error
    //NSString *pathString = [[NSBundle mainBundle] pathForResource:@"weex" ofType:@"js"];
    NSString *pathString = [NSString stringWithFormat:@"file://%@",[[NSBundle mainBundle] pathForResource:@"weex-bluetooth" ofType:@"js"]];
    self.url = [NSURL URLWithString:pathString];
    [self.instance renderWithURL:self.url options:@{@"bundleUrl":[self.url absoluteString]} data:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
