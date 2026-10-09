package com.aqw.battery;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class GetLastPickedContentFunction implements FREFunction {
    @Override
    public FREObject call(FREContext context, FREObject[] args) {
        try {
            return FREObject.newObject(SafHelper.lastLoadedContent != null ? SafHelper.lastLoadedContent : "");
        } catch (Exception ignored) {}
        return null;
    }
}
