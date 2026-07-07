import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/template.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';

class ExportScreen extends StatefulWidget {
  final String imagePath;
  final Template template;
  final String deceasedName;
  final String lifespanDates;

  const ExportScreen({
    super.key,
    required this.imagePath,
    required this.template,
    required this.deceasedName,
    required this.lifespanDates,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isSavingDevice = false;
  bool _isSavingApp = false;

  Future<void> _saveToDevice() async {
    setState(() {
      _isSavingDevice = true;
    });

    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final fileName = 'tribute_${DateTime.now().millisecondsSinceEpoch}.png';
        final destFile = File('${downloadDir.path}/$fileName');
        
        await File(widget.imagePath).copy(destFile.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tribute saved to Downloads: $fileName'),
              backgroundColor: Colors.green[800],
            ),
          );
        }
      } else {
        // Fallback to app documents
        final appDocDir = await getApplicationDocumentsDirectory();
        final fileName = 'tribute_${DateTime.now().millisecondsSinceEpoch}.png';
        final destFile = File('${appDocDir.path}/$fileName');
        
        await File(widget.imagePath).copy(destFile.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to App Documents: $fileName'),
              backgroundColor: Colors.orange[800],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to device: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDevice = false;
        });
      }
    }
  }

  Future<void> _saveToApp() async {
    setState(() {
      _isSavingApp = true;
    });

    try {
      // Map layers to include customized values
      final updatedTextLayers = widget.template.textLayers.map((text) {
        if (text.id == '2') {
          return text.copyWith(content: widget.deceasedName);
        } else if (text.id == 'date') {
          return text.copyWith(content: widget.lifespanDates);
        }
        return text;
      }).toList();

      final updatedTemplate = widget.template.copyWith(
        title: 'Tribute - ${widget.deceasedName}',
        textLayers: updatedTextLayers,
      );

      final success = await ApiService.updateTemplate(updatedTemplate);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Successfully updated open template in dashboard database!'),
              backgroundColor: Colors.green[800],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save to dashboard backend.'),
              backgroundColor: Colors.red[800],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingApp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Options'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Preview Card Container
            Expanded(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save to Device Option Card
            Card(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderSoft),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.sunlitCream,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.save_alt_rounded,
                    color: AppTheme.terracotta,
                  ),
                ),
                title: const Text(
                  'Save to Device',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.walnutBrown),
                ),
                subtitle: const Text('Save image directly to your Downloads folder'),
                trailing: _isSavingDevice
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.terracotta),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onPressed: _saveToDevice,
                      ),
                onTap: _isSavingDevice ? null : _saveToDevice,
              ),
            ),
            const SizedBox(height: 12),

            // Save to App Option Card
            Card(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderSoft),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.sunlitCream,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: AppTheme.terracotta,
                  ),
                ),
                title: const Text(
                  'Save to App',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.walnutBrown),
                ),
                subtitle: const Text('Save customized data layout back to templates dashboard'),
                trailing: _isSavingApp
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.terracotta),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onPressed: _saveToApp,
                      ),
                onTap: _isSavingApp ? null : _saveToApp,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
