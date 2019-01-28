//
//  GLVRViewController.m
//  VRTest
//
//  Created by taagoo on 2019/1/24.
//  Copyright © 2019 taagoo. All rights reserved.
//

#import "VRGLViewController.h"

#define GLES_SILENCE_DEPRECATION

@interface VRGLViewController ()
@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic , assign) GLuint       myProgram;
@end

@implementation VRGLViewController

//设置顶点信息数组
const GLfloat Vertices[] = {
    1, -1, 0.0f,    1.0f, 0.0f, //右下(x,y,z坐标 + s,t纹理)
    -1, 1, 0.0f,    0.0f, 1.0f, //左上
    -1, -1, 0.0f,   0.0f, 0.0f, //左下
    1, 1, 0.0f,    1.0f, 1.0f, //右上
};

//设置顶点索引数组
const GLuint indices[] = {
    0,1,2,
    1,3,0
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    //颜色缓冲区格式
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    //self.context为OpenGL的"当前激活的Context"。之后所有"GL"指令均作用在这个Context上。
    if (![EAGLContext setCurrentContext:self.context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    [self setupVBOs];
    
    //读取文件路径
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"v" ofType:@"vsh"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"f" ofType:@"fsh"];
    
    //加载shader
    self.myProgram = [self loadShaders:vertFile frag:fragFile];
    
    //链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) { //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return ;
    }
    else {
        NSLog(@"link ok");
        glUseProgram(self.myProgram); //成功便使用，避免由于未使用导致的的bug
    }
    
//    GLuint attrBuffer;
//    glGenBuffers(1, &attrBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);
    
    GLuint textCoor = glGetAttribLocation(self.myProgram, "textCoordinate");
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);
    
//    [self setZRotation:180];
    [self setRotX:0];
    [self setRotY:0];
    [self setViewfield:1];
    [self setPerspective:1];
    self.perspective_minAngel = 30.f * M_PI / 180.f;
    self.perspective_maxAngel = 60.f * M_PI / 180.f;
    self.fisheye_minAngel = 30.f * M_PI / 180.f;
    self.fisheye_maxAngel = M_PI;
}
- (void)setupVBOs{
    
    /** VBO ： 顶点缓存区对象
     两种顶点缓存类型：一种是用于跟踪每个顶点信息的（Vertices），另一种是用于跟踪组成每个三角形的索引信息（我们的Indices)
     */
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indicesBuffer;
    glGenBuffers(1, &indicesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    //启动
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    //为vertex shader的两个输入参数（Position 和 TexCoord）配置两个合适的值
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}


#pragma mark - GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    // 清屏
    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // 绘制
    int mCount = sizeof(indices) / sizeof(indices[0]);
    glDrawElements(GL_TRIANGLES, mCount, GL_UNSIGNED_INT, 0);
}


-(void)setImage:(UIImage *)image{
    _image = image;
    [self setupTexture:image];
}


- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

- (GLuint)setupTexture:(UIImage *)image {
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = image.CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load Texture");
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    glBindTexture(GL_TEXTURE_2D, 0);
    
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
//    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(spriteData);
    return 0;
}

//长宽比
-(void)viewWillLayoutSubviews{
    float w = 1;
    float h = 1;
    if (self.view.frame.size.width <= self.view.frame.size.height) {
        w = self.view.frame.size.width / self.view.frame.size.height;
    }else{
        h = self.view.frame.size.height / self.view.frame.size.width;
    }
    GLuint uintW = glGetUniformLocation(self.myProgram, "widthScale");
    glUniform1f(uintW, w);
    GLuint uintH = glGetUniformLocation(self.myProgram, "heightScale");
    glUniform1f(uintH, h);
}

/*
//zRotation
-(void)setZRotation:(float)rot{
    //获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    GLuint rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");
    
    float radians = rot * M_PI / 180.0f;
    float s = sin(radians);
    float c = cos(radians);
    
    //z轴旋转矩阵
    GLKMatrix4 scale = GLKMatrix4MakeScale(-1, 1, 1);
    GLKMatrix4 rotation = GLKMatrix4MakeRotation(radians , 0.0, 0.0, 1.0);
    GLKMatrix4 transformMatrix = GLKMatrix4Multiply(rotation, scale);
    
    GLfloat *zRotation = transformMatrix.m;
    glUniformMatrix4fv(rotate, 1, GL_FALSE, zRotation);
    
//    GLfloat zRotation[16] = { //
//        c, -s, 0, 0, //
//        s, c, 0, 0,//
//        0, 0, 1.0, 0,//
//        0.0, 0, 0, 1.0//
//    };
    //设置旋转矩阵
//    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
}
 */
-(void)setRotX:(float)rotX{
    _rotX = rotX;//0-1
    [self setRotMatrix];
}
-(void)setRotY:(float)rotY{
    _rotY = rotY;
    [self setRotMatrix];
}
-(void)setRotX:(float)rotX RotY:(float)rotY{
    _rotX = rotX;
    _rotY = rotY;
    [self setRotMatrix];
}
-(void)setRotMatrix{
    //先转到左下角
    
    float radiansX = -_rotX * M_PI * 2; //相反
    float radiansY = _rotY * M_PI;
    GLKMatrix4 rotationX = GLKMatrix4MakeRotation(radiansX , 0.0, 0.0, 1.0);
    GLKMatrix4 rotationY = GLKMatrix4MakeRotation(radiansY , 1.0, 0.0, 0.0);
    
    GLuint uint = glGetUniformLocation(self.myProgram, "rotMatrix");
    GLKMatrix4 transformMatrix = GLKMatrix4Multiply(rotationY, rotationX);
    GLfloat *rot = transformMatrix.m;
    glUniformMatrix4fv(uint, 1, GL_FALSE, rot);
}

-(void)setViewfield:(float)viewfield{
    _viewfield = viewfield;
    GLuint uint = glGetUniformLocation(self.myProgram, "viewfield");
    glUniform1f(uint, viewfield);
}

-(void)setPerspective:(float)perspective{
    _perspective = perspective;
    GLuint uint = glGetUniformLocation(self.myProgram, "perspective");
    glUniform1f(uint, perspective);
}
-(void)setPerspective_minAngel:(float)perspective_minAngel{
    _perspective_minAngel = perspective_minAngel;
    GLuint uint = glGetUniformLocation(self.myProgram, "p_min");
    glUniform1f(uint, perspective_minAngel);
}
-(void)setPerspective_maxAngel:(float)perspective_maxAngel{
    _perspective_maxAngel = perspective_maxAngel;
    GLuint uint = glGetUniformLocation(self.myProgram, "p_max");
    glUniform1f(uint, perspective_maxAngel);
}
-(void)setFisheye_minAngel:(float)fisheye_minAngel{
    _fisheye_minAngel = fisheye_minAngel;
    GLuint uint = glGetUniformLocation(self.myProgram, "f_min");
    glUniform1f(uint, fisheye_minAngel);
}
-(void)setFisheye_maxAngel:(float)fisheye_maxAngel{
    _fisheye_maxAngel = fisheye_maxAngel;
    GLuint uint = glGetUniformLocation(self.myProgram, "f_max");
    glUniform1f(uint, fisheye_maxAngel);
}
    

@end
