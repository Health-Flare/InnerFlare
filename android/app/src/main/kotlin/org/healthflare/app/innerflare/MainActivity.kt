package org.healthflare.app.innerflare

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth requires a FragmentActivity host on Android to show the
// biometric prompt (see local_auth's Android setup docs).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // FLAG_SECURE (issue #91): Android shows a blank Recents thumbnail
        // instead of the last screen, and screenshots, screen recording,
        // casting and other apps' screen capture get a blank window. Set
        // before super.onCreate so the very first frame is already covered.
        //
        // Always on, in debug builds too. The store screenshots and videos
        // are captured on the iOS simulator (docs/marketing/README.md), and
        // integration_test's takeScreenshot reads Flutter's own surface
        // in-process, which FLAG_SECURE doesn't block.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }
}
