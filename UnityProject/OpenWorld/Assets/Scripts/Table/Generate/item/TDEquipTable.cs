//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------
using Bright.Serialization;
using System.Collections.Generic;
using SimpleJSON;



namespace OpenWorld.item
{

    public sealed partial class TDEquipTable
    {
        private readonly Dictionary<int, item.TDEquip> _dataMap;
        private readonly List<item.TDEquip> _dataList;

        public TDEquipTable(JSONNode _json)
        {
            _dataMap = new Dictionary<int, item.TDEquip>();
            _dataList = new List<item.TDEquip>();

            foreach (JSONNode _row in _json.Children)
            {
                var _v = item.TDEquip.DeserializeTDEquip(_row);
                _dataList.Add(_v);
                _dataMap.Add(_v.Id, _v);
            }
            PostInit();
        }

        public Dictionary<int, item.TDEquip> DataMap => _dataMap;
        public List<item.TDEquip> DataList => _dataList;

        public item.TDEquip GetOrDefault(int key) => _dataMap.TryGetValue(key, out var v) ? v : null;
        public item.TDEquip Get(int key) => _dataMap[key];
        public item.TDEquip this[int key] => _dataMap[key];

        public void Resolve(Dictionary<string, object> _tables)
        {
            foreach (var v in _dataList)
            {
                v.Resolve(_tables);
            }
            PostResolve();
        }

        public void TranslateText(System.Func<string, string, string> translator)
        {
            foreach (var v in _dataList)
            {
                v.TranslateText(translator);
            }
        }


        partial void PostInit();
        partial void PostResolve();
    }

}