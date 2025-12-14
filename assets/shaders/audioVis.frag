#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    int aa;
    float time;
    float a[6];
};
void main() {
    fragColor = vec4(vec3(qt_TexCoord0, a[aa]), 1.) * qt_Opacity;
}