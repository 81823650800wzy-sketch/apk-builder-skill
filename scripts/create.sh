#!/bin/bash
# APK Builder - 创建原生 Android 项目
# 用法: create.sh <AppName> <PackageName>
# 示例: create.sh FlashVibe com.example.flashvibe

set -e

APP_NAME="$1"
PKG="$2"

if [ -z "$APP_NAME" ]; then
    echo "用法: create.sh <AppName> <PackageName>"
    exit 1
fi

if [ -z "$PKG" ]; then
    PKG="com.example.$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')"
fi

PROJECT_DIR="./$APP_NAME"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_DIR="$SKILL_DIR/templates/native"

echo "[1/5] 创建项目: $APP_NAME ($PKG)"

# 复制模板
cp -r "$TEMPLATE_DIR" "$PROJECT_DIR"

# 包名转路径
PKG_PATH=$(echo "$PKG" | tr '.' '/')

# SDK 路径 (Windows 格式)
SDK_POSIX="$HOME/AppData/Local/Android/Sdk"
# /c/xxx -> C:\xxx
DRIVE="${SDK_POSIX:1:1}"
DRIVE="${DRIVE^^}"
REST="${SDK_POSIX:3}"
REST="${REST//\//\\\\}"
SDK_WIN="${DRIVE}:\\\\${REST}"

# 创建目录
mkdir -p "$PROJECT_DIR/app/src/main/java/$PKG_PATH/updater"
mkdir -p "$PROJECT_DIR/app/src/main/java/$PKG_PATH/sync"
mkdir -p "$PROJECT_DIR/app/src/main/res/layout"
mkdir -p "$PROJECT_DIR/app/src/main/res/values"
mkdir -p "$PROJECT_DIR/app/src/main/res/drawable"
mkdir -p "$PROJECT_DIR/app/src/main/res/xml"
mkdir -p "$PROJECT_DIR/app/src/main/assets"

echo "[2/5] 生成构建配置"

# settings.gradle
cat > "$PROJECT_DIR/settings.gradle" << GREOF
rootProject.name = '$APP_NAME'
include ':app'
GREOF

# build.gradle (project)
cat > "$PROJECT_DIR/build.gradle" << 'GREOF'
buildscript {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/central' }
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.13.0'
    }
}
allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/central' }
        google()
        mavenCentral()
    }
}
GREOF

# app/build.gradle
cat > "$PROJECT_DIR/app/build.gradle" << GREOF
plugins {
    id 'com.android.application'
}
android {
    namespace '$PKG'
    compileSdk 36
    buildToolsVersion "37.0.0"
    defaultConfig {
        applicationId "$PKG"
        minSdk 24
        targetSdk 36
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.7.1'
    implementation 'com.google.android.material:material:1.14.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.2.1'
}
GREOF

# local.properties
echo "sdk.dir=$SDK_WIN" > "$PROJECT_DIR/local.properties"

# gradle.properties
cat > "$PROJECT_DIR/gradle.properties" << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.suppressUnsupportedCompileSdk=36
EOF

# proguard
touch "$PROJECT_DIR/app/proguard-rules.pro"

echo "[3/5] 生成源代码"

# AndroidManifest.xml (基础权限，根据需求追加)
cat > "$PROJECT_DIR/app/src/main/AndroidManifest.xml" << MFEOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.FLASHLIGHT" />
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.flash" android:required="false" />
    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="\${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
</manifest>
MFEOF

# FileProvider paths
cat > "$PROJECT_DIR/app/src/main/res/xml/file_paths.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <files-path name="downloads" path="downloads/" />
    <files-path name="synced" path="synced_resources/" />
    <external-files-path name="external_downloads" path="downloads/" />
</paths>
EOF

# strings.xml
cat > "$PROJECT_DIR/app/src/main/res/values/strings.xml" << STREOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
STREOF

# styles.xml (AppCompat 主题，兼容性最好)
cat > "$PROJECT_DIR/app/src/main/res/values/styles.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.NoActionBar">
        <item name="colorPrimary">#667eea</item>
        <item name="colorPrimaryDark">#1a1a2e</item>
        <item name="colorAccent">#f093fb</item>
        <item name="android:windowBackground">#1a1a2e</item>
        <item name="android:statusBarColor">#0f0c29</item>
        <item name="android:navigationBarColor">#0f0c29</item>
    </style>
</resources>
EOF

# 默认布局 (ScrollView > LinearLayout，所有按钮显式 textColor)
cat > "$PROJECT_DIR/app/src/main/res/layout/activity_main.xml" << LAYEOF
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:fillViewport="true"
    android:background="#1a1a2e">
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:padding="20dp">
        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="$APP_NAME"
            android:textSize="28sp"
            android:textColor="#FFFFFF"
            android:textStyle="bold"
            android:gravity="center"
            android:layout_marginTop="20dp" />
        <TextView
            android:id="@+id/tvStatus"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="就绪"
            android:textSize="14sp"
            android:textColor="#64ffda"
            android:gravity="center"
            android:padding="16dp"
            android:layout_marginTop="30dp" />
    </LinearLayout>
</ScrollView>
LAYEOF

# 默认 MainActivity.java
cat > "$PROJECT_DIR/app/src/main/java/$PKG_PATH/MainActivity.java" << JAVAEOF
package $PKG;

import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        // TODO: 在这里添加功能代码
    }
}
JAVAEOF

echo "[4/5] 生成 gradlew"

# gradlew
cat > "$PROJECT_DIR/gradlew" << 'GWEOF'
#!/bin/bash
if [ -z "$JAVA_HOME" ]; then
    [ -d "/d/Android_studio/jbr" ] && export JAVA_HOME="/d/Android_studio/jbr"
fi
if echo "$JAVA_HOME" | grep -q "^[A-Za-z]:"; then
    JAVA_HOME=$(echo "$JAVA_HOME" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/\L\1|')
    export JAVA_HOME
fi
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/AppData/Local/Android/Sdk}"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
exec java $JAVA_OPTS -classpath "$DIR/gradle/wrapper/gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain "$@"
GWEOF
chmod +x "$PROJECT_DIR/gradlew"

echo "[5/5] 完成"
echo ""
echo "项目路径: $PROJECT_DIR"
echo "下一步:"
echo "  1. 编辑 app/src/main/res/layout/activity_main.xml 添加 UI"
echo "  2. 编辑 app/src/main/java/$PKG_PATH/MainActivity.java 添加逻辑"
echo "  3. bash ~/.claude/skills/apk-builder/scripts/build.sh $PROJECT_DIR"
