import Flutter
import UIKit
import XCTest

@testable import flutter_inappwebview_ios_kontext

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testPluginInstantiation() {
    let plugin = InAppWebViewFlutterKontextPlugin()
    XCTAssertNotNil(plugin)
  }

}
