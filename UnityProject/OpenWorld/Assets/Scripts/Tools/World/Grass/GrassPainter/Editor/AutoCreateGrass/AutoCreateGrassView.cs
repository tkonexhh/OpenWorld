// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;
// using UnityEngine.UIElements;
// using UnityEditor.UIElements;
// using UnityEditor;
// using Sirenix.OdinInspector;
// using Sirenix.OdinInspector.Editor;

// namespace GrassPainter
// {
//     public class AutoCreateGrassView : FuncElement
//     {
//         private ScrollView m_PrefabScrollView;
//         private PaintGrassSelecter m_Selecter;

//         private Button m_AddBtn;

//         private AutoCreateGrassSO m_CreateGrassSO;
//         private PropertyTree m_PropertyTree;

//         public override void Init()
//         {
//             var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(GrassPainterDefine.toolPath + "GrassPainter/Res/UXML/AutoCreateGrassView.uxml");
//             VisualElement labelFromUXML = visualTree.Instantiate();
//             this.Add(labelFromUXML);

//             m_PrefabScrollView = labelFromUXML.Q<ScrollView>("PrefabScrollView");
//             m_PrefabScrollView.style.flexDirection = FlexDirection.Row;
//             m_PrefabScrollView.showHorizontal = true;

//             m_Selecter = new PaintGrassSelecter(m_PrefabScrollView);
//             m_Selecter.onSelectChaned += OnSelectChaned;

//             IMGUIContainer m_IMGUIContainer = new IMGUIContainer(OnIMGUI);
//             this.Add(m_IMGUIContainer);
//         }

//         private void OnIMGUI()
//         {
//             if (m_PropertyTree != null)
//             {
//                 m_PropertyTree.Draw(false);
//             }
//         }


//         public override void OnDestroy()
//         {
//             m_Selecter.onSelectChaned -= OnSelectChaned;
//         }

//         private void OnSelectChaned()
//         {
//             if (m_Selecter.painterPrefab == null)
//                 return;
//             m_CreateGrassSO = null;
//             m_PropertyTree = null;
//             var so = AssetDatabase.LoadAssetAtPath<AutoCreateGrassSO>(GrassPainterHelper.GetAutoCreateGrassSOPath(m_Selecter.painterPrefab.GetName()));
//             if (so == null)
//             {
//                 CreateAddBtn();
//             }
//             else
//             {
//                 RemvoeAddBtn();

//                 m_CreateGrassSO = so;
//                 m_CreateGrassSO.grassPainterPrefab = m_Selecter.painterPrefab;
//                 m_PropertyTree = PropertyTree.Create(m_CreateGrassSO);
//             }

//         }

//         private void CreateAddBtn()
//         {
//             RemvoeAddBtn();

//             m_AddBtn = new Button();
//             m_AddBtn.text = "+";
//             m_AddBtn.clicked += OnClickAdd;
//             this.Add(m_AddBtn);
//         }

//         private void RemvoeAddBtn()
//         {
//             if (m_AddBtn != null)
//             {
//                 if (this.Contains(m_AddBtn))
//                     this.Remove(m_AddBtn);
//             }
//         }

//         private void OnClickAdd()
//         {
//             var so = SerializedScriptableObject.CreateInstance<AutoCreateGrassSO>();
//             AssetDatabase.CreateAsset(so, GrassPainterHelper.GetAutoCreateGrassSOPath(m_Selecter.painterPrefab.GetName()));
//             OnSelectChaned();
//         }

//     }
// }
