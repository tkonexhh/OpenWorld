#ifndef TERRAIN_COMMON_INPUT
#define TERRAIN_COMMON_INPUT

#define TERRAIN_MAX_LOD 5//最大的LOD级别是5
#define PATCH_COUNT_PER_NODE 5 //一个Node拆成8x8个Patch
#define NodeEvaluationC 1.2//节点分化评价C值
#define SECTOR_COUNT_WORLD 160 //最大Node的情况 160*160 5*2^6

#define PATCH_MESH_GRID_COUNT 16//一个Patch由多少个格子组成
#define PATCH_MESH_GRID_SIZE 0.3125//PatchMesh一个格子的大小为0.5x0.5
#define PATCH_MESH_SIZE PATCH_MESH_GRID_COUNT * PATCH_MESH_GRID_SIZE//一个patch的大小是count*size

#define RENDER_TILE_COUNT 20
//节点描述
struct NodeDescriptor
{
    uint branch;//1 细分过,0 没有细分
    // uint nodeID;
    // uint nodeLoc;
    // uint atlasID;
    // uint2 renderLoc;//绘制信息坐标

};

// struct MapDescriptor
// {
//     uint nodeCount;//节点实际数量

// }

struct RenderPatch
{
    float2 position;
    float2 minMaxHeight;//x:最小Y y:最大Y
    uint lod;
    uint4 lodTrans;//+x,-x,+z,-z 4个方向的LOD变化情况

};

struct Bounds
{
    float3 minPosition;
    float3 maxPosition;
};

struct BoundsDebug
{
    Bounds bounds;
    float4 color;
};

#endif