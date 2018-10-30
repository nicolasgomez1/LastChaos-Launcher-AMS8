using RGiesecke.DllExport;
using LuaVM.Utilities.Lua;
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text;

namespace launcher
{
    public class launcher
    {
        public static string Decrypt(byte[] Info, byte Key)
        {
            for (int i = 0; i < Info.Length; i++)
            {
                Info[i] = BitConverter.GetBytes(Convert.ToInt32((int)(Info[i] - Key)))[0];
                Key = BitConverter.GetBytes(Convert.ToInt32((int)(Info[i] + Key)))[0];
            }
            return Encoding.ASCII.GetString(Info);
        }
        public static byte[] Encrypt(string Text, byte Key)
        {
            byte[] bytes = Encoding.ASCII.GetBytes(Text);
            for (int i = 0; i < bytes.Length; i++)
            {
                bytes[i] = BitConverter.GetBytes(Convert.ToInt32((int)(bytes[i] + Key)))[0];
                Key = bytes[i];
            }
            return bytes;
        }
        public static int ReadLCCNCT(IntPtr Ls)
        {
            string path = Lua.lua_tostring(Ls, 1);
            try
            {
                using (BinaryReader binaryReader = new BinaryReader(File.Open(path, FileMode.Open)))
                {
                    byte[] info = new byte[(int)binaryReader.BaseStream.Length - 19];
                    byte[] array = binaryReader.ReadBytes(19);
                    info = binaryReader.ReadBytes((int)binaryReader.BaseStream.Length - 19);
                    binaryReader.Close();
                    byte key = array[10];
                    string s = launcher.Decrypt(info, key);
                    Lua.lua_pushstring(Ls, s);
                }
            }
            catch (Exception ex)
            {
                string s2 = "lccnct.dta found but not recognised\r\n" + ex.Message;
                Lua.lua_pushstring(Ls, s2);
            }
            return 1;
        }
        public static int WriteLCCNCT(IntPtr Ls)
        {
            string path = Lua.lua_tostring(Ls, 1);
            string text = Lua.lua_tostring(Ls, 2);
            byte[] array = new byte[19];
            byte key = array[10];
            byte[] buffer = launcher.Encrypt(text, key);
            FileStream output = new FileStream(path, FileMode.Create);
            BinaryWriter binaryWriter = new BinaryWriter(output);
            binaryWriter.Write(array);
            binaryWriter.Write(buffer);
            binaryWriter.Close();
            string s = "LCCNCT Saved.";
            Lua.lua_pushstring(Ls, s);
            return 1;
        }
        public static int ReadVTM(IntPtr Ls)
        {
            string path = Lua.lua_tostring(Ls, 1);
            try
            {
                using (BinaryReader binaryReader = new BinaryReader(File.Open(path, FileMode.Open, FileAccess.Read)))
                {
                    int num = binaryReader.ReadInt32();
                    binaryReader.Close();
                    string s = ((num - 27) / 3).ToString();
                    Lua.lua_pushstring(Ls, s);
                }
            }
            catch (Exception ex)
            {
                string s = "vtm.brn found but not recognised\r\n" + ex.ToString();
                Lua.lua_pushstring(Ls, s);
            }
            return 1;
        }
        public static int WriteVTM(IntPtr Ls)
        {
            string path = Lua.lua_tostring(Ls, 1);
            int num = 0;
            int.TryParse(Lua.lua_tostring(Ls, 2), out num);
            num = num * 3 + 27;
            BinaryWriter binaryWriter = new BinaryWriter(new FileStream(path, FileMode.Create));
            binaryWriter.Write(num);
            binaryWriter.Close();
            string s = "VTM Saved.";
            Lua.lua_pushstring(Ls, s);
            return 1;
        }
        [DllExport(CallingConvention = CallingConvention.Cdecl)]
        public static int luaopen_launcher(IntPtr Ls)
        {
            Lua.lua_register(Ls, "ReadVTM", new Lua.LuaFunction(launcher.ReadVTM));
            Lua.lua_register(Ls, "WriteVTM", new Lua.LuaFunction(launcher.WriteVTM));
            Lua.lua_register(Ls, "ReadLCCNCT", new Lua.LuaFunction(launcher.ReadLCCNCT));
            Lua.lua_register(Ls, "WriteLCCNCT", new Lua.LuaFunction(launcher.WriteLCCNCT));
            return 1;
        }
    }
}
