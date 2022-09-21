#ifndef RENDERPIPELINE_LOD_INCLUDED
#define RENDERPIPELINE_LOD_INCLUDED


void ClipLOD(float2 positionCS, float fade)
{
    #if defined(LOD_FADE_CROSSFADE)
        float dither = InterleavedGradientNoise(positionCS, 0);
        clip(fade - dither);
    #endif
}

#endif

