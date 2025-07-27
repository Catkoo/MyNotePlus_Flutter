import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔔 Inisialisasi notifikasi lokal (panggil sekali di main.dart)
Future<void> initializeNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(
    android: androidSettings,
  );

  // ✅ Inisialisasi plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) async {
      final payload = response.payload;
      if (payload != null) {
        final parts = payload.split('|');
        if (parts.length >= 2) {
          final title = parts[0];
          final body = parts[1];

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('notifications')
                .add({
                  'title': title,
                  'message': body,
                  'timestamp': Timestamp.now(),
                  'isRead': false,
                  'isLocal': true,
                });
          }
        }
      }
    },
  );

  // ✅ Buat channel notifikasi Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'film_reminder_channel', // ID
    'Film Reminder', // Nama channel
    description: 'Notifikasi episode berikutnya film/drama',
    importance: Importance.max,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await androidPlugin?.createNotificationChannel(channel);

  // ✅ Minta izin notifikasi (Android 13+)
  await androidPlugin?.requestNotificationsPermission();
}

/// 🕓 Jadwalkan notifikasi lokal berdasarkan tanggal
Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  if (scheduledDate.isBefore(DateTime.now())) return;

  final location = tz.getLocation('Asia/Jakarta');
  final scheduleTZ = tz.TZDateTime.from(scheduledDate, location);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    scheduleTZ,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'film_reminder_channel',
        'Film Reminder',
        channelDescription: 'Notifikasi episode berikutnya film/drama',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

    matchDateTimeComponents: DateTimeComponents.dateAndTime,
    payload: '$title|$body',
  );

  // 🔔 Simpan juga ke Firestore agar muncul di NotificationScreen
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({
          'title': title,
          'message': body,
          'timestamp': Timestamp.fromDate(scheduledDate),
          'isRead': false,
          'isLocal': true,
        });
  }

  debugPrint("✅ Notifikasi dijadwalkan pada $scheduledDate");
}

/// ❌ Batalkan notifikasi berdasarkan ID
Future<void> cancelNotification(int id) async {
  await flutterLocalNotificationsPlugin.cancel(id);
}

/// ❌ Alias pembatalan notifikasi
Future<void> cancelNotificationById(int id) async {
  await cancelNotification(id);
}
