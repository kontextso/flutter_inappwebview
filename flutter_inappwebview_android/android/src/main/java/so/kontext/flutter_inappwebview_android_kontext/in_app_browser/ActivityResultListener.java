package so.kontext.flutter_inappwebview_android_kontext.in_app_browser;

import android.content.Intent;

public interface ActivityResultListener {
  /** @return true if the result has been handled. */
  boolean onActivityResult(int requestCode, int resultCode, Intent data);
}
