package com.example.offline_menu_translator

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity: FlutterActivity() {
    // ...existing code...

    private fun initModel() {
        // Change logic to check for model file existence first
        val modelPath = File(filesDir, "gemma-2b-it-cpu-int4.bin")
        if (!modelPath.exists()) {
            println("Gemma model is not installed yet. Use the model manager to load model first")
            return
        }

        try {
            // ...existing code...
        } catch (e: Exception) {
            println("Failed to Initialize AI model: ${e.message}")
        }
    }
}
