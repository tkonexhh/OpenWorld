using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

namespace GrassPainter
{
    public delegate void OnSelectChaned();

    public class PaintGrassSelecter
    {
        private ScrollView scrollView { get; set; }
        private int m_CurIndex = -1;
        private int m_LastIndex = -1;


        private List<PrefabPreviewElement> elements = new List<PrefabPreviewElement>();

        public GrassPainterPrefab painterPrefab;

        public event OnSelectChaned onSelectChaned;


        public PaintGrassSelecter(ScrollView scrollView)
        {
            m_CurIndex = -1;
            m_LastIndex = -1;
            this.scrollView = scrollView;
            InitScrollView();
            RefeshSelect();
        }

        private void InitScrollView()
        {
            elements.Clear();
            for (int i = 0; i < GrassPainterDB.S.grassPainterDBSO.prefabs.Count; i++)
            {
                var prefabInfo = GrassPainterDB.S.grassPainterDBSO.prefabs[i];
                var prefabItem = new PrefabPreviewElement();
                prefabItem.index = i;
                prefabItem.painterPrefab = prefabInfo;
                prefabItem.bgButton.clicked += () =>
                {
                    m_LastIndex = m_CurIndex;
                    m_CurIndex = prefabItem.index;
                    RefeshSelect();
                    if (m_LastIndex != m_CurIndex)
                    {
                        onSelectChaned?.Invoke();
                    }
                };
                elements.Add(prefabItem);



                scrollView.Add(prefabItem);
            }
        }

        private void RefeshSelect()
        {
            painterPrefab = null;
            for (int i = 0; i < elements.Count; i++)
            {
                if (elements[i].index == m_CurIndex)
                {
                    elements[i].Selected();
                    painterPrefab = elements[i].painterPrefab;
                }
                else
                    elements[i].UnSelected();
            }
        }
    }
}
