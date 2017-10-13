//
//  UIView+DR_CustomBlockAnimations.m
//  AnimationDemo
//
//  Created by huajiao on 2017/10/13.
//  Copyright © 2017年 huajiao. All rights reserved.
//

#import "UIView+DR_CustomBlockAnimations.h"
#import <objc/runtime.h>

@interface DRSavedPopAnimationState : NSObject

@property (strong) CALayer  *layer;
@property (copy)   NSString *keyPath;
@property (strong) id        oldValue;

+ (instancetype)savedStateWithLayer:(CALayer *)layer
                            keyPath:(NSString *)keyPath;

@end

@implementation DRSavedPopAnimationState

+ (instancetype)savedStateWithLayer:(CALayer *)layer
                            keyPath:(NSString *)keyPath
{
    DRSavedPopAnimationState *savedState = [DRSavedPopAnimationState new];
    savedState.layer    = layer;
    savedState.keyPath  = keyPath;
    savedState.oldValue = [layer valueForKeyPath:keyPath];
    return savedState;
}

@end

@implementation UIView (DR_CustomBlockAnimations)

+ (void)load
{
    SEL originalSelector = @selector(actionForLayer:forKey:);
    SEL extendedSelector = @selector(DR_actionForLayer:forKey:);
    
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method extendedMethod = class_getInstanceMethod(self, extendedSelector);
    
    NSAssert(originalMethod, @"original method should exist");
    NSAssert(extendedMethod, @"exchanged method should exist");
    
    if(class_addMethod(self, originalSelector, method_getImplementation(extendedMethod), method_getTypeEncoding(extendedMethod))) {
        class_replaceMethod(self, extendedSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, extendedMethod);
    }
}



+ (NSMutableArray <DRSavedPopAnimationState *> *)DR_savedPopAnimationStates{
    static NSMutableArray <DRSavedPopAnimationState *> *states = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        states = [NSMutableArray array];
    });
    return states;
}


static void *DR_currentAnimationContext = NULL;
static void *DR_popAnimationContext     = &DR_popAnimationContext;


- (id<CAAction>)DR_actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if (DR_currentAnimationContext == DR_popAnimationContext) {
        [[UIView DR_savedPopAnimationStates] addObject:[DRSavedPopAnimationState savedStateWithLayer:layer
                                                                                             keyPath:event]];
        
        // 没有隐式的动画 (稍后添加)
        return (id<CAAction>)[NSNull null];
    }
    
    // 调用原始方法
    return [self DR_actionForLayer:layer forKey:event]; // 没错，你没看错。因为它们已经被交换了
}


+ (void)DR_popAnimationWithDuration:(NSTimeInterval)duration
                         animations:(void (^)(void))animations
{
    DR_currentAnimationContext = DR_popAnimationContext;
    // 执行动画 (它将触发交换后的 delegate 方法)
    animations();
    
    
    [[self DR_savedPopAnimationStates] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DRSavedPopAnimationState *savedState   = (DRSavedPopAnimationState *)obj;
        CALayer *layer    = savedState.layer;
        NSString *keyPath = savedState.keyPath;
        id oldValue       = savedState.oldValue;
        id newValue       = [layer valueForKeyPath:keyPath];
        
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:keyPath];
        
        CGFloat easing = 0.2;
        CAMediaTimingFunction *easeIn  = [CAMediaTimingFunction functionWithControlPoints:1.0 :0.0 :(1.0-easing) :1.0];
        CAMediaTimingFunction *easeOut = [CAMediaTimingFunction functionWithControlPoints:easing :0.0 :0.0 :1.0];
        
        anim.duration = duration;
        anim.keyTimes = @[@0, @(0.35), @1];
        anim.values = @[oldValue, newValue, oldValue];
        anim.timingFunctions = @[easeIn, easeOut];
        
        // 不带动画地返回原来的值
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [layer setValue:oldValue forKeyPath:keyPath];
        [CATransaction commit];
        
        // 添加 "pop" 动画
        [layer addAnimation:anim forKey:keyPath];
        
    }];
    
    // 扫除工作 (移除所有存储的状态)
    [[self DR_savedPopAnimationStates] removeAllObjects];
    /* 一会儿再添加 */
    DR_currentAnimationContext = NULL;
}

@end
