//
//  ZBDragView.h
//
//  Created by Aleksey Garbarev on 26.03.13.
//

#import <UIKit/UIKit.h>

@protocol ZBDragViewDelegate;

@interface ZBDragView : UIView

@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, weak)   IBOutlet UIScrollView *contentScrollView;
@property (nonatomic, weak)   IBOutlet id<ZBDragViewDelegate> delegate;

@property (nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic) CGFloat minimizedHeight;       /* Default: 60.0f */
@property (nonatomic) CGFloat deteachHeight;         /* Default: 0.0f */
@property (nonatomic) BOOL deteachBouncesWithHeader; /* Default: NO */

/* You should use this values to setup DragView position and size instead of set frame */
@property (nonatomic) CGFloat position;
@property (nonatomic) CGSize size;

@property (nonatomic) CGFloat stickHeight;          /* Default: 40.0f */


@property (nonatomic, weak) UINavigationBar *navigationBar;
@property (nonatomic) BOOL shouldHidesNavigationBar; /* Default: NO. Don't forget to set navigationBar when set to YES */

/* Refresh current position. Call at viewWillAppear time */
- (void) refresh;

- (void) setPosition:(CGFloat)position animated:(BOOL)animated;
- (void) minimizeAnimated:(BOOL)animated;
- (void) maximizeAnimated:(BOOL)animated;

@end


@protocol ZBDragViewDelegate <NSObject>

@optional
- (void) dragView:(ZBDragView *)view didScrollToPosition:(CGPoint)position;
- (void) dragViewBeginDeceleration:(ZBDragView *)view;
- (void) dragViewDidEndDecelerating:(ZBDragView *)view;

@end