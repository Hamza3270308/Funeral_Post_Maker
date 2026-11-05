import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/template.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../services/ad_service.dart';

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


  void _handleSaveToDevice() {
    if (_isSavingDevice) return;

    if (!AdService.instance.isRewardedAdsEnabled) {
      _saveToDevice();
      return;
    }

    // Preload Rewarded Ad just-in-time while the user reviews the confirmation dialog
    AdService.instance.preloadRewardedAd();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.video_library_rounded, color: AppTheme.accentNeon),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Watch Ad & Export Template',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Text(
          'Watch a short video ad to export and download your high-resolution memorial tribute to your photo library for free.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              AdService.instance.showRewardedAd(
                context,
                onUserEarnedReward: () {
                  _saveToDevice();
                },
              );
            },
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
            label: const Text(
              'Watch Ad & Export',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentNeon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text('Export Tribute', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tribute Name Field
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: AppTheme.textGray, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter tribute title...',
                          ),
                          onChanged: (val) {
                            setState(() {
                              _currentTitle = val.trim().isEmpty ? 'Memorial Tribute' : val.trim();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image Preview Card
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
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
              const SizedBox(height: 24),

              // Save to Device Option Card
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentNeon.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.download_rounded, color: AppTheme.textDark, size: 24),
                  ),
                  title: const Text(
                    'Export to Device',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Download high-res PNG image to your photo library',
                    style: TextStyle(fontSize: 13, color: AppTheme.textGray),
                  ),
                  trailing: _isSavingDevice
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _isSavingDevice ? null : _handleSaveToDevice,
                ),
              ),
              const SizedBox(height: 12),

              // Save to App Templates & Favorites Option Card
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  leading: const Icon(Icons.cloud_upload_rounded, color: AppTheme.goldAccent, size: 30),
                  title: const Text('Save to App Templates & Favorites', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  subtitle: const Text('Save design project to edit later on Web or Mobile', style: TextStyle(fontSize: 13)),
                  trailing: _isSavingApp
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _isSavingApp ? null : _saveToAppDashboard,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
