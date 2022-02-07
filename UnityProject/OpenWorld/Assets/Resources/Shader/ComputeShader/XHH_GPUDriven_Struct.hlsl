#pragma one


struct InstanceData
{
    //AABB 包围盒
    float3 boundsCenter;         // 3
    float3 boundsExtents;        // 6
    uint drawCallInstanceIndex;  // 9

};

struct InstanceTRS
{
    float3 position;
    float3 rotation;
    float3 scale;
};

#define NUMBER_OF_ARGS_PER_DRAW 5
#define NUMBER_OF_ARGS_PER_INSTANCE_TYPE 15