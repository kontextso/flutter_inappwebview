package so.kontext.flutter_inappwebview_android_kontext.in_app_browser;

import androidx.annotation.NonNull;

import so.kontext.flutter_inappwebview_android_kontext.types.ChannelDelegateImpl;
import so.kontext.flutter_inappwebview_android_kontext.types.InAppBrowserMenuItem;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class InAppBrowserChannelDelegate extends ChannelDelegateImpl {
  public InAppBrowserChannelDelegate(@NonNull MethodChannel channel) {
    super(channel);
  }

  public void onBrowserCreated() {
    MethodChannel channel = getChannel();
    if (channel == null) return;
    Map<String, Object> obj = new HashMap<>();
    channel.invokeMethod("onBrowserCreated", obj);
  }

  public void onMenuItemClicked(InAppBrowserMenuItem menuItem) {
    MethodChannel channel = getChannel();
    if (channel == null) return;
    Map<String, Object> obj = new HashMap<>();
    obj.put("id", menuItem.getId());
    channel.invokeMethod("onMenuItemClicked", obj);
  }

  public void onExit() {
    MethodChannel channel = getChannel();
    if (channel == null) return;
    Map<String, Object> obj = new HashMap<>();
    channel.invokeMethod("onExit", obj);
  }
}
