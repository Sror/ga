//
//  ReaderAdvertisersViewController.h
//  General Aviation
//
//  Created by Alex Burov on 1/7/15.
//
//

#import <UIKit/UIKit.h>

@interface ReaderAdvertisersViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) UIWebView* webView;
@property (strong, nonatomic) NSString *pathToAds;

@end
