//
//  ViewController.m
//  VRTest
//
//  Created by taagoo on 2019/1/21.
//  Copyright © 2019 taagoo. All rights reserved.
//

#import "ViewController.h"
#import "VRGLViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *vrView;
@property (weak, nonatomic) IBOutlet UISlider *rotX;
@property (weak, nonatomic) IBOutlet UISlider *rotY;
@property (weak, nonatomic) IBOutlet UISlider *viewField;
@property (weak, nonatomic) IBOutlet UISlider *perspective;

@property (strong, nonatomic) VRGLViewController *vrViewController;

@property (weak, nonatomic) IBOutlet UIScrollView *btnsScrollView;
@property (weak, nonatomic) IBOutlet UIView *scrollContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollWidth;
@property (strong, nonatomic) NSArray *arrImageNames;

//手势
@property (strong, nonatomic) UIPanGestureRecognizer *pan;
@property (assign, nonatomic) CGPoint originRot;
@property (assign, nonatomic) CGPoint rotSpeed;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSDate *startTime; //动画开始时间
@property (nonatomic, strong) NSDate *lastUpdateTime;
@property (nonatomic, assign) float animTime;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _vrViewController = [[VRGLViewController alloc] init];
    [_vrViewController setPreferredFramesPerSecond:40];
    [self.vrView addSubview: _vrViewController.view];
    [_vrViewController.view setFrame: self.vrView.bounds];
    [_vrViewController setImage:[UIImage imageNamed:@"testRoom1_2kMono.jpg"]];
    
    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [_vrView addGestureRecognizer:_pan];
    
    self.arrImageNames = @[@"testRoom1_2kMono.jpg", @"1-1ceshi.jpg", @"1-3测试.jpg", @"1-4测试.jpg", @"1-5测试.jpg", @"2.jpg", @"3.jpg"];
    for (int i = 0; i< self.arrImageNames.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.scrollContentView addSubview:btn];
        btn.tag = i;
        [btn addTarget:self action:@selector(imageChanged:) forControlEvents:UIControlEventTouchUpInside];
        //[btn setTranslatesAutoresizingMaskIntoConstraints:NO];
        //btn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
        [btn setFrame:CGRectMake(160 * i + 4 * (i+1), 0, 160, 80)];
        [btn setContentMode:UIViewContentModeScaleAspectFill];
        UIImage *image = [UIImage imageNamed:[self.arrImageNames objectAtIndex:i]];
        UIImage *compressImage = [self compressPictureWith:image MaxSize:160];
        [btn setImage:compressImage forState:UIControlStateNormal];
    }
    self.scrollWidth.constant = 160 * self.arrImageNames.count + 4 * (self.arrImageNames.count+1);
}
-(UIImage *)compressPictureWith:(UIImage *)originnalImage MaxSize:(float)maxSize{
    CGFloat ruleSize = maxSize;
    if (originnalImage.size.width <= ruleSize && originnalImage.size.height <= ruleSize) {
        return originnalImage;
    }
    
    CGFloat width = originnalImage.size.width, height = originnalImage.size.height;
    if (width > ruleSize) {
        height = ruleSize/width * height;
        width = ruleSize;
    }
    if (height > ruleSize) {
        width = ruleSize/height * width;
        height = ruleSize;
    }
    
    CGRect rect = CGRectMake(0, 0, width, height);
    // 开启图片上下文
    UIGraphicsBeginImageContext(rect.size);
    // 将图片渲染到图片上下文
    [originnalImage drawInRect:rect];
    // 获取图片
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    // 关闭图片上下文
    UIGraphicsEndImageContext();
    return img;
}

-(void)dealloc{
    [self stopAnim];
}

-(void)pan:(UIPanGestureRecognizer *)gesture{
    float size = MIN(_vrView.bounds.size.width, _vrView.bounds.size.height);
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _originRot = CGPointMake(_rotX.value, _rotY.value);
        [self stopAnim];
    }else if (gesture.state == UIGestureRecognizerStateChanged){
        CGPoint trans = [gesture translationInView: _vrView];
//        float size = MIN(_vrView.bounds.size.width, _vrView.bounds.size.height);
        float perspViewfield = _viewField.value * (_vrViewController.perspective_maxAngel - _vrViewController.perspective_minAngel) + _vrViewController.perspective_minAngel;
        float fishViewfield = _viewField.value * (_vrViewController.fisheye_maxAngel - _vrViewController.fisheye_minAngel) + _vrViewController.fisheye_minAngel;
        float viewField = _perspective.value * perspViewfield + (1 - _perspective.value) * fishViewfield;
        float x = _originRot.x + trans.x / size * viewField / M_PI;
        float y = _originRot.y + trans.y / size * viewField / M_PI;
        [self setRotX:x RotY:y];
        
    }else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled){
        _rotSpeed = [gesture velocityInView: _vrView];
        float fullSpeed = sqrtf(_rotSpeed.x * _rotSpeed.x + _rotSpeed.y * _rotSpeed.y);
        _animTime = MIN(fullSpeed/size, 0.7);
        [self startAnim];
    }
}
-(void)setRotX:(float)x RotY:(float)y{
    while (x < 0) {
        x += 1;
    }
    while (x > 1) {
        x -= 1;
    }
    if (y < 0) {
        y = 0;
    }
    if (y > 1) {
        y = 1;
    }
    
    _rotX.value = x;
    _rotY.value = y;
    
    [_vrViewController setRotX:x RotY:y];
}

-(void)startAnim{
    [self stopAnim];
    _startTime = [NSDate date];
    _lastUpdateTime = [NSDate date];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    if (@available(iOS 10, *)) {
        self.displayLink.preferredFramesPerSecond = 0; //default
    }else{
        self.displayLink.frameInterval = 1;
    }
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];//NSRunLoopCommonModes才能保证动画不被阻塞
}
-(void)stopAnim{
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}
-(void)update{
    double time = [[NSDate date] timeIntervalSinceDate: _startTime];
    float leftPercent = (_animTime - time) / _animTime;
    if (leftPercent <= 0) {
        [self stopAnim];
        return;
    }
    
    CGPoint nowSpeed = CGPointMake(_rotSpeed.x * leftPercent, _rotSpeed.y * leftPercent);
    
    double timeInterval = [[NSDate date] timeIntervalSinceDate: _lastUpdateTime];
    float x = _rotX.value;
    float y = _rotY.value;
    
    float size = MIN(_vrView.bounds.size.width, _vrView.bounds.size.height);
    float perspViewfield = _viewField.value * (_vrViewController.perspective_maxAngel - _vrViewController.perspective_minAngel) + _vrViewController.perspective_minAngel;
    float fishViewfield = _viewField.value * (_vrViewController.fisheye_maxAngel - _vrViewController.fisheye_minAngel) + _vrViewController.fisheye_minAngel;
    float viewField = _perspective.value * perspViewfield + (1 - _perspective.value) * fishViewfield;
//    float x = _originRot.x + trans.x / size * viewField / M_PI;
//    float y = _originRot.y + trans.y / size * viewField / M_PI;
    x += nowSpeed.x * timeInterval / size * viewField / M_PI;
    y += nowSpeed.y * timeInterval/ size * viewField / M_PI;
    
    [self setRotX:x RotY:y];
    
    _lastUpdateTime = [NSDate date];
}


- (IBAction)xRoted:(id)sender {
    //_vrView.rotX = _rotX.value;
    //[_vrViewController setRotation:_rotX.value * 360];
    [_vrViewController setRotX:_rotX.value];
}
- (IBAction)yRoted:(id)sender {
    //_vrView.rotY = _rotY.value;
    [_vrViewController setRotY:_rotY.value];
}
- (IBAction)viewChanged:(id)sender {
    //_vrView.visualAngle = _visualAngle.value;
    [_vrViewController setViewfield:_viewField.value];
}
- (IBAction)perspectiveChanged:(id)sender {
    [_vrViewController setPerspective: _perspective.value];
}

- (IBAction)imageChanged:(UIButton *)sender {
    //[_vrViewController setImage:sender.imageView.image];
    UIImage *oriImage = [UIImage imageNamed:[self.arrImageNames objectAtIndex:sender.tag]];
    UIImage *image = [self compressPictureWith:oriImage MaxSize:4096];
    [_vrViewController setImage:image];
}

@end
