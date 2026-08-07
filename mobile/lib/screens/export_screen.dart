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
  final String designTitle;

  const ExportScreen({
    super.key,
    required this.imagePath,
    required this.template,
    required this.deceasedName,
    required this.lifespanDates,
    this.designTitle = 'Untitled Memorial',
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isSavingDevice = false;
  bool _isSavingApp = false;
  late String _currentTitle;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.designTitle;
    _titleController = TextEditingController(text: _currentTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showRenameDialog() {
    _titleController.text = _currentTitle;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Memorial Design', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Design Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_titleController.text.trim().isNotEmpty) {
                  _currentTitle = _titleController.text.trim();
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBAFF00),
              foregroundColor: Colors.black,
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDevice() async {
    setState(() {
      _isSavingDevice = true;
    });

    try {
      final safeName = _currentTitle.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.png';
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
        final fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.png';
        final destFile = File('${appDocDir.path}/$fileName');
        
        await File(widget.imagePath).copy(destFile.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tribute saved to App Storage: $fileName'),
              backgroundColor: Colors.green[800],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
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

  Future<void> _saveToAppDashboard() async {
    setState(() {
      _isSavingApp = true;
    });

    try {
      final updatedTemplate = widget.template.copyWith(title: _currentTitle);
      bool success = false;
      if (updatedTemplate.id == 'new' || updatedTemplate.id.isEmpty) {
        success = await ApiService.createTemplate(updatedTemplate);
      } else {
        success = await ApiService.updateTemplate(updatedTemplate);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$_currentTitle" saved to your dashboard!'),
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
        title: Row(
          children: [
            Flexible(
              child: Text(
                _currentTitle,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: _showRenameDialog,
              tooltip: 'Rename Design',
            ),
          ],
        ),
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
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.download_rounded, color: AppTheme.textDark, size: 32),
                title: const Text('Save to Device', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Download high-res PNG image to your photo library'),
                trailing: _isSavingDevice
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _isSavingDevice ? null : _saveToDevice,
              ),
            ),
            const SizedBox(height: 16),

            // Save to App Templates & Favorites Option Card
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.cloud_upload_rounded, color: AppTheme.goldAccent, size: 32),
                title: const Text('Save to App Templates & Favorites', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Save design project to edit later on Web or Mobile'),
                trailing: _isSavingApp
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _isSavingApp ? null : _saveToAppDashboard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
