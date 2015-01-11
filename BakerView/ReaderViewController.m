//
//	ReaderViewController.m
//	Reader v2.8.1
//
//	Created by Julius Oklamcak on 2011-07-01.
//	Copyright © 2011-2014 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderConstants.h"
#import "ReaderViewController.h"
#import "ThumbsViewController.h"
#import "ReaderMainToolbar.h"
#import "ReaderMainPagebar.h"
#import "ReaderContentView.h"
#import "ReaderThumbCache.h"
#import "ReaderThumbQueue.h"
#import "BKRShelfViewController.h"
#import "ReaderMediaViewController.h"


#import <MessageUI/MessageUI.h>
#import "ReaderAdvertisersViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>

@interface ReaderViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate,
									ReaderMainToolbarDelegate, ReaderMainPagebarDelegate, ReaderContentViewDelegate, ThumbsViewControllerDelegate, MWPhotoBrowserDelegate>

@property (strong, nonatomic) NSArray *arrayOfImagesPath;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *thumbs;
@end

@implementation ReaderViewController
{
	ReaderDocument *document;
    
    ThumbsViewController *sideBarViewController;

	UIScrollView *theScrollView;

	ReaderMainToolbar *mainToolbar;

	ReaderMainPagebar *mainPagebar;

	NSMutableDictionary *contentViews;

	UIUserInterfaceIdiom userInterfaceIdiom;

	NSInteger currentPage, minimumPage, maximumPage;
    
    NSInteger myCurrentPage;
    
    NSInteger myPreviousPage;

	UIDocumentInteractionController *documentInteraction;

	UIPrintInteractionController *printInteraction;
    
    BOOL doublePage;
    
	CGFloat scrollViewOutset;

	CGSize lastAppearSize;

	NSDate *lastHideTime;

	BOOL ignoreDidScroll;
    UIButton *videoButton;
    UIButton *videoButton1;
    UIButton *imageButton;
    UIButton *imageButton1;
    UIButton *mainVideoButton;
    UIButton *mainImageButton;
}

#pragma mark - Constants

#define STATUS_HEIGHT 20.0f

#define TOOLBAR_HEIGHT 44.0f
#define PAGEBAR_HEIGHT 100.0f

#define THUMBS_BAR_WIDTH 180.0f

#define SCROLLVIEW_OUTSET_SMALL 4.0f
#define SCROLLVIEW_OUTSET_LARGE 8.0f

#define LANDSCAPE_DOUBLE_PAGE true
#define LANDSCAPE_SINGLE_FIRST_PAGE true

#define ICON_WIDTH 45.0f
#define ICON_HEIGHT 45.0f

#define ICON_OFFSET_WIDTH 20.0f
#define ICON_OFFSET_HEIGHT 10.0f

#define ICON_MEDIA_MAIN_OFFSET 250.0f


#define TAP_AREA_SIZE 48.0f

#pragma mark - Properties

@synthesize delegate;

#pragma mark - ReaderViewController methods



- (void)updateContentSize:(UIScrollView *)scrollView
{
	CGFloat contentHeight = scrollView.bounds.size.height; // Height

	CGFloat contentWidth = (scrollView.bounds.size.width * maximumPage);

	scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (void)handleLandscapeDoublePage {
    NSInteger futureCurrentPage = currentPage;
    
    if (futureCurrentPage == 0) {
        return;
    }
    
    UIInterfaceOrientation orientation= [[UIApplication sharedApplication] statusBarOrientation];
    maximumPage = [document.pageCount integerValue];
    
    doublePage = false;
    
    if(UIInterfaceOrientationIsLandscape(orientation)){
        doublePage = true;
        float maxPage = maximumPage;
        float nextCurrentPage = (currentPage / 2.0);
        
        
        if (LANDSCAPE_SINGLE_FIRST_PAGE) {
            nextCurrentPage = floor(nextCurrentPage) + 1;
            maxPage = ((maxPage - 1) / 2) + 1;
        } else {
            maxPage = (maxPage / 2);
        }
        
        currentPage = (int) ceil(nextCurrentPage);
        maximumPage = (int) ceil(maxPage);
    }
    
    //Clear cached pages
    for (NSNumber *key in [contentViews allKeys]) // Enumerate content views
    {
        ReaderContentView *contentView = [contentViews objectForKey:key];
        
        [contentView removeFromSuperview]; [contentViews removeObjectForKey:key];
    }
    
    
    [self updateContentViews:theScrollView];
    //Force recompute view
    [self showDocumentPage:futureCurrentPage forceRedraw:true];
}

- (void)updateContentViews:(UIScrollView *)scrollView
{
	[self updateContentSize:scrollView]; // Update content size first

	[contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
		^(NSNumber *key, ReaderContentView *contentView, BOOL *stop)
		{
			NSInteger page = [key integerValue]; // Page number value

			CGRect viewRect = CGRectZero; viewRect.size = scrollView.bounds.size;
			viewRect.origin.x = (viewRect.size.width * (page - 1)); // Update X

			contentView.frame = CGRectInset(viewRect, scrollViewOutset, 0.0f);
		}
	];

	NSInteger page = currentPage; // Update scroll view offset to current page

	CGPoint contentOffset = CGPointMake((scrollView.bounds.size.width * (page - 1)), 0.0f);

	if (CGPointEqualToPoint(scrollView.contentOffset, contentOffset) == false) // Update
	{
		scrollView.contentOffset = contentOffset; // Update content offset
	}

	[mainToolbar setBookmarkState:[document.bookmarks containsIndex:page]];

	[mainPagebar updatePagebar]; // Update page bar
}

- (void)addContentView:(UIScrollView *)scrollView page:(NSInteger)page
{
    NSInteger renderPage = page;
    BOOL renderDoublePage = false;
    if (doublePage) {
        NSInteger lastPageEven;
 
        if (!LANDSCAPE_SINGLE_FIRST_PAGE) {
            lastPageEven = [document.pageCount integerValue];
            renderDoublePage = true;
            if (page > 1) {
                renderPage = (renderPage) * 2 - 1;
            }
        } else {
            lastPageEven = [document.pageCount integerValue] - 1;
            if (page > 1) {
                renderPage = (renderPage - 1) * 2;
                renderDoublePage = true;
            }
        }

        //Handle single last page
        if (page == maximumPage && lastPageEven % 2 == 1) {
            renderDoublePage = false;
        }
    }
	CGRect viewRect = CGRectZero; viewRect.size = scrollView.bounds.size;

	viewRect.origin.x = (viewRect.size.width * (page - 1)); viewRect = CGRectInset(viewRect, scrollViewOutset, 0.0f);

	NSURL *fileURL = document.fileURL; NSString *phrase = document.password; NSString *guid = document.guid; // Document properties

    NSString *pageStr = [NSString stringWithFormat:@"%d", page];
    NSString *nextPageStr = [NSString stringWithFormat:@"%d",page+1];
    if ([document.images objectForKey:pageStr]) {
        //addGalleryView for page
        NSLog(@"Fuck has img");
        NSLog(@"%@", [document.images objectForKey:pageStr]);
    }
    
    if ([document.video objectForKey:pageStr]) {
        //addGalleryView for page
        NSLog(@"Fuck has video");
        NSLog(@"%@", [document.video objectForKey:pageStr]);
    }
    
    ReaderContentView *contentView = [[ReaderContentView alloc] initWithFrame:viewRect fileURL:fileURL page:renderPage password:phrase doublePage:renderDoublePage videoFiles:[document.video objectForKey:pageStr] imageFiles:[document.images objectForKey:pageStr] nextVideo:[document.video objectForKey:nextPageStr] nextImage:[document.images objectForKey:nextPageStr]];// ReaderContentView

	contentView.message = self; [contentViews setObject:contentView forKey:[NSNumber numberWithInteger:page]]; [scrollView addSubview:contentView];

    [contentView showPageThumb:fileURL page:renderPage password:phrase guid:guid]; // Request page preview thumb
}

- (void)layoutContentViews:(UIScrollView *)scrollView
{
	CGFloat viewWidth = scrollView.bounds.size.width; // View width

	CGFloat contentOffsetX = scrollView.contentOffset.x; // Content offset X

	NSInteger pageB = ((contentOffsetX + viewWidth - 1.0f) / viewWidth); // Pages

	NSInteger pageA = (contentOffsetX / viewWidth); pageB += 2; // Add extra pages

	if (pageA < minimumPage) pageA = minimumPage; if (pageB > maximumPage) pageB = maximumPage;

	NSRange pageRange = NSMakeRange(pageA, (pageB - pageA + 1)); // Make page range (A to B)
    

	NSMutableIndexSet *pageSet = [NSMutableIndexSet indexSetWithIndexesInRange:pageRange];

	for (NSNumber *key in [contentViews allKeys]) // Enumerate content views
	{
		NSInteger page = [key integerValue]; // Page number value

		if ([pageSet containsIndex:page] == NO) // Remove content view
		{
			ReaderContentView *contentView = [contentViews objectForKey:key];

			[contentView removeFromSuperview]; [contentViews removeObjectForKey:key];
		}
		else // Visible content view - so remove it from page set
		{
			[pageSet removeIndex:page];
		}
	}
	NSInteger pages = pageSet.count;

	if (pages > 0) // We have pages to add
	{
		NSEnumerationOptions options = 0; // Default
        

		if (pages == 2) // Handle case of only two content views
		{
			if ((maximumPage > 2) && ([pageSet lastIndex] == maximumPage)) options = NSEnumerationReverse;
		}
		else if (pages == 3) // Handle three content views - show the middle one first
		{
			NSMutableIndexSet *workSet = [pageSet mutableCopy]; options = NSEnumerationReverse;

			[workSet removeIndex:[pageSet firstIndex]]; [workSet removeIndex:[pageSet lastIndex]];

			NSInteger page = [workSet firstIndex]; [pageSet removeIndex:page];
			[self addContentView:scrollView page:page];
		}

		[pageSet enumerateIndexesWithOptions:options usingBlock: // Enumerate page set
			^(NSUInteger page, BOOL *stop)
			{
				[self addContentView:scrollView page:page];
			}
		];
	}
}

- (void)handleScrollViewDidEnd:(UIScrollView *)scrollView
{
	CGFloat viewWidth = scrollView.bounds.size.width; // Scroll view width

	CGFloat contentOffsetX = scrollView.contentOffset.x; // Content offset X

	NSInteger page = (contentOffsetX / viewWidth); page++; // Page number
    
    if (doublePage && page > 1) {
        if (!LANDSCAPE_SINGLE_FIRST_PAGE) {
            page = page * 2;
        } else if (page > 1) {
            page = (page - 1) * 2;
        }
        
    }
    if (page != currentPage) // Only if on different page
	{
        
		currentPage = page; document.pageNumber = [NSNumber numberWithInteger:page];
        
		[contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
			^(NSNumber *key, ReaderContentView *contentView, BOOL *stop)
			{
				if ([key integerValue] != page) [contentView zoomResetAnimated:NO];
			}
		];

		[mainToolbar setBookmarkState:[document.bookmarks containsIndex:page]];

		[mainPagebar updatePagebar]; // Update page bar
	}
    [self enablesMediaButtonsWithPageNumber:currentPage];
}

- (void)showDocumentPage:(NSInteger)page {
    [self showDocumentPage:page forceRedraw:false];
    
    //[self enablesMediaButtonsWithPageNumber:page];
 
}
- (void)showDocumentPage:(NSInteger)page forceRedraw:(bool)forceRedraw
{
    NSInteger renderPage = page;
    
    if(doublePage){
        float nextRenderPage;
        //If double renderPage is not the same as page
        nextRenderPage = (page / 2.0);
        if (LANDSCAPE_SINGLE_FIRST_PAGE) {
            nextRenderPage = floor(nextRenderPage) + 1;
        } else if (page == 1) {
            nextRenderPage = 1;
        }
        
        renderPage = (int) ceil(nextRenderPage);
    }
	   
    if (page != currentPage || forceRedraw) // Only if on different page or if force redraw
	{
        if ((renderPage < minimumPage) || (renderPage > maximumPage)) return;
        myPreviousPage = currentPage;
		currentPage = page; document.pageNumber = [NSNumber numberWithInteger:page];

		CGPoint contentOffset = CGPointMake((theScrollView.bounds.size.width * (renderPage - 1)), 0.0f);

		if (CGPointEqualToPoint(theScrollView.contentOffset, contentOffset) == true)
			[self layoutContentViews:theScrollView];
		else
			[theScrollView setContentOffset:contentOffset];

		[contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
			^(NSNumber *key, ReaderContentView *contentView, BOOL *stop)
			{
				if ([key integerValue] != page) [contentView zoomResetAnimated:NO];
			}
		];

		[mainToolbar setBookmarkState:[document.bookmarks containsIndex:page]];
        
		[mainPagebar updatePagebar]; // Update page bar
        [self enablesMediaButtonsWithPageNumber:currentPage];
	}
    
    
}

- (void)showDocument
{
    UIInterfaceOrientation orientation= [[UIApplication sharedApplication] statusBarOrientation];
    
    if(UIInterfaceOrientationIsLandscape(orientation) && LANDSCAPE_DOUBLE_PAGE){
        currentPage = [document.pageNumber integerValue];
        [self handleLandscapeDoublePage];
    } else {
        [self updateContentSize:theScrollView]; // Update content size first
        [self showDocumentPage:[document.pageNumber integerValue]]; // Show page
    }
    
    [self enablesMediaButtonsWithPageNumber:currentPage];
    

	document.lastOpen = [NSDate date]; // Update document last opened date
}

- (void)closeDocument
{
	if (printInteraction != nil) [printInteraction dismissAnimated:NO];

	[document archiveDocumentProperties]; // Save any ReaderDocument changes

	[[ReaderThumbQueue sharedInstance] cancelOperationsWithGUID:document.guid];

	[[ReaderThumbCache sharedInstance] removeAllObjects]; // Empty the thumb cache

//	if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
//	{
//		[delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
//	}
//	else // We have a "Delegate must respond to -dismissReaderViewController:" error
//	{
//		NSAssert(NO, @"Delegate must respond to -dismissReaderViewController:");
//	}
}

#pragma mark - UIViewController methods

- (instancetype)initWithReaderDocument:(ReaderDocument *)object
{
	if ((self = [super initWithNibName:nil bundle:nil])) // Initialize superclass
	{
		if ((object != nil) && ([object isKindOfClass:[ReaderDocument class]])) // Valid object
		{
           
			userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom; // User interface idiom

			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter]; // Default notification center

			[notificationCenter addObserver:self selector:@selector(applicationWillResign:) name:UIApplicationWillTerminateNotification object:nil];

			[notificationCenter addObserver:self selector:@selector(applicationWillResign:) name:UIApplicationWillResignActiveNotification object:nil];

			scrollViewOutset = ((userInterfaceIdiom == UIUserInterfaceIdiomPad) ? SCROLLVIEW_OUTSET_LARGE : SCROLLVIEW_OUTSET_SMALL);

			[object updateDocumentProperties]; document = object; // Retain the supplied ReaderDocument object for our use

			[ReaderThumbCache touchThumbCacheWithGUID:object.guid]; // Touch the document thumb cache directory
            
		}
		else // Invalid ReaderDocument object
		{
			self = nil;
		}
	}

	return self;
}

- (void)setMediaButtonsAvailable:(UIButton *)localVideoButton andImage:(UIButton *)localImageButton andPage:(NSUInteger)page {
    
    
    NSString *currentPageStr = [NSString stringWithFormat:@"%d",page];
    if ([document.video objectForKey:currentPageStr] != nil) {
        localVideoButton.hidden = NO;
    }else{
        localVideoButton.hidden = YES;
    }
    
    if ([document.images objectForKey:currentPageStr] != nil) {
        localImageButton.hidden = NO;
    }else{
        localImageButton.hidden = YES;
    }
}

- (void)setMainMediaButtons:(UIButton *)localVideoButton andImage:(UIButton *)localImageButton andPage:(NSUInteger)page {
    NSString *currentPageStr = [NSString stringWithFormat:@"%d",page];
    if ([document.video objectForKey:currentPageStr] != nil) {
        localVideoButton.hidden = NO;
    }else{
        localVideoButton.hidden = YES;
    }
    
    if ([document.images objectForKey:currentPageStr] != nil) {
        localImageButton.hidden = NO;
    }else{
        localImageButton.hidden = YES;
    }
}

-(void)hideMediaButtons{
    videoButton.hidden = videoButton1.hidden = imageButton.hidden = imageButton1.hidden = mainImageButton.hidden = mainVideoButton.hidden = YES ;
}

- (void)enablesMediaButtonsWithPageNumber:(NSInteger) pageNumber{
    
    NSUInteger maxPage = [document.pageCount integerValue];
    
    if (doublePage) {
        if (pageNumber != 1 || pageNumber != maxPage){
            if ((pageNumber + 1 == myPreviousPage &&  myPreviousPage % 2 == 1) || (pageNumber - 1 == myPreviousPage && myPreviousPage % 2 == 0 )) {
                return;
            }

        }
        if (pageNumber == 1) {
            myCurrentPage = pageNumber;
            [self setMediaButtonsAvailable:mainVideoButton andImage:mainImageButton andPage:myCurrentPage];
            return;
        }
        
        if (pageNumber == maxPage && (maxPage % 2 == 0)){
            myCurrentPage = pageNumber;
            [self setMediaButtonsAvailable:mainVideoButton andImage:mainImageButton andPage:myCurrentPage];
            
            return;
        }
        
        if (pageNumber + 1 == maxPage && maxPage % 2 == 0) {
            myCurrentPage = pageNumber - 1;
            [self setMediaButtonsAvailable:videoButton andImage:imageButton andPage:myCurrentPage];
            [self setMediaButtonsAvailable:videoButton1 andImage:imageButton1 andPage:myCurrentPage + 1];
            return;
        }
        
        if (pageNumber == maxPage ) {
            myCurrentPage = pageNumber - 1;
        }else{
            myCurrentPage = pageNumber;
        }
        [self setMediaButtonsAvailable:videoButton andImage:imageButton andPage:myCurrentPage];
        [self setMediaButtonsAvailable:videoButton1 andImage:imageButton1 andPage:myCurrentPage + 1];
    }else{
        myCurrentPage = pageNumber;
        [self setMediaButtonsAvailable:videoButton andImage:imageButton andPage:myCurrentPage];
    }
    
}

-(void)showImages:(NSInteger)page{
    
    self.arrayOfImagesPath = [document.images objectForKey:[NSString stringWithFormat: @"%d", page]];
    self.thumbs = [[NSMutableArray alloc] init];
    
    self.photos = [NSMutableArray array];
    
    for (NSURL *imgURL in self.arrayOfImagesPath) {
        MWPhoto *photo = [MWPhoto photoWithURL:imgURL];
        [self.photos addObject:photo];
        [self.thumbs addObject:photo];
    }
    
    //https://github.com/mwaterfall/MWPhotoBrowser
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = YES; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    browser.enableGrid = YES; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:nc animated:YES completion:nil];
    
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:0];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photos.count)
        return [self.photos objectAtIndex:index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _thumbs.count)
        return [_thumbs objectAtIndex:index];
    return nil;
}

- (void)playVideo:(NSInteger)page
{
    NSURL *myURL = [[document.video objectForKey:[NSString stringWithFormat: @"%d", page]] firstObject];
    ReaderMediaViewController *vc = [[ReaderMediaViewController alloc]initWithURL:myURL];
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)videoButtonAction:(UIButton *)sender {
    NSLog(@"Video page numbder %d",myCurrentPage);
    [self playVideo:myCurrentPage];
}

- (void)videoButton1Action:(UIButton *)sender {
    NSLog(@"Video page numbder %d",myCurrentPage + 1);
    [self playVideo:(myCurrentPage+1)];
}

- (void)imageButtonAction:(UIButton *)sender {
   [self showImages:myCurrentPage];
}

- (void)imageButton1Action:(UIButton *)sender {
   [self showImages:myCurrentPage+1];
}

- (void)mainVideoButtonAction:(UIButton *)sender {
    NSLog(@"Image page numbder %d",myCurrentPage);
    [self playVideo:myCurrentPage];
}

- (void)mainImageButtonAction:(UIButton *)sender {
    [self showImages:myCurrentPage];
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = YES;
    
	assert(document != nil); // Must have a valid ReaderDocument

	self.view.backgroundColor = [UIColor grayColor]; // Neutral gray

	UIView *fakeStatusBar = nil; CGRect viewRect = self.view.bounds; // View bounds

	if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) // iOS 7+
	{
		if ([self prefersStatusBarHidden] == NO) // Visible status bar
		{
			CGRect statusBarRect = viewRect; statusBarRect.size.height = STATUS_HEIGHT;
			fakeStatusBar = [[UIView alloc] initWithFrame:statusBarRect]; // UIView
			fakeStatusBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			fakeStatusBar.backgroundColor = [UIColor blackColor];
			fakeStatusBar.contentMode = UIViewContentModeRedraw;
			fakeStatusBar.userInteractionEnabled = NO;

			viewRect.origin.y += STATUS_HEIGHT; viewRect.size.height -= STATUS_HEIGHT;
		}
	}
    
	CGRect scrollViewRect = CGRectInset(viewRect, -scrollViewOutset, 0.0f);
	theScrollView = [[UIScrollView alloc] initWithFrame:scrollViewRect]; // All
	theScrollView.autoresizesSubviews = NO; theScrollView.contentMode = UIViewContentModeRedraw;
	theScrollView.showsHorizontalScrollIndicator = NO; theScrollView.showsVerticalScrollIndicator = NO;
	theScrollView.scrollsToTop = NO; theScrollView.delaysContentTouches = NO; theScrollView.pagingEnabled = YES;
	theScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	theScrollView.backgroundColor = [UIColor clearColor]; theScrollView.delegate = self;
	[self.view addSubview:theScrollView];

	CGRect toolbarRect = viewRect; toolbarRect.size.height = TOOLBAR_HEIGHT;
	mainToolbar = [[ReaderMainToolbar alloc] initWithFrame:toolbarRect document:document]; // ReaderMainToolbar
	mainToolbar.delegate = self; // ReaderMainToolbarDelegate
	[self.view addSubview:mainToolbar];
    
    sideBarViewController = [[ThumbsViewController alloc] initWithReaderDocument:document];
    sideBarViewController.delegate = self;
    
    [self addChildViewController:sideBarViewController];
    
    [self.view addSubview:sideBarViewController.view];
    

	if (fakeStatusBar != nil) [self.view addSubview:fakeStatusBar]; // Add status bar background view

	UITapGestureRecognizer *singleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTapOne.numberOfTouchesRequired = 1; singleTapOne.numberOfTapsRequired = 1; singleTapOne.delegate = self;
	[self.view addGestureRecognizer:singleTapOne];

	UITapGestureRecognizer *doubleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapOne.numberOfTouchesRequired = 1; doubleTapOne.numberOfTapsRequired = 2; doubleTapOne.delegate = self;
	[self.view addGestureRecognizer:doubleTapOne];

	UITapGestureRecognizer *doubleTapTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapTwo.numberOfTouchesRequired = 2; doubleTapTwo.numberOfTapsRequired = 2; doubleTapTwo.delegate = self;
	[self.view addGestureRecognizer:doubleTapTwo];

	[singleTapOne requireGestureRecognizerToFail:doubleTapOne]; // Single tap requires double tap to fail

	contentViews = [NSMutableDictionary new]; lastHideTime = [NSDate date];

	minimumPage = 1; maximumPage = [document.pageCount integerValue];
    
    CGFloat offset;
    
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
        offset = CGRectGetWidth([[UIScreen mainScreen]bounds])/2;
    else
        offset = CGRectGetHeight([[UIScreen mainScreen]bounds])/2;
    
    mainVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mainVideoButton.frame = CGRectMake(ICON_MEDIA_MAIN_OFFSET+ICON_OFFSET_WIDTH, TOOLBAR_HEIGHT + ICON_OFFSET_HEIGHT + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT);
    mainVideoButton.backgroundColor = [UIColor clearColor];
    [mainVideoButton setImage:[UIImage imageNamed:@"video"] forState:UIControlStateNormal];
    [mainVideoButton setImage:nil forState:UIControlStateHighlighted];
    [mainVideoButton addTarget:self action:@selector(mainVideoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:mainVideoButton];
    
    mainImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mainImageButton.frame = CGRectMake(ICON_MEDIA_MAIN_OFFSET+ICON_OFFSET_WIDTH, TOOLBAR_HEIGHT + ICON_OFFSET_HEIGHT, ICON_WIDTH, ICON_HEIGHT);
    mainImageButton.backgroundColor = [UIColor clearColor];
    [mainImageButton setImage:[UIImage imageNamed:@"images"] forState:UIControlStateNormal];
    [mainImageButton setImage:nil forState:UIControlStateHighlighted];
    [mainImageButton addTarget:self action:@selector(mainImageButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:mainImageButton];
    
    videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    videoButton.frame = CGRectMake(ICON_OFFSET_WIDTH , TOOLBAR_HEIGHT + ICON_OFFSET_HEIGHT + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT);
    videoButton.backgroundColor = [UIColor clearColor];
    [videoButton setImage:[UIImage imageNamed:@"video"] forState:UIControlStateNormal];
    [videoButton setImage:nil forState:UIControlStateHighlighted];
    [videoButton addTarget:self action:@selector(videoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoButton];
    
    imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    imageButton.frame = CGRectMake(ICON_OFFSET_WIDTH, TOOLBAR_HEIGHT + ICON_OFFSET_HEIGHT, ICON_WIDTH, ICON_HEIGHT);
    imageButton.backgroundColor = [UIColor clearColor];
    [imageButton setImage:[UIImage imageNamed:@"images"] forState:UIControlStateNormal];
    [imageButton setImage:nil forState:UIControlStateHighlighted];
    [imageButton addTarget:self action:@selector(imageButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:imageButton];
    
    videoButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    videoButton1.frame = CGRectMake(offset+ICON_OFFSET_WIDTH , TOOLBAR_HEIGHT + ICON_OFFSET_HEIGHT + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT);
    videoButton1.backgroundColor = [UIColor clearColor];
    [videoButton1 setImage:[UIImage imageNamed:@"video"] forState:UIControlStateNormal];
    [videoButton1 setImage:nil forState:UIControlStateHighlighted];
    [videoButton1 addTarget:self action:@selector(videoButton1Action:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoButton1];
    
    imageButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    imageButton1.frame = CGRectMake(offset+ICON_OFFSET_WIDTH, TOOLBAR_HEIGHT + ICON_OFFSET_HEIGHT, ICON_WIDTH, ICON_HEIGHT);
    imageButton1.backgroundColor = [UIColor clearColor];
    [imageButton1 setImage:[UIImage imageNamed:@"images"] forState:UIControlStateNormal];
    [imageButton1 setImage:nil forState:UIControlStateHighlighted];
    [imageButton1 addTarget:self action:@selector(imageButton1Action:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:imageButton1];
    
    [self hideMediaButtons];//HIDE MEDIA BUTTONS
}




- (void)viewDidLayoutSubviews {
    
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
    
	if (CGSizeEqualToSize(lastAppearSize, CGSizeZero) == false)
	{
		if (CGSizeEqualToSize(lastAppearSize, self.view.bounds.size) == false)
		{
			[self updateContentViews:theScrollView]; // Update content views
		}

		lastAppearSize = CGSizeZero; // Reset view size tracking
	}
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if (CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero) == true)
	{
		[self performSelector:@selector(showDocument) withObject:nil afterDelay:0.0];
	}

#if (READER_DISABLE_IDLE == TRUE) // Option

	[UIApplication sharedApplication].idleTimerDisabled = YES;

#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.hidden = NO;
    
	lastAppearSize = self.view.bounds.size; // Track view size

#if (READER_DISABLE_IDLE == TRUE) // Option

	[UIApplication sharedApplication].idleTimerDisabled = NO;

#endif // end of READER_DISABLE_IDLE Option
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];

}

- (void)viewDidUnload
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif

	mainToolbar = nil; mainPagebar = nil;

	theScrollView = nil; contentViews = nil; lastHideTime = nil;

	documentInteraction = nil; printInteraction = nil;
    
    sideBarViewController = nil;
    
	lastAppearSize = CGSizeZero; currentPage = 0;
    

	[super viewDidUnload];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (userInterfaceIdiom == UIUserInterfaceIdiomPad) if (printInteraction != nil) [printInteraction dismissAnimated:NO];

	ignoreDidScroll = YES;
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	if (CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero) == false)
	{
        if (LANDSCAPE_DOUBLE_PAGE) {
            [self handleLandscapeDoublePage];
        } else {
            [self updateContentViews:theScrollView];
        }
        lastAppearSize = CGSizeZero;
	}
    [self hideMediaButtons];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	ignoreDidScroll = NO;
    [self enablesMediaButtonsWithPageNumber:currentPage];
    
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif

	[super didReceiveMemoryWarning];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (ignoreDidScroll == NO) [self layoutContentViews:scrollView];
    [self hideMediaButtons];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self handleScrollViewDidEnd:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	[self handleScrollViewDidEnd:scrollView];
}





#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
	if ([touch.view isKindOfClass:[UIScrollView class]]) return YES;

	return NO;
}

#pragma mark - UIGestureRecognizer action methods

- (void)decrementPageNumber
{
	if ((maximumPage > minimumPage) && (currentPage != minimumPage))
	{
		CGPoint contentOffset = theScrollView.contentOffset; // Offset

		contentOffset.x -= theScrollView.bounds.size.width; // View X--

		[theScrollView setContentOffset:contentOffset animated:YES];
	}
}

- (void)incrementPageNumber
{
	if ((maximumPage > minimumPage) && (currentPage != maximumPage))
	{
		CGPoint contentOffset = theScrollView.contentOffset; // Offset

		contentOffset.x += theScrollView.bounds.size.width; // View X++
        
		[theScrollView setContentOffset:contentOffset animated:YES];
	}
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view]; // Point

		CGRect areaRect = CGRectInset(viewRect, TAP_AREA_SIZE, 0.0f); // Area rect

		if (CGRectContainsPoint(areaRect, point) == true) // Single tap is inside area
		{
			NSNumber *key = [NSNumber numberWithInteger:currentPage]; // Page number key

			ReaderContentView *targetView = [contentViews objectForKey:key]; // View

			id target = [targetView processSingleTap:recognizer]; // Target object

			if (target != nil) // Handle the returned target object
			{
				if ([target isKindOfClass:[NSURL class]]) // Open a URL
				{
					NSURL *url = (NSURL *)target; // Cast to a NSURL object

					if (url.scheme == nil) // Handle a missing URL scheme
					{
						NSString *www = url.absoluteString; // Get URL string

						if ([www hasPrefix:@"www"] == YES) // Check for 'www' prefix
						{
							NSString *http = [[NSString alloc] initWithFormat:@"http://%@", www];

							url = [NSURL URLWithString:http]; // Proper http-based URL
						}
					}

					if ([[UIApplication sharedApplication] openURL:url] == NO)
					{
						#ifdef DEBUG
							NSLog(@"%s '%@'", __FUNCTION__, url); // Bad or unknown URL
						#endif
					}
				}
				else // Not a URL, so check for another possible object type
				{
					if ([target isKindOfClass:[NSNumber class]]) // Goto page
					{
						NSInteger number = [target integerValue]; // Number

						[self showDocumentPage:number]; // Show the page
					}
				}
			}
			else // Nothing active tapped in the target content view
			{
				if ([lastHideTime timeIntervalSinceNow] < -0.75) // Delay since hide
				{
					if ((mainToolbar.alpha < 1.0f) || (mainPagebar.alpha < 1.0f)) // Hidden
					{
						[mainToolbar showToolbar]; [mainPagebar showPagebar]; // Show
                        [self showSidebar];
					}
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = TAP_AREA_SIZE;
		nextPageRect.origin.x = (viewRect.size.width - TAP_AREA_SIZE);

		if (CGRectContainsPoint(nextPageRect, point) == true) // page++
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = TAP_AREA_SIZE;

		if (CGRectContainsPoint(prevPageRect, point) == true) // page--
		{
			[self decrementPageNumber]; return;
		}
	}
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view]; // Point

		CGRect zoomArea = CGRectInset(viewRect, TAP_AREA_SIZE, TAP_AREA_SIZE); // Area

		if (CGRectContainsPoint(zoomArea, point) == true) // Double tap is inside zoom area
		{
			NSNumber *key = [NSNumber numberWithInteger:currentPage]; // Page number key

			ReaderContentView *targetView = [contentViews objectForKey:key]; // View

			switch (recognizer.numberOfTouchesRequired) // Touches count
			{
				case 1: // One finger double tap: zoom++
				{
					[targetView zoomIncrement:recognizer]; break;
				}

				case 2: // Two finger double tap: zoom--
				{
					[targetView zoomDecrement:recognizer]; break;
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = TAP_AREA_SIZE;
		nextPageRect.origin.x = (viewRect.size.width - TAP_AREA_SIZE);

		if (CGRectContainsPoint(nextPageRect, point) == true) // page++
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = TAP_AREA_SIZE;

		if (CGRectContainsPoint(prevPageRect, point) == true) // page--
		{
			[self decrementPageNumber]; return;
		}
	}
}

#pragma mark - ReaderContentViewDelegate methods

- (void)contentView:(ReaderContentView *)contentView touchesBegan:(NSSet *)touches
{
	if ((mainToolbar.alpha > 0.0f) || (mainPagebar.alpha > 0.0f))
	{
		if (touches.count == 1) // Single touches only
		{
			UITouch *touch = [touches anyObject]; // Touch info

			CGPoint point = [touch locationInView:self.view]; // Touch location

			CGRect areaRect = CGRectInset(self.view.bounds, TAP_AREA_SIZE, TAP_AREA_SIZE);

			if (CGRectContainsPoint(areaRect, point) == false) return;
		}

		[mainToolbar hideToolbar]; [mainPagebar hidePagebar]; // Hide
        [self hideSidebar];

		lastHideTime = [NSDate date]; // Set last hide time
	}
}

#pragma mark - ReaderMainToolbarDelegate methods

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar doneButton:(UIButton *)button
{
#if (READER_STANDALONE == FALSE) // Option

	[self closeDocument]; // Close ReaderViewController

    NSArray *pathComponents = [document.fileURL pathComponents];
    
    NSString *path = @"";
    
    for (int i = [pathComponents count] - 5; i< [pathComponents count]; i++) {
        path = [path stringByAppendingPathComponent:pathComponents[i]];
    }
    
    
    BKRShelfViewController *vc = self.navigationController.viewControllers.firstObject;
    vc.path = path;
    [self.navigationController popToRootViewControllerAnimated:YES];
#endif // end of READER_STANDALONE Option
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar thumbsButton:(UIButton *)button
{
#if (READER_ENABLE_THUMBS == TRUE) // Option

	if (printInteraction != nil) [printInteraction dismissAnimated:NO];

	ThumbsViewController *thumbsViewController = [[ThumbsViewController alloc] initWithReaderDocument:document];

	thumbsViewController.title = self.title; thumbsViewController.delegate = self; // ThumbsViewControllerDelegate

	thumbsViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    thumbsViewController.modalPresentationStyle = UIModalPresentationFormSheet;

	[self presentViewController:thumbsViewController animated:NO completion:NULL];

#endif // end of READER_ENABLE_THUMBS Option
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar advertisersButtonTapped:(UIButton *)button
{
    
    ReaderAdvertisersViewController *advertiserVC = [[ReaderAdvertisersViewController alloc]initWithPathToAds:document.fileURL];
    advertiserVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    advertiserVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:advertiserVC animated:YES completion:NULL];
}


- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar exportButton:(UIButton *)button
{
    
    if (printInteraction != nil) [printInteraction dismissAnimated:YES];
    
	NSURL *fileURL = document.fileURL; // Document file URL

	documentInteraction = [UIDocumentInteractionController interactionControllerWithURL:fileURL];

	documentInteraction.delegate = self; // UIDocumentInteractionControllerDelegate

	[documentInteraction presentOpenInMenuFromRect:button.bounds inView:button animated:YES];
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar printButton:(UIButton *)button
{
	if ([UIPrintInteractionController isPrintingAvailable] == YES)
	{
		NSURL *fileURL = document.fileURL; // Document file URL

		if ([UIPrintInteractionController canPrintURL:fileURL] == YES)
		{
			printInteraction = [UIPrintInteractionController sharedPrintController];

			UIPrintInfo *printInfo = [UIPrintInfo printInfo];
			printInfo.duplex = UIPrintInfoDuplexLongEdge;
			printInfo.outputType = UIPrintInfoOutputGeneral;
			printInfo.jobName = document.fileName;

			printInteraction.printInfo = printInfo;
			printInteraction.printingItem = fileURL;
			printInteraction.showsPageRange = YES;

			if (userInterfaceIdiom == UIUserInterfaceIdiomPad) // Large device printing
			{
				[printInteraction presentFromRect:button.bounds inView:button animated:YES completionHandler:
					^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
					{
						#ifdef DEBUG
							if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
						#endif
					}
				];
			}
			else // Handle printing on small device
			{
				[printInteraction presentAnimated:YES completionHandler:
					^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
					{
						#ifdef DEBUG
							if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
						#endif
					}
				];
			}
		}
	}
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar emailButton:(UIButton *)button
{
    if ([MFMailComposeViewController canSendMail] == NO) return;
    MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];
    
    //[mailComposer addAttachmentData:attachment mimeType:@"application/pdf" fileName:fileName];
    
    [mailComposer setSubject:@"Letter to the editor"]; // Use the document file name for the subject
    [mailComposer setToRecipients:@[@"aviajournal.aon@gmail.com"]];
    [mailComposer setMessageBody:@"Dear editor of General Aviation magazine! I'd like to discuss about the following: \n\n\n\n-----------------" isHTML:NO];
    
    mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
    
    mailComposer.mailComposeDelegate = self; // MFMailComposeViewControllerDelegate
    
    [self presentViewController:mailComposer animated:YES completion:NULL];
//	if ([MFMailComposeViewController canSendMail] == NO) return;
//    
//    
//
//	if (printInteraction != nil) [printInteraction dismissAnimated:YES];
//
//	unsigned long long fileSize = [document.fileSize unsignedLongLongValue];
//
//	if (fileSize < 15728640ull) // Check attachment size limit (15MB)
//	{
//		NSURL *fileURL = document.fileURL; NSString *fileName = document.fileName;
//
//		NSData *attachment = [NSData dataWithContentsOfURL:fileURL options:(NSDataReadingMapped|NSDataReadingUncached) error:nil];
//
//		if (attachment != nil) // Ensure that we have valid document file attachment data available
//		{
//			MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];
//
//			[mailComposer addAttachmentData:attachment mimeType:@"application/pdf" fileName:fileName];
//
//			[mailComposer setSubject:fileName]; // Use the document file name for the subject
//
//			mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//			mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
//
//			mailComposer.mailComposeDelegate = self; // MFMailComposeViewControllerDelegate
//
//			[self presentViewController:mailComposer animated:YES completion:NULL];
//		}
//	}
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar markButton:(UIButton *)button
{
#if (READER_BOOKMARKS == TRUE) // Option

	if (printInteraction != nil) [printInteraction dismissAnimated:YES];

	if ([document.bookmarks containsIndex:currentPage]) // Remove bookmark
	{
		[document.bookmarks removeIndex:currentPage]; [mainToolbar setBookmarkState:NO];
	}
	else // Add the bookmarked page number to the bookmark index set
	{
		[document.bookmarks addIndex:currentPage]; [mainToolbar setBookmarkState:YES];
	}
    
    [sideBarViewController markThumbAndRefresh:currentPage];
#endif // end of READER_BOOKMARKS Option
}

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
#ifdef DEBUG
	if ((result == MFMailComposeResultFailed) && (error != NULL)) NSLog(@"%@", error);
#endif

	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIDocumentInteractionControllerDelegate methods

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
	documentInteraction = nil;
}

#pragma mark - ThumbsViewControllerDelegate methods

- (void)thumbsViewController:(ThumbsViewController *)viewController gotoPage:(NSInteger)page
{
#if (READER_ENABLE_THUMBS == TRUE) // Option

	[self showDocumentPage:page];

#endif // end of READER_ENABLE_THUMBS Option
}

- (void)dismissThumbsViewController:(ThumbsViewController *)viewController
{
#if (READER_ENABLE_THUMBS == TRUE) // Option

	[self dismissViewControllerAnimated:NO completion:NULL];

#endif // end of READER_ENABLE_THUMBS Option
}

#pragma mark - ReaderMainPagebarDelegate methods

- (void)pagebar:(ReaderMainPagebar *)pagebar gotoPage:(NSInteger)page
{
	[self showDocumentPage:page];
}

#pragma mark - UIApplication notification methods

- (void)applicationWillResign:(NSNotification *)notification
{
	[document archiveDocumentProperties]; // Save any ReaderDocument changes

	if (userInterfaceIdiom == UIUserInterfaceIdiomPad) if (printInteraction != nil) [printInteraction dismissAnimated:NO];
}



- (void)hideSidebar
{
    if (sideBarViewController.view.hidden == NO) // Only if visible
    {
        [UIView animateWithDuration:0.25 delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^(void)
         {
             sideBarViewController.view.alpha = 0.0f;
         }
                         completion:^(BOOL finished)
         {
             sideBarViewController.view.hidden = YES;
         }
         ];
    }
}

- (void)showSidebar
{
    if (sideBarViewController.view.hidden == YES) // Only if hidden
    {
        [UIView animateWithDuration:0.25 delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^(void)
         {
             sideBarViewController.view.hidden = NO;
             sideBarViewController.view.alpha = 1.0f;
         }
                         completion:NULL
         ];
    }
}

- (void)didRotate:(NSNotification *)notification {
    CGRect rect;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8) {
        UIInterfaceOrientation newOrientation =  [UIApplication sharedApplication].statusBarOrientation;
        if (UIInterfaceOrientationIsLandscape(newOrientation)) {
            rect = CGRectMake(CGRectGetWidth([[UIScreen mainScreen] bounds]) - THUMBS_BAR_WIDTH,TOOLBAR_HEIGHT, THUMBS_BAR_WIDTH, CGRectGetHeight([[UIScreen mainScreen] bounds]) - TOOLBAR_HEIGHT);
        }else{
            rect = CGRectMake(CGRectGetWidth([[UIScreen mainScreen] bounds]) - THUMBS_BAR_WIDTH, TOOLBAR_HEIGHT, THUMBS_BAR_WIDTH, CGRectGetHeight([[UIScreen mainScreen] bounds]) - TOOLBAR_HEIGHT);
        }
        
        
        [UIView animateWithDuration:0.25 delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             sideBarViewController.view.frame = rect;
         }
                         completion:NULL
         ];
    }

}



@end
