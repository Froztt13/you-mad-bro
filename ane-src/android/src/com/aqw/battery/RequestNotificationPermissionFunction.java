package com.aqw.battery;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class RequestNotificationPermissionFunction implements FREFunction {

    private static final String TAG = "ReqNotifPermFn";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            Activity activity = context.getActivity();
            if (activity == null) return null;

            if (Build.VERSION.SDK_INT >= 33) {
                int check = activity.checkCallingOrSelfPermission("android.permission.POST_NOTIFICATIONS");
                if (check != PackageManager.PERMISSION_GRANTED) {
                    activity.requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 102);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error requesting notification permission", e);
        }
        return null;
    }
}
