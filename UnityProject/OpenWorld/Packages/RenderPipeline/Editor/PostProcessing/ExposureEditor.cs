using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using OpenWorld.RenderPipelines.Runtime.PostProcessing;
using UnityEditor;
using UnityEditor.Rendering;

namespace OpenWorld.RenderPipelines.Editor.PostProcessing
{
    [CustomEditor(typeof(Exposure))]
    public class ExposureEditor : VolumeComponentEditor
    {
        SerializedDataParameter m_Mode;
        SerializedDataParameter m_MeteringMode;

        SerializedDataParameter m_LimitMin;
        SerializedDataParameter m_LimitMax;
        SerializedDataParameter m_CurveMap;
        SerializedDataParameter m_CurveMin;
        SerializedDataParameter m_CurveMax;

        SerializedDataParameter m_AdaptationMode;
        SerializedDataParameter m_AdaptationSpeedDarkToLight;
        SerializedDataParameter m_AdaptationSpeedLightToDark;

        SerializedDataParameter m_HistogramPercentages;

        public override void OnEnable()
        {
            var o = new PropertyFetcher<Exposure>(serializedObject);

            m_Mode = Unpack(o.Find(x => x.mode));
            m_MeteringMode = Unpack(o.Find(x => x.meteringMode));

            m_LimitMin = Unpack(o.Find(x => x.limitMin));
            m_LimitMax = Unpack(o.Find(x => x.limitMax));
            m_CurveMap = Unpack(o.Find(x => x.curveMap));
            m_CurveMin = Unpack(o.Find(x => x.limitMinCurveMap));
            m_CurveMax = Unpack(o.Find(x => x.limitMaxCurveMap));

            m_AdaptationMode = Unpack(o.Find(x => x.adaptationMode));
            m_AdaptationSpeedDarkToLight = Unpack(o.Find(x => x.adaptationSpeedDarkToLight));
            m_AdaptationSpeedLightToDark = Unpack(o.Find(x => x.adaptationSpeedLightToDark));

            m_HistogramPercentages = Unpack(o.Find(x => x.histogramPercentages));
        }

        public override void OnInspectorGUI()
        {
            PropertyField(m_Mode);
            int mode = m_Mode.value.intValue;
            if (mode == (int)ExposureMode.UsePhysicalCamera)
            {

            }
            else
            {
                EditorGUILayout.Space();
                PropertyField(m_MeteringMode);


                if (mode == (int)ExposureMode.CurveMapping)
                {
                    PropertyField(m_CurveMap);
                    PropertyField(m_CurveMin, EditorGUIUtility.TrTextContent("Limit Min"));
                    PropertyField(m_CurveMax, EditorGUIUtility.TrTextContent("Limit Max"));
                }

                if (mode == (int)ExposureMode.AutomaticHistogram)
                {
                    PropertyField(m_HistogramPercentages);
                }


                PropertyField(m_AdaptationMode, EditorGUIUtility.TrTextContent("Mode"));

                if (m_AdaptationMode.value.intValue == (int)AdaptationMode.Progressive)
                {
                    PropertyField(m_AdaptationSpeedDarkToLight, EditorGUIUtility.TrTextContent("Speed Dark to Light"));
                    PropertyField(m_AdaptationSpeedLightToDark, EditorGUIUtility.TrTextContent("Speed Light to Dark"));
                }
            }


        }
    }
}
