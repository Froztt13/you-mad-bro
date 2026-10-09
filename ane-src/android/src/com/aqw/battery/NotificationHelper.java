package com.aqw.battery;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.util.Log;

public class NotificationHelper {

    private static final String TAG = "BatteryANE_Notif";

    public static final String CHANNEL_SERVICE_ID = "youmadbro_keepalive_channel";
    public static final String CHANNEL_ALERT_ID = "youmadbro_alerts_channel_v2";

    public static final int SERVICE_NOTIFICATION_ID = 1001;

    public static void createChannels(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                if (manager == null) return;

                // 1. Silent persistent channel for foreground keepalive service
                NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_SERVICE_ID,
                    "YouMadBro Keep-Alive Service",
                    NotificationManager.IMPORTANCE_LOW
                );
                serviceChannel.setDescription("Keeps YouMadBro bot running and connected in background");
                serviceChannel.setShowBadge(false);
                manager.createNotificationChannel(serviceChannel);

                // Clean up previous high-vibration channel if present
                try {
                    manager.deleteNotificationChannel("youmadbro_alerts_channel");
                } catch (Exception ignored) {}

                // 2. Alert channel without vibration to avoid continuous buzzing
                NotificationChannel alertChannel = new NotificationChannel(
                    CHANNEL_ALERT_ID,
                    "YouMadBro Game Alerts",
                    NotificationManager.IMPORTANCE_DEFAULT
                );
                alertChannel.setDescription("Notifications for completed quests, drops, and disconnects");
                alertChannel.enableVibration(false);
                alertChannel.setVibrationPattern(new long[]{0});
                alertChannel.setShowBadge(true);
                manager.createNotificationChannel(alertChannel);

            } catch (Exception e) {
                Log.e(TAG, "Error creating notification channels", e);
            }
        }
    }

    private static int getAppIcon(Context context) {
        try {
            ApplicationInfo appInfo = context.getApplicationInfo();
            if (appInfo != null && appInfo.icon != 0) {
                return appInfo.icon;
            }
        } catch (Exception e) {}
        return android.R.drawable.ic_dialog_info;
    }

    private static PendingIntent getLaunchIntent(Context context) {
        try {
            Intent intent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
            if (intent != null) {
                intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                int flags = PendingIntent.FLAG_UPDATE_CURRENT;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    flags |= PendingIntent.FLAG_IMMUTABLE;
                }
                return PendingIntent.getActivity(context, 0, intent, flags);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error creating launch pending intent", e);
        }
        return null;
    }

    public static Notification buildServiceNotification(Context context, String title, String text) {
        createChannels(context);

        String nTitle = (title != null && !title.isEmpty()) ? title : "YouMadBro Bot Active";
        String nText = (text != null && !text.isEmpty()) ? text : "Background keep-alive running...";

        Notification.Builder builder;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder = new Notification.Builder(context, CHANNEL_SERVICE_ID);
        } else {
            builder = new Notification.Builder(context);
        }

        builder.setContentTitle(nTitle)
               .setContentText(nText)
               .setSmallIcon(getAppIcon(context))
               .setOngoing(true);

        PendingIntent pi = getLaunchIntent(context);
        if (pi != null) {
            builder.setContentIntent(pi);
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            builder.setVisibility(Notification.VISIBILITY_PUBLIC);
        }

        return builder.build();
    }

    public static void sendAlert(Context context, String title, String text, int id) {
        createChannels(context);

        try {
            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager == null) return;

            Notification.Builder builder;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder = new Notification.Builder(context, CHANNEL_ALERT_ID);
            } else {
                builder = new Notification.Builder(context);
                builder.setPriority(Notification.PRIORITY_DEFAULT);
            }

            builder.setContentTitle(title != null ? title : "YouMadBro Alert")
                   .setContentText(text != null ? text : "")
                   .setSmallIcon(getAppIcon(context))
                   .setOnlyAlertOnce(true)
                   .setAutoCancel(true);

            PendingIntent pi = getLaunchIntent(context);
            if (pi != null) {
                builder.setContentIntent(pi);
            }

            manager.notify(id > 0 ? id : 2001, builder.build());
        } catch (Exception e) {
            Log.e(TAG, "Error sending alert notification", e);
        }
    }

    public static void cancelNotification(Context context, int id) {
        try {
            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager != null) {
                manager.cancel(id);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error cancelling notification", e);
        }
    }
}
