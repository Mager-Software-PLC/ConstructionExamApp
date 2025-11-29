import 'dart:io';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../models/api_models.dart' show Material;
import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class MaterialDetailScreen extends StatefulWidget {
  final Material material;

  const MaterialDetailScreen({super.key, required this.material});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  bool _isDownloading = false;
  bool _isOpening = false;

  Future<void> _openPDF(BuildContext context) async {
    if (_isOpening) return;
    
    setState(() {
      _isOpening = true;
    });

    try {
      final baseUrl = AppConfig.backendBaseUrl;
      final fileUrl = '$baseUrl${widget.material.fileUrl}';

      // Try to open in external app first (better user experience)
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched && context.mounted) {
          setState(() {
            _isOpening = false;
          });
          return;
        }
      }

      // If external launch fails, download and open locally
      await _downloadAndOpenPDF(context, fileUrl);
    } catch (e) {
      debugPrint('Error opening PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  Future<void> _downloadAndOpenPDF(BuildContext context, String fileUrl) async {
    try {
      // Get token for authenticated requests
      final apiService = ApiService();
      final token = await apiService.getToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/pdf',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      if (context.mounted) {
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
                  child: Text('Downloading PDF...'),
                ),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Download the PDF
      final response = await http.get(Uri.parse(fileUrl), headers: headers);
      
      if (response.statusCode == 200) {
        // Get the directory for saving the file
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/${widget.material.fileName}';
        final file = File(filePath);
        
        // Write the file
        await file.writeAsBytes(response.bodyBytes);
        
        // Open the file
        try {
          final result = await OpenFile.open(filePath);
          
          if (context.mounted) {
            // Check if file was opened successfully (result.type == ResultType.done)
            if (result.type.toString().contains('done') || result.message == 'done') {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('PDF opened successfully'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error opening PDF: ${result.message}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (openError) {
          debugPrint('Error opening file: $openError');
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening PDF: $openError'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPDF(BuildContext context) async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
    });

    try {
      final baseUrl = AppConfig.backendBaseUrl;
      final fileUrl = '$baseUrl${widget.material.fileUrl}';

      // Get token for authenticated requests
      final apiService = ApiService();
      final token = await apiService.getToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/pdf',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      if (context.mounted) {
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
                  child: Text('Downloading PDF...'),
                ),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Download the PDF
      final response = await http.get(Uri.parse(fileUrl), headers: headers);
      
      if (response.statusCode == 200) {
        // Get the directory for saving the file (Downloads directory if available)
        Directory? directory;
        if (Platform.isAndroid) {
          // Try to get external storage directory for Android
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            final downloadsPath = '${directory.path}/Download';
            directory = Directory(downloadsPath);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        }
        
        // Fallback to application documents directory
        directory ??= await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/${widget.material.fileName}';
        final file = File(filePath);
        
        // Write the file
        await file.writeAsBytes(response.bodyBytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('PDF downloaded to: ${file.path}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () {
                  Share.shareXFiles(
                    [XFile(file.path)],
                    text: '${widget.material.title} - ${widget.material.description}',
                  );
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _copyUrl(BuildContext context) async {
    final baseUrl = AppConfig.backendBaseUrl;
    final fileUrl = '$baseUrl${widget.material.fileUrl}';

    try {
      await Clipboard.setData(ClipboardData(text: fileUrl));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('PDF URL copied to clipboard'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.material.title,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _copyUrl(context),
                tooltip: 'Copy URL',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Icon Card
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Description Card
                  if (widget.material.description.isNotEmpty) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Description',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.material.description,
                              style: AppTypography.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // File Info Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'File Information',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoRow(
                            context,
                            Icons.insert_drive_file,
                            'File Name',
                            widget.material.fileName,
                          ),
                          const Divider(height: 32),
                          _buildInfoRow(
                            context,
                            Icons.storage,
                            'File Size',
                            widget.material.fileSizeFormatted,
                          ),
                          if (widget.material.uploadedByName != null) ...[
                            const Divider(height: 32),
                            _buildInfoRow(
                              context,
                              Icons.person,
                              'Uploaded By',
                              widget.material.uploadedByName!,
                            ),
                          ],
                          if (widget.material.createdAt != null) ...[
                            const Divider(height: 32),
                            _buildInfoRow(
                              context,
                              Icons.calendar_today,
                              'Uploaded On',
                              '${widget.material.createdAt!.day}/${widget.material.createdAt!.month}/${widget.material.createdAt!.year}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isOpening ? null : () => _openPDF(context),
                              icon: _isOpening
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.open_in_new),
                              label: Text(_isOpening ? 'Opening...' : l10n.translate('open_pdf')),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isDownloading ? null : () => _downloadPDF(context),
                              icon: _isDownloading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(_isDownloading ? 'Downloading...' : 'Download'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _copyUrl(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 8),
                            Text('Copy URL'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
