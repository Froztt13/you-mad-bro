package com.aqw.battery;

import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class IsKeepAliveRunningFunction implements FREFunction {

    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            boolean running = KeepAliveService.isServiceRunning();
            return FREObject.newObject(running);
        } catch (Exception e) {
            return null;
        }
    }
}
