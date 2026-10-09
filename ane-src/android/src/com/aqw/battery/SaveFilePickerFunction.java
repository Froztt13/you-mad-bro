package com.aqw.battery;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class SaveFilePickerFunction implements FREFunction {
    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        String fileName = "bot_script.json";
        String content = "{}";

        if (args != null && args.length >= 1 && args[0] != null) {
            try {
                fileName = args[0].getAsString();
            } catch (Exception ignored) {}
        }
        if (args != null && args.length >= 2 && args[1] != null) {
            try {
                content = args[1].getAsString();
            } catch (Exception ignored) {}
        }

        boolean started = false;
        if (context instanceof BatteryContext) {
            started = SafHelper.saveFilePicker((BatteryContext) context, fileName, content);
        }

        try {
            return FREObject.newObject(started);
        } catch (Exception ignored) {}
        return null;
    }
}
