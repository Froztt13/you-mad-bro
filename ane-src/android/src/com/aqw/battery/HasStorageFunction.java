package com.aqw.battery;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Environment;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class HasStorageFunction implements FREFunction {

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            Activity activity = context.getActivity();
            if (activity == null) {
                return FREObject.newObject(false);
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                boolean hasManage = Environment.isExternalStorageManager();
                return FREObject.newObject(hasManage);
            } else {
                int writePerm = activity.checkCallingOrSelfPermission("android.permission.WRITE_EXTERNAL_STORAGE");
                return FREObject.newObject(writePerm == PackageManager.PERMISSION_GRANTED);
            }
        } catch (Exception e) {
            return null;
        }
    }
}
