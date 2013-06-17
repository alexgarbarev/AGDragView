//
//  ZBDragView.m
//
//  Created by Aleksey Garbarev on 26.03.13.
//

#import "AGDragView.h"

/////////////////// OnlyContentTouchableScrollView


@interface OnlyContentTouchableScrollView : UIScrollView

@end

@implementation OnlyContentTouchableScrollView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView * view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}

@end

///////////////////

typedef enum {
    ZBDragViewStateMinimized = 0, ZBDragViewStateFullscreen
} ZBDragViewState;

@interface AGDragView () <UIScrollViewDelegate>

@property (nonatomic) ZBDragViewState state;

@end

@implementation AGDragView {
    OnlyContentTouchableScrollView *_scrollView;
    BOOL _originalContentScroll;
    CGFloat _maximizedPosition;
    
    struct {
        BOOL didScrollToPosition;
        BOOL beginDecelerate;
        BOOL endDecelerate;
    } _delegateResponds;
}

@dynamic size;

- (void) commonInit
{
    _scrollView = [[OnlyContentTouchableScrollView alloc] initWithFrame:self.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _scrollView.delegate = self;
    _scrollView.contentSize = CGSizeZero;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    
    _maximizedPosition = 0.0f;
    _minimizedHeight = 60.0f;
    _deteachHeight = 0.0f;
    _deteachBouncesWithHeader = NO;
    
    _stickHeight = 40.0f;
    
    _state = ZBDragViewStateMinimized;
    
    [self addSubview:_scrollView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.contentScrollView = nil;
}

#pragma mark - Layout

- (void) didMoveToSuperview
{
    if (self.superview) {
        [self.superview addGestureRecognizer:self.panGestureRecognizer];
        [self setNeedsLayout];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [self.superview removeGestureRecognizer:self.panGestureRecognizer];
}

- (void) layoutSubviews
{
    [self updateMaximizedPosition];
    
    /* Layout self frame */
    CGSize size;
    size.width = self.superview.bounds.size.width;
    size.height = self.superview.bounds.size.height + _headerView.bounds.size.height + _navigationBar.frame.size.height * _shouldHidesNavigationBar;
    
    if (_state == ZBDragViewStateFullscreen) {
        self.frame = (CGRect){ 0, _maximizedPosition, size};
    } else {
        self.frame = (CGRect){ 0, -_scrollView.contentOffset.y, size};
    }
    
    /* Layout content */
    _headerView.frame = (CGRect){CGPointZero, _headerView.frame.size};
    _contentView.frame = (CGRect){0.0f, CGRectGetMaxY(_headerView.frame), size.width, size.height -_headerView.frame.size.height };
    
    [_headerView layoutSubviews];
    [_contentView layoutSubviews];
    [_contentScrollView layoutSubviews];
    
    /* Layout scrollView */
    [self layoutScrollViewSize];
    
    _scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(_contentView.frame.origin.y, 0, 0, 0);

    [super layoutSubviews];
}

- (void) minimizeAnimated:(BOOL)animated
{
    self.state = ZBDragViewStateMinimized;
    [self layoutScrollViewSize];
    [self setPosition:_scrollView.contentInset.top animated:animated];
}

- (void) maximizeAnimated:(BOOL)animated
{
    [self setPosition:_maximizedPosition - 1 animated:animated];
}

- (void) setPosition:(CGFloat)position animated:(BOOL)animated
{
    [_scrollView setContentOffset:_scrollView.contentOffset animated:NO]; //To stop scrolling hack
    [_scrollView setContentOffset:CGPointMake(0, -position) animated:animated];
}

- (void) updateMaximizedPosition
{
    _maximizedPosition = - (_headerView.frame.size.height + _navigationBar.frame.size.height * _shouldHidesNavigationBar);
}

- (void) refresh
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollViewDidScroll:_scrollView];
    });
}

#pragma mark - Properties

- (void)setNavigationBar:(UINavigationBar *)navigationBar
{
    [[_navigationBar superview] removeGestureRecognizer:self.panGestureRecognizer];
    _navigationBar = navigationBar;
    [[_navigationBar superview] addGestureRecognizer:self.panGestureRecognizer];
    [self setNeedsLayout];
}

- (void)setDelegate:(id<AGDragViewDelegate>)delegate
{
    _delegate = delegate;
    
    _delegateResponds.beginDecelerate = [delegate respondsToSelector:@selector(dragViewBeginDeceleration:)];
    _delegateResponds.endDecelerate = [delegate respondsToSelector:@selector(dragViewDidEndDecelerating:)];
    _delegateResponds.didScrollToPosition = [delegate respondsToSelector:@selector(dragView:didScrollToPosition:)]; 
}

- (void) setContentView:(UIView *)contentView
{
    [_contentView removeFromSuperview];
    _contentView = contentView;
    [self insertSubview:_contentView belowSubview:_scrollView];
    [self setNeedsLayout];
}

- (void)setState:(ZBDragViewState)state
{
    if (_state != state) {
        _state = state;
        [self layoutScrollViewSize];
        
        if (_shouldHidesNavigationBar) {
            /* Ugly hack, but I need to hide _navigationBar without setting hidden flag (alpha = 0 also marks as hidden) */
            _navigationBar.alpha = !(_state == ZBDragViewStateFullscreen) + 0.0001;
        }
    }
}

- (void)setMinimizedHeight:(CGFloat)minimizedHeight
{
    _minimizedHeight = minimizedHeight;
    [self setNeedsLayout];
}

- (void) setHeaderView:(UIView *)headerView
{
    [_headerView removeFromSuperview];
    _headerView = headerView;

    [self insertSubview:_headerView belowSubview:_scrollView];
    
    [self updateMaximizedPosition];

    [self setNeedsLayout];
}

- (void) setContentScrollView:(UIScrollView *)contentScrollView
{
    /* Restore scrollEnabled  */
    if (_contentScrollView) {
        _contentScrollView.scrollEnabled = _originalContentScroll;
    }
    
    if (contentScrollView) {
        _originalContentScroll = contentScrollView.scrollEnabled;
        _contentScrollView = contentScrollView;
        _contentScrollView.scrollEnabled = NO;
    }
}

- (UIPanGestureRecognizer *) panGestureRecognizer
{
    return _scrollView.panGestureRecognizer;
}


- (void)setPosition:(CGFloat)position
{    
    _scrollView.contentOffset =  CGPointMake(0, -position);
    [self scrollViewDidScroll:_scrollView];
}

- (CGFloat)position
{
    return self.frame.origin.y;
}

- (void)setSize:(CGSize)size
{
    CGRect currentFrame = self.frame;
    currentFrame.size = size;
    self.frame = currentFrame;
}

- (CGSize)size
{
    return self.bounds.size;
}

#pragma mark - UIScrollView Delegate methods

- (void) layoutScrollViewSize
{

    CGFloat contentHeight = MAX(_contentScrollView.contentSize.height, self.bounds.size.height);

    if (_state == ZBDragViewStateFullscreen) {
        _scrollView.contentInset = UIEdgeInsetsMake( _maximizedPosition, 0, contentHeight - _maximizedPosition + _headerView.bounds.size.height, 0);
        _scrollView.showsVerticalScrollIndicator = YES;
    } else if (_state == ZBDragViewStateMinimized){
        _contentScrollView.contentOffset = CGPointZero;
        _scrollView.contentInset = UIEdgeInsetsMake( self.superview.bounds.size.height - _minimizedHeight, 0, contentHeight - _maximizedPosition, 0);
        _scrollView.showsVerticalScrollIndicator = NO;
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{

    CGFloat dragPosition = -_scrollView.contentOffset.y;
    
    /* Switching to fullscreen mode */
    if (_state == ZBDragViewStateMinimized && dragPosition <= _maximizedPosition) {
        if (_contentScrollView.contentSize.height > self.bounds.size.height) {
            self.state = ZBDragViewStateFullscreen;
        }
    }
    
    /* Switching to miminized mode */
    if (_state == ZBDragViewStateFullscreen && (dragPosition > _maximizedPosition + _deteachHeight) ) {
        
        self.state = ZBDragViewStateMinimized;
    
        BOOL animated = _deteachHeight > 0;
        
        if (animated) {
            CFTimeInterval animationDuration = 0.3f;
            CFTimeInterval delegateAnimationDuration = 0.23f; /* Hardcoded magical constant */
            
            _contentScrollView.contentOffset = CGPointMake(0, -_deteachHeight);
            [UIView animateWithDuration:animationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut  animations:^{
                CGRect frame = self.frame;
                frame.origin.y = dragPosition;
                self.frame = frame;
                _contentScrollView.contentOffset = CGPointMake(0, 0);
            } completion:nil];
            
            [UIView animateWithDuration:delegateAnimationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState  animations:^{
                if (_delegateResponds.didScrollToPosition) {
                    [_delegate dragView:self didScrollToPosition:CGPointMake(0, self.frame.origin.y)];
                }
            } completion:nil];
        } else {
            _contentScrollView.contentOffset = CGPointMake(0, 0);
        }
    }

    BOOL dragContent = (_state == ZBDragViewStateFullscreen);
    BOOL dragView = (_deteachBouncesWithHeader) || ((_state == ZBDragViewStateMinimized) || self.frame.origin.y != _maximizedPosition);
    BOOL dragNavigationBar = dragPosition > _maximizedPosition;//dragPosition < 0; && dragPosition > _maximizedPosition && _navigationBar.frame.origin.y != 0 && _navigationBar.frame.origin.y != _maximizedPosition;
    
    if (dragView) {
        CGRect frame = self.frame;
        frame.origin.y = MAX(dragPosition, _maximizedPosition);
        self.frame = frame;
        
        if (_delegateResponds.didScrollToPosition) {
            [_delegate dragView:self didScrollToPosition:CGPointMake(0, self.frame.origin.y)];
        }
    }
    
    if (dragContent) {
        self.contentScrollView.contentOffset = CGPointMake(0, - (dragPosition - _maximizedPosition) );
    }
    
    /* Layout navigationBar */
    if (dragNavigationBar && _shouldHidesNavigationBar && _navigationBar) {
        CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
        statusBarFrame = [self convertRect:statusBarFrame fromView:self.window];
        
        CGRect navigationBarFrame = _navigationBar.frame;
        navigationBarFrame.origin.y = statusBarFrame.size.height + MIN(dragPosition, 0);
        _navigationBar.frame = navigationBarFrame;
    }
}

- (void) scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if (_delegateResponds.beginDecelerate && _state == ZBDragViewStateMinimized) {
        [_delegate dragViewBeginDeceleration:self];
    }
}

- (void) stickIfNeeded
{
    if (_stickHeight == 0) {
        return;
    }
    
    CGFloat distanceToFullscreen = self.position;
    CGFloat distanceToStart = _scrollView.contentInset.top - self.position;
    
    if (distanceToStart <= _stickHeight) {
        [self minimizeAnimated:YES];
    } else if (distanceToFullscreen <= _stickHeight) {
        [self maximizeAnimated:YES];
    }
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate && _state == ZBDragViewStateMinimized) {
        [self stickIfNeeded];
        if (_delegateResponds.endDecelerate) {
            
            [_delegate dragViewDidEndDecelerating:self];
        }
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (!scrollView.tracking && _state == ZBDragViewStateMinimized) {
        [self stickIfNeeded];
        if (_delegateResponds.endDecelerate) {
            [_delegate dragViewDidEndDecelerating:self];
        }
    }
}


@end


