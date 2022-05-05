using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace GrassPainter
{
    public delegate void OnPaint();

    public class SceneViewHandle
    {
        private static Color activeOuterColor = Color.green;
        private static Color passiveOuterColor = Color.red;
        private static Color innerColor = new Color(0, 0, 1, 0.3f);
        private static string MouseLocationName = "MouseLocation";
        private Transform m_MouseLocation;

        private PaintGrassElement m_PaintGrassElement;
        private BrushSetting m_BrushSetting;

        private RaycastHit m_MouseHitPoint;
        private Vector3 m_PreviousMousePosition;

        private Event m_CurrentEvent;
        private bool isPainting = true;
        private bool displayDebugInfo = true;

        ////////////
        private GrassPainterPrefab m_GrassPrefab;
        private string m_GroupName;

        public event OnPaint onEarse;

        public void Init(PaintGrassElement paintGrassElement)
        {
            m_PaintGrassElement = paintGrassElement;
            isPainting = true;
            m_GrassPrefab = null;
        }

        public void OnSelectChaned()
        {
            m_GrassPrefab = m_PaintGrassElement.selecter.painterPrefab;
            if (m_GrassPrefab != null)
            {
                m_GroupName = m_GrassPrefab.GetName();
                SceneGrassContainerMgr.S.CreateContainer(m_GroupName);
            }
        }

        public void SceneGUI(SceneView sceneView)
        {
            HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));//为scene响应添加默认事件,用来屏蔽以前的点击选中物体
            m_BrushSetting = m_PaintGrassElement.brushSetting;
            m_CurrentEvent = Event.current;
            UpdateMousePos(sceneView);
            DrawBrushGizmo();
            SceneInput();
        }

        private void UpdateMousePos(SceneView sceneView)
        {
            if (m_CurrentEvent.control)
                HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));

            RaycastHit hit;
            Vector3 mousePos = m_CurrentEvent.mousePosition;
            float ppp = EditorGUIUtility.pixelsPerPoint;
            mousePos.y = sceneView.camera.pixelHeight - mousePos.y * ppp;
            mousePos.x *= ppp;

            Ray ray = sceneView.camera.ScreenPointToRay(mousePos);

            if (Physics.Raycast(ray, out hit, 1000, m_BrushSetting.paintMask))
            {
                m_MouseHitPoint = hit;
            }
            else
            {
                m_MouseHitPoint = new RaycastHit();
            }
        }

        private void DrawBrushGizmo()
        {
            if (isPainting)
                Handles.color = activeOuterColor;
            else
                Handles.color = passiveOuterColor;

            if (m_MouseHitPoint.transform)
            {
                if (GameObject.Find(MouseLocationName) == null)
                    m_MouseLocation = new GameObject(MouseLocationName).transform;
                else
                    m_MouseLocation = GameObject.Find(MouseLocationName).transform;

                m_MouseLocation.rotation = m_MouseHitPoint.transform.rotation;
                m_MouseLocation.forward = m_MouseHitPoint.normal;
                Handles.ArrowHandleCap(3, m_MouseHitPoint.point, m_MouseLocation.rotation, 1 * m_BrushSetting.brushSize, EventType.Repaint);
                Handles.CircleHandleCap(2, m_MouseHitPoint.point, m_MouseLocation.rotation, m_BrushSetting.brushSize, EventType.Repaint);
                Handles.color = innerColor;
                Handles.DrawSolidDisc(m_MouseHitPoint.point, m_MouseHitPoint.normal, m_BrushSetting.brushSize);
                m_MouseLocation.up = m_MouseHitPoint.normal;
            }


            if (displayDebugInfo)
            {
                Handles.BeginGUI();
                GUIStyle style = new GUIStyle();
                style.normal.textColor = Color.black;
                GUILayout.BeginArea(new Rect(m_CurrentEvent.mousePosition.x + 10, m_CurrentEvent.mousePosition.y + 10, 250, 100));

                GUILayout.TextField("Size: " + System.Math.Round(m_BrushSetting.brushSize, 2), style);
                GUILayout.TextField("Density: " + System.Math.Round((double)m_BrushSetting.brushDensity, 2), style);
                // GUILayout.TextField("Height: " + System.Math.Round(m_CurrentMousePosition.y, 2), style);
                GUILayout.TextField("Surface Name: " + (m_MouseHitPoint.collider ? m_MouseHitPoint.collider.name : "none"), style);
                GUILayout.TextField("Position: " + m_MouseHitPoint.point.ToString(), style);

                GUILayout.EndArea();
                Handles.EndGUI();
            }
        }


        private void SceneInput()
        {
            if (m_CurrentEvent.type == EventType.KeyDown && m_CurrentEvent.keyCode == KeyCode.LeftControl)
            {
                isPainting = false;

            }
            else if (m_CurrentEvent.type == EventType.KeyUp)
            {
                isPainting = true;
            }


            if ((m_CurrentEvent.type == EventType.MouseDown || m_CurrentEvent.type == EventType.MouseDrag) && m_CurrentEvent.button == 0)//点击左键就可以刷
            {
                if (isPainting)
                {
                    Painting();
                }
                else
                {
                    Erasing();
                }
            }

            if (m_CurrentEvent.type == EventType.MouseUp && m_CurrentEvent.button == 0)//鼠标抬起 不需要考虑连续刷的问题
            {
                m_PreviousMousePosition = Vector3.zero;
            }
        }

        private void Painting()
        {
            if (Vector3.Distance(m_PreviousMousePosition, m_MouseHitPoint.point) <= m_BrushSetting.mouseModeDelta)
                return;

            m_PreviousMousePosition = m_MouseHitPoint.point;

            if (m_GrassPrefab == null)
                return;

            int localDensity = m_BrushSetting.brushDensity;

            if (localDensity == 1)
            {
                SpawnObject(m_MouseHitPoint.point);
            }
            else
            {
                for (int i = 0; i < localDensity; i++)
                {
                    //向上转一圈
                    // Vector3 dir = Quaternion.AngleAxis(UnityEngine.Random.Range(0, 360), Vector3.up) * Vector3.right;
                    Vector3 dir = Quaternion.AngleAxis(UnityEngine.Random.Range(0, 360), m_MouseHitPoint.normal) * Vector3.right;
                    Vector3 spawnPos = (dir * m_BrushSetting.brushSize * Random.Range(0.1f, 1f)) + m_MouseHitPoint.point;
                    SpawnObject(spawnPos);
                }
            }

            GrassQuadTreeSpaceMgr.S.Update(true);
        }

        private void SpawnObject(Vector3 pos)
        {
            GameObject go = null;
            var prefab = m_PaintGrassElement.selecter.painterPrefab.prefab;
            if (PrefabUtility.IsPartOfAnyPrefab(prefab))
            {
                go = PrefabUtility.InstantiatePrefab(prefab) as GameObject;
            }
            else
            {
                go = GameObject.Instantiate(prefab);
            }

            Undo.RegisterCreatedObjectUndo(go, "Prefab Paint");

            go.transform.position = pos;
            go.layer = m_BrushSetting.targetLayer;

            DoubleRayCast(go);

            if (go)
            {
                float scale = m_BrushSetting.randomScale ? Random.Range(m_BrushSetting.scaleRange.x, m_BrushSetting.scaleRange.y) : 1;
                // byte rotationY = (byte)Random.Range(0, byte.MaxValue);
                float rotationY = Random.Range(0, 360);

                if (m_BrushSetting.randomRotate)
                    go.transform.Rotate(Vector3.up, ((float)rotationY / (float)byte.MaxValue) * 360f);


                go.transform.localScale = Vector3.one * scale;
                GrassTRS instanceData = new GrassTRS();
                instanceData.position = go.transform.position;
                instanceData.scale = scale;
                instanceData.rotateY = rotationY;

                SceneGrassContainerMgr.S.AddInstanceData(m_GroupName, instanceData);
                GameObject.DestroyImmediate(go);

            }

        }

        private void DoubleRayCast(GameObject go)
        {
            //5 应该是一个可选值嘛？
            Vector3 position = go.transform.position + go.transform.up * 5;

            RaycastHit groundHit;
            if (Physics.Raycast(position, -go.transform.up, out groundHit, Mathf.Infinity, m_BrushSetting.paintMask))//如果向下没有击中物体 直接删除物体
            {
                Vector3 newPos = groundHit.point;
                go.transform.position = newPos;
                return;
            }

            GameObject.DestroyImmediate(go);
        }

        private void Erasing()
        {
            SceneGrassContainerMgr.S.Erasing(m_GroupName, m_MouseHitPoint.point, m_BrushSetting.brushSize);
            onEarse?.Invoke();

        }

        public void Destroy()
        {
            if (m_MouseLocation != null)
            {
                GameObject.DestroyImmediate(m_MouseLocation.gameObject);
            }
        }
    }
}
