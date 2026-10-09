package com.aqw.battery;

import android.app.Activity;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class UpdateForegroundFunction implements FREFunction {

    private static final String TAG = "UpdateForegroundFn";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            Activity activity = context.getActivity();
            if (activity == null) return null;

            String title = "YouMadBro Bot Active";
            String text = "Running...";

            if (args != null && args.length > 0 && args[0] != null) {
                try {
                    title = args[0].getAsString();
                } catch (Exception e) {}
            }

            if (args != null && args.length > 1 && args[1] != null) {
                try {
                    text = args[1].getAsString();
                } catch (Exception e) {}
            }

            KeepAliveService.update(activity, title, text);
        } catch (Exception e) {
            Log.e(TAG, "Error in UpdateForegroundFunction", e);
        }
        return null;
    }
}
