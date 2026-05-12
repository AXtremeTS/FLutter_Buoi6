import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const SmsAnalyzerApp());
}

class SmsAnalyzerApp extends StatelessWidget {
  const SmsAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Analyzer',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const SmsAnalyzerHome(),
    );
  }
}

class SmsAnalyzerHome extends StatefulWidget {
  const SmsAnalyzerHome({super.key});

  @override
  State<SmsAnalyzerHome> createState() => _SmsAnalyzerHomeState();
}

class _SmsAnalyzerHomeState extends State<SmsAnalyzerHome> {
  final Telephony telephony = Telephony.instance;
  
  List<SmsMessage> _allMessages = [];
  List<SmsMessage> _filteredMessages = [];
  
  bool _isLoading = true;
  String _filterType = 'Tất cả'; // Phân loại: Tất cả, Quảng cáo, OTP
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  // 1. Xin quyền truy cập SMS
  Future<void> _initializePermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.sms, Permission.phone].request();

    if (statuses[Permission.sms]!.isGranted) {
      _loadMessages();
    } else {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng cấp quyền SMS!')),
      );
    }
  }

  // 2. Lấy tất cả tin nhắn
  Future<void> _loadMessages() async {
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    setState(() {
      _allMessages = messages;
      _filteredMessages = messages;
      _isLoading = false;
    });
  }

  // 3. Hàm xử lý Lọc tin nhắn
  void _applyFilters() {
    List<SmsMessage> temp = _allMessages;

    // Lọc theo số điện thoại
    if (_phoneController.text.isNotEmpty) {
      temp = temp.where((m) => m.address?.contains(_phoneController.text) ?? false).toList();
    }

    // Lọc theo nhóm (Quảng cáo có [QC], OTP có [OTP])
    if (_filterType == 'Quảng cáo [QC]') {
      temp = temp.where((m) => m.body?.startsWith('[QC]') ?? false).toList();
    } else if (_filterType == 'Mã OTP') {
      temp = temp.where((m) => m.body?.contains('[OTP]') ?? false).toList();
    }

    setState(() {
      _filteredMessages = temp;
    });
  }

  // 4. Trích xuất chuỗi 6 ký số OTP
  void _extractAndShowOTP(String? body) {
    if (body == null) return;
    
    // Tìm chuỗi [OTP] và theo sau là 6 số liên tiếp bằng Regex
    RegExp regExp = RegExp(r'\[OTP\]\s*.*?(\d{6})');
    var match = regExp.firstMatch(body);
    
    String extractedCode = match != null ? match.group(1)! : "Không tìm thấy 6 ký số hợp lệ!";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mã OTP trích xuất được'),
        content: Text(
          extractedCode, 
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 5),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  // Tiện ích chuyển đổi Timestamp thành Ngày/Tháng
  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'Không rõ thời gian';
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Analyzer')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Thống kê tổng quan
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.teal.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng SMS: ${_allMessages.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Đang hiển thị: ${_filteredMessages.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Công cụ Lọc
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Lọc theo số điện thoại cụ thể...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _applyFilters,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => _applyFilters(),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Lọc theo nhóm tin nhắn'),
                    items: ['Tất cả', 'Quảng cáo [QC]', 'Mã OTP']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filterType = value!;
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Danh sách tin nhắn
                  Expanded(
                    child: _filteredMessages.isEmpty
                        ? const Center(child: Text('Không có tin nhắn nào khớp với bộ lọc.'))
                        : ListView.builder(
                            itemCount: _filteredMessages.length,
                            itemBuilder: (context, index) {
                              SmsMessage message = _filteredMessages[index];
                              bool isOTP = message.body?.contains('[OTP]') ?? false;

                              return Card(
                                child: ListTile(
                                  title: Text(message.address ?? 'Không rõ số'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(message.body ?? 'Không có nội dung'),
                                      Text(
                                        'Ngày: ${_formatDate(message.date)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: isOTP 
                                    ? ElevatedButton(
                                        onPressed: () => _extractAndShowOTP(message.body),
                                        child: const Text('Lấy mã'),
                                      )
                                    : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}