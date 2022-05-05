using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor;
using System;

namespace GrassPainter
{
    public class PrefabListElement : VisualElement
    {
        private ListView m_ListView;
        public PrefabListElement()
        {
            var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(GrassPainterDefine.toolPath + "GrassPainter/Res/UXML/PrefabListElement.uxml");
            VisualElement labelFromUXML = visualTree.Instantiate();
            this.Add(labelFromUXML);

            m_ListView = labelFromUXML.Q<ListView>("ListView");
            m_ListView.itemHeight = 100;
            m_ListView.selectionType = SelectionType.Single;
            m_ListView.style.flexGrow = 1;
            m_ListView.style.flexDirection = FlexDirection.Column;
            m_ListView.horizontalScrollingEnabled = true;
            m_ListView.itemsSource = GrassPainterDB.S.grassPainterDBSO.prefabs;
            m_ListView.makeItem = MakeItem;
            m_ListView.bindItem = BindItem;


        }

        public void Refresh()
        {
            m_ListView.Rebuild();
        }

        private VisualElement MakeItem()
        {
            return new PrefabItemElement();
        }

        private void BindItem(VisualElement element, int index)
        {
            var prefabItem = element as PrefabItemElement;
            prefabItem.painterPrefab = GrassPainterDB.S.grassPainterDBSO.prefabs[index];
            prefabItem.removeButton.clicked += () =>
            {
                GrassPainterDB.S.RemovePrefab(index);
                Refresh();
            };
        }

        // private voud B
    }
}
