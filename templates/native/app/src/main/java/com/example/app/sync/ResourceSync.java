package com.example.app.sync;

import android.content.Context;
import android.util.Log;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class ResourceSync {
    private static final String TAG = "ResourceSync";
    private static final String META_URL = "https://example.com/resources.json";
    private final Context context;
    private final File syncDir;

    public interface SyncCallback { void onSuccess(File dir); void onError(String err); }

    public ResourceSync(Context ctx) {
        this.context = ctx;
        this.syncDir = new File(ctx.getFilesDir(), "synced_resources");
        if (!syncDir.exists()) syncDir.mkdirs();
    }

    public void sync(SyncCallback cb) {
        new Thread(() -> {
            try {
                String meta = httpGet(META_URL);
                if (meta == null) { cb.onError("无法连接"); return; }
                String zipUrl = extract(meta, "zipUrl");
                if (zipUrl == null) { cb.onError("配置无效"); return; }
                File zip = new File(context.getFilesDir(), "res.zip");
                if (!download(zipUrl, zip)) { cb.onError("下载失败"); return; }
                unzip(zip, syncDir);
                zip.delete();
                cb.onSuccess(syncDir);
            } catch (Exception e) { cb.onError(e.getMessage()); }
        }).start();
    }

    public void clearCache() {
        delete(syncDir);
        syncDir.mkdirs();
    }

    private String httpGet(String u) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(u).openConnection();
        c.setConnectTimeout(5000); c.setReadTimeout(5000);
        if (c.getResponseCode() != 200) return null;
        BufferedReader r = new BufferedReader(new InputStreamReader(c.getInputStream()));
        StringBuilder s = new StringBuilder(); String l;
        while ((l = r.readLine()) != null) s.append(l);
        r.close(); return s.toString();
    }

    private boolean download(String u, File f) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(u).openConnection();
        c.setConnectTimeout(10000); c.setReadTimeout(30000);
        if (c.getResponseCode() != 200) return false;
        InputStream is = c.getInputStream();
        FileOutputStream fos = new FileOutputStream(f);
        byte[] b = new byte[8192]; int n;
        while ((n = is.read(b)) != -1) fos.write(b, 0, n);
        fos.close(); is.close(); return true;
    }

    private void unzip(File z, File d) throws Exception {
        ZipInputStream zis = new ZipInputStream(new java.io.FileInputStream(z));
        ZipEntry e;
        while ((e = zis.getNextEntry()) != null) {
            File o = new File(d, e.getName());
            if (e.isDirectory()) { o.mkdirs(); }
            else { o.getParentFile().mkdirs(); FileOutputStream f = new FileOutputStream(o); byte[] b = new byte[8192]; int n; while ((n = zis.read(b)) != -1) f.write(b, 0, n); f.close(); }
            zis.closeEntry();
        }
        zis.close();
    }

    private String extract(String j, String k) {
        int i = j.indexOf("\"" + k + "\"");
        if (i < 0) return null;
        i = j.indexOf(":", i); if (i < 0) return null;
        i++; while (i < j.length() && j.charAt(i) == ' ') i++;
        if (i >= j.length()) return null;
        if (j.charAt(i) == '"') { int e = j.indexOf("\"", i + 1); return e > i ? j.substring(i + 1, e) : null; }
        int e = i; while (e < j.length() && (Character.isDigit(j.charAt(e)) || j.charAt(e) == '.')) e++;
        return e > i ? j.substring(i, e) : null;
    }

    private void delete(File f) {
        if (f == null || !f.exists()) return;
        if (f.isDirectory()) { File[] c = f.listFiles(); if (c != null) for (File x : c) delete(x); }
        f.delete();
    }
}
