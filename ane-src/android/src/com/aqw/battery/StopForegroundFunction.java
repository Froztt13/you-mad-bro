package com.aqw.battery;

import android.app.Activity;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class StopForegroundFunction implements FREFunction {

    private static final String TAG = "StopForegroundFn";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            Activity activity = context.getActivity();
            if (activity != null) {
                KeepAliveService.stop(activity);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in StopForegroundFunction", e);
        }
        return null;
    }
}
