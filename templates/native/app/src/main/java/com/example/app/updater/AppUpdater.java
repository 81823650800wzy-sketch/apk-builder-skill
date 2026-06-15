package com.example.app.updater;

import android.app.Activity;
import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Environment;
import android.util.Log;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class AppUpdater {
    private static final String TAG = "AppUpdater";
    private static final String UPDATE_CHECK_URL = "https://example.com/update.json";

    public static void checkForUpdates(Activity activity) {
        new Thread(() -> {
            try {
                int cur = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).versionCode;
                String json = httpGet(UPDATE_CHECK_URL);
                if (json == null) return;
                int remote = parseInt(extract(json, "versionCode"));
                String apkUrl = extract(json, "apkUrl");
                String log = extract(json, "changelog");
                String ver = extract(json, "versionName");
                if (remote > cur && apkUrl != null) {
                    String vn = ver != null ? ver : String.valueOf(remote);
                    activity.runOnUiThread(() -> {
                        try {
                            new android.app.AlertDialog.Builder(activity)
                                .setTitle("发现新版本 v" + vn)
                                .setMessage(log != null ? log : "有新版本可用")
                                .setPositiveButton("更新", (d, w) -> download(activity, apkUrl))
                                .setNegativeButton("稍后", null).show();
                        } catch (Exception e) {}
                    });
                }
            } catch (Exception e) {}
        }).start();
    }

    private static void download(Context ctx, String url) {
        try {
            DownloadManager dm = (DownloadManager) ctx.getSystemService(Context.DOWNLOAD_SERVICE);
            DownloadManager.Request req = new DownloadManager.Request(Uri.parse(url));
            req.setTitle("下载更新...");
            req.setDestinationInExternalFilesDir(ctx, Environment.DIRECTORY_DOWNLOADS, "update.apk");
            req.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
            long id = dm.enqueue(req);
            BroadcastReceiver done = new BroadcastReceiver() {
                public void onReceive(Context c, Intent i) {
                    if (i.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1) == id) {
                        try { c.unregisterReceiver(this); } catch (Exception e) {}
                        try {
                            Intent inst = new Intent(Intent.ACTION_VIEW);
                            inst.setDataAndType(dm.getUriForDownloadedFile(id), "application/vnd.android.package-archive");
                            inst.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
                            c.startActivity(inst);
                        } catch (Exception e) {}
                    }
                }
            };
            ctx.registerReceiver(done, new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE), Context.RECEIVER_NOT_EXPORTED);
        } catch (Exception e) {}
    }

    private static String httpGet(String u) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(u).openConnection();
        c.setConnectTimeout(5000); c.setReadTimeout(5000);
        if (c.getResponseCode() != 200) return null;
        BufferedReader r = new BufferedReader(new InputStreamReader(c.getInputStream()));
        StringBuilder s = new StringBuilder(); String l;
        while ((l = r.readLine()) != null) s.append(l);
        r.close(); return s.toString();
    }

    private static String extract(String j, String k) {
        int i = j.indexOf("\"" + k + "\"");
        if (i < 0) return null;
        i = j.indexOf(":", i); if (i < 0) return null;
        i++; while (i < j.length() && j.charAt(i) == ' ') i++;
        if (i >= j.length()) return null;
        if (j.charAt(i) == '"') { int e = j.indexOf("\"", i + 1); return e > i ? j.substring(i + 1, e) : null; }
        int e = i; while (e < j.length() && (Character.isDigit(j.charAt(e)) || j.charAt(e) == '.')) e++;
        return e > i ? j.substring(i, e) : null;
    }

    private static int parseInt(String s) { try { return Integer.parseInt(s); } catch (Exception e) { return 0; } }
}
