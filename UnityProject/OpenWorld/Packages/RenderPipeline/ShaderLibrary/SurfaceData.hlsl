#ifndef OPENWORLD_SURFACE_DATA_INCLUDED
#define OPENWORLD_SURFACE_DATA_INCLUDED


struct SurfaceData
{
    half3 albedo;
    half alpha;
    half metallic;
    half roughness;
    half3 emission;
    half occlusion;

    // half dither;

};

#endif

