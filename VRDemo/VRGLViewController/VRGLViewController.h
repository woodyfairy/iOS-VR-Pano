//
//  GLVRViewController.h
//  VRTest
//
//  Created by wdy on 2019/1/24.
//  Copyright © 2019 wdy. All rights reserved.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VRGLViewController : GLKViewController
@property (strong, nonatomic) UIImage *image;
@property (assign, nonatomic) float rotX;//水平旋转0-1
@property (assign, nonatomic) float rotY;//竖直旋转0-1
-(void)setRotX:(float)rotX RotY:(float)rotY;//同时旋转0-1
@property (assign, nonatomic) float viewfield;// 视野0-1
@property (assign, nonatomic) float perspective; //使用透视还是鱼眼？0-1

@property (assign, nonatomic) float perspective_minAngel, perspective_maxAngel;
@property (assign, nonatomic) float fisheye_minAngel, fisheye_maxAngel;


//test
-(void)setRotation:(float)rot;
@end

NS_ASSUME_NONNULL_END
