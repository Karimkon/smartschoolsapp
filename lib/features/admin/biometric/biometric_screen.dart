import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _ScanRecord {
  final String name, type, method, time, status;
  const _ScanRecord({required this.name, required this.type, required this.method, required this.time, required this.status});
}

class _Device {
  final String name, location, apiKey, lastSeen, status;
  const _Device({required this.name, required this.location, required this.apiKey, required this.lastSeen, required this.status});
}

const _mockScans = [
  _ScanRecord(name:'Amara Osei',     type:'Student', method:'RFID',         time:'08:02 AM', status:'Check In'),
  _ScanRecord(name:'Mr. Paul Ochieng',type:'Teacher', method:'Fingerprint',  time:'07:55 AM', status:'Check In'),
  _ScanRecord(name:'Brian Mwangi',   type:'Student', method:'RFID',         time:'08:05 AM', status:'Check In'),
  _ScanRecord(name:'Ms. Grace Wanjiku',type:'Teacher',method:'QR Code',     time:'08:10 AM', status:'Check In'),
  _ScanRecord(name:'Diana Kamau',    type:'Student', method:'RFID',         time:'08:18 AM', status:'Late'),
  _ScanRecord(name:'Emmanuel Ssali', type:'Student', method:'Fingerprint',  time:'03:30 PM', status:'Check Out'),
  _ScanRecord(name:'Amara Osei',     type:'Student', method:'RFID',         time:'03:35 PM', status:'Check Out'),
];

const _mockDevices = [
  _Device(name:'Main Gate Scanner',  location:'Front Gate',    apiKey:'DEV-001-XXXX', lastSeen:'2 min ago', status:'Online'),
  _Device(name:'Staff Entrance',     location:'Staff Block',   apiKey:'DEV-002-XXXX', lastSeen:'5 min ago', status:'Online'),
  _Device(name:'Library Scanner',    location:'Library',       apiKey:'DEV-003-XXXX', lastSeen:'1h ago',    status:'Offline'),
  _Device(name:'Sports Complex',     location:'Sports Ground', apiKey:'DEV-004-XXXX', lastSeen:'3 min ago', status:'Online'),
];

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});
  @override State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override void dispose() { _tabs.dispose(); super.dispose(); }

  Color _scanStatusColor(String s) => s == 'Check In' ? AppColors.success : s == 'Check Out' ? AppColors.primary : AppColors.warning;
  IconData _methodIcon(String m) {
    switch (m) {
      case 'RFID': return Icons.contactless_rounded;
      case 'Fingerprint': return Icons.fingerprint_rounded;
      case 'QR Code': return Icons.qr_code_scanner_rounded;
      default: return Icons.sensors_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Biometric & QR Attendance', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () {})],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.success,
          labelColor: AppColors.success,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Scan Log'), Tab(text: 'Devices')],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: TabBarView(controller: _tabs, children: [
          // Scan Log
          Column(children: [
            Padding(padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: _StatBox('Today Total', '247', AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: _StatBox('Check In', '198', AppColors.success)),
                const SizedBox(width: 10),
                Expanded(child: _StatBox('Check Out', '49', AppColors.accent)),
              ]).animate().fadeIn(),
            ),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16,0,16,80),
              itemCount: _mockScans.length,
              itemBuilder: (ctx, i) {
                final s = _mockScans[i];
                final color = _scanStatusColor(s.status);
                return Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(_methodIcon(s.method), color: color, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Row(children: [
                          StatusBadge(label: s.type, color: s.type == 'Teacher' ? AppColors.roleTeacher : AppColors.primary),
                          const SizedBox(width: 6),
                          Text(s.method, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ]),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        StatusBadge(label: s.status, color: color),
                        const SizedBox(height: 4),
                        Text(s.time, style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                      ]),
                    ]),
                  ),
                ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
              },
            )),
          ]),

          // Devices
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mockDevices.length,
            itemBuilder: (ctx, i) {
              final d = _mockDevices[i];
              final online = d.status == 'Online';
              return Padding(padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(color: online ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.sensors_rounded, color: online ? AppColors.success : AppColors.error, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(d.location, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ])),
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: online ? AppColors.success : AppColors.error,
                        boxShadow: [BoxShadow(color: (online ? AppColors.success : AppColors.error).withOpacity(0.5), blurRadius: 6)])),
                    ]),
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.key_rounded, size: 14, color: AppColors.textHint), const SizedBox(width: 6),
                        Text(d.apiKey, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, letterSpacing: 1)),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textHint), const SizedBox(width: 4),
                        Text(d.lastSeen, style: TextStyle(fontSize: 11, color: online ? AppColors.success : AppColors.error)),
                      ]),
                    ),
                  ]),
                ),
              ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideY(begin: 0.1, end: 0);
            },
          ),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value; final Color color;
  const _StatBox(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => GlassCard(padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ]),
  );
}
