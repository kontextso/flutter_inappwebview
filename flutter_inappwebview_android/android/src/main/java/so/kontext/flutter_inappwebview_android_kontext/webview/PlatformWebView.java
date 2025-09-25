package so.kontext.flutter_inappwebview_android_kontext.webview;

import java.util.HashMap;

import io.flutter.plugin.platform.PlatformView;

public interface PlatformWebView extends PlatformView {
  void makeInitialLoad(HashMap<String, Object> params);
}
