import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }
  
  Future<void> showTrendNotification({
    required String symbol,
    required String trend,
    required String timeframe,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'trend_channel',
      'تنبيهات الاتجاه',
      channelDescription: 'تنبيهات عند تغير اتجاه العملة',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.show(
      0,
      'تحليل $symbol',
      'الاتجاه المتوقع: $trend - الإطار الزمني: $timeframe',
      platformChannelSpecifics,
    );
  }
  
  Future<void> scheduleTimeframeEndNotification({
    required String symbol,
    required String trend,
    required String timeframe,
    required DateTime endTime,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'timeframe_channel',
      'تنبيهات انتهاء الإطار الزمني',
      channelDescription: 'تنبيهات عند انتهاء الإطار الزمني المتوقع',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'انتهاء الإطار الزمني لـ $symbol',
      'انتهى الإطار الزمني المتوقع ($timeframe) للاتجاه: $trend',
      TZDateTime.from(endTime, local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}

// Helper for timezone
class TZDateTime {
  static DateTime from(DateTime time, bool local) {
    return time;
  }
}
