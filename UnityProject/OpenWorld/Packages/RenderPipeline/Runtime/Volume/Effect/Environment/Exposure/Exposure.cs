using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.Environment + Exposure.title)]
    public class Exposure : VolumeSetting
    {
        public const string title = "曝光 (Exposure)";

        public Exposure()
        {
            this.displayName = title;
        }

        public override bool IsActive() => meteringMode.value != MeteringMode.None;

        public ExposureModeParameter mode = new ExposureModeParameter(ExposureMode.None);

        [Tooltip("计量模式")]
        public MeteringModeParameter meteringMode = new MeteringModeParameter(MeteringMode.None);

        #region ExposureMode.CurveMapping
        /// <summary>
        /// Sets the minimum value that the Scene exposure can be set to.
        /// This parameter is only used when <see cref="ExposureMode.Automatic"/> or <see cref="ExposureMode.CurveMapping"/> is set.
        /// </summary>
        [Tooltip("Sets the minimum value that the Scene exposure can be set to.")]
        public FloatParameter limitMin = new FloatParameter(-1f);

        /// <summary>
        /// Sets the maximum value that the Scene exposure can be set to.
        /// This parameter is only used when <see cref="ExposureMode.Automatic"/> or <see cref="ExposureMode.CurveMapping"/> is set.
        /// </summary>
        [Tooltip("Sets the maximum value that the Scene exposure can be set to.")]
        public FloatParameter limitMax = new FloatParameter(14f);

        /// <summary>
        /// Specifies a curve that remaps the Scene exposure on the x-axis to the exposure you want on the y-axis.
        /// This parameter is only used when <see cref="ExposureMode.CurveMapping"/> is set.
        /// </summary>
        [Tooltip("Specifies a curve that remaps the Scene exposure on the x-axis to the exposure you want on the y-axis.")]
        public AnimationCurveParameter curveMap = new AnimationCurveParameter(AnimationCurve.Linear(-10f, -10f, 20f, 20f)); // TODO: Use TextureCurve instead?

        /// <summary>
        /// Specifies a curve that determines for each current exposure value (x-value) what minimum value is allowed to auto-adaptation (y-axis).
        /// This parameter is only used when <see cref="ExposureMode.CurveMapping"/> is set.
        /// </summary>
        [Tooltip("Specifies a curve that determines for each current exposure value (x-value) what minimum value is allowed to auto-adaptation (y-axis).")]
        public AnimationCurveParameter limitMinCurveMap = new AnimationCurveParameter(AnimationCurve.Linear(-10f, -12f, 20f, 18f));

        /// <summary>
        /// Specifies a curve that determines for each current exposure value (x-value) what maximum value is allowed to auto-adaptation (y-axis).
        /// This parameter is only used when <see cref="ExposureMode.CurveMapping"/> is set.
        /// </summary>
        [Tooltip("Specifies a curve that determines for each current exposure value (x-value) what maximum value is allowed to auto-adaptation (y-axis).")]
        public AnimationCurveParameter limitMaxCurveMap = new AnimationCurveParameter(AnimationCurve.Linear(-10f, -8f, 20f, 22f));
        #endregion


        [Header("Adaptation")]
        public AdaptationModeParameter adaptationMode = new AdaptationModeParameter(AdaptationMode.Progressive);
        public MinFloatParameter adaptationSpeedDarkToLight = new MinFloatParameter(3f, 0.001f);
        public MinFloatParameter adaptationSpeedLightToDark = new MinFloatParameter(1f, 0.001f);

        [Header("Histogram")]
        [Tooltip("Sets the range of values (in terms of percentages) of the histogram that are accepted while finding a stable average exposure. Anything outside the value is discarded.")]
        public FloatRangeParameter histogramPercentages = new FloatRangeParameter(new Vector2(40.0f, 90.0f), 0.0f, 100.0f);

    }

    public enum ExposureMode { None, Automatic, AutomaticHistogram, CurveMapping, UsePhysicalCamera }
    public enum MeteringMode { None, Auto, Curve, Physical }
    public enum AdaptationMode { Fixed, Progressive }

    [System.Serializable]
    public sealed class MeteringModeParameter : VolumeParameter<MeteringMode>
    {
        public MeteringModeParameter(MeteringMode value, bool overrideState = false) : base(value, overrideState) { }
    }

    [System.Serializable]
    public sealed class ExposureModeParameter : VolumeParameter<ExposureMode>
    {
        public ExposureModeParameter(ExposureMode value, bool overrideState = false) : base(value, overrideState) { }
    }

    [System.Serializable]
    public sealed class AdaptationModeParameter : VolumeParameter<AdaptationMode>
    {
        public AdaptationModeParameter(AdaptationMode value, bool overrideState = false) : base(value, overrideState) { }
    }
}