package com.aqw.battery;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class IsPipSupportedFunction implements FREFunction {
    private static final String TAG = "BatteryANE_PiP";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            try {
                return FREObject.newObject(false);
            } catch (Exception ignored) {}
            return null;
        }

        Activity activity = context.getActivity();
        if (activity == null) {
            try {
                return FREObject.newObject(false);
            } catch (Exception ignored) {}
            return null;
        }

        try {
            boolean supported = activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE);
            return FREObject.newObject(supported);
        } catch (Exception e) {
            Log.e(TAG, "Error checking PiP support", e);
            try {
                return FREObject.newObject(false);
            } catch (Exception ignored) {}
        }
        return null;
    }
}
