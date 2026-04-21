import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Material {
  final int id;
  final String title, subject, className, teacher, uploadDate, fileType;
  final String fileSize;
  const _Material({required this.id, required this.title, required this.subject, required this.className,
    required this.teacher, required this.uploadDate, required this.fileType, required this.fileSize});
}

const _mockMaterials = [
  _Material(id:1, title:'Algebra Notes – Chapter 3',     subject:'Mathematics', className:'Grade 8A', teacher:'Mr. Paul Ochieng',  uploadDate:'Apr 15', fileType:'PDF',  fileSize:'2.4 MB'),
  _Material(id:2, title:'Essay Writing Guide',            subject:'English',     className:'All',      teacher:'Ms. Grace Wanjiku', uploadDate:'Apr 14', fileType:'DOCX', fileSize:'1.1 MB'),
  _Material(id:3, title:'Photosynthesis Diagram',         subject:'Science',     className:'Grade 7A', teacher:'Mr. James Kariuki', uploadDate:'Apr 13', fileType:'PPT',  fileSize:'5.2 MB'),
  _Material(id:4, title:'World War II Timeline',          subject:'History',     className:'Grade 10A',teacher:'Ms. Lucy Auma',     uploadDate:'Apr 12', fileType:'PDF',  fileSize:'3.0 MB'),
  _Material(id:5, title:'Kiswahili Sarufi Notes',         subject:'Kiswahili',   className:'Grade 7B', teacher:'Mr. David Mwangi',  uploadDate:'Apr 10', fileType:'PDF',  fileSize:'1.8 MB'),
  _Material(id:6, title:'Map Reading Exercises',          subject:'Geography',   className:'Grade 8B', teacher:'Ms. Agnes Nakato',  uploadDate:'Apr 9',  fileType:'PDF',  fileSize:'4.5 MB'),
  _Material(id:7, title:'Chemical Reactions Lab Sheet',   subject:'Chemistry',   className:'Grade 10A',teacher:'Ms. Ruth Otieno',   uploadDate:'Apr 8',  fileType:'XLSX', fileSize:'0.8 MB'),
];

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});
  @override State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  String _subject = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<String> get _subjects => ['All', ..._mockMaterials.map((m) => m.subject).toSet().toList()..sort()];
  List<_Material> get _filtered => _mockMaterials.where((m) {
    final ms = _subject == 'All' || m.subject == _subject;
    final mq = _query.isEmpty || m.title.toLowerCase().contains(_query.toLowerCase()) || m.subject.toLowerCase().contains(_query.toLowerCase());
    return ms && mq;
  }).toList();

  Color _fileColor(String type) {
    switch (type) {
      case 'PDF': return const Color(0xFFEF4444);
      case 'DOCX': return AppColors.primary;
      case 'PPT': return const Color(0xFFF59E0B);
      case 'XLSX': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  IconData _fileIcon(String type) {
    switch (type) {
      case 'PDF': return Icons.picture_as_pdf_rounded;
      case 'PPT': return Icons.slideshow_rounded;
      case 'XLSX': return Icons.table_chart_rounded;
      default: return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final materials = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Study Materials', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary), onPressed: () {})],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0),
            child: Column(children: [
              AppSearchField(hint: 'Search materials...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate().fadeIn(),
              const SizedBox(height: 12),
              SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: _subjects.map((s) {
                final sel = s == _subject;
                return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onTap: () => setState(() => _subject = s),
                  child: AnimatedContainer(duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: sel ? const Color(0xFFEF4444) : AppColors.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.07))),
                    child: Text(s, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ));
              }).toList())).animate(delay: 100.ms).fadeIn(),
            ]),
          ),
          Expanded(child: materials.isEmpty
            ? const Center(child: Text('No materials found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,12,16,80),
                itemCount: materials.length,
                itemBuilder: (ctx, i) {
                  final m = materials[i];
                  final fileColor = _fileColor(m.fileType);
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(width: 50, height: 50, decoration: BoxDecoration(color: fileColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_fileIcon(m.fileType), color: fileColor, size: 24)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('${m.subject} · ${m.className}', style: TextStyle(fontSize: 11, color: fileColor, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.person_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 4),
                            Text(m.teacher, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 4),
                            Text(m.uploadDate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ]),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: fileColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(m.fileType, style: TextStyle(color: fileColor, fontSize: 11, fontWeight: FontWeight.w700))),
                          const SizedBox(height: 6),
                          Text(m.fileSize, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          const SizedBox(height: 6),
                          GestureDetector(onTap: () {},
                            child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 16))),
                        ]),
                      ]),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              ),
          ),
        ]),
      ),
    );
  }
}
