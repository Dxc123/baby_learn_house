package com.baby.baby_learn_house

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = DrawingShareHandler(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "baby_learn_house/drawing_share")
            .setMethodCallHandler { call, result ->
                if (call.method != "sharePng") result.notImplemented()
                else handler.share(call.arguments, result)
            }
    }
}
