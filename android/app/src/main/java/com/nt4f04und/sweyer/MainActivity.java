package com.nt4f04und.sweyer;

import android.content.Context;

import androidx.annotation.NonNull;

import com.ryanheise.audioservice.AudioServicePlugin;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
   @Override
   public FlutterEngine provideFlutterEngine(@NonNull Context context) {
      return AudioServicePlugin.getFlutterEngine(context);
   }
}
