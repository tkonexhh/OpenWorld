#pragma once

#define NUMBER_OF_ARGS_PER_DRAW 5

struct GrassTRS
{
    float3 position;
    float rotateY;
    float scale;
};

// struct VisibleInfo
// {
//     uint id;
//     uint lod;
// };


struct InstanceData
{
    float3 boundsCenter;
    float3 boundsExtends;
};

