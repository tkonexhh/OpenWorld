#ifndef RENDERPIPELINE_IMAGE_BASED_LIGHTING_INCLUDED
#define RENDERPIPELINE_IMAGE_BASED_LIGHTING_INCLUDED

#ifndef UNITY_SPECCUBE_LOD_STEPS
    // This is actuall the last mip index, we generate 7 mips of convolution
    #define UNITY_SPECCUBE_LOD_STEPS 6
#endif

//根据粗糙度计算立方体贴图的Mip等级
//同PerceptualRoughnessToMipmapLevel
half CubeMapMip(half roughness)
{
    half mip_roughness = (roughness) * (1.7 - 0.7 * roughness);//Unity内部不是线性 调整下拟合曲线求近似
    half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;//把粗糙度remap到0-6 7个阶级 然后进行lod采样
    return mip;
}

#endif