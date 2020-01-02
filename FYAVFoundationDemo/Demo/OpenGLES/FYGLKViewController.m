//
//  FYGLKViewController.m
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/19.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import "FYGLKViewController.h"
#import "FYGLView.h"

@interface FYGLKViewController () {
    //GPU帧缓存唯一标识符
    GLuint vertexBufferID;
}

//执行GPU渲染的步骤
//1)生成(Generate)— 请求 OpenGL ES 为图形处理器控制的缓存生成一个独一 无二的标识符。
//2)绑定(Bind)— 告诉 OpenGL ES 为接下来的运算使用一个缓存。
//3)缓存数据(Buffer Data)— 让 OpenGL ES 为当前绑定的缓存分配并初始化足 够的连续内存(通常是从 CPU 控制的内存复制数据到分配的内存)。
//4)启用(Enable)或者禁止(Disable)— 告诉 OpenGL ES 在接下来的渲染中是 否使用缓存中的数据。
//5)设置指针(Set Pointers)— 告诉 Open-GL ES 在缓存中的数据的类型和所有需 要访问的数据的内存偏移值。
//6)绘图(Draw)— 告诉 OpenGL ES 使用当前绑定并启用的缓存中的数据渲染 整个场景或者某个场景的一部分
//7)删除(Delete)— 告诉 OpenGL ES 删除以前生成的缓存并释放相关的资源。
//理想情况下，每个生成的缓存都可以使用一个相当长的时间(可能是程序的整个生命周期)。生成、初始化和删除缓存有时需要耗费时间来同步图形处理器和 CPU。 存在这个延迟是因为 GPU 在删除一个缓存之前必须完成所有与该缓存相关的等待中 的运算。如果一个程序每秒生成和删除缓存数千次，GPU 可能就没有时间来完成任何 渲染了。



//GLKBaseEffect 类提供了不依赖于所使用的 OpenGL ES 版本的控制 OpenGL ES 渲染的方法。
//OpenGL ES 1.1 跟 OpenGL ES 2.0 的内部工作机制是非常不同的。2.0 版 本执行为 GPU 专门定制的程序。
//如果没有 GLKit 和 GLKBaseEffect 类，完成这个简 单的例子就需要用 OpenGL ES 2.0 的“Shading Language”编写一个小的 GPU 程序。
//GLKBaseEffect 会在需要的时候自动地构建 GPU 程序并极大地简化本书中的例子
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@end

@implementation FYGLKViewController

@synthesize baseEffect;

- (void)dealloc {
    GLKView *view = (GLKView *)self.view;
    [EAGLContext setCurrentContext:view.context];
    if (vertexBufferID != 0) {
        //step 7 删除缓存
        glDeleteBuffers(1, &vertexBufferID);
        vertexBufferID = 0;
    }
    view.context = nil;
    [EAGLContext setCurrentContext:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self setUpContext];
//    [self setUpVertextData];
//    [self setUpEffect];
//    
    
    FYGLView *glView = [[FYGLView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    [self.view addSubview:glView];
    
}

//设置OpenGL 上下文
- (void)setUpContext {
    GLKView *view = (GLKView *)self.view;
    
    NSAssert([view isKindOfClass:[GLKView class]], @"view controller is not a GLKView");
    //设置上下文
    //EAGLContext 封装了OpenGLES不同版本之间的差异
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:view.context];
}

//初始化顶点数据
- (void)setUpVertextData {
    
    //顶点数据，前三个是顶点坐标（x、y、z轴），后面两个是纹理坐标（x，y）
    //OpenGL坐标系 中心点是(0,0)  纹理坐标系左下角是(0,0)
    GLfloat vertices[] = {
         ///三角形
        0.5f,   -0.5f,  0.0,   1.0, 0.0,         //右下角
        -0.5f,  -0.5f,  0.0,   0.0, 0.0,         //左下角
        -0.5f,  0.5f,   0.0,   0.0, 1.0,         //左上角
        
       
        0.5f,   0.5f,   0.0,   1.0, 1.0,         //右上角
        0.5f,  -0.5f,   0.0,   1.0, 0.0,         //右下角
        -0.5f,  0.5f,   0.0,   0.0, 1.0          //左上角
    };
    
    //step 1 generate buffer
    glGenBuffers(1, &vertexBufferID);
    
    //step 2 bind buffer
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
    
    //step 3 copy data to buffer
    glBufferData(
                 GL_ARRAY_BUFFER, //缓存数据类型
                 sizeof(vertices),//缓存大小
                 vertices,        //缓存数据
                 GL_STATIC_DRAW); //缓存数据到GPU 内存中
    
    //step 4 使用缓存数据
    glEnableVertexAttribArray(GLKVertexAttribPosition); //指定缓存数据的类型
    
    //step 5 设置内存指针
    
    //设置顶点坐标数据
    glVertexAttribPointer(
                          GLKVertexAttribPosition, //缓存包含的每个顶点的数据信息
                          3,                       //每个位置有3个部分
                          GL_FLOAT,                //数据类型
                          GL_FALSE,                //小数点固定数据是否可以被改变
                          sizeof(GLfloat) * 5,     //指定了每个顶点的保存需要多少个字节
                          (GLfloat *)NULL + 0);    //数据起始位置
    
    //设置纹理坐标数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
    glVertexAttribPointer(
                          GLKVertexAttribTexCoord0,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(GLfloat) * 5,
                          (GLfloat *)NULL + 3);
}

//初始化着色器
- (void)setUpEffect {
    
    //设置纹理贴图
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"poster_default" ofType:@"png"];
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:@{GLKTextureLoaderOriginBottomLeft: @(1)} error:nil];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
//    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.texture2d0.enabled = GL_TRUE;
    self.baseEffect.texture2d0.name = textureInfo.name;
    
    //设置渲染颜色
    self.baseEffect.constantColor = GLKVector4Make(1.f, 1.f, 1.f, 1.f);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.baseEffect prepareToDraw];
    
    //step 6 绘制
    glDrawArrays(
                 GL_TRIANGLES,   //告诉GPU如何处理数据
                 0,              //第一个顶点的位置
                 6);             //需要渲染的顶点的数量
    
}

@end
