package com.aqw.battery;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

public class BatteryExtension implements FREExtension {

    @Override
    public void initialize() {
    }

    @Override
    public FREContext createContext(String extId) {
        return new BatteryContext();
    }

    @Override
    public void dispose() {
    }
}
