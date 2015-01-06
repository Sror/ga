//
//  ThumbsSideViewController.h
//  General Aviation
//
//  Created by Enzo Nieri on 1/6/15.
//
//



#import <UIKit/UIKit.h>

#import "ThumbsMainToolbar.h"
#import "ReaderThumbsView.h"

@class ReaderDocument;
@class ThumbsSideViewController;

@protocol ThumbsSideViewControllerDelegate <NSObject>

@required // Delegate protocols

- (void)thumbsViewController:(ThumbsSideViewController *)viewController gotoPage:(NSInteger)page;

- (void)dismissThumbsViewController:(ThumbsSideViewController *)viewController;

@end

@interface ThumbsSideViewController : UIViewController

@property (nonatomic, weak, readwrite) id <ThumbsSideViewControllerDelegate> delegate;

- (instancetype)initWithReaderDocument:(ReaderDocument *)object;

@end

#pragma mark -

//
//	ThumbsPageThumb class interface
//

@interface ThumbsPageThumb : ReaderThumbView

- (CGSize)maximumContentSize;

- (void)showText:(NSString *)text;

- (void)showBookmark:(BOOL)show;

@end
