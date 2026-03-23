import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

    Future<void> _markAsRead() async {
      if (uid == null) return;

      final announcements = await FirebaseFirestore.instance
          .collection('announcements')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in announcements.docs) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('readAnnouncements')
            .doc(doc.id);

        batch.set(ref, {
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Semua notifikasi ditandai dibaca")),
        );
      }
    }

    Stream<List<Map<String, dynamic>>> _getCombinedNotifications() {
      var globalStream = FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .snapshots();

      var personalStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots();

      var readStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('readAnnouncements')
          .snapshots();

      return Rx.combineLatest3(
        globalStream,
        personalStream,
        readStream,
        (QuerySnapshot globalSnap, QuerySnapshot personalSnap, QuerySnapshot readSnap) {
          List<Map<String, dynamic>> combined = [];

          final readIds = readSnap.docs.map((e) => e.id).toSet();

          // GLOBAL
          for (var doc in globalSnap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            combined.add({
              ...data,
              'id': doc.id,
              'isGlobal': true,
              'isRead': readIds.contains(doc.id),
            });
          }

          // PERSONAL
          for (var doc in personalSnap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            combined.add({
              ...data,
              'id': doc.id,
              'isGlobal': false,
              'isRead': data['isRead'] ?? false,
            });
          }

          combined.sort((a, b) {
            Timestamp t1 = a['timestamp'] ?? Timestamp.now();
            Timestamp t2 = b['timestamp'] ?? Timestamp.now();
            return t2.compareTo(t1);
          });

          return combined;
        },
      );
    }

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const Scaffold(body: Center(child: Text("Silakan login.")));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Notifikasi", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.indigo),
            onPressed: _markAsRead,
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getCombinedNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              final bool isGlobal = item['isGlobal'] ?? false;
              final bool isRead = item['isRead'] ?? true;

              return Container(
                // Perbaikan EdgeInsets: Pakai .only(bottom: 12)
                margin: const EdgeInsets.only(bottom: 12), 
                decoration: BoxDecoration(
                  // Perbaikan withOpacity ke withValues (Modern Flutter)
                  color: isRead ? Colors.white : Colors.indigo.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isRead ? Colors.transparent : Colors.indigo.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: isGlobal ? Colors.orange[100] : Colors.indigo[100],
                        child: Icon(
                          isGlobal ? Icons.campaign_rounded : Icons.notifications_active_rounded,
                          color: isGlobal ? Colors.orange[800] : Colors.indigo[800],
                        ),
                      ),
                      if (!isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    item['title'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['message'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['timestamp'] != null
                              ? DateFormat('dd MMM, HH:mm').format(item['timestamp'].toDate())
                              : '',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  trailing: isGlobal
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("INFO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                          onPressed: () => _deleteNotification(item['id']),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteNotification(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .delete();
  }
}