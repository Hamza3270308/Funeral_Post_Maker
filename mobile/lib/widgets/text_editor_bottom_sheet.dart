import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/template.dart';
import '../theme/theme.dart';

class TextEditorBottomSheet extends StatefulWidget {
  final TextLayer initialLayer;
  final List<String> googleFontsLibrary;
  final Function(TextLayer) onLayerUpdated;

  const TextEditorBottomSheet({
    Key? key,
    required this.initialLayer,
    required this.googleFontsLibrary,
    required this.onLayerUpdated,
  }) : super(key: key);

  @override
  State<TextEditorBottomSheet> createState() => _TextEditorBottomSheetState();
}

class _TextEditorBottomSheetState extends State<TextEditorBottomSheet> {
  late TextLayer _layer;

  final List<String> _colors = [
    '#FFFFFF', // White
    '#000000', // Black
    '#F5F5DC', // Beige
    '#E6DEC9', // Cream
    '#3E2723', // Dark Brown
    '#2D3748', // Slate Blue
    '#8F5D6B', // Burgundy
    '#3E5C76', // Navy Blue
    '#4A5D4E', // Forest Green
    '#8B5E3C', // Autumn Brown
    '#E2E8F0', // Light Grey
  ];

  @override
  void initState() {
    super.initState();
    _layer = widget.initialLayer.copyWith();
  }

  void _updateLayer(TextLayer newLayer) {
    setState(() {
      _layer = newLayer;
    });
    widget.onLayerUpdated(newLayer);
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBold = _layer.fontWeight == 'bold';
    final bool isItalic = _layer.fontStyle == 'italic';
    final bool isUnderline = _layer.textDecoration == 'underline';

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Text Style',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Font Family Dropdown
          const Text('Font Family', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.font_download_outlined, color: AppTheme.textSecondary),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: widget.googleFontsLibrary.contains(_layer.fontFamily) ? _layer.fontFamily : 'Inter',
            isExpanded: true,
            items: widget.googleFontsLibrary.map((font) {
              TextStyle style = const TextStyle();
              if (font == 'Georgia' || font == 'serif') {
                style = const TextStyle(fontFamily: 'serif');
              } else {
                try {
                  style = GoogleFonts.getFont(font);
                } catch (e) {
                  style = const TextStyle(fontFamily: 'sans-serif');
                }
              }
              return DropdownMenuItem(
                value: font,
                child: Text(font, style: style),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                _updateLayer(_layer.copyWith(fontFamily: val));
              }
            },
          ),
          const SizedBox(height: 24),

          // Style Toggles
          const Text('Text Style', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStyleToggle(
                icon: Icons.format_bold,
                isActive: isBold,
                onTap: () => _updateLayer(_layer.copyWith(fontWeight: isBold ? 'normal' : 'bold')),
              ),
              const SizedBox(width: 12),
              _buildStyleToggle(
                icon: Icons.format_italic,
                isActive: isItalic,
                onTap: () => _updateLayer(_layer.copyWith(fontStyle: isItalic ? 'normal' : 'italic')),
              ),
              const SizedBox(width: 12),
              _buildStyleToggle(
                icon: Icons.format_underlined,
                isActive: isUnderline,
                onTap: () => _updateLayer(_layer.copyWith(textDecoration: isUnderline ? 'none' : 'underline')),
              ),
              const Spacer(),
              _buildAlignmentToggle(
                icon: Icons.format_align_left,
                isActive: _layer.alignment == 'left',
                onTap: () => _updateLayer(_layer.copyWith(alignment: 'left')),
              ),
              const SizedBox(width: 8),
              _buildAlignmentToggle(
                icon: Icons.format_align_center,
                isActive: _layer.alignment == 'center',
                onTap: () => _updateLayer(_layer.copyWith(alignment: 'center')),
              ),
              const SizedBox(width: 8),
              _buildAlignmentToggle(
                icon: Icons.format_align_right,
                isActive: _layer.alignment == 'right',
                onTap: () => _updateLayer(_layer.copyWith(alignment: 'right')),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Color Palette
          const Text('Text Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final hex = _colors[index];
                final color = _parseHexColor(hex);
                final isSelected = _layer.color.toUpperCase() == hex.toUpperCase();
                
                return GestureDetector(
                  onTap: () => _updateLayer(_layer.copyWith(color: hex)),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.terracotta : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: AppTheme.terracotta.withOpacity(0.3), blurRadius: 8)
                      ] : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleToggle({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.terracotta.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isActive ? AppTheme.terracotta : AppTheme.borderSoft),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isActive ? AppTheme.terracotta : AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildAlignmentToggle({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey.shade200 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20, color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary),
      ),
    );
  }
}
