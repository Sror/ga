//
//  ReaderAdvertisersViewController.m
//  General Aviation
//
//  Created by Alex Burov on 1/7/15.
//
//

#import "ReaderAdvertisersViewController.h"

@interface ReaderAdvertisersViewController ()

@end

@implementation ReaderAdvertisersViewController

- (instancetype)initWithPathToAds:(NSString *)path
{
    self = [super init];
    if (self) {
        self.pathToAds = path;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    
    [self.webView loadHTMLString:htmlString baseURL:nil];
    
    [self.view addSubview:self.webView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    self.webView = nil;
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
