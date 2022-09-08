using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class Vector3Drawer : MaterialPropertyDrawer
{
    //该控件会在以下选项中显示
    private string[] _showList = new string[0];
    //绘制折叠页的ShaderGUI
    // private SimpleShaderGUI _simpleShaderGUI;
    //是否总是显示
    private bool _isAlwaysShow = true;
    //材质属性
    private MaterialProperty _property;
    //是否编辑
    private bool _isEditor = false;
    //是否开始编辑
    private bool _isStartEditor = true;
    //当前旋转
    private Quaternion _rotation = Quaternion.identity;
    //当前材质的对象
    private GameObject _selectGameObj;

    public Vector3Drawer()
    {
        _isAlwaysShow = true;
    }

    public Vector3Drawer(params string[] showList)
    {
        _showList = showList;
        _isAlwaysShow = showList == null || showList.Length == 0;
    }

    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        //如果不是Vector类型，则把unity的默认警告框的高度40
        if (!(prop.type == MaterialProperty.PropType.Vector))
        {
            return 40f;
        }
        return EditorGUI.GetPropertyHeight(SerializedPropertyType.Vector3, new GUIContent(label));
    }

    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {

        if (prop.type != MaterialProperty.PropType.Vector)
        {
            GUILayout.Label(prop.displayName + " :   Property must be of type vector");
            // editor.DefaultShaderProperty( prop, label );
            return;
        }

        _property = prop;

        //检查属性是否要被绘制
        // if (!(_isAlwaysShow || _simpleShaderGUI.GetShowState(_showList)))
        //     return;


        EditorGUI.BeginChangeCheck();

        float oldLabelWidth = EditorGUIUtility.labelWidth;
        EditorGUIUtility.labelWidth = 0f;

        Color oldColor = GUI.color;
        if (_isEditor)
            GUI.color = Color.green;

        //绘制属性
        Rect vecRect = new Rect(position)
        {
            width = position.width - 68,
        };

        Vector3 value = new Vector3(prop.vectorValue.x, prop.vectorValue.y, prop.vectorValue.z);
        value = EditorGUI.Vector3Field(vecRect, label, value);
        EditorGUIUtility.labelWidth = oldLabelWidth;
        if (EditorGUI.EndChangeCheck())
        {
            prop.vectorValue = new Vector4(value.x, value.y, value.z);
        }

        //绘制开关
        Rect butRect = new Rect(position)
        {
            x = position.xMax - 63f,
            y = (position.height > 20) ? position.y + 20 : position.y,
            width = 60f,
            height = 18f
        };
        // _isEditor = EditorGUILayout.Toggle("Set", _isEditor);
        _isEditor = GUI.Toggle(butRect, _isEditor, "Set", "Button");
        // EditorGUILayout.EndHorizontal();

        //绘制手柄
        if (_isEditor && _isStartEditor)
            CreateHandle(value);
        else if (!_isEditor && !_isStartEditor)
            DeleteHandle();

        GUI.color = oldColor;
        EditorGUI.showMixedValue = false;
        if (EditorGUI.EndChangeCheck())
        {
            prop.vectorValue = new Vector4(value.x, value.y, value.z, prop.vectorValue.w);
        }
    }

    //创建手柄
    private void CreateHandle(Vector3 dir)
    {
        //清除当前选择状态
        Tools.current = Tool.None;
        _selectGameObj = Selection.activeGameObject;
        _rotation = Quaternion.FromToRotation(Vector3.forward, dir);
        // SceneView.onSceneGUIDelegate += HandleDraw;//该委托在高版本Unity已被弃用(替换成duringSceneGui)，如果你使用旧版的untiy，你可能需要使用该语句
        SceneView.duringSceneGui += HandleDraw;//添加绘制事件
        SceneView.RepaintAll();
        _isStartEditor = false;
    }

    //清除手柄
    private void DeleteHandle()
    {
        //移除绘制事件
        // SceneView.onSceneGUIDelegate -= HandleDraw;//该委托在高版本Unity已被弃用(替换成duringSceneGui)，如果你使用旧版的untiy，你可能需要使用该语句
        SceneView.duringSceneGui -= HandleDraw;
        SceneView.RepaintAll();
        _selectGameObj = null;
        _isStartEditor = true;
    }


    //绘制手柄
    private void HandleDraw(SceneView sceneView)
    {
        //如果切换了对象，关闭绘制
        if (_selectGameObj == null || _selectGameObj != Selection.activeGameObject)
        {
            DeleteHandle();
            _isEditor = false;
            return;
        }

        Vector3 pos = _selectGameObj.transform.position;

        //绘制旋转控件
        _rotation = Handles.RotationHandle(_rotation, pos);


        Vector3 newDir = _rotation * Vector3.forward;

        _property.vectorValue = new Vector4(newDir.x, newDir.y, newDir.z, _property.vectorValue.w);

        //绘制手柄中心图标
        Handles.color = Color.green;
        float size = HandleUtility.GetHandleSize(pos);
        Handles.ConeHandleCap(0, pos, _rotation.normalized, size, EventType.Repaint);
    }
}
