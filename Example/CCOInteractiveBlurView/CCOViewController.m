//
//  CCOViewController.m
//  CCOInteractiveBlurView
//
//  Created by Gian Franco Zabarino on 06/10/2016.
//  Copyright (c) 2016 Gian Franco Zabarino. All rights reserved.
//

#import "CCOViewController.h"
#import <CCOInteractiveBlurView/CCOInteractiveBlurView.h>

@interface CCOViewController ()

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
    [self.view addSubview:self.backgroundImageView];
    self.dimmerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.dimmerView.backgroundColor = [UIColor blackColor];
    [self.dimmerView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)]];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)]];
    self.blurBackgroundView = [[CCOInteractiveBlurView alloc] init];
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

#pragma mark - Internal methods

- (void)onTap {
    static BOOL show = YES;
    CGRect targetFrame = CGRectMake(0, show ? 0 : self.blurBackgroundView.bounds.size.height - 100, 100, 100);
    [self.blurBackgroundView showBlur:show
                             animated:YES
                             duration:0.5
                           completion:nil];
    show = !show;
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
