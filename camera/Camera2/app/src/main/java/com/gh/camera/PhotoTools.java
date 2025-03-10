package com.gh.camera;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;

import androidx.core.content.FileProvider;

import java.io.File;

public class PhotoTools {
    public static final int REQUEST_CODE_TAKE_PICTURE = 10001;

    public static Uri takePicture(Activity activity, File file){
        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        Uri imgUri = null;

        // 7.0以上版本，必须使用FileProvider
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            String authority = activity.getPackageName()+".fileprovider";
            imgUri = FileProvider.getUriForFile(activity, authority, file);
        } else {
            imgUri = Uri.fromFile(file);
        }
        // 设置拍照后保存的路径
        intent.putExtra(MediaStore.EXTRA_OUTPUT, imgUri);
        // 设置图片保存的格式
        intent.putExtra("outputFormat", Bitmap.CompressFormat.JPEG.toString());
        activity.startActivityForResult(intent, REQUEST_CODE_TAKE_PICTURE);

        return imgUri;
    }
}
