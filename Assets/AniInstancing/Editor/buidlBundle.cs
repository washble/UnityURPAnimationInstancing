using UnityEngine;
using UnityEditor;
using System.IO;

public class BuidlBundle : MonoBehaviour
{
    static string Path = "Assets/AssetBundle";
    static string FolderName = "AssetBundle";

    [MenuItem("AnimationInstancing/BuildAssetBundle")]
    static void CreateAssetBundle()
    {
        const string streamingAssetsPath = "Assets/StreamingAssets";
        Directory.CreateDirectory(streamingAssetsPath);
        CheckDirectory(Path);
        AssetBundleManifest manifest = BuildPipeline.BuildAssetBundles(Path, BuildAssetBundleOptions.ChunkBasedCompression, EditorUserBuildSettings.activeBuildTarget);
        if (manifest == null)
            return;

        FileUtil.DeleteFileOrDirectory(streamingAssetsPath + "/" + FolderName);
        FileUtil.CopyFileOrDirectory(Path, streamingAssetsPath + "/" + FolderName);
        AssetDatabase.Refresh();
    }

    static void CheckDirectory(string path)
    {
        if (!Directory.Exists(path))
            AssetDatabase.CreateFolder("Assets", FolderName);
    }
}
