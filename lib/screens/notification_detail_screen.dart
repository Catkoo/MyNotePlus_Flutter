import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notification; // Data notifikasi yang diklik

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  
  @override
  void initState() {
    super.initState();
    _markAsRead(); // Otomatis tandai dibaca saat layar dibuka
  }

  void _markAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final notifId = widget.notification['id']; // Pastikan notifikasi punya ID unik

    if (userId != null && notifId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notifId)
          .update({'isRead': true});
          
      print("Notifikasi berhasil ditandai sebagai dibaca!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Detail Notifikasi"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon atau Label Kategori
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.notification['category'] ?? "Umum",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Judul Notifikasi
            Text(
              widget.notification['title'] ?? "Tidak ada judul",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            
            // Tanggal
            Text(
              "Diterima pada: ${widget.notification['timestamp']?.toDate().toString().split('.')[0]}",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            
            const Divider(height: 40),
            
            // Isi Pesan
            Text(
              widget.notification['message'] ?? "Isi pesan kosong",
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}