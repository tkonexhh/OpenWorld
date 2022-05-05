using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
using UnityEditor;

namespace GrassPainter
{
    public class PrefabItemElement : VisualElement
    {
        public Button removeButton { get; private set; }
        private Label m_LabelBG;
        private Label m_NameLabel;
        private ObjectField m_MeshField;
        private ObjectField m_MaterialField;
        private ObjectField m_IndirectMaterialField;

        private GrassPainterPrefab m_PainterPrefab;
        public GrassPainterPrefab painterPrefab
        {
            get => m_PainterPrefab;
            set
            {
                m_PainterPrefab = value;
                RefreshPreview();
            }
        }

        public PrefabItemElement()
        {
            var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(GrassPainterDefine.toolPath + "GrassPainter/Res/UXML/PrefabItem.uxml");
            VisualElement labelFromUXML = visualTree.Instantiate();
            this.Add(labelFromUXML);

            removeButton = labelFromUXML.Q<Button>("RemoveButton");
            removeButton.clicked += OnClickRemove;
            m_LabelBG = labelFromUXML.Q<Label>("Label");
            m_NameLabel = labelFromUXML.Q<Label>("NameLabel");

            m_MeshField = labelFromUXML.Q<ObjectField>("MeshField");
            m_MeshField.allowSceneObjects = false;
            m_MeshField.objectType = typeof(Mesh);
            m_MeshField.RegisterValueChangedCallback(OnMeshChange);

            m_MaterialField = labelFromUXML.Q<ObjectField>("MaterialField");
            m_MaterialField.allowSceneObjects = false;
            m_MaterialField.objectType = typeof(Material);
            m_MaterialField.RegisterValueChangedCallback(OnMaterialChange);

            m_IndirectMaterialField = labelFromUXML.Q<ObjectField>("IndirectMaterialField");
            m_IndirectMaterialField.allowSceneObjects = false;
            m_IndirectMaterialField.objectType = typeof(Material);
            m_IndirectMaterialField.RegisterValueChangedCallback(OnIndirectMaterialChange);

            RefreshPreview();
        }

        private void OnClickRemove()
        {
            //删除AutoCreateGrassSO
            if (m_PainterPrefab == null)
                return;
            AssetDatabase.DeleteAsset(GrassPainterHelper.GetAutoCreateGrassSOPath(m_PainterPrefab.GetName()));
        }

        private void RefreshPreview()
        {
            if (m_PainterPrefab != null)
            {
                m_LabelBG.style.backgroundImage = AssetPreview.GetAssetPreview(m_PainterPrefab.prefab);
                m_NameLabel.text = m_PainterPrefab.GetName();
                m_MeshField.value = m_PainterPrefab.mesh as Mesh;
                m_MaterialField.value = m_PainterPrefab.material as Material;
                m_IndirectMaterialField.value = m_PainterPrefab.indirectMaterial as Material;
            }
        }

        private void OnMeshChange(ChangeEvent<Object> mesh)
        {
            if (m_PainterPrefab == null)
                return;

            m_PainterPrefab.mesh = mesh.newValue as Mesh;
        }

        private void OnMaterialChange(ChangeEvent<Object> material)
        {
            if (m_PainterPrefab == null)
                return;

            m_PainterPrefab.material = material.newValue as Material;
        }

        private void OnIndirectMaterialChange(ChangeEvent<Object> material)
        {
            if (m_PainterPrefab == null)
                return;

            m_PainterPrefab.indirectMaterial = material.newValue as Material;
        }
    }
}
