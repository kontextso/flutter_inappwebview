package com.pichillilorenzo.flutter_inappwebview_android.omid;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.iab.omid.library.megabrainco.Omid;
import com.iab.omid.library.megabrainco.adsession.AdSession;
import com.iab.omid.library.megabrainco.adsession.AdSessionConfiguration;
import com.iab.omid.library.megabrainco.adsession.AdSessionContext;
import com.iab.omid.library.megabrainco.adsession.CreativeType;
import com.iab.omid.library.megabrainco.adsession.ImpressionType;
import com.iab.omid.library.megabrainco.adsession.Owner;
import com.iab.omid.library.megabrainco.adsession.Partner;
import com.pichillilorenzo.flutter_inappwebview_android.InAppWebViewFlutterPlugin;
import com.pichillilorenzo.flutter_inappwebview_android.types.ChannelDelegateImpl;
import com.pichillilorenzo.flutter_inappwebview_android.webview.WebViewInstanceRegistry;
import com.pichillilorenzo.flutter_inappwebview_android.webview.in_app_webview.InAppWebView;

import java.lang.ref.WeakReference;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class OmidSessionManager extends ChannelDelegateImpl {
  public static final String METHOD_CHANNEL_NAME = "kontext_omid";
  private static final int WEBVIEW_HOLD_DURATION_MS = 1100;

  @NonNull
  private final InAppWebViewFlutterPlugin plugin;
  @NonNull
  private final Handler mainHandler = new Handler(Looper.getMainLooper());
  @NonNull
  private final Map<String, OmidSessionState> sessions = new ConcurrentHashMap<>();

  public OmidSessionManager(@NonNull InAppWebViewFlutterPlugin plugin) {
    super(new MethodChannel(plugin.messenger, METHOD_CHANNEL_NAME));
    this.plugin = plugin;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    switch (call.method) {
      case "startOmidSession":
        startSession(call, result);
        break;
      case "stopOmidSession":
        stopSession(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void startSession(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    final String instanceId = call.argument("instanceId");
    if (TextUtils.isEmpty(instanceId)) {
      result.error("missing_instance_id", "Expected a non-empty instanceId.", null);
      return;
    }
    if (sessions.containsKey(instanceId)) {
      result.error("duplicate_session", "An OMID session already exists for instanceId " + instanceId + ".", null);
      return;
    }

    final InAppWebView webView = WebViewInstanceRegistry.get(instanceId);
    if (webView == null) {
      result.error("webview_not_found", "No WebView found for instanceId " + instanceId + ".", null);
      return;
    }

    final String partnerName = call.argument("partnerName");
    final String partnerVersion = call.argument("partnerVersion");
    if (TextUtils.isEmpty(partnerName) || TextUtils.isEmpty(partnerVersion)) {
      result.error("invalid_partner", "partnerName and partnerVersion are required.", null);
      return;
    }

    final String contentUrl = call.argument("contentUrl");
    final String customReferenceData = call.argument("customReferenceData");

    if (contentUrl != null && contentUrl.length() > 512) {
      result.error("invalid_content_url", "contentUrl must be 512 characters or fewer.", null);
      return;
    }
    if (customReferenceData != null && customReferenceData.length() > 256) {
      result.error("invalid_custom_reference_data", "customReferenceData must be 256 characters or fewer.", null);
      return;
    }

    mainHandler.post(() -> {
      if (sessions.containsKey(instanceId)) {
        result.error("duplicate_session", "An OMID session already exists for instanceId " + instanceId + ".", null);
        return;
      }
      if (!ensureOmidActivated(result)) {
        return;
      }
      try {
        Partner partner = Partner.createPartner(partnerName, partnerVersion);
        AdSessionContext context = AdSessionContext.createHtmlAdSessionContext(
                partner,
                webView,
                contentUrl,
                customReferenceData
        );
        AdSessionConfiguration configuration = AdSessionConfiguration.createAdSessionConfiguration(
                CreativeType.HTML_DISPLAY,
                ImpressionType.BEGIN_TO_RENDER,
                Owner.JAVASCRIPT,
                Owner.NONE,
                false
        );
        AdSession adSession = AdSession.createAdSession(configuration, context);
        adSession.registerAdView(webView);
        adSession.start();

        sessions.put(instanceId, new OmidSessionState(webView, adSession));
        result.success(true);
      } catch (Exception e) {
        result.error("session_start_failed", "Failed to start OMID session: " + e.getMessage(), null);
        return;
      }
    });
  }

  private void stopSession(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    final String instanceId = call.argument("instanceId");
    if (TextUtils.isEmpty(instanceId)) {
      result.error("missing_instance_id", "Expected a non-empty instanceId.", null);
      return;
    }
    mainHandler.post(() -> {
      if (!Omid.isActive()) {
        result.error("omid_inactive", "OM SDK is not active.", null);
        return;
      }
      OmidSessionState sessionState = sessions.remove(instanceId);
      if (sessionState == null) {
        result.error("session_not_found", "No active OMID session for instanceId " + instanceId + ".", null);
        return;
      }
      try {
        sessionState.adSession.finish();
      } catch (Exception e) {
        result.error("omid_stop_failed", "Failed to finish OMID session: " + e.getMessage(), null);
        return;
      }
      InAppWebView webView = sessionState.webViewRef.get();
      if (webView != null) {
        // The 1.1 second delay (OMID guidance) gives the system time to properly clean up
        // any remaining ad-related operations before allowing the WebView to be disposed of.
        webView.postDelayed(() -> webView.hashCode(), WEBVIEW_HOLD_DURATION_MS);
      }
      result.success(true);
    });
  }

  private boolean ensureOmidActivated(@NonNull MethodChannel.Result result) {
    if (Omid.isActive()) {
      return true;
    }
    Context context = plugin.applicationContext;
    if (context == null) {
      result.error("omid_activation_failed", "Application context is unavailable for OM SDK activation.", null);
      return false;
    }
    try {
      Omid.activate(context);
      return true;
    } catch (Exception e) {
      result.error("omid_activation_failed", "Failed to activate OM SDK: " + e.getMessage(), null);
      return false;
    }
  }

  private static class OmidSessionState {
    final WeakReference<InAppWebView> webViewRef;
    final AdSession adSession;

    OmidSessionState(@NonNull InAppWebView webView, @NonNull AdSession adSession) {
      this.webViewRef = new WeakReference<>(webView);
      this.adSession = adSession;
    }
  }
}