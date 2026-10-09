package com.aqw.battery;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.PowerManager;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class IsIgnoringFunction implements FREFunction {

    private static final String TAG = "BatteryANE";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        boolean ignoring = false;
        try {
            Activity activity = context.getActivity();
            if (activity != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PowerManager pm = (PowerManager) activity.getSystemService(Context.POWER_SERVICE);
                if (pm != null) {
                    ignoring = pm.isIgnoringBatteryOptimizations(activity.getPackageName());
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error checking isIgnoringBatteryOptimizations", e);
        }

        try {
            return FREObject.newObject(ignoring);
        } catch (Exception e) {
            return null;
        }
    }
}
