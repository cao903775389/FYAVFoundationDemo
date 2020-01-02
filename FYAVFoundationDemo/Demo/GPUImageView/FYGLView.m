//
//  FYGLView.m
//  FYAVFoundationDemo
//
//  Created by admin on 2019/12/24.
//  Copyright © 2019 fengyangcao. All rights reserved.
//

#import "FYGLView.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/gl.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString * kVertexShader = SHADER_STRING
(
 layout (location = 0) in vec3 aPos;
 
 void main()
 {
     gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
 }
);

NSString * kFragmentShader = SHADER_STRING
(
 out vec4 FragColor;
 
 void main()
 {
     FragColor = vec4(1.0, 0.5, 0.2, 1.0);
 }
);


@interface FYGLView ()
{
    GLuint _colorRenderBuffer;
    GLuint _frameBuffers;
    GLuint _vertShader; //顶点着色器
    GLuint _fragShader; //片元着色器
}
@property (nonatomic, strong) EAGLContext *context;

@end

@implementation FYGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    [self setUpContext];
    
    [self setupShader];
}

//1.设置OpenGL 上下文
- (void)setUpContext {
    //设置上下文
    //EAGLContext 封装了OpenGLES不同版本之间的差异
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    [EAGLContext setCurrentContext:_context];
}

//2. 创建渲染缓冲区
//OpenGLES 总共有三大不同用途的color buffer，depth buffer 和 stencil buffer.
- (void)setupRenderBuffer {
    
    CAEAGLLayer *openGLLayer = (CAEAGLLayer *)self.layer;
    NSAssert([openGLLayer isKindOfClass:[CAEAGLLayer class]], @"layer is not a CAEAGLLayer");

    //生成
    glGenRenderbuffers(1, &_colorRenderBuffer);
    
    //绑定
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    // 把渲染缓存绑定到渲染图层上CAEAGLLayer，并为它分配一个共享内存。
    // 并且会设置渲染缓存的格式，和宽度
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:openGLLayer];
    
//    glRenderbufferStorage(
//      //Color bit-depth：仅当内部格式为 color 时，设置颜色的 bit-depth，默认值为0；
//      //Depth bit-depth：仅当内部格式为 depth时，默认值为0；
//      //Stencil bit-depth: 仅当内部格式为 stencil，默认值为0
//      GL_RENDERBUFFER,
//      //internal format：内部格式，三大 buffer 格式之一 -- color，depth or stencil；
//      GL_RGBA,
//      //width 和 height：像素单位的宽和高，默认值为0；
//      openGLLayer.bounds.size.width,
//      openGLLayer.bounds.size.height
//    );
}

//3. 创建帧缓冲区
- (void)setupFrameBuffer {
    //生成
    glGenFramebuffers(1, &_frameBuffers);
    
    //绑定
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffers);
    
    //渲染
    // 把颜色渲染缓存 添加到 帧缓存的GL_COLOR_ATTACHMENT0上,就会自动把渲染缓存的内容填充到帧缓存，在由帧缓存渲染到屏幕
    glFramebufferRenderbuffer(
      GL_FRAMEBUFFER,
      GL_COLOR_ATTACHMENT0,    //对应三大渲染buffer类型
      GL_RENDERBUFFER,
      _colorRenderBuffer
    );
}

//4. 创建着色器
- (void)setupShader {
    
    //创建顶点着色器
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    const GLchar *vertextStr = [kVertexShader UTF8String];
    glShaderSource(vertexShader, 1, &vertextStr, NULL);
    glCompileShader(vertexShader);
    GLint status;
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE) {
        //编译失败
        GLint logLength;
        glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
            NSLog(@"%s", log);
            free(log);
            return;
        }
    }
    
    //创建片段着色器
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    const GLchar *fragmentStr = [kFragmentShader UTF8String];
    glShaderSource(fragmentShader, 1, &fragmentStr, NULL);
    glCompileShader(fragmentShader);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE) {
        //编译失败
        GLint logLength;
        glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(fragmentShader, logLength, &logLength, log);
            NSLog(@"%s", log);
            free(log);
            return;
        }
    }
    
    //初始化着色器程序
    GLuint program = glCreateProgram();
    
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        return;
    }
    //删除shader
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    //三角形顶点数组
    GLfloat vertices[] = {
        -0.5f, -0.5f, 0.0f,  //左下
        0.5f, -0.5f, 0.0f,   //右下
        0.0f,  0.5f, 0.0f    //中上
    };
    
//    顶点数组对象：Vertex Array Object，VAO ES3.0
//    顶点缓冲对象：Vertex Buffer Object，VBO
//    索引缓冲对象：Element Buffer Object，EBO或Index Buffer Object，IBO
    GLuint VBO;
    GLuint VAO;
    
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    //链接顶点属性(第一个参数 index 对应顶点着色器中location)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), (void *)0);
    glEnableVertexAttribArray(0);
    
    glClearColor(0.2, 0.3, 0.3, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    //使用着色器程序
    glUseProgram(program);
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

@end
