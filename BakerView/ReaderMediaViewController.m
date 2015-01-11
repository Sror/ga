//
//  ReaderMediaController.m
//  General Aviation
//
//  Created by Alex Burov on 1/10/15.
//
//

#import "ReaderMediaViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ReaderMediaViewController ()
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) MPMoviePlayerController *videoController;
@end

@implementation ReaderMediaViewController

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.url = url;
    }
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(0, 0, 80, 40);
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.videoController =
    [[MPMoviePlayerController alloc] initWithContentURL: self.url];
    self.videoController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin   |
    UIViewAutoresizingFlexibleWidth        |
    UIViewAutoresizingFlexibleRightMargin  |
    UIViewAutoresizingFlexibleTopMargin    |
    UIViewAutoresizingFlexibleHeight       |
    UIViewAutoresizingFlexibleBottomMargin ;
    [self.videoController prepareToPlay];
    [self.videoController.view setFrame: self.view.bounds]; // player's frame must match parent's
    [self.view addSubview: self.videoController.view];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.videoController];

    [self.videoController play];
    [self.view addSubview:closeButton];
    [self.view bringSubviewToFront:closeButton];

}


-(void)closeButtonAction:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)videoPlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [self.videoController stop];
}

@end
