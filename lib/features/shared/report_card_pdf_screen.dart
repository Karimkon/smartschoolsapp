import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/api_service.dart';

class ReportCardPdfScreen extends StatefulWidget {
  final int studentId;
  final int curriculumId;
  final int sessionYearId;
  final int term;
  final String studentName;
  final bool isParent;

  const ReportCardPdfScreen({
    super.key,
    required this.studentId,
    required this.curriculumId,
    required this.sessionYearId,
    required this.term,
    required this.studentName,
    this.isParent = false,
  });

  @override
  State<ReportCardPdfScreen> createState() => _ReportCardPdfScreenState();
}

class _ReportCardPdfScreenState extends State<ReportCardPdfScreen> {
  Uint8List? _pdfBytes;
  String?    _error;
  bool       _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() { _loading = true; _error = null; });
    try {
      final path = widget.isParent
          ? '/parent/children/${widget.studentId}/reports/pdf'
          : '/report-cards/pdf';

      final params = <String, String>{
        'curriculum_id':   widget.curriculumId.toString(),
        'session_year_id': widget.sessionYearId.toString(),
        'term':            widget.term.toString(),
      };
      if (widget.studentId > 0) params['student_id'] = widget.studentId.toString();

      final bytes = await ApiService().getBytes(path, params: params);

      if (mounted) setState(() { _pdfBytes = bytes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error   = e.toString().contains(':') ? e.toString().split(':').last.trim() : e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Card',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            Text('Term ${widget.term}  •  ${widget.studentName}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              tooltip: 'Reload',
              onPressed: _loadPdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(
            width: 52, height: 52,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          const Text('Preparing report card...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('This may take a few seconds',
              style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        ]).animate().fadeIn(duration: 400.ms),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Could not load report card',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]).animate().fadeIn(),
        ),
      );
    }

    return SfPdfViewer.memory(
      _pdfBytes!,
      pageLayoutMode: PdfPageLayoutMode.single,
      scrollDirection: PdfScrollDirection.vertical,
      enableDoubleTapZooming: true,
      canShowScrollHead: false,
    );
  }
}
