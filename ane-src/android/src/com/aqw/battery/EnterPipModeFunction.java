package com.aqw.battery;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.os.Build;
import android.util.Log;
import android.util.Rational;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class EnterPipModeFunction implements FREFunction {
    private static final String TAG = "BatteryANE_PiP";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.w(TAG, "PiP mode requires Android 8.0 (API 26) or higher");
            try {
                return FREObject.newObject(false);
            } catch (Exception ignored) {}
            return null;
        }

        Activity activity = context.getActivity();
        if (activity == null) {
            Log.e(TAG, "Activity is null, cannot enter PiP");
            try {
                return FREObject.newObject(false);
            } catch (Exception ignored) {}
            return null;
        }

        try {
            int num = 16;
            int den = 9;
            if (args != null && args.length >= 2 && args[0] != null && args[1] != null) {
                try {
                    int n = args[0].getAsInt();
                    int d = args[1].getAsInt();
                    if (n > 0 && d > 0) {
                        double ratio = (double) n / (double) d;
                        if (ratio >= 0.418410 && ratio <= 2.39) {
                            num = n;
                            den = d;
                        }
                    }
                } catch (Exception eArgs) {
                    Log.w(TAG, "Could not parse aspect ratio args, using 16:9", eArgs);
                }
            }

            PictureInPictureParams.Builder builder = new PictureInPictureParams.Builder();
            builder.setAspectRatio(new Rational(num, den));

            boolean success = activity.enterPictureInPictureMode(builder.build());
            return FREObject.newObject(success);
        } catch (Exception e) {
            Log.e(TAG, "Error entering PiP mode", e);
            try {
                return FREObject.newObject(false);
            } catch (Exception ignored) {}
        }
        return null;
    }
}
