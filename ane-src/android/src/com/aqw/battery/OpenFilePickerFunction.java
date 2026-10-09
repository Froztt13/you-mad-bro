package com.aqw.battery;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class OpenFilePickerFunction implements FREFunction {
    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        String mime = "*/*";
        if (args != null && args.length >= 1 && args[0] != null) {
            try {
                mime = args[0].getAsString();
            } catch (Exception ignored) {}
        }

        boolean started = false;
        if (context instanceof BatteryContext) {
            started = SafHelper.openFilePicker((BatteryContext) context, mime);
        }

        try {
            return FREObject.newObject(started);
        } catch (Exception ignored) {}
        return null;
    }
}
