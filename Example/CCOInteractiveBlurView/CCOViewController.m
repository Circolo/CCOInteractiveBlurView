//
//  CCOViewController.m
//  CCOInteractiveBlurView
//
//  Created by Gian Franco Zabarino on 06/10/2016.
//  Copyright (c) 2016 Gian Franco Zabarino. All rights reserved.
//

#import "CCOViewController.h"
#import <CCOInteractiveBlurView/CCOInteractiveBlurView.h>

@interface CCOViewController () <CCOInteractiveBlurViewDelegate, UIGestureRecognizerDelegate>

@property(nonatomic, strong) UIImageView *backgroundImageView;
@property(nonatomic, strong) UIView *dimmerView;
@property(nonatomic, strong) CCOInteractiveBlurView *blurBackgroundView;
@property(nonatomic, assign) BOOL madeFirstAppearing;

- (void)onTap;
- (void)onPan:(UIPanGestureRecognizer *)panGestureRecognizer;

@end

@implementation CCOViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewAutoresizing autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background"]];
    self.backgroundImageView.autoresizingMask = autoresizingMask;
    self.backgroundImageView.frame = self.view.bounds;
    self.backgroundImageView.userInteractionEnabled = YES;
    [self.backgroundImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)]];
    [self.view addSubview:self.backgroundImageView];
    self.dimmerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.dimmerView.backgroundColor = [UIColor blackColor];
    [self.dimmerView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)]];
    self.blurBackgroundView = [[CCOInteractiveBlurView alloc] initWithDelegate:self];
    self.blurBackgroundView.autoresizingMask = autoresizingMask;
    self.blurBackgroundView.frame = self.view.bounds;
    [self.view addSubview:self.blurBackgroundView];
    [self.blurBackgroundView.contentView addSubview:self.dimmerView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.madeFirstAppearing) {
        self.dimmerView.frame = CGRectMake(0, self.blurBackgroundView.bounds.size.height - 100, 100, 100);
        [self.blurBackgroundView prepareBlurEffect];
        self.madeFirstAppearing = YES;
    }
}

#pragma mark - CCOInteractiveBlurViewDelegate methods

- (void)interactiveBlurViewOnBackgroundTap:(CCOInteractiveBlurView *)interactiveBlurView {
    CGRect targetFrame = CGRectMake(0, self.blurBackgroundView.bounds.size.height - 100, 100, 100);
    [self.blurBackgroundView showBlur:NO
                             animated:YES
                             duration:0.5
                           completion:nil];
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.dimmerView.frame = targetFrame;
                     }
                     completion:nil];
}

#pragma mark - Gesture Recognizers

- (void)onTap {
    CGRect targetFrame = CGRectMake(0, 0, 100, 100);
    [self.blurBackgroundView showBlur:YES
                             animated:YES
                             duration:0.5
                           completion:nil];
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.dimmerView.frame = targetFrame;
                     }
                     completion:nil];
}

- (void)onPan:(UIPanGestureRecognizer *)panGestureRecognizer {
    static CGFloat startingOrigin;
    UIView *view = panGestureRecognizer.view;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        startingOrigin = view.frame.origin.y;
    } else {
        CGRect frame = view.frame;
        frame.origin.y = startingOrigin + [panGestureRecognizer translationInView:view.superview].y;
        view.frame = frame;
        CGFloat maximumY = view.superview.bounds.size.height - view.frame.size.height;
        self.blurBackgroundView.percentage = 1.0 - MIN(MAX(0.0, frame.origin.y), maximumY) / maximumY;
    }
}

@end
