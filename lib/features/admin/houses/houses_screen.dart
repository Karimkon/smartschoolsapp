import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/app_widgets.dart';

class HousesScreen extends StatefulWidget {
  const HousesScreen({super.key});
  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  final _api = ApiService();
  List<dynamic> _houses = [];
  dynamic _selectedHouse;
  List<dynamic> _houseStudents = [];
  bool _loading = true;
  bool _loadingStudents = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get(ApiConstants.houses);
      setState(() {
        _houses = res.data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load houses'; _loading = false; });
    }
  }

  Future<void> _loadStudents(dynamic house) async {
    setState(() { _selectedHouse = house; _loadingStudents = true; _houseStudents = []; });
    try {
      final url = ApiConstants.houseStudents.replaceAll('{id}', '${house['id']}');
      final res = await _api.get(url);
      setState(() { _houseStudents = res.data['students'] ?? []; _loadingStudents = false; });
    } catch (e) {
      setState(() { _loadingStudents = false; });
    }
  }

  Color _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
                        : _selectedHouse != null
                            ? _buildStudentList()
                            : _buildHouseGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _selectedHouse != null ? Icons.arrow_back_ios_rounded : Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20,
            ),
            onPressed: () {
              if (_selectedHouse != null) {
                setState(() { _selectedHouse = null; _houseStudents = []; });
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          Expanded(
            child: Text(
              _selectedHouse != null ? '${_selectedHouse['name']} — Students' : 'School Houses',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          if (_selectedHouse != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _hexColor(_selectedHouse['color']).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _hexColor(_selectedHouse['color']).withOpacity(0.3)),
              ),
              child: Text(
                '${_houseStudents.length} students',
                style: TextStyle(color: _hexColor(_selectedHouse['color']), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHouseGrid() {
    if (_houses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('No houses configured yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Create houses from the web dashboard.', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.1,
        ),
        itemCount: _houses.length,
        itemBuilder: (ctx, i) {
          final h = _houses[i];
          final color = _hexColor(h['color']);
          return GestureDetector(
            onTap: () => _loadStudents(h),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.3), width: 2),
                boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                  ),
                  const SizedBox(height: 12),
                  Text(h['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('${h['student_count'] ?? 0} students', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(duration: 350.ms).scale(begin: const Offset(0.85, 0.85)),
          );
        },
      ),
    );
  }

  Widget _buildStudentList() {
    if (_loadingStudents) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    if (_houseStudents.isEmpty) {
      return const Center(child: Text('No students assigned to this house.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final color = _hexColor(_selectedHouse?['color']);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _houseStudents.length,
      itemBuilder: (ctx, i) {
        final s = _houseStudents[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface1, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surface2.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                (s['name'] as String?)?.isNotEmpty == true ? s['name'][0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(s['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${s['class_name'] ?? '—'} · ${s['admission_number'] ?? '—'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
              child: Text(s['gender'] ?? '—', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 30)).fadeIn(duration: 300.ms);
      },
    );
  }
}
