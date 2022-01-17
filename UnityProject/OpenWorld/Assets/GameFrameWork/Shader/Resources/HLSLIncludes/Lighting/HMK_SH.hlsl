#pragma once

//球谐函数参考:https://zh.wikipedia.org/wiki/%E7%90%83%E8%B0%90%E5%87%BD%E6%95%B0


#define PI 3.1415926

//==============直角坐标系下的3阶球谐函数============//
//球谐函数定义 只需要L0L1
//l = 0,m = 0
float GetY0(float3 v)
{
    return 0.2820947917f;
}

float GetY1(float3 v)
{
    return 0.4886025119f * v.y;
}

float GetY2(float3 v)
{
    return 0.4886025119f * v.z;
}

float GetY3(float3 v)
{
    return 0.4886025119f * v.x;
}

//==============极坐标系下的3阶球谐函数============//

//l = 0,m = 0
float GetY0(float theta, float phi)
{
    return 0.2820947917f;
}

//l = 1,m = 0
float GetY1(float theta, float phi)
{
    return 0.4886025119f * sin(theta) * sin(phi);
}

//l = 1,m = 1
float GetY2(float theta, float phi)
{
    return 0.4886025119f * cos(theta);
}

//l = 1,m = -1
float GetY3(float theta, float phi)
{
    return 0.4886025119f * sin(theta) * cos(phi);
}


///===== 其他工具函数 =======
float3 UnitDirFromThetaPhi(float theta, float phi)
{
    float3 result;
    float s_theta, c_theta, s_phi, c_phi;
    sincos(theta, s_theta, c_theta);
    sincos(phi, s_phi, c_phi);
    result.y = c_theta;
    result.x = s_theta * c_phi;
    result.z = s_theta * s_phi;
    return result;
}