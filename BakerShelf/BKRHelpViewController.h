//
//  BKRInfoViewController.h
//  General Aviation
//
//  Created by Alex Burov on 1/8/15.
//
//

#import <UIKit/UIKit.h>

@interface BKRHelpViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSURLRequest *request;

- (instancetype)initWithRequest:(NSURLRequest *)request;
@end
