import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/api_models.dart';
import '../l10n/app_localizations.dart';
import '../services/screenshot_protection_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../providers/progress_provider.dart';
import '../providers/language_provider.dart';

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
  Map<String, dynamic>? _progressData;
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
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
      
      // Fetch both certificate and progress data
      final results = await Future.wait([
        apiService.getMyCertificate(),
        progressProvider.getUserProgress(),
      ]);
      
      final certResponse = results[0] as Map<String, dynamic>;
      final progressResult = results[1] as Map<String, dynamic>?;
      
      // Set progress data
      if (progressResult != null) {
        setState(() {
          _progressData = progressResult;
        });
      }
      
      if (certResponse['success'] == true && certResponse['data'] != null) {
        final certificates = certResponse['data'] as List;
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
  
  Future<void> _handleGenerateCertificate() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });
    
    try {
      final apiService = ApiService();
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final currentLanguage = languageProvider.locale.languageCode;
      
      final response = await apiService.generateMyCertificate(language: currentLanguage);
      
      if (response['success'] == true) {
        // Refresh certificate data
        await _fetchCertificateData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Certificate generated successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to generate certificate');
      }
    } catch (e) {
      debugPrint('Error generating certificate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate certificate: $e'),
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
  
  Future<void> _handleShare() async {
    if (_certificateData == null) return;
    
    final certificateId = _certificateData!['certificateId'] as String?;
    if (certificateId == null) return;
    
    try {
      // Get the base URL from config
      final baseUrl = AppConfig.backendBaseUrl.replaceAll('/api', '');
      final verificationUrl = '$baseUrl/verify-certificate/$certificateId';
      
      await Share.share(
        'Check out my certificate!\n\nVerification link: $verificationUrl\nCertificate ID: $certificateId',
        subject: 'My Construction Exam Certificate',
      );
    } catch (e) {
      debugPrint('Error sharing certificate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _handleCopyLink() async {
    if (_certificateData == null) return;
    
    final certificateId = _certificateData!['certificateId'] as String?;
    if (certificateId == null) return;
    
    try {
      final baseUrl = AppConfig.backendBaseUrl.replaceAll('/api', '');
      final verificationUrl = '$baseUrl/verify-certificate/$certificateId';
      
      // Copy to clipboard (using share_plus for now, or clipboard package)
      await Share.share(verificationUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Verification link copied!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying link: $e');
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
      final certId = _certificateData?['_id'] ?? _certificateData?['id'];
      if (certId == null) {
        // If no certificate ID, generate PDF locally (fallback)
        await _exportPDFLocal();
        return;
      }

      // Try to download from backend first (matching web implementation)
      try {
        final apiService = ApiService();
        final response = await apiService.downloadCertificate(certId);
        
        if (response['success'] == true && response['data']?['url'] != null) {
          final downloadUrl = response['data']['url'] as String;
          
          // Download the PDF from the URL
          await _downloadPDFFromUrl(downloadUrl);
          return;
        }
      } catch (e) {
        debugPrint('Error downloading from backend: $e');
        // Fallback to local PDF generation
      }

      // Fallback to local PDF generation
      await _exportPDFLocal();
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

  Future<void> _downloadPDFFromUrl(String url) async {
    try {
      final apiService = ApiService();
      final token = await apiService.getToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/pdf',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Construct full URL if relative
      final baseUrl = url.startsWith('http') 
          ? url 
          : '${AppConfig.backendBaseUrl}$url';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Downloading certificate...'),
                ),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final response = await http.get(Uri.parse(baseUrl), headers: headers);
      
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filename = 'certificate_${_certificateData?['certificateId'] ?? widget.user.id.substring(0, 8)}.pdf';
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);
        
        // Share the downloaded file
        await Printing.sharePdf(
          bytes: response.bodyBytes,
          filename: filename,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Certificate downloaded: ${file.path}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  await OpenFile.open(filePath);
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to download certificate: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF from URL: $e');
      // Fallback to local generation
      await _exportPDFLocal();
    }
  }

  Future<void> _exportPDFLocal() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final pdf = await _generateCertificatePDF(l10n);
      final pdfBytes = await pdf.save();
      final filename = 'certificate_${_certificateData?['certificateId'] ?? widget.user.id.substring(0, 8)}.pdf';
      
      // Save to device first
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        
        // Then share/download
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Certificate saved and shared: ${file.path}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  await OpenFile.open(filePath);
                },
              ),
            ),
          );
        }
      } catch (saveError) {
        // If save fails, just share
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
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
      }
    } catch (e) {
      throw e; // Re-throw to be caught by caller
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
    
    // Calculate accuracy from certificate data or progress data
    final certAccuracy = _certificateData?['accuracy']?.toDouble() ?? 
        _progressData?['accuracy']?.toDouble() ?? 
        widget.progressPercentage;
    
    // Calculate overall progress
    final overallProgress = _certificateData?['progress']?.toDouble() ?? 
        _progressData?['overallProgress']?.toDouble() ?? 
        widget.progressPercentage;
    
    // Check if user has 85% accuracy or certificate exists (matching web requirement)
    final hasCertificate = _certificateData != null;
    final isEligible = certAccuracy >= 85.0;
    final canGenerate = isEligible && !hasCertificate;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.translate('certificate'))),
        body: const Center(child: CircularProgressIndicator()),
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
        actions: hasCertificate ? [
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
        ] : null,
      ),
      body: Container(
        color: const Color(0xFFF5F5DC), // Cream background (matching web)
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Status Card (when no certificate)
              if (!hasCertificate) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.track_changes, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Certificate Progress',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Achieve at least 85% overall accuracy (correct answers / total answered) to earn your certificate',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Overall Progress',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${overallProgress.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: overallProgress / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        if (certAccuracy < 85) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You need at least 85% overall accuracy to earn your certificate.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your current accuracy: ${certAccuracy.toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Overall accuracy = (Correct answers / Total answered) × 100',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (canGenerate) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isGenerating ? null : _handleGenerateCertificate,
                              icon: _isGenerating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(_isGenerating ? 'Generating Certificate...' : 'Generate Certificate'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Certificate Display (when certificate exists)
              if (hasCertificate) ...[
                // Elegant Certificate Design
                Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Stack(
                children: [
                  // Main Certificate Container
                  Container(
                    padding: const EdgeInsets.all(60),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5DC), // Cream background
                      border: Border.all(
                        color: const Color(0xFFFFD700), // Gold border
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        if (_logoBytes != null)
                          SizedBox(
                            width: 128,
                            height: 128,
                            child: Image.memory(
                              _logoBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        if (_logoBytes != null) const SizedBox(height: 20),
                        
                        // Certificate Title
                        Text(
                          'CERTIFICATE',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1a1a1a),
                            letterSpacing: 3.2, // 0.2em equivalent
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'OF COMPLETION',
                          style: TextStyle(
                            fontSize: 28,
                            color: const Color(0xFF1a1a1a),
                            letterSpacing: 2.8, // 0.1em equivalent
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // This certificate is proudly presented to
                        Text(
                          l10n.translate('this_is_to_certify'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1a1a1a),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        
                        // Recipient Name with underline
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFF1a1a1a), width: 2),
                            ),
                          ),
                          child: Text(
                            widget.user.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700), // Gold
                              letterSpacing: 3.6, // 0.1em equivalent
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Description
                        const Text(
                          'For successfully completing the Construction Exam',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1a1a1a),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'with an accuracy of ${certAccuracy.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1a1a1a),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),
                        
                        // Bottom section with QR code, date, and signature
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // QR Code
                            if (_qrCodeBytes != null)
                              Container(
                                width: 128,
                                height: 128,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Image.memory(
                                  _qrCodeBytes!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            else
                              const SizedBox(width: 128),
                            
                            const Spacer(),
                            
                            // Date and Signature
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${issuedDate.day} ${_getMonthName(issuedDate.month)} ${issuedDate.year}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1a1a1a),
                                  ),
                                ),
                                const SizedBox(height: 60),
                                Container(
                                  width: 150,
                                  height: 0.5, // 1px equivalent
                                  color: const Color(0xFF1a1a1a),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Signature',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1a1a1a),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Certificate ID
                        Container(
                          padding: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Certificate ID: $certificateId',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Decorative Corner Elements - Top Left
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 192, // 48 * 4 = 192 (matching web's w-48)
                      height: 192,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: const Color(0xFFFFD700), width: 4),
                          left: BorderSide(color: const Color(0xFFFFD700), width: 4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Decorative Corner Elements - Bottom Right
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 192,
                      height: 192,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: const Color(0xFFFFD700), width: 4),
                          right: BorderSide(color: const Color(0xFFFFD700), width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Certificate Details Card
                Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Certificate Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Chip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      label: Text(
                        cert?['status'] == 'issued' ? 'Issued' : 'Ready',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green.shade50,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Verification and sharing options',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Certificate Details Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: [
                    _buildDetailItem(
                      'Certificate ID',
                      certificateId,
                      Icons.fingerprint,
                    ),
                    _buildDetailItem(
                      'Issued Date',
                      '${issuedDate.day} ${_getMonthName(issuedDate.month)} ${issuedDate.year}',
                      Icons.calendar_today,
                    ),
                    _buildDetailItem(
                      'Accuracy',
                      '${certAccuracy.toStringAsFixed(1)}%',
                      Icons.star,
                    ),
                    _buildDetailItem(
                      'Progress',
                      '${overallProgress.toStringAsFixed(1)}%',
                      Icons.trending_up,
                    ),
                  ],
                ),
                
                // QR Code Section
                if (_qrCodeBytes != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Verification QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.memory(
                            _qrCodeBytes!,
                            width: 192,
                            height: 192,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Actions
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _exportPDF,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: const Text('Download Certificate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleShare,
                        icon: const Icon(Icons.share),
                        label: const Text('Share Certificate'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleCopyLink,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Link'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Verification Information Card
                Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Verification Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This certificate can be verified by anyone using the QR code or verification link. Share your certificate ID or verification URL to allow others to verify your achievement.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification URL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        '${AppConfig.backendBaseUrl.replaceAll('/api', '')}/verify-certificate/$certificateId',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
