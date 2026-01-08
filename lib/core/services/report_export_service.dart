import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'report_export_service.g.dart';

/// Data model for session reports.
class SessionReportData {
  const SessionReportData({
    required this.date,
    required this.exerciseName,
    required this.durationSeconds,
    required this.score,
    required this.isCorrect,
    this.feedback = const {},
    this.textReport,
    this.notes,
  });

  final DateTime date;
  final String exerciseName;
  final int durationSeconds;
  final int score;
  final bool isCorrect;
  final Map<String, dynamic> feedback;
  final String? textReport;
  final String? notes;
}

/// Service for generating and exporting exercise reports.
/// Supports PDF generation and native sharing (iOS/Android).
class ReportExportService {
  /// Generate PDF report for a single exercise session.
  Future<File> generateSessionPdf({
    required String exerciseName,
    required DateTime sessionDate,
    required int score,
    required bool isCorrect,
    required Map<String, dynamic> feedback,
    required String textReport,
    String? patientName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(patientName),
          pw.SizedBox(height: 20),
          _buildSessionInfo(exerciseName, sessionDate, dateFormat),
          pw.SizedBox(height: 20),
          _buildScoreSection(score, isCorrect),
          pw.SizedBox(height: 20),
          _buildFeedbackSection(feedback),
          pw.SizedBox(height: 20),
          _buildDetailedReport(textReport),
          pw.SizedBox(height: 30),
          _buildDisclaimer(),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/orthosense_report_$timestamp.pdf');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Generate PDF report for multiple sessions (Activity Log export).
  Future<File> generateActivityLogPdf({
    required List<SessionReportData> sessions,
    required DateTime startDate,
    required DateTime endDate,
    String? patientName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(patientName),
          pw.SizedBox(height: 10),
          pw.Text(
            'Activity Report: ${dateFormat.format(startDate)} - '
            '${dateFormat.format(endDate)}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          _buildSummaryStats(sessions),
          pw.SizedBox(height: 20),
          _buildSessionsTable(sessions),
          pw.SizedBox(height: 30),
          _buildDisclaimer(),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/orthosense_activity_$timestamp.pdf');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Share PDF via native iOS/Android share sheet.
  Future<void> sharePdf(File pdfFile, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: subject ?? 'OrthoSense Exercise Report',
          text: 'Exercise analysis report from OrthoSense',
          files: [XFile(pdfFile.path)],
        ),
      );
    } finally {
      // Cleanup temp file after sharing
      _scheduledCleanup(pdfFile);
    }
  }

  /// Generate CSV export for Activity Log.
  Future<File> generateActivityLogCsv({
    required List<SessionReportData> sessions,
  }) async {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Date,Exercise,Duration (min),Score,Status,Notes');

    // CSV Rows
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    for (final session in sessions) {
      final date = dateFormat.format(session.date);
      final duration = (session.durationSeconds / 60).toStringAsFixed(1);
      final status = session.isCorrect ? 'Correct' : 'Needs Improvement';
      final notes = session.notes?.replaceAll(',', ';') ?? '';

      buffer.writeln(
        '$date,${session.exerciseName},$duration,${session.score},$status,'
        '$notes',
      );
    }

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/orthosense_activity_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    return file;
  }

  /// Share CSV via native share sheet.
  Future<void> shareCsv(File csvFile) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'OrthoSense Activity Export',
          text: 'Exercise activity data from OrthoSense (CSV format)',
          files: [XFile(csvFile.path)],
        ),
      );
    } finally {
      _scheduledCleanup(csvFile);
    }
  }

  // --- Private PDF building methods ---

  pw.Widget _buildHeader(String? patientName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'OrthoSense',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              'Exercise Analysis Report',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
            ),
          ],
        ),
        if (patientName != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Patient: $patientName',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
        pw.Divider(color: PdfColors.blue200),
      ],
    );
  }

  pw.Widget _buildSessionInfo(
    String exerciseName,
    DateTime date,
    DateFormat format,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Exercise: $exerciseName',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Date: ${format.format(date)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildScoreSection(int score, bool isCorrect) {
    final color = isCorrect ? PdfColors.green700 : PdfColors.orange700;
    final status = isCorrect ? 'Correct Form' : 'Needs Improvement';

    return pw.Row(
      children: [
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: color,
          ),
          child: pw.Center(
            child: pw.Text(
              '$score',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Overall Score',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
            ),
            pw.Text(
              status,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFeedbackSection(Map<String, dynamic> feedback) {
    if (feedback.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.green200),
        ),
        child: pw.Text(
          'Excellent form! No issues detected.',
          style: pw.TextStyle(color: PdfColors.green800),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detected Issues:',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...feedback.entries.map((entry) {
          final detail = entry.value == true ? '' : ': ${entry.value}';
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(color: PdfColors.red700)),
                pw.Expanded(
                  child: pw.Text(
                    '${entry.key}$detail',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildDetailedReport(String textReport) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Detailed Analysis',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(textReport, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryStats(List<SessionReportData> sessions) {
    final totalSessions = sessions.length;
    final avgScore = sessions.isEmpty
        ? 0
        : sessions.map((s) => s.score).reduce((a, b) => a + b) ~/ totalSessions;
    final correctCount = sessions.where((s) => s.isCorrect).length;
    final complianceRate = totalSessions > 0
        ? (correctCount / totalSessions * 100).round()
        : 0;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildStatBox('Total Sessions', '$totalSessions'),
        _buildStatBox('Avg Score', '$avgScore'),
        _buildStatBox('Correct Form', '$complianceRate%'),
      ],
    );
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSessionsTable(List<SessionReportData> sessions) {
    final dateFormat = DateFormat('dd/MM/yy');

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      headers: ['Date', 'Exercise', 'Score', 'Status'],
      data: sessions.map((s) {
        return [
          dateFormat.format(s.date),
          s.exerciseName,
          '${s.score}',
          s.isCorrect ? '✓' : '✗',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'This report is generated by OrthoSense for informational purposes. '
        'It is not a medical diagnosis. Please consult a healthcare '
        'professional for medical advice.',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  void _scheduledCleanup(File file) {
    // Cleanup after 5 minutes to ensure share sheet had time to process
    Future.delayed(const Duration(minutes: 5), () {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Cleanup error: $e');
      }
    });
  }
}

@Riverpod(keepAlive: true)
ReportExportService reportExportService(Ref ref) {
  return ReportExportService();
}
