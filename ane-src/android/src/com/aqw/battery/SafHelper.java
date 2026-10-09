package com.aqw.battery;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.OpenableColumns;
import android.util.Log;

import com.adobe.air.AndroidActivityWrapper;
import com.adobe.air.AndroidActivityWrapper.ActivityResultCallback;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class SafHelper implements ActivityResultCallback {
    private static final String TAG = "BatteryANE_SAF";

    public static final int REQUEST_CODE_OPEN = 8101;
    public static final int REQUEST_CODE_SAVE = 8102;

    public static String lastLoadedFileName = "";
    public static String lastLoadedContent = "";
    public static String pendingSaveFileName = "bot_script.json";
    public static String pendingSaveContent = "{}";

    private BatteryContext context;

    public SafHelper(BatteryContext context) {
        this.context = context;
    }

    public static boolean openFilePicker(BatteryContext ctx, String mimeType) {
        try {
            Activity activity = ctx.getActivity();
            if (activity == null) {
                Log.e(TAG, "Activity is null in openFilePicker");
                return false;
            }

            SafHelper callback = new SafHelper(ctx);
            AndroidActivityWrapper.GetAndroidActivityWrapper().addActivityResultListener(callback);

            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("*/*");

            String[] mimes = new String[]{
                "application/json",
                "text/plain",
                "application/octet-stream",
                "*/*"
            };
            intent.putExtra(Intent.EXTRA_MIME_TYPES, mimes);

            activity.startActivityForResult(intent, REQUEST_CODE_OPEN);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Error starting openFilePicker intent", e);
            return false;
        }
    }

    public static boolean saveFilePicker(BatteryContext ctx, String fileName, String content) {
        try {
            Activity activity = ctx.getActivity();
            if (activity == null) {
                Log.e(TAG, "Activity is null in saveFilePicker");
                return false;
            }

            pendingSaveFileName = (fileName != null && !fileName.isEmpty()) ? fileName : "my_bot.json";
            if (!pendingSaveFileName.toLowerCase().endsWith(".json")) {
                pendingSaveFileName += ".json";
            }
            pendingSaveContent = (content != null) ? content : "{}";

            SafHelper callback = new SafHelper(ctx);
            AndroidActivityWrapper.GetAndroidActivityWrapper().addActivityResultListener(callback);

            Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("application/json");
            intent.putExtra(Intent.EXTRA_TITLE, pendingSaveFileName);

            activity.startActivityForResult(intent, REQUEST_CODE_SAVE);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Error starting saveFilePicker intent", e);
            return false;
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        try {
            AndroidActivityWrapper.GetAndroidActivityWrapper().removeActivityResultListener(this);
        } catch (Exception ignored) {}

        if (requestCode == REQUEST_CODE_OPEN) {
            handleOpenResult(resultCode, data);
        } else if (requestCode == REQUEST_CODE_SAVE) {
            handleSaveResult(resultCode, data);
        }
    }

    private void handleOpenResult(int resultCode, Intent data) {
        if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
            Log.i(TAG, "SAF Open file cancelled or null data");
            if (context != null) {
                context.dispatchStatusEventAsync("SAF_OPEN_CANCELLED", "");
            }
            return;
        }

        Uri uri = data.getData();
        Activity activity = (context != null) ? context.getActivity() : null;
        if (activity == null) return;

        try {
            // 1. Resolve display name
            String fileName = "imported_bot.json";
            Cursor cursor = null;
            try {
                cursor = activity.getContentResolver().query(uri, null, null, null, null);
                if (cursor != null && cursor.moveToFirst()) {
                    int nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                    if (nameIndex >= 0) {
                        String n = cursor.getString(nameIndex);
                        if (n != null && !n.trim().isEmpty()) {
                            fileName = n.trim();
                        }
                    }
                }
            } catch (Exception eCursor) {
                Log.w(TAG, "Failed resolving filename: " + eCursor.getMessage());
            } finally {
                if (cursor != null) {
                    try { cursor.close(); } catch (Exception ignored) {}
                }
            }

            // 2. Read full content
            InputStream is = activity.getContentResolver().openInputStream(uri);
            if (is == null) {
                if (context != null) context.dispatchStatusEventAsync("SAF_OPEN_ERROR", "Could not open stream");
                return;
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int read;
            while ((read = is.read(buf)) != -1) {
                baos.write(buf, 0, read);
            }
            is.close();

            byte[] bytes = baos.toByteArray();
            lastLoadedFileName = fileName;
            lastLoadedContent = new String(bytes, StandardCharsets.UTF_8);

            // 3. Mirror into local Documents/YouMadBro/Bots/ directory if possible
            try {
                File botsDir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "YouMadBro/Bots");
                if (!botsDir.exists()) {
                    botsDir.mkdirs();
                }
                if (botsDir.exists() && botsDir.canWrite()) {
                    File localFile = new File(botsDir, fileName);
                    FileOutputStream fos = new FileOutputStream(localFile);
                    fos.write(bytes);
                    fos.flush();
                    fos.close();
                    Log.i(TAG, "Mirrored SAF imported file to: " + localFile.getAbsolutePath());
                }
            } catch (Exception eMirror) {
                Log.w(TAG, "Could not mirror to local dir: " + eMirror.getMessage());
            }

            Log.i(TAG, "SAF Open file success: " + fileName + " (" + bytes.length + " bytes)");
            if (context != null) {
                context.dispatchStatusEventAsync("SAF_OPEN_SUCCESS", fileName);
            }

        } catch (Exception e) {
            Log.e(TAG, "Error reading SAF stream", e);
            if (context != null) {
                context.dispatchStatusEventAsync("SAF_OPEN_ERROR", e.getMessage() != null ? e.getMessage() : "Unknown read error");
            }
        }
    }

    private void handleSaveResult(int resultCode, Intent data) {
        if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
            Log.i(TAG, "SAF Save file cancelled");
            if (context != null) {
                context.dispatchStatusEventAsync("SAF_SAVE_CANCELLED", "");
            }
            return;
        }

        Uri uri = data.getData();
        Activity activity = (context != null) ? context.getActivity() : null;
        if (activity == null) return;

        try {
            OutputStream os = activity.getContentResolver().openOutputStream(uri);
            if (os == null) {
                if (context != null) context.dispatchStatusEventAsync("SAF_SAVE_ERROR", "Could not open output stream");
                return;
            }

            byte[] bytes = pendingSaveContent.getBytes(StandardCharsets.UTF_8);
            os.write(bytes);
            os.flush();
            os.close();

            Log.i(TAG, "SAF Save file success: " + pendingSaveFileName + " (" + bytes.length + " bytes)");
            if (context != null) {
                context.dispatchStatusEventAsync("SAF_SAVE_SUCCESS", pendingSaveFileName);
            }

        } catch (Exception e) {
            Log.e(TAG, "Error writing SAF output stream", e);
            if (context != null) {
                context.dispatchStatusEventAsync("SAF_SAVE_ERROR", e.getMessage() != null ? e.getMessage() : "Unknown write error");
            }
        }
    }
}
