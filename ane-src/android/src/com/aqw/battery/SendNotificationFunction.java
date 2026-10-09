package com.aqw.battery;

import android.app.Activity;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class SendNotificationFunction implements FREFunction {

    private static final String TAG = "SendNotificationFn";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            Activity activity = context.getActivity();
            if (activity == null) return null;

            String title = "YouMadBro Alert";
            String text = "";
            int id = 2001;

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

            if (args != null && args.length > 2 && args[2] != null) {
                try {
                    id = args[2].getAsInt();
                } catch (Exception e) {}
            }

            NotificationHelper.sendAlert(activity, title, text, id);
        } catch (Exception e) {
            Log.e(TAG, "Error in SendNotificationFunction", e);
        }
        return null;
    }
}
