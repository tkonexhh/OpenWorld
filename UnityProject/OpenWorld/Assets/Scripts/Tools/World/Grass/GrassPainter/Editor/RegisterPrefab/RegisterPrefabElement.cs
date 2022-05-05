using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
using UnityEditor;

namespace GrassPainter
{
    public class RegisterPrefabElement : FuncElement
    {
        private ObjectField m_MeshField;
        private ObjectField m_MaterialField;
        private ObjectField m_IndirectMaterialField;
        private Button m_AddButton;
        private PrefabListElement m_PrefabListElement;

        public override void Init()
        {
            var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(GrassPainterDefine.toolPath + "GrassPainter/Res/UXML/RegisterPrefabElement.uxml");
            VisualElement labelFromUXML = visualTree.Instantiate();
            this.Add(labelFromUXML);


            m_MeshField = labelFromUXML.Q<ObjectField>("MeshField");
            m_MeshField.allowSceneObjects = false;
            m_MeshField.objectType = typeof(Mesh);

            m_MaterialField = labelFromUXML.Q<ObjectField>("MaterialField");
            m_MaterialField.allowSceneObjects = false;
            m_MaterialField.objectType = typeof(Material);

            m_IndirectMaterialField = labelFromUXML.Q<ObjectField>("IndirectMaterialField");
            m_IndirectMaterialField.allowSceneObjects = false;
            m_IndirectMaterialField.objectType = typeof(Material);


            m_AddButton = labelFromUXML.Q<Button>("AddButton");
            m_AddButton.clicked += OnClickAdd;

            m_PrefabListElement = new PrefabListElement();
            this.Add(m_PrefabListElement);

            GrassPainterDB.S.Init();
        }

        public override void OnDestroy()
        {
        }

        private void OnClickAdd()
        {
            if (m_MeshField.value == null || m_MaterialField.value == null || m_IndirectMaterialField.value == null)
                return;

            GrassPainterPrefabArgs args = new GrassPainterPrefabArgs();
            args.mesh = m_MeshField.value as Mesh;
            args.material = m_MaterialField.value as Material;
            args.indirectMaterial = m_IndirectMaterialField.value as Material;
            GrassPainterDB.S.AddPrefab(args);

            m_PrefabListElement.Refresh();

            m_MeshField.value = null;
            m_MaterialField.value = null;
            m_IndirectMaterialField.value = null;
        }
    }
}
