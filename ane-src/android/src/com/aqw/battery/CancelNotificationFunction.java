package com.aqw.battery;

import android.app.Activity;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class CancelNotificationFunction implements FREFunction {

    private static final String TAG = "CancelNotificationFn";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            Activity activity = context.getActivity();
            if (activity == null) return null;

            int id = 2001;
            if (args != null && args.length > 0 && args[0] != null) {
                try {
                    id = args[0].getAsInt();
                } catch (Exception e) {}
            }

            NotificationHelper.cancelNotification(activity, id);
        } catch (Exception e) {
            Log.e(TAG, "Error in CancelNotificationFunction", e);
        }
        return null;
    }
}
