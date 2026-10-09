package com.aqw.battery;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.os.Build;
import android.util.Log;
import android.util.Rational;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class SetPipAutoEnterFunction implements FREFunction {
    private static final String TAG = "BatteryANE_PiP";

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            // setAutoEnterEnabled is supported on Android 12 (API 31)+
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
            boolean enabled = true;
            if (args != null && args.length >= 1 && args[0] != null) {
                enabled = args[0].getAsBool();
            }

            int num = 16;
            int den = 9;
            if (args != null && args.length >= 3 && args[1] != null && args[2] != null) {
                try {
                    int n = args[1].getAsInt();
                    int d = args[2].getAsInt();
                    if (n > 0 && d > 0) {
                        double ratio = (double) n / (double) d;
                        if (ratio >= 0.418410 && ratio <= 2.39) {
                            num = n;
                            den = d;
                        }
                    }
                } catch (Exception ignored) {}
            }

            PictureInPictureParams.Builder builder = new PictureInPictureParams.Builder();
            builder.setAspectRatio(new Rational(num, den));
            builder.setAutoEnterEnabled(enabled);

            activity.setPictureInPictureParams(builder.build());
            return FREObject.newObject(true);
        } catch (Exception e) {
            Log.e(TAG, "Error configuring PiP auto-enter", e);
            try {
                return FREObject.newObject(false);
            } catch (Exception ignored) {}
        }
        return null;
    }
}
