//
//  UIScrollView+APParallaxHeader.m
//
//  Created by Mathias Amnell on 2013-04-12.
//  Copyright (c) 2013 Apping AB. All rights reserved.
//

#import "UIScrollView+APParallaxHeader.h"
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
@interface APParallaxView ()

@property (nonatomic, readwrite) APParallaxTrackingState state;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic) CGFloat parallaxHeight;

@property(nonatomic, assign) BOOL isObserving;

@end



#pragma mark - UIScrollView (APParallaxHeader)
#import <objc/runtime.h>

static char UIScrollViewParallaxView;

@implementation UIScrollView (APParallaxHeader)

- (void)addParallaxWithImage:(UIImage *)image andHeight:(CGFloat)height {
    
    if(!self.parallaxView) {
        APParallaxView *view = [[APParallaxView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, height)];
        [view.imageView setImage:image];
        
        
        view.scrollView = self;
        view.parallaxHeight = height;
        [self addSubview:view];
        
        view.originalTopInset = 50;
        
        UIEdgeInsets newInset = self.contentInset;
        newInset.top = height;
        self.contentInset = newInset;
        
        self.parallaxView = view;
        self.showsParallax = YES;
    }
}


//- (void)addParallaxWithMapLocation:(double)lat andLon:(double)lon atHeight:(CGFloat)height{
//    
//
//    if(!self.parallaxView) {
//        APParallaxView *view = [[APParallaxView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, height)];
//        //[view.imageView setImage:image];
//        
//        
//        view.mapView = [[MKMapView alloc]initWithFrame:CGRectMake(0, 0, self.bounds.size.width, height)];
//        view.mapView.userInteractionEnabled = YES;
//        [view.imageView addSubview:view.mapView ];
//    
//        [view.mapView  setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
//        [view.mapView  setContentMode:UIViewContentModeScaleAspectFill];
//        [view.mapView  setClipsToBounds:YES];
//        
//        
//        
//        view.scrollView = self;
//        view.parallaxHeight = height;
//        [self addSubview:view];
//        
//        view.originalTopInset = 50;
//        
//        UIEdgeInsets newInset = self.contentInset;
//        newInset.top = height;
//        self.contentInset = newInset;
//        
//        self.parallaxView = view;
//        self.showsParallax = YES;
//    }
//}




- (void)setParallaxView:(APParallaxView *)parallaxView {
    [self willChangeValueForKey:@"APParallaxView"];
    objc_setAssociatedObject(self, &UIScrollViewParallaxView,
                             parallaxView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"APParallaxView"];
}

- (APParallaxView *)parallaxView {
    return objc_getAssociatedObject(self, &UIScrollViewParallaxView);
}

- (void)setShowsParallax:(BOOL)showsParallax {
    self.parallaxView.hidden = !showsParallax;
    
    if(!showsParallax) {
        if (self.parallaxView.isObserving) {
            [self removeObserver:self.parallaxView forKeyPath:@"contentOffset"];
            [self removeObserver:self.parallaxView forKeyPath:@"frame"];
            self.parallaxView.isObserving = NO;
        }
    }
    else {
        if (!self.parallaxView.isObserving) {
            [self addObserver:self.parallaxView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.parallaxView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.parallaxView.isObserving = YES;
        }
    }
}

- (BOOL)showsParallax {
    return !self.parallaxView.hidden;
}

@end

#pragma mark - ShadowLayer

@interface ShadowView : UIView

@end

@implementation ShadowView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setOpaque:NO];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    //// Gradient Declarations
    NSArray* gradient3Colors = [NSArray arrayWithObjects:
                                (id)[UIColor colorWithWhite:0 alpha:0.3].CGColor,
                                (id)[UIColor clearColor].CGColor, nil];
    CGFloat gradient3Locations[] = {0, 1};
    CGGradientRef gradient3 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradient3Colors, gradient3Locations);
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, CGRectGetWidth(rect), 8)];
    CGContextSaveGState(context);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient3, CGPointMake(0, CGRectGetHeight(rect)), CGPointMake(0, 0), 0);
    CGContextRestoreGState(context);
    
    
    //// Cleanup
    CGGradientRelease(gradient3);
    CGColorSpaceRelease(colorSpace);

}

@end

#pragma mark - APParallaxView

@implementation APParallaxView

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [self setState:APParallaxTrackingActive];
        [self setAutoresizesSubviews:YES];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
        [self.imageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.imageView setClipsToBounds:YES];
        [self addSubview:self.imageView];
        
        self.shadowView = [[ShadowView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(frame)-8-0, CGRectGetWidth(frame), 8)];
        [self.shadowView setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
        [self addSubview:self.shadowView];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    
    
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsParallax) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "APParallaxView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
}


- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    // We do not want to track when the parallax view is hidden
    //NSLog(@"%f",contentOffset);
    if (contentOffset.y > 0.) {
        [self setState:APParallaxTrackingInactive];
    } else {
        [self setState:APParallaxTrackingActive];
    }
    
    if(self.state == APParallaxTrackingActive) {
        CGFloat yOffset = contentOffset.y*-1;
        [self setFrame:CGRectMake(0, contentOffset.y, CGRectGetWidth(self.frame), yOffset)];
    }
}
@end
