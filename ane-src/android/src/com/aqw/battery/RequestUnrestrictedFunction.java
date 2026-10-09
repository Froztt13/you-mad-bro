package com.aqw.battery;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class RequestUnrestrictedFunction implements FREFunction {

    private static final String TAG = "BatteryANE";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            Activity activity = context.getActivity();
            if (activity == null) {
                Log.w(TAG, "Activity is null in RequestUnrestrictedFunction");
                return null;
            }

            String pkg = activity.getPackageName();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PowerManager pm = (PowerManager) activity.getSystemService(Context.POWER_SERVICE);
                if (pm != null && !pm.isIgnoringBatteryOptimizations(pkg)) {
                    Log.i(TAG, "Requesting ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS for " + pkg);
                    Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                    intent.setData(Uri.parse("package:" + pkg));
                    activity.startActivity(intent);
                    return null;
                } else {
                    Log.i(TAG, "App is already ignoring battery optimizations");
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, trying fallback", e);
            try {
                Activity activity = context.getActivity();
                if (activity != null) {
                    Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                    intent.setData(Uri.parse("package:" + activity.getPackageName()));
                    activity.startActivity(intent);
                }
            } catch (Exception ex) {
                Log.e(TAG, "Fallback also failed", ex);
            }
        }
        return null;
    }
}
