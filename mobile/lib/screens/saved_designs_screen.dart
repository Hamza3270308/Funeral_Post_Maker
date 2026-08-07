import 'package:flutter/material.dart';
import '../models/template.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import 'editor_screen.dart';

class SavedDesignsScreen extends StatefulWidget {
  const SavedDesignsScreen({super.key});

  @override
  State<SavedDesignsScreen> createState() => _SavedDesignsScreenState();
}

class _SavedDesignsScreenState extends State<SavedDesignsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<Template> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final templates = await ApiService.fetchTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  String _resolveImageUrl(String url) {
    return ApiService.resolveImageUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Designs & Projects',
          style: TextStyle(
            color: AppTheme.textDark,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentNeon),
            )
          : _hasError
              ? _buildErrorState()
              : _templates.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTemplates,
                  color: AppTheme.accentNeon,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 100), // Extra padding for bottom nav
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return _buildDesignCard(template);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bookmark_border_rounded, size: 64, color: AppTheme.textGray),
          SizedBox(height: 16),
          Text(
            'No Saved Designs Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your custom memorial designs will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.textGray),
          const SizedBox(height: 16),
          const Text(
            'Cannot Connect to Server',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure the backend server is running.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentNeon,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(Template template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Design'),
        content: Text('Are you sure you want to delete "${template.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deleteTemplate(template.id);
      if (success) {
        _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Design deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete design')),
          );
        }
      }
    }
  }

  Widget _buildDesignCard(Template template) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditorScreen(template: template),
          ),
        );
        _loadTemplates(); // Refresh after returning
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Live mini-preview of the actual template design
                  _buildMiniPreview(template),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'READY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _deleteTemplate(template),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edited recently',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Render a live scaled-down preview of the actual template layers
  Widget _buildMiniPreview(Template template) {
    final w = template.width;
    final h = template.height;
    final bg = template.background;

    // Background widget
    Widget backgroundWidget;
    if (bg.type == 'image' && bg.value.isNotEmpty) {
      final resolvedUrl = ApiService.resolveImageUrl(bg.value);
      if (resolvedUrl.startsWith('assets/')) {
        backgroundWidget = Image.asset(
          resolvedUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.white),
        );
      } else {
        backgroundWidget = Image.network(
          resolvedUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.white),
        );
      }
    } else if (bg.type == 'color' && bg.value.startsWith('#')) {
      try {
        var hexStr = bg.value.replaceFirst('#', '');
        if (hexStr.length == 6) {
          hexStr = 'FF$hexStr';
        }
        final color = Color(int.parse(hexStr, radix: 16));
        backgroundWidget = Container(color: color);
      } catch (_) {
        backgroundWidget = Container(color: Colors.white);
      }
    } else {
      backgroundWidget = Container(color: Colors.white);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            Positioned.fill(child: backgroundWidget),
            // Render shape layers
            ...template.shapeLayers.map((layer) {
              final colorStr = layer.color.trim();
              Color fillColor;
              try {
                fillColor = colorStr.startsWith('#')
                    ? Color(int.parse('FF${colorStr.replaceFirst('#', '')}', radix: 16))
                    : const Color(0xFF888888);
              } catch (_) {
                fillColor = const Color(0xFF888888);
              }
              return Positioned(
                left: layer.x * w,
                top: layer.y * h,
                width: layer.width * w,
                height: layer.height * h,
                child: Opacity(
                  opacity: layer.opacity.clamp(0.0, 1.0),
                  child: Container(color: fillColor),
                ),
              );
            }),
            // Render sticker image layers (non-frame)
            ...template.imageLayers.where((l) => l.type == 'sticker').map((layer) {
              final resolvedUrl = ApiService.resolveImageUrl(layer.url);
              Widget imgWidget;
              if (resolvedUrl.startsWith('assets/')) {
                imgWidget = Image.asset(resolvedUrl, fit: BoxFit.fill, errorBuilder: (_, __, ___) => const SizedBox.shrink());
              } else if (resolvedUrl.startsWith('http')) {
                imgWidget = Image.network(resolvedUrl, fit: BoxFit.fill, errorBuilder: (_, __, ___) => const SizedBox.shrink());
              } else {
                return const SizedBox.shrink();
              }
              
              return Positioned(
                left: layer.x * w,
                top: layer.y * h,
                width: layer.width * w,
                height: layer.height * h,
                child: Opacity(
                  opacity: layer.opacity.clamp(0.0, 1.0),
                  child: imgWidget,
                ),
              );
            }),
            // Render text layers (simple preview)
            ...template.textLayers.map((layer) {
              Color textColor;
              try {
                var hexStr = layer.color.replaceFirst('#', '');
                if (hexStr.length == 6) {
                  hexStr = 'FF$hexStr';
                }
                textColor = Color(int.parse(hexStr, radix: 16));
              } catch (_) {
                textColor = Colors.white;
              }
              return Positioned(
                left: layer.x * w,
                top: layer.y * h,
                width: layer.width * w,
                child: Text(
                  layer.textTransform == 'uppercase' ? layer.content.toUpperCase() : layer.content,
                  style: TextStyle(
                    fontSize: layer.fontSize * w,
                    color: textColor,
                    fontWeight: layer.fontWeight == 'bold' ? FontWeight.w700 : FontWeight.w400,
                    height: layer.lineHeight,
                  ),
                  textAlign: layer.alignment == 'center'
                      ? TextAlign.center
                      : (layer.alignment == 'right' ? TextAlign.right : TextAlign.left),
                  overflow: TextOverflow.clip,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

