import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'voice_service.dart'; 

class BackgroundServiceManager {

  @pragma('vm:entry-point')
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: "emergency_channel", 
        initialNotificationTitle: "ZeroTouch Rescue Active",
        initialNotificationContent: "Monitoring for your safety...",
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true, 
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
   
    await service.startService();
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    final VoiceService voiceService = VoiceService();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
      
      service.on('stopService').listen((event) {
        service.stopSelf();
      });
    }

    debugPrint("Background Voice Service Started... 🎤");

    
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (!(await service.isForegroundService())) {
         
        }
      }
      if (!voiceService.isListening) {
        voiceService.startListening((alertData) {
          if (alertData["isDanger"] == true) {
            service.invoke("emergencyDetected", alertData);
            
            if (service is AndroidServiceInstance) {
              service.setForegroundNotificationInfo(
                title: "🚨 EMERGENCY DETECTED!",
                content: "Alert Type: ${alertData['type']}",
              );
            }
          }
        });
      }
    });
  }
}