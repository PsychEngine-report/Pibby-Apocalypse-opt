package;

import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Exception;
import lime.app.Application;
import openfl.Assets;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;

/**
 * A storage class optimized for iOS.
 * Stripped of Android-specific dependencies to prevent build errors.
 */
class StorageUtil
{
    #if sys
    // On iOS, this points to the app's internal sandbox storage
    public static final rootDir:String = LimeSystem.applicationStorageDirectory;

    public static function getStorageDirectory():String
    {
        // iOS apps must use the documentsDirectory for persistent user data
        return LimeSystem.documentsDirectory;
    }

    public static function createDirectories(directory:String):Void
    {
        try
        {
            if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
                return;
        }
        catch (e:haxe.Exception)
        {
            trace('Something went wrong checking directory: ${e.message}');
        }

        var total:String = '';
        if (directory.substr(0, 1) == '/')
            total = '/';

        var parts:Array<String> = directory.split('/');
        for (part in parts)
        {
            if (part != '.' && part != '')
            {
                if (total != '' && total != '/')
                    total += '/';

                total += part;

                try
                {
                    if (!FileSystem.exists(total))
                        FileSystem.createDirectory(total);
                }
                catch (e:Exception)
                    trace('Error creating directory: ${e.message}');
            }
        }
    }

    public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
    {
        // Ensure we are saving to the Documents folder, not the read-only App Bundle
        final folder:String = Path.addTrailingSlash(getStorageDirectory()) + 'saves/';
        try
        {
            if (!FileSystem.exists(folder))
                createDirectories(folder);

            File.saveContent(Path.join([folder, fileName]), fileData);
            
            if (alert)
                trace('${fileName} has been saved to ${folder}');
        }
        catch (e:Dynamic)
        {
            trace('${fileName} couldn\'t be saved: ${e.message}');
        }
    }
    #end

    /**
     * Copies assets from the App Bundle to the Documents folder.
     * Necessary on iOS if you want to modify files at runtime.
     */
    public static function copyAssets(sourcePath:String = "assets/", targetPath:String = null):Void {
        if (targetPath == null)
            targetPath = Path.addTrailingSlash(getStorageDirectory()) + "assets/";

        try {
            if (!FileSystem.exists(targetPath))
                createDirectories(targetPath);

            var assetList:Array<String> = Assets.list();

            for (assetPath in assetList) {
                if (StringTools.startsWith(assetPath, sourcePath)) {
                    var relativePath = assetPath;
                    if (StringTools.startsWith(relativePath, "assets/"))
                        relativePath = relativePath.substring(7);

                    if (relativePath == "") continue;

                    var fullTargetPath = Path.join([targetPath, relativePath]);
                    var targetDir = Path.directory(fullTargetPath);

                    if (!FileSystem.exists(targetDir))
                        createDirectories(targetDir);

                    if (Assets.exists(assetPath)) {
                        var fileData:Bytes = Assets.getBytes(assetPath);
                        if (fileData != null) {
                            File.saveBytes(fullTargetPath, fileData);
                        }
                    }
                }
            }
        } catch (e:Dynamic) {
            trace('Error copying assets: $e');
        }
    }
}
