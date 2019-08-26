//  Created by wdy on 2019/1/24.
//  Copyright © 2019 wdy. All rights reserved.

varying highp vec2 varyTextCoord;
uniform sampler2D colorMap;
uniform highp mat4 rotMatrix;
//uniform highp float rotH;
//uniform highp float rotV;
uniform highp float viewfield;
uniform highp float perspective;
uniform highp float p_min;
uniform highp float p_max;
uniform highp float f_min;
uniform highp float f_max;

highp float PI = 3.14159265358979323846264338327950288;
void main()
{
    //屏幕像素坐标相对于中心坐标
    highp float xx = varyTextCoord.x - 0.5;
    highp float yy = varyTextCoord.y - 0.5;
    highp float dis = sqrt(xx*xx + yy*yy) / sqrt(0.5); //距离中心距离比例 (0-1)(最长是对角线)
    highp float R = 1.0;//球半径， 任意值
    
    //像素所在球面上的初始角度（球面坐标）,想象向正下方看，图片的底边为0，底边旋转一圈为最下方一点
    //以z轴：横向旋转角度
    highp float angelH0 = atan(yy, xx);
    
    //真实透视效果：最大可视角度为 -PI/2 ~ PI/2，视平面距离球心为cos(edgeAngel)*R, 边界长度为sin(edgeAngel)*R，dis为视平面上的距离，最终角度为dis点与视中心线的夹角
    highp float edgeAngel = viewfield * (p_max - p_min) + p_min; //边界的角度（最大视野 30度-60度）
    highp float angelV0_p = atan(dis * tan(edgeAngel)); //夹角
    //highp float angelV0_p = sin(dis * PI * 0.5 * viewfield); //wrong
    //鱼眼效果：距离及为在球面上的距离，角度直接为比例
    highp float angelV0_f = dis * (viewfield * (f_max - f_min) + f_min);
    
    //以x轴：纵向向旋转角度：相当于从原点，在球面上，向四周移动成的角度
    highp float angelV0 = perspective * angelV0_p + (1.0 - perspective) * angelV0_f; //平滑渐变
    
    
    
    
    //初始坐标（转到直角坐标系）
    highp float x0 = R * cos(angelH0) * sin(angelV0);
    highp float y0 = R * sin(angelH0) * sin(angelV0);
    highp float z0 = R * cos(angelV0);
    highp vec4 pos0 = vec4(x0, y0, z0, 1.0);
    
    //手动构造旋转矩阵
//    highp mat4 matH = mat4(
//                           cos(rotH),   -sin(rotH), 0,  0,
//                           sin(rotH),   cos(rotH),  0,  0,
//                           0,           0,          1,  0,
//                           0,           0,          0,  1
//                           );
//    highp mat4 matV = mat4(
//                           1,   0,          0,          0,
//                           0,   cos(rotV),  -sin(rotV), 0,
//                           0,   sin(rotV),  cos(rotV),  0,
//                           0,   0,          0,          1
//                           );
//    highp mat4 rotMatrix = matV * matH;

    //旋转后坐标（矩阵变换）
    highp vec4 pos1 = pos0 * rotMatrix;
    //旋转后角度（转到球面坐标）
    highp float angelH1 = atan(pos1.y,pos1.x);
    pos1.z = clamp(pos1.z, -R, R);//防止误差（32位机器精度不够）导致无效数值
    highp float angelV1 = acos(pos1.z/R);

    //球面坐标求得纹理uv
    highp float uu = angelH1 / PI*0.5 + 0.5;
    highp float vv = angelV1 / PI;
    
    //test
//    highp float uu = 1.0;
//    highp float vv = 1.0;
    
    highp vec2 uv = vec2(1.0 - uu, 1.0 - vv);
    gl_FragColor = texture2D(colorMap, uv);
}
