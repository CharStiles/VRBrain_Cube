Shader "Raymarching/Forward_ModWorld_for_VR"
{

Properties
{
    [Header(PBS)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2

    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0

    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
[Header(Additional Parameters)]
_Grid("Grid", 2D) = "" {}
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Opaque"
    "Queue" = "Geometry"
    "DisableBatching" = "True"
}

Cull [_Cull]

CGINCLUDE

#define WORLD_SPACE

#define OBJECT_SHAPE_NONE

#define CAMERA_INSIDE_OBJECT

#define USE_RAYMARCHING_DEPTH

#define DISABLE_VIEW_CULLING

#define DISTANCE_FUNCTION DistanceFunction
#define PostEffectOutput SurfaceOutputStandard
#define POST_EFFECT PostEffect

#include "Assets\uRaymarching\Runtime\Shaders\Include\Legacy/Common.cginc"

// @block DistanceFunction
void pR(inout float2 p, float a) {
	p = cos(a)*p + sin(a)*float2(p.y, -p.x);
}
// inline float DistanceFunction(float3 pos)
// {
//     float r = abs(sin(2 * PI * _Time.y / 2.0));
//     float d1 = Box(Repeat(pos, float3(6, 6, 6)), 1 - r);
//     float d2 = Sphere(pos, 3.0);
//     float d3 = Plane(pos - float3(0, -3, 0), float3(0, 1, 0));
//     return SmoothMin(SmoothMin(d1, d2, 1.0), d3, 1.0);
// }

inline float DistanceFunction(float3 pos)
{
    //float r = abs(sin(2 * PI * _Time.y / 2.0));
    float time = _Time.y/8.;
    float3 posR = pos;// Repeat(pos, float3(6, 6, 6));
    pR(posR.zy,time/2.);
    pR(posR.xz,time/10.);
    
    float d1 = Box(posR + float3(0,0,sin(time*2.3)*1.87543), 1.);
    
    pR(posR.zy,-time);
    pR(posR.xy,-time);
    pR(posR.xz,-time/7.);
    
    float d2 =Box(posR, 1.0);
    float d3 = Plane(pos - float3(0, -3, 0), float3(0, 1, 0));
    return SmoothMin(max(d1, d2), d3, .6);
}
// @endblock

// @block PostEffect
sampler2D _Grid;
float4 _Grid_ST;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float ao = 1.0 - 1.0 * ray.loop / ray.maxLoop;
   //o.Emission += tex2D(_Grid, ray.endPos.xy * _Grid_ST.xy + _Grid_ST.zw) * ao;
    o.Occlusion *= ao;
}
// @endblock

ENDCG

Pass
{
    Tags { "LightMode" = "ForwardBase" }

    ZWrite [_ZWrite]

    CGPROGRAM
    #include "Assets\uRaymarching\Runtime\Shaders\Include\Legacy/ForwardBaseStandard.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma multi_compile_fwdbase
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ForwardAdd" }
    ZWrite Off 
    Blend One One

    CGPROGRAM
    #include "Assets\uRaymarching\Runtime\Shaders\Include\Legacy/ForwardAddStandard.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma skip_variants INSTANCING_ON
    #pragma multi_compile_fwdadd_fullshadows
    ENDCG
}

}

Fallback Off

CustomEditor "uShaderTemplate.MaterialEditor"

}