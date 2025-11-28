import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/api_models.dart';
import '../l10n/app_localizations.dart';
import '../services/screenshot_protection_service.dart';
import '../services/api_service.dart';

class CertificateScreen extends StatefulWidget {
  final User user;
  final double progressPercentage;

  const CertificateScreen({super.key, required this.user, required this.progressPercentage});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  Map<String, dynamic>? _certificateData;
  Uint8List? _logoBytes;
  Uint8List? _qrCodeBytes;

  @override
  void initState() {
    super.initState();
    // Enable screenshot protection for certificate screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenshotProtectionService().enableProtection();
      _fetchCertificateData();
      _loadLogo();
    });
  }

  @override
  void dispose() {
    // Disable screenshot protection when leaving certificate screen
    ScreenshotProtectionService().disableProtection();
    super.dispose();
  }

  Future<void> _loadLogo() async {
    try {
      // Load logo from assets
      final ByteData logoData = await DefaultAssetBundle.of(context).load('assets/logo.png');
      setState(() {
        _logoBytes = logoData.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint('Failed to load logo: $e');
    }
  }

  Future<void> _fetchCertificateData() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getMyCertificate();
      
      if (response['success'] == true && response['data'] != null) {
        final certificates = response['data'] as List;
        if (certificates.isNotEmpty) {
          final cert = certificates[0] as Map<String, dynamic>;
          
          // Load QR code if available (it's a base64 data URL)
          if (cert['qrCode'] != null) {
            try {
              final qrCodeString = cert['qrCode'] as String;
              if (qrCodeString.startsWith('data:image')) {
                // Extract base64 data
                final base64Data = qrCodeString.split(',')[1];
                setState(() {
                  _qrCodeBytes = base64Decode(base64Data);
                });
              } else {
                // It's a URL
                final qrResponse = await http.get(Uri.parse(qrCodeString));
                if (qrResponse.statusCode == 200) {
                  setState(() {
                    _qrCodeBytes = qrResponse.bodyBytes;
                  });
                }
              }
            } catch (e) {
              debugPrint('Failed to load QR code: $e');
            }
          }
          
          setState(() {
            _certificateData = cert;
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch certificate: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<pw.Document> _generateCertificatePDF(AppLocalizations l10n) async {
    final pdf = pw.Document();
    final cert = _certificateData;
    final now = cert?['issuedAt'] != null 
        ? DateTime.parse(cert!['issuedAt']) 
        : DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(now.month)} ${now.year}';
    final certificateId = cert?['certificateId'] ?? 'CERT-${widget.user.id.substring(0, 8).toUpperCase()}';
    
    // Cream color: #F5F5DC
    final creamColor = PdfColor.fromHex('#F5F5DC');
    // Gold color: #FFD700
    final goldColor = PdfColor.fromHex('#FFD700');
    final blackColor = PdfColors.black;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
              children: [
              // Cream background
              pw.Container(
                color: creamColor,
                  child: pw.Container(
                  margin: const pw.EdgeInsets.all(40),
                    decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: goldColor, width: 8),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(50),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                        // Logo
                        if (_logoBytes != null)
                          pw.Image(
                            pw.MemoryImage(_logoBytes!),
                            width: 150,
                            height: 150,
                            fit: pw.BoxFit.contain,
                          ),
                        pw.SizedBox(height: 20),
                        
                      // Certificate Title
                        pw.Text(
                          'CERTIFICATE',
                          style: pw.TextStyle(
                            fontSize: 48,
                            fontWeight: pw.FontWeight.bold,
                            color: blackColor,
                            letterSpacing: 3,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'OF COMPLETION',
                          style: pw.TextStyle(
                            fontSize: 28,
                            color: blackColor,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 40),
                        
                        // This certificate is proudly presented to
                      pw.Text(
                        l10n.translate('this_is_to_certify'),
                        style: pw.TextStyle(
                          fontSize: 18,
                            color: blackColor,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                        
                        // Recipient Name
                      pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(color: blackColor, width: 1),
                          ),
                        ),
                        child: pw.Text(
                          widget.user.name.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 36,
                            fontWeight: pw.FontWeight.bold,
                              color: goldColor,
                              letterSpacing: 2,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 30),
                        
                      // Description
                      pw.Text(
                          'For successfully completing the Construction Exam',
                        style: pw.TextStyle(
                          fontSize: 18,
                            color: blackColor,
                        ),
                          textAlign: pw.TextAlign.center,
                      ),
                        pw.SizedBox(height: 10),
                      pw.Text(
                          'with an accuracy of ${cert?['accuracy']?.toStringAsFixed(0) ?? widget.progressPercentage.toStringAsFixed(0)}%',
                        style: pw.TextStyle(
                          fontSize: 16,
                            color: blackColor,
                        ),
                          textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 50),
                        
                        // Bottom section with QR code, date, and signature
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                            // QR Code
                            if (_qrCodeBytes != null)
                          pw.Container(
                                width: 120,
                                height: 120,
                                child: pw.Image(
                                  pw.MemoryImage(_qrCodeBytes!),
                                  fit: pw.BoxFit.contain,
                                ),
                              )
                            else
                              pw.SizedBox(width: 120),
                            
                            pw.Spacer(),
                            
                            // Date and Signature
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                  dateStr,
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    color: blackColor,
                                  ),
                                ),
                                pw.SizedBox(height: 60),
                              pw.Container(
                                width: 150,
                                height: 1,
                                  color: blackColor,
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                  'Signature',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                    color: blackColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                        
                      // Certificate ID
                      pw.Text(
                          'Certificate ID: $certificateId',
                        style: pw.TextStyle(
                          fontSize: 10,
                            color: PdfColors.grey700,
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ),
              
              // Decorative gold borders (top-left and bottom-right corners)
              pw.Positioned(
                top: 0,
                left: 0,
                child: pw.Container(
                  width: 200,
                  height: 200,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: goldColor, width: 4),
                      left: pw.BorderSide(color: goldColor, width: 4),
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                bottom: 0,
                right: 0,
                child: pw.Container(
                  width: 200,
                  height: 200,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: goldColor, width: 4),
                      right: pw.BorderSide(color: goldColor, width: 4),
                    ),
                  ),
                  ),
                ),
              ],
          );
        },
      ),
    );

    return pdf;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _exportPDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final pdf = await _generateCertificatePDF(l10n);
      
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'certificate_${_certificateData?['certificateId'] ?? widget.user.id.substring(0, 8)}.pdf',
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
    
    // Calculate accuracy from certificate data or use progress percentage
    final certAccuracy = _certificateData?['accuracy']?.toDouble() ?? widget.progressPercentage;
    
    // Check if user has 75% accuracy or certificate exists
    final hasCertificate = _certificateData != null;
    final isEligible = certAccuracy >= 75.0;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.translate('certificate'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!isEligible && !hasCertificate) {
      // User hasn't passed - show message
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.translate('certificate')),
        ),
        body: Container(
          color: const Color(0xFFF5F5DC), // Cream background
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Certificate Not Available',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You need at least 75% accuracy to generate a certificate.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your current progress: ${widget.progressPercentage.toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    final cert = _certificateData;
    final certificateId = cert?['certificateId'] ?? 'CERT-${widget.user.id.substring(0, 8).toUpperCase()}';
    final issuedDate = cert?['issuedAt'] != null 
        ? DateTime.parse(cert!['issuedAt']) 
        : DateTime.now();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('certificate')),
        backgroundColor: const Color(0xFFF5F5DC),
        foregroundColor: Colors.black87,
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
        color: const Color(0xFFF5F5DC), // Cream background
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                  color: const Color(0xFFFFD700), // Gold
                  width: 8,
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
                mainAxisSize: MainAxisSize.min,
                  children: [
                  // Logo
                  if (_logoBytes != null)
                    Image.memory(
                      _logoBytes!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  const SizedBox(height: 20),
                  
                  // Certificate Title
                  Text(
                    'CERTIFICATE',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'OF COMPLETION',
                        style: TextStyle(
                      fontSize: 28,
                      color: Colors.black87,
                          letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),
                  
                  // This certificate is proudly presented to
                      Text(
                        l10n.translate('this_is_to_certify'),
                    style: const TextStyle(
                          fontSize: 18,
                      color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 30),
                  
                  // Recipient Name with underline
                    Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black87, width: 1),
                        ),
                      ),
                      child: Text(
                        widget.user.name.toUpperCase(),
                        style: TextStyle(
                        fontSize: 36,
                          fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700), // Gold
                        letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  
                    // Description
                  const Text(
                    'For successfully completing the Construction Exam',
                      style: TextStyle(
                        fontSize: 18,
                      color: Colors.black87,
                      ),
                    textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 10),
                    Text(
                    'with an accuracy of ${certAccuracy.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 16,
                      color: Colors.black87,
                      ),
                    textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                  
                  // Bottom section with QR code, date, and signature
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      // QR Code
                      if (_qrCodeBytes != null)
                        Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            _qrCodeBytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        const SizedBox(width: 120),
                      
                      const Spacer(),
                      
                      // Date and Signature
                        Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                            '${issuedDate.day} ${_getMonthName(issuedDate.month)} ${issuedDate.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 60),
                        Container(
                            width: 150,
                            height: 1,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Signature',
                              style: TextStyle(
                                fontSize: 12,
                              color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
                  
                  // Certificate ID
                  Text(
                    'Certificate ID: $certificateId',
                        style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
