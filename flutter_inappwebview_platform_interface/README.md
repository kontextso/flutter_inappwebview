# flutter_inappwebview_platform_interface_kontext

A Kontext-maintained fork of the [`flutter_inappwebview_platform_interface`](https://pub.dev/packages/flutter_inappwebview_platform_interface)
package that preserves the same APIs under a new, non-conflicting import path.

# Usage

To implement a new platform-specific implementation of `flutter_inappwebview`, extend
[`InAppWebViewPlatform`](lib/src/inappwebview_platform.dart) with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`InAppWebViewPlatform` by calling
`InAppWebViewPlatform.instance = MyPlatformWebview()`.

Import this package with:

```dart
import 'package:flutter_inappwebview_platform_interface_kontext/flutter_inappwebview_platform_interface.dart';
```

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.