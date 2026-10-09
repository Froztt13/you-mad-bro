package com.aqw.battery;

import java.util.HashMap;
import java.util.Map;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;

public class BatteryContext extends FREContext {

    @Override
    public Map<String, FREFunction> getFunctions() {
        Map<String, FREFunction> functions = new HashMap<String, FREFunction>();
        functions.put("requestUnrestricted", new RequestUnrestrictedFunction());
        functions.put("isIgnoringBatteryOptimizations", new IsIgnoringFunction());
        functions.put("openAppDetails", new OpenAppDetailsFunction());
        functions.put("requestStoragePermission", new RequestStorageFunction());
        functions.put("hasStoragePermission", new HasStorageFunction());
        functions.put("startForeground", new StartForegroundFunction());
        functions.put("stopForeground", new StopForegroundFunction());
        functions.put("updateForeground", new UpdateForegroundFunction());
        functions.put("sendNotification", new SendNotificationFunction());
        functions.put("cancelNotification", new CancelNotificationFunction());
        functions.put("isKeepAliveRunning", new IsKeepAliveRunningFunction());
        functions.put("requestNotificationPermission", new RequestNotificationPermissionFunction());
        functions.put("enterPipMode", new EnterPipModeFunction());
        functions.put("isPipSupported", new IsPipSupportedFunction());
        functions.put("isInPipMode", new IsInPipModeFunction());
        functions.put("setPipAutoEnter", new SetPipAutoEnterFunction());
        functions.put("openFilePicker", new OpenFilePickerFunction());
        functions.put("saveFilePicker", new SaveFilePickerFunction());
        functions.put("getLastPickedFileName", new GetLastPickedFileNameFunction());
        functions.put("getLastPickedContent", new GetLastPickedContentFunction());
        return functions;
    }

    @Override
    public void dispose() {
    }
}
