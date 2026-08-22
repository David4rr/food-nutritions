package com.example.food_nutritions

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.food_nutritions.ocr/recognize"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "recognizeText") {
                val imagePath = call.argument<String>("imagePath")
                if (imagePath == null) {
                    result.error("INVALID_ARGUMENT", "imagePath required", null)
                    return@setMethodCallHandler
                }

                try {
                    val file = File(imagePath)
                    if (!file.exists()) {
                        result.success("")
                        return@setMethodCallHandler
                    }

                    val inputImage = InputImage.fromFilePath(this, Uri.fromFile(file))
                    val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

                    recognizer.process(inputImage)
                        .addOnSuccessListener { visionText ->
                            result.success(visionText.text ?: "")
                        }
                        .addOnFailureListener {
                            result.success("")
                        }
                } catch (e: Throwable) {
                    result.success("")
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
