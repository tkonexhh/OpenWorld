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

    public sealed partial class TDEquip : Bright.Config.BeanBase
    {
        public TDEquip(JSONNode _json)
        {
            { if (!_json["id"].IsNumber) { throw new SerializationException(); } Id = _json["id"]; }
            { if (!_json["name"].IsString) { throw new SerializationException(); } Name = _json["name"]; }
            { if (!_json["desc"].IsString) { throw new SerializationException(); } Desc = _json["desc"]; }
            { if (!_json["exchange_stream"].IsObject) { throw new SerializationException(); } ExchangeStream = item.ItemExchange.DeserializeItemExchange(_json["exchange_stream"]); }
            PostInit();
        }

        public TDEquip(int id, string name, string desc, item.ItemExchange exchange_stream)
        {
            this.Id = id;
            this.Name = name;
            this.Desc = desc;
            this.ExchangeStream = exchange_stream;
            PostInit();
        }

        public static TDEquip DeserializeTDEquip(JSONNode _json)
        {
            return new item.TDEquip(_json);
        }

        /// <summary>
        /// 这是id
        /// </summary>
        public int Id { get; private set; }
        /// <summary>
        /// 名字
        /// </summary>
        public string Name { get; private set; }
        /// <summary>
        /// 描述
        /// </summary>
        public string Desc { get; private set; }
        /// <summary>
        /// 道具兑换配置
        /// </summary>
        public item.ItemExchange ExchangeStream { get; private set; }

        public const int __ID__ = -1616430139;
        public override int GetTypeId() => __ID__;

        public void Resolve(Dictionary<string, object> _tables)
        {
            ExchangeStream?.Resolve(_tables);
            PostResolve();
        }

        public void TranslateText(System.Func<string, string, string> translator)
        {
            ExchangeStream?.TranslateText(translator);
        }

        public override string ToString()
        {
            return "{ "
            + "Id:" + Id + ","
            + "Name:" + Name + ","
            + "Desc:" + Desc + ","
            + "ExchangeStream:" + ExchangeStream + ","
            + "}";
        }

        partial void PostInit();
        partial void PostResolve();
    }
}
