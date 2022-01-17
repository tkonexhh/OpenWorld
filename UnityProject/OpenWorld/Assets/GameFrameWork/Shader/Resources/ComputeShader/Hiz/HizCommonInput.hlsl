#pragma once

struct TerrainObjBounds
{
    float3 minPosition;
    float3 maxPosition;
    int cullState;//-1还没有参与剔除 0没有被剔除 1被剔除

};
