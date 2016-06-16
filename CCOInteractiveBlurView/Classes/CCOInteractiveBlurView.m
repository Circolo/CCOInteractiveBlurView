//
//  CCOInteractiveBlurView.m
//  CCOInteractiveBlurView
//
//  Created by Gian Franco Zabarino on 10/6/16.
//  Copyright © 2016 Gian Franco. All rights reserved.
//

#import "CCOInteractiveBlurView.h"
#import "UIImageEffects.h"

static NSUInteger const CCOBlurBackgroundViewDefaultNumberOfStages = 30;
static NSUInteger const CCOBlurBackgroundViewMaximumAnimationsPerSecond = 60;
static CGFloat const CCOBlurBackgroundViewDefaultMaximumRadius = 25.0;

#ifndef DLog
#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define DLog(...)
#define NSLog(...)
#endif
#endif

@interface CCOInteractiveBlurView ()

@property(nonatomic, strong) NSMutableArray *blurredImages;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *blurredImagesDictionary;
@property(nonatomic, strong) UIImage *snapshotImage;
@property(nonatomic, strong) UIImageView *firstImageView;
@property(nonatomic, strong) UIImageView *secondImageView;
@property(nonatomic, assign) NSUInteger numberOfStages;
@property(nonatomic, assign) CGFloat maximumRadius;
@property(nonatomic, assign) CFAbsoluteTime animationStartTime;
@property(nonatomic, strong) dispatch_queue_t queue;
@property(nonatomic, assign) BOOL hitTestInProgress;

- (void)onBackgroundTap;
- (void)setupWithMaximumRadius:(CGFloat)maximumRadius numberOfStages:(NSUInteger)numberOfStages;
- (void)animate:(NSUInteger)animationStep
  startingIndex:(NSUInteger)startingIndex
     totalSteps:(NSUInteger)totalSteps
       duration:(NSTimeInterval)duration
        reverse:(BOOL)reverse
     completion:(void (^)())completion;

@end

@implementation CCOInteractiveBlurView {
    CGFloat _percentage;
}

#pragma mark - View lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupWithMaximumRadius:CCOBlurBackgroundViewDefaultMaximumRadius
                  numberOfStages:CCOBlurBackgroundViewDefaultNumberOfStages];
}

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<CCOInteractiveBlurViewDelegate>)delegate {
    return [self initWithMaximumRadius:CCOBlurBackgroundViewDefaultMaximumRadius
                              delegate:delegate];
}

- (instancetype)initWithMaximumRadius:(CGFloat)maximumRadius
                             delegate:(id<CCOInteractiveBlurViewDelegate>)delegate {
    return [self initWithMaximumRadius:maximumRadius
                        numberOfStages:CCOBlurBackgroundViewDefaultNumberOfStages
                              delegate:delegate];
}

- (instancetype)initWithMaximumRadius:(CGFloat)maximumRadius
                       numberOfStages:(NSUInteger)numberOfStages
                             delegate:(id<CCOInteractiveBlurViewDelegate>)delegate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.delegate = delegate;
        [self setupWithMaximumRadius:maximumRadius numberOfStages:numberOfStages];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *realTouchedView = [super hitTest:point withEvent:event];
    if (self.isShowing) {
        // showing, continue with normal flow
        return realTouchedView;
    }
    if (self.hitTestInProgress) {
        // we called this superview's method (see below), and now it's calling us, so make ourselves 'transparent'
        return nil;
    }
    if (realTouchedView == self.firstImageView || realTouchedView == self.secondImageView || realTouchedView == self.contentView) {
        self.hitTestInProgress = YES;
        UIView *belowView = [self.superview hitTest:point withEvent:event];
        self.hitTestInProgress = NO;
        // return the view that should be touched if this view wouldn't be on the superview hierarchy
        return belowView;
    }
    // a view that has been added by the user is being touched, return it
    return realTouchedView;
}

#pragma mark - Public methods

- (void)prepareBlurEffect {
    // temporarily hide the content view, since it shouldn't be blurred
    CGRect originalFrame = self.contentView.frame;
    UIView *firstWindowSubview = self.superview;
    while (YES) {
        if ([firstWindowSubview.superview isKindOfClass:[UIWindow class]]) {
            break;
        }
        firstWindowSubview = firstWindowSubview.superview;
        if (!firstWindowSubview) {
            break;
        }
    }
    CGRect outOfHierarchyFrame = [firstWindowSubview.superview convertRect:self.bounds fromView:self];
    [firstWindowSubview.superview addSubview:self.contentView];
    self.contentView.frame = outOfHierarchyFrame;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CGRect rectInView = [firstWindowSubview convertRect:self.bounds fromView:self];
    // make this fast, set scale to 1
    UIGraphicsBeginImageContextWithOptions(rectInView.size, YES, 1.0);
    rectInView.origin.y = -rectInView.origin.y;
    rectInView.size = firstWindowSubview.bounds.size;
    [firstWindowSubview drawViewHierarchyInRect:rectInView afterScreenUpdates:YES];
    self.snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self addSubview:self.contentView];
    self.contentView.frame = originalFrame;
    DLog(@"taking screenshot took: %f", CFAbsoluteTimeGetCurrent() - now);
    self.blurredImages[0] = self.snapshotImage;
    now = CFAbsoluteTimeGetCurrent();
    DLog(@"starting to generate blurs");
    dispatch_apply(self.numberOfStages, self.queue, ^(size_t i) {
        CFAbsoluteTime innerNow = CFAbsoluteTimeGetCurrent();
        self.blurredImagesDictionary[@(i + 1)] = [UIImageEffects imageByApplyingBlurToImage:self.snapshotImage
                                                                                 withRadius:self.maximumRadius * ((CGFloat) i / self.numberOfStages)
                                                                                  tintColor:nil
                                                                      saturationDeltaFactor:1.0
                                                                                  maskImage:nil];
        if (i == self.numberOfStages - 1) {
            // repeat last stage
            self.blurredImagesDictionary[@(i + 2)] = self.blurredImagesDictionary[@(i + 1)];
        }
        DLog(@"%f", CFAbsoluteTimeGetCurrent() - innerNow);
    });
    DLog(@"generating blurs took: %f", CFAbsoluteTimeGetCurrent() - now);
    for (NSUInteger i = 1; i <= self.numberOfStages + 1; i++) {
        self.blurredImages[i] = self.blurredImagesDictionary[@(i)];
    }
    // trigger percentage setting with updated blur images
    self.percentage = self.percentage;
}

- (void)showBlur:(BOOL)showBlur animated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void (^)())completion {
    if (!self.blurredImages.count) {
        DLog(@"No blurred images have been generated yet, please call prepareBlurEffect to fix this");
        return;
    }
    if (animated) {
        if (showBlur && self.firstImageView.hidden) {
            self.firstImageView.hidden = NO;
            self.secondImageView.hidden = NO;
        }
        self.animationStartTime = CFAbsoluteTimeGetCurrent();
        [self animate:0
        startingIndex:0
           totalSteps:0
             duration:duration
              reverse:!showBlur
           completion:completion];
    } else {
        if (showBlur) {
            self.percentage = 1.0;
        } else {
            self.percentage = 0.0;
        }
    }
}

#pragma mark - Gesture Recognizers

- (void)onBackgroundTap {
    if ([self.delegate respondsToSelector:@selector(interactiveBlurViewOnBackgroundTap:)]) {
        [self.delegate interactiveBlurViewOnBackgroundTap:self];
    }
}

#pragma mark - Internal methods

- (void)setupWithMaximumRadius:(CGFloat)maximumRadius numberOfStages:(NSUInteger)numberOfStages {
    self.queue = dispatch_queue_create("com.circolo.blur_background_queue", DISPATCH_QUEUE_CONCURRENT);
    self.numberOfStages = numberOfStages;
    self.maximumRadius = maximumRadius;
    self.blurredImagesDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.blurredImages.count];
    self.blurredImages = [[NSMutableArray alloc] initWithCapacity:numberOfStages + 2];
    UIViewAutoresizing autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentView.autoresizingMask = autoresizingMask;
    self.contentView.frame = self.bounds;
    [self addSubview:self.contentView];
    self.firstImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.firstImageView.autoresizingMask = autoresizingMask;
    self.firstImageView.frame = self.bounds;
    self.firstImageView.hidden = YES;
    self.firstImageView.userInteractionEnabled = YES;
    [self.firstImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTap)]];
    [self.contentView addSubview:self.firstImageView];
    self.secondImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.secondImageView.autoresizingMask = autoresizingMask;
    self.secondImageView.frame = self.bounds;
    self.secondImageView.hidden = YES;
    self.secondImageView.userInteractionEnabled = YES;
    [self.secondImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTap)]];
    [self.contentView addSubview:self.secondImageView];
}

- (void)animate:(NSUInteger)animationStep
  startingIndex:(NSUInteger)startingIndex
     totalSteps:(NSUInteger)totalSteps
       duration:(NSTimeInterval)duration
        reverse:(BOOL)reverse
     completion:(void (^)())completion {
    if (!animationStep) {
        NSUInteger currentFirstImageIndex = (NSUInteger)(self.percentage * (self.blurredImages.count - 1));
        if (reverse) {
            currentFirstImageIndex--;
        }
        startingIndex = currentFirstImageIndex;
        NSUInteger availableImages = reverse ? currentFirstImageIndex : self.blurredImages.count - startingIndex - 1;
        totalSteps = (NSUInteger)MIN((CCOBlurBackgroundViewMaximumAnimationsPerSecond * duration), availableImages);
    }
    NSUInteger numberOfRemainingAnimations = totalSteps - animationStep;
    CFAbsoluteTime currentAnimationDuration = CFAbsoluteTimeGetCurrent() - self.animationStartTime;
    [UIView animateWithDuration:MAX(0.0, (duration - currentAnimationDuration)) / (NSTimeInterval)numberOfRemainingAnimations
                     animations:^{
                         self.secondImageView.alpha = reverse ? 0.0 : 1.0;
                     }
                     completion:^(BOOL finished) {
                         void (^finish)() = ^{
                             if (reverse) {
                                 self.firstImageView.hidden = YES;
                                 self.secondImageView.hidden = YES;
                                 self.secondImageView.alpha = 0.0;
                             } else {
                                 self.secondImageView.alpha = 1.0;
                             }
                             if (completion) {
                                 completion();
                             }
                         };
                         CGFloat animationPercentage = (animationStep + 1) / (CGFloat)totalSteps;
                         if (reverse) {
                             _percentage = startingIndex * (1.0 - animationPercentage) / (CGFloat)self.blurredImages.count;
                         } else {
                             _percentage = startingIndex * (1.0 - animationPercentage) / (CGFloat)self.blurredImages.count + animationPercentage;
                         }
                         DLog(@"percentage: %f", _percentage);
                         if (finished) {
                             if (animationStep + 1 < totalSteps) {
                                 float stepDelta = (reverse ? startingIndex : (self.blurredImages.count - 1 - startingIndex)) / (float)totalSteps;
                                 float realLowerIndex = startingIndex + (reverse ? -((animationStep + 2) * stepDelta) : ((animationStep + 1) * stepDelta));
                                 self.firstImageView.image = self.blurredImages[(NSUInteger)rintf(realLowerIndex)];
                                 self.secondImageView.image = self.blurredImages[(NSUInteger)rintf(realLowerIndex + stepDelta)];
                                 self.secondImageView.alpha = reverse ? 1.0 : 0.0;
                                 [self animate:animationStep + 1
                                 startingIndex:startingIndex
                                    totalSteps:totalSteps
                                      duration:duration
                                       reverse:reverse
                                    completion:completion];
                             } else {
                                 finish();
                             }
                         } else {
                             finish();
                         }
                     }];
}

#pragma mark - Override accessors

- (CGFloat)percentage {
    return _percentage;
}

- (void)setPercentage:(CGFloat)percentage {
    _percentage = percentage;
    DLog(@"interactive percentage: %f", _percentage);
    if (!self.blurredImages.count) {
        DLog(@"No blurred images have been generated yet, please call prepareBlurEffect to fix this");
        return;
    }
    percentage = MIN(1.0, MAX(percentage, 0.0));
    CGFloat blur = MIN(1.0, MAX(percentage, 0.0)) * (CGFloat) (self.blurredImages.count - 2);
    NSUInteger blurIndex = (NSUInteger) blur;
    CGFloat blurRemainder = blur - blurIndex;

    if (self.firstImageView.image != self.blurredImages[blurIndex]) {
        self.firstImageView.image = self.blurredImages[blurIndex];
    }
    if (ABS(self.secondImageView.alpha - blurRemainder) > CGFLOAT_MIN) {
        self.secondImageView.alpha = blurRemainder;
    }
    if (self.secondImageView.image != self.blurredImages[blurIndex + 1]) {
        self.secondImageView.image = self.blurredImages[blurIndex + 1];
    }
    if (percentage < FLT_MIN && !self.firstImageView.hidden) {
        self.firstImageView.hidden = YES;
        self.secondImageView.hidden = YES;
    } else if (percentage > FLT_MIN && self.firstImageView.hidden) {
        self.firstImageView.hidden = NO;
        self.secondImageView.hidden = NO;
    }
}

- (BOOL)isShowing {
    return _percentage > CGFLOAT_MIN;
}

@end
