package com.app.verithrive

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /// Reuse the same activity when an App Link / deep link is tapped while
    /// the app is already running (prevents a second task in Recents).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
