package com.pichillilorenzo.flutter_inappwebview_android.webview;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.pichillilorenzo.flutter_inappwebview_android.webview.in_app_webview.InAppWebView;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public final class WebViewInstanceRegistry {
  private static final Map<String, WeakReference<InAppWebView>> REGISTRY = new ConcurrentHashMap<>();

  private WebViewInstanceRegistry() {
  }

  public static void register(@NonNull String instanceId, @NonNull InAppWebView webView) {
    removeStaleReferencesFor(webView);
    REGISTRY.put(instanceId, new WeakReference<>(webView));
  }

  public static void unregister(@Nullable String instanceId, @Nullable InAppWebView webView) {
    if (instanceId == null) {
      return;
    }
    WeakReference<InAppWebView> reference = REGISTRY.get(instanceId);
    InAppWebView registered = reference != null ? reference.get() : null;
    if (registered == null || registered == webView) {
      REGISTRY.remove(instanceId);
    }
  }

  public static void unregister(@NonNull InAppWebView webView) {
    removeStaleReferencesFor(webView);
  }

  @Nullable
  public static InAppWebView get(@NonNull String instanceId) {
    WeakReference<InAppWebView> reference = REGISTRY.get(instanceId);
    InAppWebView webView = reference != null ? reference.get() : null;
    if (webView == null && reference != null) {
      REGISTRY.remove(instanceId);
    }
    return webView;
  }

  @NonNull
  public static List<String> getRegisteredInstanceIds() {
    cleanUp();
    return new ArrayList<>(REGISTRY.keySet());
  }

  public static boolean isRegistered(@NonNull String instanceId) {
    return get(instanceId) != null;
  }

  public static void clear() {
    REGISTRY.clear();
  }

  private static void cleanUp() {
    List<String> keysToRemove = new ArrayList<>();
    for (Map.Entry<String, WeakReference<InAppWebView>> entry : REGISTRY.entrySet()) {
      if (entry.getValue().get() == null) {
        keysToRemove.add(entry.getKey());
      }
    }
    for (String key : keysToRemove) {
      REGISTRY.remove(key);
    }
  }

  private static void removeStaleReferencesFor(@NonNull InAppWebView webView) {
    List<String> keysToRemove = new ArrayList<>();
    for (Map.Entry<String, WeakReference<InAppWebView>> entry : REGISTRY.entrySet()) {
      InAppWebView registered = entry.getValue().get();
      if (registered == null || registered == webView) {
        keysToRemove.add(entry.getKey());
      }
    }
    for (String key : keysToRemove) {
      REGISTRY.remove(key);
    }
  }
}
