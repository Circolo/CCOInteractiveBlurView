//
//  CCOInteractiveBlurView.h
//  CCOInteractiveBlurView
//
//  Created by Gian Franco Zabarino on 10/6/16.
//  Copyright © 2016 Circolo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCOInteractiveBlurView : UIView

@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, assign) CGFloat percentage;

- (instancetype)initWithNumberOfStages:(NSUInteger)numberOfStages;
- (void)prepareBlurEffect;
- (void)showBlur:(BOOL)showBlur animated:(BOOL)animated duration:(CGFloat)duration completion:(void (^)())completion;

@end
