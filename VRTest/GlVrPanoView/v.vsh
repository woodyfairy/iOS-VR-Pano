attribute vec4 position;
attribute vec2 textCoordinate;
varying lowp vec2 varyTextCoord;
//uniform mat4 rotateMatrix;
//长宽比
uniform lowp float widthScale;
uniform lowp float heightScale;
void main()
{
    varyTextCoord = vec2(0.5 + widthScale * (textCoordinate.x - 0.5), 0.5 + heightScale * (textCoordinate.y - 0.5));
    
    vec4 vPos = position;
    
//    vPos = vPos * rotateMatrix;
    
    gl_Position = vPos;
}
