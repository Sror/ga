//
//  ReaderImagesGalleryControllerViewController.m
//  General Aviation
//
//  Created by Enzo Nieri on 1/11/15.
//
//

#import "ReaderImagesGalleryControllerViewController.h"
#import <MWPhotoBrowser.h>


@interface ReaderImagesGalleryControllerViewController ()
@property (strong, nonatomic) NSArray *arrayOfImagesPath;
@property (strong, nonatomic) NSMutableArray *photos;
@end

@implementation ReaderImagesGalleryControllerViewController
- (instancetype)initWithImages:(NSArray *)array
{
    self = [super init];
    if (self) {
        self.arrayOfImagesPath = array;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(0, 0, 80, 40);
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:closeButton];
    
    self.photos = [NSMutableArray array];
    
    for (NSURL *imgURL in self.arrayOfImagesPath) {
        [self.photos addObject:[MWPhoto photoWithURL:imgURL]];
    }
    
    //https://github.com/mwaterfall/MWPhotoBrowser
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];

    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = YES; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    browser.wantsFullScreenLayout = YES;
    
    [browser setCurrentPhotoIndex:1];
    
    [self.navigationController pushViewController:browser animated:YES];
    
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:10];
    
    [self.view bringSubviewToFront:closeButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)closeButtonAction:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
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
