using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using Sirenix.OdinInspector;


namespace OpenWorld
{
    public class StreamTest : MonoBehaviour
    {
        string path;
        public TextAsset textAsset;

        void Start()
        {
            path = Application.dataPath + "/StreamTest.txt";
            Write();
        }


        private void Write()
        {
            Debug.LogError(path);
            FileStream stream = File.Open(path, FileMode.Create);


            StreamHelper.WriteByte(stream, 24);
            StreamHelper.WriteInt(stream, 123);
            StreamHelper.WriteVector3(stream, Vector3.back);

            stream.Flush();
            stream.Close();
        }

        [Button]
        private void Read()
        {
            if (textAsset == null)
                return;

            var data = textAsset.bytes;
            MemoryStream stream = new MemoryStream(data);
            var v = StreamHelper.ReadByte(stream);
            Debug.LogError("Byte:" + v);
            var v2 = StreamHelper.ReadInt(stream);
            Debug.LogError("Int:" + v2);

            var v3 = StreamHelper.ReadVector3(stream);
            Debug.LogError("V3:" + v3);
        }


    }

}