package com.gh.camera;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import android.Manifest;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import java.io.File;
import java.io.IOException;
import java.util.List;

import pub.devrel.easypermissions.EasyPermissions;

public class MainActivity extends AppCompatActivity implements EasyPermissions.PermissionCallbacks {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button takeBtn = findViewById(R.id.take);
        takeBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                takePicture();
            }
        });
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);

    }

    private void takePicture() {
        if (EasyPermissions.hasPermissions(this,
                Manifest.permission.CAMERA,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE)) {

            File dir = new File(Environment.getExternalStorageDirectory(), "Pictures");
            // 如果不存在Pictures文件夹，则创建
            if (!dir.exists()) dir.mkdir();
            File image = new File(dir, System.currentTimeMillis() + ".jpg");
            if (!image.exists()) {
                try {
                    // 创建一个空文件
                    image.createNewFile();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            Log.d("PhotoTools", image.getAbsolutePath());

            PhotoTools.takePicture(this, image);
        } else {
            EasyPermissions.requestPermissions(this, "拍照授权", 10010,
                    Manifest.permission.CAMERA,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    Manifest.permission.READ_EXTERNAL_STORAGE);
        }
    }

    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PhotoTools.REQUEST_CODE_TAKE_PICTURE) {
            Log.d("PhotoTools", "onActivityResult " + resultCode);
            if (resultCode == RESULT_OK) {
                Toast.makeText(this, "照片已保存", Toast.LENGTH_LONG).show();
            }
        }
    }

    @Override
    public void onPermissionsGranted(int requestCode, @NonNull List<String> perms) {
        takePicture();//成功
    }

    @Override
    public void onPermissionsDenied(int requestCode, @NonNull List<String> perms) {
        //失败
    }
}