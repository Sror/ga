//
//  ReaderMediaController.m
//  General Aviation
//
//  Created by Alex Burov on 1/10/15.
//
//

#import "ReaderMediaViewController.h"

@interface ReaderMediaViewController ()
@property (strong, nonatomic) UIButton *button;
@end

@implementation ReaderMediaViewController

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    self.button = [[UIButton alloc]initWithFrame:CGRectMake(20, 20, 40, 40)];
    [self.button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.button setBackgroundColor:[UIColor redColor]];
    [self.button setTitle:@"SOSALITY" forState:UIControlStateNormal];
    [self.button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [self.view addSubview:self.button];
}


-(void)buttonAction:(UIButton *)sender{
    NSLog(@"HOHOHOHO EPTA");
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
