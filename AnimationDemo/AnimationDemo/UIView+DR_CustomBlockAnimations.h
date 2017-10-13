//
//  UIView+DR_CustomBlockAnimations.h
//  AnimationDemo
//
//  Created by huajiao on 2017/10/13.
//  Copyright © 2017年 huajiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (DR_CustomBlockAnimations)

+ (void)DR_popAnimationWithDuration:(NSTimeInterval)duration
                         animations:(void (^)(void))animations;

@end
