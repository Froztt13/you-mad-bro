package com.aqw.battery;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class GetLastPickedFileNameFunction implements FREFunction {
    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            return FREObject.newObject(SafHelper.lastLoadedFileName != null ? SafHelper.lastLoadedFileName : "");
        } catch (Exception ignored) {}
        return null;
    }
}
