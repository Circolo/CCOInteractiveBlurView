//
//  CCOInteractiveBlurView.h
//  CCOInteractiveBlurView
//
//  Created by Gian Franco Zabarino on 10/6/16.
//  Copyright (c) 2016 Circolo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CCOInteractiveBlurViewDelegate;

@interface CCOInteractiveBlurView : UIView

@property(nonatomic, weak) id<CCOInteractiveBlurViewDelegate> delegate;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, assign) CGFloat percentage;
@property(nonatomic, readonly, getter=isShowing) BOOL showing;

/**
 * When the blur effect is removed, it will clear generated blurred images. Leave this set if you want to save
 * memory. However, blurred images will need to be generated at the beginning of each blur effect showing.
 * Default is YES.
 */
@property(nonatomic, assign) BOOL shouldClearGeneratedImagesOnBlurRemoval;

- (instancetype)init;

- (instancetype)initWithDelegate:(id<CCOInteractiveBlurViewDelegate>)delegate;

- (instancetype)initWithMaximumRadius:(CGFloat)maximumRadius
                             delegate:(id<CCOInteractiveBlurViewDelegate>)delegate;

- (instancetype)initWithMaximumRadius:(CGFloat)maximumRadius
                       numberOfStages:(NSUInteger)numberOfStages
                             delegate:(id<CCOInteractiveBlurViewDelegate>)delegate;

- (void)prepareBlurEffect;

- (void)showBlur:(BOOL)showBlur animated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void (^)())completion;

@end

@protocol CCOInteractiveBlurViewDelegate <NSObject>

- (void)interactiveBlurViewOnBackgroundTap:(CCOInteractiveBlurView *)interactiveBlurView;

@end
