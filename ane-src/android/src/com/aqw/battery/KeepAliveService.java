package com.aqw.battery;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.IBinder;
import android.os.PowerManager;
import android.util.Log;

public class KeepAliveService extends Service {

    private static final String TAG = "KeepAliveService";

    public static final String ACTION_START = "com.aqw.battery.ACTION_START";
    public static final String ACTION_UPDATE = "com.aqw.battery.ACTION_UPDATE";
    public static final String ACTION_STOP = "com.aqw.battery.ACTION_STOP";

    public static final String EXTRA_TITLE = "extra_title";
    public static final String EXTRA_TEXT = "extra_text";

    private PowerManager.WakeLock wakeLock = null;
    private WifiManager.WifiLock wifiLock = null;
    private static boolean isRunning = false;

    public static boolean isServiceRunning() {
        return isRunning;
    }

    public static void start(Context context, String title, String text) {
        if (context == null) return;
        try {
            Intent intent = new Intent(context, KeepAliveService.class);
            intent.setAction(ACTION_START);
            intent.putExtra(EXTRA_TITLE, title);
            intent.putExtra(EXTRA_TEXT, text);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent);
            } else {
                context.startService(intent);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error starting KeepAliveService", e);
        }
    }

    public static void update(Context context, String title, String text) {
        if (context == null) return;
        try {
            Intent intent = new Intent(context, KeepAliveService.class);
            intent.setAction(ACTION_UPDATE);
            intent.putExtra(EXTRA_TITLE, title);
            intent.putExtra(EXTRA_TEXT, text);
            context.startService(intent);
        } catch (Exception e) {
            Log.e(TAG, "Error updating KeepAliveService", e);
        }
    }

    public static void stop(Context context) {
        if (context == null) return;
        try {
            Intent intent = new Intent(context, KeepAliveService.class);
            intent.setAction(ACTION_STOP);
            context.stopService(intent);
        } catch (Exception e) {
            Log.e(TAG, "Error stopping KeepAliveService", e);
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        acquireLocks();
        isRunning = true;
        Log.d(TAG, "KeepAliveService created and locks acquired");
    }

    private void acquireLocks() {
        try {
            if (wakeLock == null) {
                PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
                if (pm != null) {
                    wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "YouMadBro:KeepAliveWakeLock");
                    wakeLock.setReferenceCounted(false);
                    wakeLock.acquire();
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to acquire WakeLock", e);
        }

        try {
            if (wifiLock == null) {
                WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
                if (wm != null) {
                    wifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "YouMadBro:KeepAliveWifiLock");
                    wifiLock.setReferenceCounted(false);
                    wifiLock.acquire();
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to acquire WifiLock", e);
        }
    }

    private void releaseLocks() {
        try {
            if (wakeLock != null && wakeLock.isHeld()) {
                wakeLock.release();
                wakeLock = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error releasing WakeLock", e);
        }

        try {
            if (wifiLock != null && wifiLock.isHeld()) {
                wifiLock.release();
                wifiLock = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error releasing WifiLock", e);
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : null;
        String title = intent != null ? intent.getStringExtra(EXTRA_TITLE) : null;
        String text = intent != null ? intent.getStringExtra(EXTRA_TEXT) : null;

        if (ACTION_STOP.equals(action)) {
            stopSelf();
            return START_NOT_STICKY;
        }

        Notification notification = NotificationHelper.buildServiceNotification(this, title, text);

        try {
            startForeground(NotificationHelper.SERVICE_NOTIFICATION_ID, notification);
        } catch (Exception e) {
            Log.e(TAG, "Error in startForeground", e);
        }

        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        isRunning = false;
        releaseLocks();
        try {
            stopForeground(true);
        } catch (Exception e) {}
        Log.d(TAG, "KeepAliveService destroyed and locks released");
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
