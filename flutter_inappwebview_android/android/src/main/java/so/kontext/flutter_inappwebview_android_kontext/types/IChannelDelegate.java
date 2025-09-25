package so.kontext.flutter_inappwebview_android_kontext.types;

import androidx.annotation.Nullable;

import io.flutter.plugin.common.MethodChannel;

public interface IChannelDelegate extends MethodChannel.MethodCallHandler, Disposable {
  @Nullable
  MethodChannel getChannel();
}
