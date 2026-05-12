import 'package:flutter/material.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _avatar;

  // Chọn ảnh từ Gallery hoặc Camera
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
      });
    }
  }

  // Yêu cầu quyền truy cập danh bạ
  Future<bool> _requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // Lưu thông tin danh bạ
  Future<void> _saveContact() async {
    // Kiểm tra nếu tên hoặc số điện thoại bị bỏ trống
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên và số điện thoại không được để trống!'),
        ),
      );
      return;
    }

    // Yêu cầu quyền truy cập danh bạ
    final hasPermission = await _requestContactsPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ứng dụng cần quyền truy cập danh bạ!'),
        ),
      );
      return;
    }

    // Tạo danh sách email chỉ nếu email không trống
    List<ValueItem> emails = [];
    if (_emailController.text.isNotEmpty) {
      emails.add(ValueItem(label: 'email', value: _emailController.text));
    }

    // Tạo đối tượng ContactInfo
    final contact = ContactInfo(
      displayName: _nameController.text,
      phones: [ValueItem(label: 'mobile', value: _phoneController.text)],
      emails: emails,
      avatar: _avatar != null ? await _avatar!.readAsBytes() : null,
    );

    // Lưu danh bạ vào điện thoại
    try {
      await FlutterContactsService.addContact(contact);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Danh bạ đã được lưu thành công!')),
      );
      Navigator.pop(context); // Quay lại màn hình trước
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu danh bạ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm danh bạ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                child: _avatar == null
                    ? const Icon(Icons.camera_alt, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _saveContact, child: const Text('Lưu')),
          ],
        ),
      ),
    );
  }
}