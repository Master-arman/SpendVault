package com.antigravity.finance.finance_app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

    /**
     * Phase 52: Android Recent-Task Privacy Window Shield
     *
     * FLAG_SECURE prevents the OS task switcher (and any screen-recording tool)
     * from capturing the window content. This protects sensitive financial data
     * from appearing in the Android recent-apps thumbnail.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
