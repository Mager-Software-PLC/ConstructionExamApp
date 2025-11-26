import 'package:flutter/material.dart' hide Material;
import 'package:flutter/services.dart';
import '../models/api_models.dart' show Material;
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class MaterialDetailScreen extends StatelessWidget {
  final Material material;

  const MaterialDetailScreen({super.key, required this.material});

  Future<void> _openPDF(BuildContext context) async {
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final fileUrl = '$baseUrl${material.fileUrl}';

    try {
      // Copy URL to clipboard and show message
      await Clipboard.setData(ClipboardData(text: fileUrl));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF URL copied to clipboard. Open it in your browser.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
      appBar: AppBar(
        title: Text(material.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PDF Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              material.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            if (material.description.isNotEmpty) ...[
              Text(
                material.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // File Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    Icons.insert_drive_file,
                    'File Name',
                    material.fileName,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    Icons.storage,
                    'File Size',
                    material.fileSizeFormatted,
                  ),
                  if (material.uploadedByName != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      context,
                      Icons.person,
                      'Uploaded By',
                      material.uploadedByName!,
                    ),
                  ],
                  if (material.createdAt != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Uploaded On',
                      '${material.createdAt!.day}/${material.createdAt!.month}/${material.createdAt!.year}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Open PDF Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openPDF(context),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.translate('open_pdf')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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

