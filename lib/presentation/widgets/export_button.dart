import 'package:flutter/material.dart';

/// Export action button that shows a bottom sheet with format options.
class ExportButton extends StatelessWidget {
  final VoidCallback? onShareImage;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportCsv;

  const ExportButton({
    super.key,
    this.onShareImage,
    this.onExportPdf,
    this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.ios_share),
      tooltip: 'Export',
      onPressed: () => _showExportSheet(context),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Export Options',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Share Image'),
                subtitle: const Text('Share as a screenshot'),
                onTap: () {
                  Navigator.pop(context);
                  onShareImage?.call();
                  if (onShareImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image export coming soon')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export PDF'),
                subtitle: const Text('Generate a PDF report'),
                onTap: () {
                  Navigator.pop(context);
                  onExportPdf?.call();
                  if (onExportPdf == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF export coming soon')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Export CSV'),
                subtitle: const Text('Export data as spreadsheet'),
                onTap: () {
                  Navigator.pop(context);
                  onExportCsv?.call();
                  if (onExportCsv == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV export coming soon')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
