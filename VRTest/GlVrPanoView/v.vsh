attribute vec4 position;
attribute vec2 textCoordinate;
//uniform mat4 rotateMatrix;
varying lowp vec2 varyTextCoord;
//长宽比
uniform lowp float widthScale;
uniform lowp float heightScale;
void main()
{
    //视图对角线长度（可视最远距离）已变化，除以比例以在对角线上显示uv1点
    lowp float s = sqrt(2.0 / (widthScale * widthScale + heightScale * heightScale));
    //s = 1.0;//test
    lowp float wS = widthScale * s;
    lowp float hS = heightScale * s;
    
    varyTextCoord = vec2(0.5 + wS * (textCoordinate.x - 0.5), 0.5 + hS * (textCoordinate.y - 0.5));
    
    vec4 vPos = position;
    
//    vPos = vPos * rotateMatrix;
    
    gl_Position = vPos;
}
