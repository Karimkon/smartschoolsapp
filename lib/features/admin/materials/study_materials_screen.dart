import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final materialsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final params = query.isNotEmpty ? {'search': query} : <String, dynamic>{};
  final res = await ApiService().get('/materials', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _fileColor(String type) {
  switch (type.toUpperCase()) {
    case 'PDF':  return const Color(0xFFEF4444);
    case 'DOCX':
    case 'DOC':  return AppColors.primary;
    case 'PPT':
    case 'PPTX': return const Color(0xFFF59E0B);
    case 'XLSX':
    case 'XLS':  return AppColors.success;
    default:     return AppColors.textSecondary;
  }
}

IconData _fileIcon(String type) {
  switch (type.toUpperCase()) {
    case 'PDF':  return Icons.picture_as_pdf_rounded;
    case 'PPT':
    case 'PPTX': return Icons.slideshow_rounded;
    case 'XLSX':
    case 'XLS':  return Icons.table_chart_rounded;
    default:     return Icons.description_rounded;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StudyMaterialsScreen extends ConsumerStatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  ConsumerState<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends ConsumerState<StudyMaterialsScreen> {
  String _subject = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  List<dynamic> _filterBySubject(List<dynamic> items) {
    if (_subject == 'All') return items;
    return items.where((m) {
      return (m['subject'] ?? m['subject_name'] ?? '').toString().toLowerCase() ==
          _subject.toLowerCase();
    }).toList();
  }

  List<String> _getSubjects(List<dynamic> items) {
    final subs = items
        .map((m) => (m['subject'] ?? m['subject_name'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...subs];
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(materialsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Study Materials',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(children: [
                ShimmerBox(height: 44, borderRadius: 14),
                const SizedBox(height: 12),
                ShimmerBox(height: 36, borderRadius: 20),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: 5,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShimmerBox(height: 85, borderRadius: 14),
                ),
              ),
            ),
          ]),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load materials',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(materialsProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (data) {
            final allMaterials = List<dynamic>.from(
                data['data'] ?? data['materials'] ?? []);
            final subjects = _getSubjects(allMaterials);
            final materials = _filterBySubject(allMaterials);

            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(children: [
                  AppSearchField(
                    hint: 'Search materials...',
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                  ).animate().fadeIn(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: subjects.map((s) {
                        final sel = s == _subject;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _subject = s),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFFEF4444) : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? const Color(0xFFEF4444)
                                      : Colors.white.withOpacity(0.07),
                                ),
                              ),
                              child: Text(s,
                                  style: TextStyle(
                                      color: sel ? Colors.white : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                ]),
              ),
              Expanded(
                child: materials.isEmpty
                    ? const Center(
                        child: Text('No materials found',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(materialsProvider),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: materials.length,
                          itemBuilder: (ctx, i) {
                            final m = materials[i];
                            final title = m['title'] ?? m['name'] ?? 'Material';
                            final subject = m['subject'] ?? m['subject_name'] ?? '';
                            final className = m['class_name'] ?? m['class'] ?? 'All';
                            final teacher = m['teacher'] ?? m['teacher_name'] ?? m['uploaded_by'] ?? '';
                            final uploadDate = m['upload_date'] ?? m['created_at'] ?? '';
                            final fileType = (m['file_type'] ?? m['type'] ?? 'PDF').toString().toUpperCase();
                            final fileSize = m['file_size'] ?? m['size'] ?? '';
                            final fileColor = _fileColor(fileType);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(
                                      color: fileColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_fileIcon(fileType), color: fileColor, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title.toString(),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 3),
                                        Text('$subject · $className',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: fileColor,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 3),
                                        Row(children: [
                                          if (teacher.toString().isNotEmpty) ...[
                                            const Icon(Icons.person_rounded,
                                                size: 11, color: AppColors.textHint),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(teacher.toString(),
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textSecondary),
                                                  overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                          if (uploadDate.toString().isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.access_time_rounded,
                                                size: 11, color: AppColors.textHint),
                                            const SizedBox(width: 4),
                                            Text(uploadDate.toString(),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary)),
                                          ],
                                        ]),
                                      ],
                                    ),
                                  ),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: fileColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(fileType,
                                          style: TextStyle(
                                              color: fileColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    if (fileSize.toString().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(fileSize.toString(),
                                          style: const TextStyle(
                                              fontSize: 10, color: AppColors.textHint)),
                                    ],
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.download_rounded,
                                            color: AppColors.primary, size: 16),
                                      ),
                                    ),
                                  ]),
                                ]),
                              ),
                            ).animate(delay: Duration(milliseconds: i * 50))
                                .fadeIn()
                                .slideX(begin: 0.05, end: 0);
                          },
                        ),
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
