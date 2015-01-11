//
//  ReaderImagesGalleryControllerViewController.m
//  General Aviation
//
//  Created by Enzo Nieri on 1/11/15.
//
//

#import "ReaderImagesGalleryControllerViewController.h"

@interface ReaderImagesGalleryControllerViewController ()
@property (strong, nonatomic) NSArray *arrayOfImagesPath;
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
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame]; // this makes the scroll view - set the frame as the size you want to SHOW on the screen
    [scrollView setContentSize:CGSizeMake(400,400)];
    scrollView.delegate = self;
    // if you set it to larger than the frame the overflow will be hidden and the view will scroll
    
    /* you can do this bit as many times as you want... make sure you set each image at a different origin */
    
    for (int i = 0; i <[self.arrayOfImagesPath count]; i++) {
        NSURL *url = self.arrayOfImagesPath[i];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:[url path]]]; // this makes the image view
        [imageView setFrame:CGRectMake(i*400,i*400,400,400)];/*SET AS 2/3 THE SIZE OF scrollView AND EACH IMAGE NEXT TO THE LAST*/ // this makes the image view display where you want it and at the right size
        [scrollView addSubview:imageView]; // this adds the image to the scrollview
    }
    
    [self.view addSubview:scrollView];
    
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
