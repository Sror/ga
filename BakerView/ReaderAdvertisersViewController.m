//
//  ReaderAdvertisersViewController.m
//  General Aviation
//
//  Created by Alex Burov on 1/7/15.
//
//

#import "ReaderAdvertisersViewController.h"

@interface ReaderAdvertisersViewController ()
@property (strong, nonatomic) UIView *toolBar;
@end

@implementation ReaderAdvertisersViewController

#pragma mark - Constants

#define TOOLBAR_HEIGHT 50.0f
#define BUTTON_HEIGHT 40.0f
#define BUTTON_WIDTH 40.0f
#define STATUS_HEIGHT 20.0f


- (instancetype)initWithPathToAds:(NSURL *)path
{
    self = [super init];
    if (self) {
        
        NSString *pathToAds = [[[path path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ads.html"];
        NSURL *url = [NSURL fileURLWithPath:pathToAds];
        self.request = [NSURLRequest requestWithURL:url];
        
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, TOOLBAR_HEIGHT + STATUS_HEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - 40)];
    
    [self.webView loadRequest:self.request];
    
    [self.view addSubview:self.webView];
    
    self.toolBar = [[UIView alloc]initWithFrame:CGRectMake(0, STATUS_HEIGHT, CGRectGetWidth(self.view.bounds), TOOLBAR_HEIGHT)];
    self.toolBar.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0f];
    [self.view addSubview:self.toolBar];
    
    UIButton *disMissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    disMissButton.frame = CGRectMake(5, 5, BUTTON_WIDTH, BUTTON_HEIGHT);
    disMissButton.backgroundColor = [UIColor blackColor];
    [disMissButton addTarget:self action:@selector(disMissButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    disMissButton.titleLabel.text = @"Back";
    [self.toolBar addSubview:disMissButton];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(CGRectGetWidth(self.toolBar.bounds) - BUTTON_WIDTH - 5, 5, BUTTON_WIDTH, BUTTON_HEIGHT);
    backButton.backgroundColor = [UIColor greenColor];
    [backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    backButton.titleLabel.text = @"Back";
    [self.toolBar addSubview:backButton];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    self.webView = nil;
}

#pragma mark - Actions

- (void)disMissButtonAction:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)backButtonAction:(UIButton *)sender{
    [self.webView loadRequest:self.request];
    [self.webView reload];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
