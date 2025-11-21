import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../l10n/app_localizations.dart';

class CertificateScreen extends StatefulWidget {
  final UserModel user;

  const CertificateScreen({super.key, required this.user});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  bool _isGenerating = false;

  Future<pw.Document> _generateCertificatePDF(AppLocalizations l10n) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.blue900,
                width: 8,
              ),
            ),
            child: pw.Stack(
              children: [
                // Background decoration
                pw.Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: pw.Container(
                    height: 120,
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [
                          PdfColor.fromHex('#1E3A8A'),
                          PdfColor.fromHex('#3B82F6'),
                        ],
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: pw.Container(
                    height: 120,
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        begin: pw.Alignment.topCenter,
                        end: pw.Alignment.bottomCenter,
                        colors: [
                          PdfColor.fromHex('#3B82F6'),
                          PdfColor.fromHex('#1E3A8A'),
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative corner elements
                pw.Positioned(
                  top: 40,
                  left: 40,
                  child: pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.blue900,
                        width: 3,
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '✓',
                        style: pw.TextStyle(
                          fontSize: 50,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  top: 40,
                  right: 40,
                  child: pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.blue900,
                        width: 3,
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '✓',
                        style: pw.TextStyle(
                          fontSize: 50,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                  ),
                ),
                // Main content
                pw.Padding(
                  padding: const pw.EdgeInsets.all(60),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(height: 40),
                      // Certificate Title
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                        ),
                        child: pw.Text(
                          l10n.translate('certificate_of_completion').toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 2,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.SizedBox(height: 50),
                      // Subtitle
                      pw.Text(
                        l10n.translate('this_is_to_certify'),
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.grey800,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      // Name
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.blue900,
                            width: 2,
                          ),
                        ),
                        child: pw.Text(
                          widget.user.fullName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                            letterSpacing: 1.5,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      // Description
                      pw.Text(
                        l10n.translate('has_successfully_completed'),
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        l10n.translate('construction_exam').toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        '${l10n.translate('with_completion_rate')} ${widget.user.progress.completionPercentage.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 50),
                      // Stats row
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          pw.Column(
                            children: [
                              pw.Text(
                                '${widget.user.progress.correct}',
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green700,
                                ),
                              ),
                              pw.Text(
                                l10n.translate('correct_answers'),
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                          pw.Container(
                            width: 1,
                            height: 40,
                            color: PdfColors.grey400,
                          ),
                          pw.Column(
                            children: [
                              pw.Text(
                                '${widget.user.progress.attempted}',
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue900,
                                ),
                              ),
                              pw.Text(
                                l10n.translate('total_questions_attempted'),
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.Spacer(),
                      // Signatures
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          pw.Column(
                            children: [
                              pw.Container(
                                width: 150,
                                height: 1,
                                color: PdfColors.black,
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                l10n.translate('signature'),
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            children: [
                              pw.Container(
                                width: 150,
                                height: 1,
                                color: PdfColors.black,
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                '${l10n.translate('date')}: $dateStr',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      // Certificate ID
                      pw.Text(
                        '${l10n.translate('certificate_id')}: ${widget.user.uid.substring(0, 8).toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _exportPDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final pdf = await _generateCertificatePDF(l10n);
      
      // Use printing package to share/save PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'certificate_${widget.user.uid.substring(0, 8)}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(l10n.translate('certificate_exported')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _printPDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final pdf = await _generateCertificatePDF(l10n);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('certificate')),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isGenerating ? null : _printPDF,
            tooltip: l10n.translate('print'),
          ),
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isGenerating ? null : _exportPDF,
            tooltip: l10n.translate('export_pdf'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E3A8A).withOpacity(0.05),
              Colors.white.withOpacity(0.95),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Visual Certificate Preview
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1E3A8A),
                    width: 6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header decoration
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Certificate Title
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                      ),
                      child: Text(
                        l10n.translate('certificate_of_completion').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Subtitle
                    Text(
                      l10n.translate('this_is_to_certify'),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF1E3A8A),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        widget.user.fullName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Description
                    Text(
                      l10n.translate('has_successfully_completed'),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      l10n.translate('construction_exam').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${l10n.translate('with_completion_rate')} ${widget.user.progress.completionPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${widget.user.progress.correct}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              l10n.translate('correct'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey.shade300,
                        ),
                        Column(
                          children: [
                            Text(
                              '${widget.user.progress.attempted}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            Text(
                              l10n.translate('attempted'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    // Footer decoration
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _printPDF,
                      icon: const Icon(Icons.print),
                      label: Text(l10n.translate('print')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _exportPDF,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isGenerating ? l10n.translate('exporting') : l10n.translate('export_pdf')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF1E3A8A),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can print or share this certificate as a PDF file.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
