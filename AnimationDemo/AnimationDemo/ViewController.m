//
//  ViewController.m
//  AnimationDemo
//
//  Created by huajiao on 2017/10/13.
//  Copyright © 2017年 huajiao. All rights reserved.
//

#import "ViewController.h"
#import "UIView+DR_CustomBlockAnimations.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *animationView;
- (IBAction)onClickBtn:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onClickBtn:(id)sender {
    [UIView DR_popAnimationWithDuration:0.25 animations:^{
        self.animationView.center = CGPointMake(200, 200);
        
    }];
}
@end
