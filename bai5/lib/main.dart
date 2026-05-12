import 'package:flutter/material.dart';
import 'contacts_list_screen.dart'; // Import màn hình danh sách danh bạ

void main() {
  runApp(const ContactsApp());
}

class ContactsApp extends StatelessWidget {
  const ContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý danh bạ',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Đặt ContactsListScreen làm màn hình khởi chạy đầu tiên
      home: const ContactsListScreen(), 
    );
  }
}