import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../widgets/text_editor_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/template.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import 'export_screen.dart';

class EditorScreen extends StatefulWidget {
  final Template template;

  const EditorScreen({super.key, required this.template});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  
  late String _startingLine;
  late String _deceasedName;
  late String _lifespanDates;
  late String _messageContent;
  String? _localPhotoPath;
  bool _isExporting = false;

  late TextEditingController _startingLineController;
  late TextEditingController _nameController;
  late TextEditingController _datesController;
  late TextEditingController _messageController;
  late List<TextLayer> _textLayers;

  String? _nameFontFamily;
  String? _datesFontFamily;

  static const List<String> _googleFontsLibrary = [
    'Inter',
    'Playfair Display',
    'Roboto',
    'Georgia',
    'Cinzel',
    'Lora',
    'Cormorant Garamond',
    'EB Garamond',
    'Merriweather',
    'Great Vibes',
    'Alex Brush',
    'Pinyon Script',
    'Parisienne',
    'Playball',
    'Dancing Script',
    'Montserrat',
    'Lato',
    'Open Sans',
    'Raleway',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize default texts from layers
    _startingLine = widget.template.textLayers.firstWhere(
      (l) => l.id == '1', 
      orElse: () => TextLayer(id: '1', content: 'In Loving Memory Of', fontFamily: 'Inter', fontSize: 16, color: '#000000', alignment: 'center', x: 0, y: 0, width: 200, height: 40, fontWeight: 'normal', fontStyle: 'normal', textDecoration: 'none', opacity: 1.0, rotation: 0.0, hasShadow: false, shadowColor: 'rgba(0,0,0,0.5)', shadowBlur: 4.0)
    ).content;

    _deceasedName = widget.template.textLayers.firstWhere(
      (l) => l.id == '2', 
      orElse: () => TextLayer(id: '2', content: 'John Doe', fontFamily: 'Inter', fontSize: 24, color: '#000000', alignment: 'center', x: 0, y: 0, width: 200, height: 40, fontWeight: 'normal', fontStyle: 'normal', textDecoration: 'none', opacity: 1.0, rotation: 0.0, hasShadow: false, shadowColor: 'rgba(0,0,0,0.5)', shadowBlur: 4.0)
    ).content;

    _lifespanDates = widget.template.textLayers.firstWhere(
      (l) => l.id == 'date', 
      orElse: () => TextLayer(id: 'date', content: 'Sunrise 1950 - Sunset 2024', fontFamily: 'Inter', fontSize: 16, color: '#000000', alignment: 'center', x: 0, y: 0, width: 200, height: 40, fontWeight: 'normal', fontStyle: 'normal', textDecoration: 'none', opacity: 1.0, rotation: 0.0, hasShadow: false, shadowColor: 'rgba(0,0,0,0.5)', shadowBlur: 4.0)
    ).content;

    _messageContent = widget.template.textLayers.firstWhere(
      (l) => l.id == 'message', 
      orElse: () => TextLayer(id: 'message', content: 'You will always be in our hearts.', fontFamily: 'Inter', fontSize: 16, color: '#000000', alignment: 'center', x: 0, y: 0, width: 200, height: 40, fontWeight: 'normal', fontStyle: 'normal', textDecoration: 'none', opacity: 1.0, rotation: 0.0, hasShadow: false, shadowColor: 'rgba(0,0,0,0.5)', shadowBlur: 4.0)
    ).content;

    _startingLineController = TextEditingController(text: _startingLine);
    _nameController = TextEditingController(text: _deceasedName);
    _datesController = TextEditingController(text: _lifespanDates);
    _messageController = TextEditingController(text: _messageContent);

    _textLayers = widget.template.textLayers.map((l) => l.copyWith()).toList();
  }

  @override
  void dispose() {
    _startingLineController.dispose();
    _nameController.dispose();
    _datesController.dispose();
    _messageController.dispose();
    super.dispose();
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

  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('rgba')) {
      try {
        final matches = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)').firstMatch(colorStr);
        if (matches != null) {
          int r = int.parse(matches.group(1)!);
          int g = int.parse(matches.group(2)!);
          int b = int.parse(matches.group(3)!);
          double a = double.parse(matches.group(4)!);
          return Color.fromRGBO(r, g, b, a);
        }
      } catch (e) {}
    }
    return _parseHexColor(colorStr);
  }

  TextStyle _getTextStyle(TextLayer text, double scale, bool isBold, bool isItalic, bool isUnderline) {
    final baseStyle = TextStyle(
      fontSize: text.fontSize * scale,
      color: _parseHexColor(text.color),
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
      shadows: text.hasShadow ? [
        Shadow(
          color: _parseColor(text.shadowColor),
          blurRadius: text.shadowBlur * scale,
          offset: Offset(0, 2 * scale),
        )
      ] : null,
    );

    String family = text.fontFamily;
    
    if (family == 'Georgia' || family == 'serif') {
      return baseStyle.copyWith(fontFamily: 'serif');
    }
    if (family == 'sans-serif') {
      return baseStyle.copyWith(fontFamily: 'sans-serif');
    }

    try {
      return GoogleFonts.getFont(family, textStyle: baseStyle);
    } catch (e) {
      return baseStyle.copyWith(fontFamily: 'sans-serif');
    }
  }

  Gradient? _parseCssGradient(String gradientStr) {
    if (!gradientStr.startsWith('linear-gradient')) return null;
    try {
      final match = RegExp(r'linear-gradient\((\d+)deg,\s*(#[a-fA-F0-9]{6}),\s*(#[a-fA-F0-9]{6})\)').firstMatch(gradientStr);
      if (match != null) {
        final angle = int.parse(match.group(1)!);
        final color1 = _parseHexColor(match.group(2)!);
        final color2 = _parseHexColor(match.group(3)!);
        
        Alignment begin = Alignment.topLeft;
        Alignment end = Alignment.bottomRight;
        
        if (angle >= 0 && angle < 45) {
          begin = Alignment.bottomCenter;
          end = Alignment.topCenter;
        } else if (angle >= 45 && angle < 135) {
          begin = Alignment.bottomLeft;
          end = Alignment.topRight;
        } else if (angle >= 135 && angle < 225) {
          begin = Alignment.topLeft;
          end = Alignment.bottomRight;
        } else if (angle >= 225 && angle < 315) {
          begin = Alignment.topCenter;
          end = Alignment.bottomCenter;
        } else {
          begin = Alignment.topRight;
          end = Alignment.bottomLeft;
        }

        return LinearGradient(
          begin: begin,
          end: end,
          colors: [color1, color2],
        );
      }
    } catch (e) {
      // Fallback to null
    }
    return null;
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://127.0.0.1:5001')) {
      return url.replaceFirst('http://127.0.0.1:5001', ApiService.baseUrl);
    }
    return url;
  }

  void _openTextEditor(String layerId) {
    final layerIndex = _textLayers.indexWhere((l) => l.id == layerId);
    if (layerIndex == -1) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TextEditorBottomSheet(
          initialLayer: _textLayers[layerIndex],
          googleFontsLibrary: _googleFontsLibrary,
          onLayerUpdated: (updatedLayer) {
            setState(() {
              _textLayers[layerIndex] = updatedLayer;
            });
          },
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _localPhotoPath = pickedFile.path;
      });
    }
  }

  Future<void> _shareTribute() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Small delay to ensure any active keyboard is hidden
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Boundary not found');

      final image = await boundary.toImage(pixelRatio: 3.0); // 3x scaling for high quality
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('ByteData is empty');
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/tribute_export.png').create();
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExportScreen(
              imagePath: file.path,
              template: widget.template,
              deceasedName: _deceasedName,
              lifespanDates: _lifespanDates,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // Visual layout mask shape builder
  BorderRadius _getShapeBorderRadius(String shape) {
    if (shape == 'circle' || shape == 'oval') {
      return BorderRadius.circular(1000);
    } else if (shape == 'rounded-rectangle') {
      return BorderRadius.circular(24);
    } else if (shape == 'arch') {
      return const BorderRadius.only(
        topLeft: Radius.circular(150),
        topRight: Radius.circular(150),
      );
    }
    return BorderRadius.zero;
  }

  @override
  Widget build(BuildContext context) {
    // Design sizes default is 1080 width, let's look at template metadata if present
    final double designWidth = widget.template.width > 0 ? widget.template.width : 1080.0;
    final double designHeight = widget.template.height > 0 ? widget.template.height : 1920.0;
    final double designAspectRatio = designWidth / designHeight;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customize Tribute'),
        ),
        body: Column(
          children: [
            // Canvas Preview Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxAvailableWidth = constraints.maxWidth - 32.0;
                  final double maxAvailableHeight = constraints.maxHeight - 32.0;

                  double previewWidth = maxAvailableWidth;
                  double previewHeight = previewWidth / designAspectRatio;

                  if (previewHeight > maxAvailableHeight) {
                    previewHeight = maxAvailableHeight;
                    previewWidth = previewHeight * designAspectRatio;
                  }

                  final double scale = previewWidth / designWidth;

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: Container(
                          width: previewWidth,
                          height: previewHeight,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: widget.template.background.type == 'image' 
                                ? Colors.white 
                                : _parseHexColor(widget.template.background.value),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Background image layer if applicable
                              if (widget.template.background.type == 'image' && widget.template.background.value.startsWith('http'))
                                Positioned.fill(
                                  child: Image.network(
                                    _resolveImageUrl(widget.template.background.value),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.white),
                                  ),
                                ),

                              // Vector shapes layers
                              ...widget.template.shapeLayers.map((shape) {
                                final gradient = _parseCssGradient(shape.color);
                                final isCircle = shape.shape == 'circle';
                                final isTriangle = shape.shape == 'triangle';
                                final isLine = shape.shape == 'line';

                                Widget shapeWidget;
                                if (isTriangle) {
                                  shapeWidget = CustomPaint(
                                    painter: TrianglePainter(
                                      color: gradient == null ? _parseHexColor(shape.color) : _parseHexColor(shape.color),
                                    ),
                                    size: Size(shape.width * scale, shape.height * scale),
                                  );
                                } else if (isLine) {
                                  shapeWidget = Center(
                                    child: Container(
                                      height: (shape.borderWidth > 0 ? shape.borderWidth : 4.0) * scale,
                                      color: _parseHexColor(shape.color),
                                    ),
                                  );
                                } else {
                                  shapeWidget = Container(
                                    decoration: BoxDecoration(
                                      color: gradient == null ? _parseHexColor(shape.color) : null,
                                      gradient: gradient,
                                      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                                      borderRadius: isCircle ? null : _getShapeBorderRadius(shape.shape),
                                      border: shape.borderWidth > 0
                                          ? Border.all(
                                              color: _parseHexColor(shape.borderColor),
                                              width: shape.borderWidth * scale,
                                            )
                                          : null,
                                    ),
                                  );
                                }

                                return Positioned(
                                  left: shape.x * scale,
                                  top: shape.y * scale,
                                  width: shape.width * scale,
                                  height: shape.height * scale,
                                  child: Transform.rotate(
                                    angle: (shape.rotation * math.pi) / 180,
                                    child: Opacity(
                                      opacity: shape.opacity,
                                      child: shapeWidget,
                                    ),
                                  ),
                                );
                              }),

                              // Image frames and photo slots
                              ...widget.template.imageLayers.map((img) {
                                final isCircle = img.maskShape == 'circle';
                                return Positioned(
                                  left: img.x * scale,
                                  top: img.y * scale,
                                  width: img.width * scale,
                                  height: img.height * scale,
                                  child: Transform.rotate(
                                    angle: (img.rotation * math.pi) / 180,
                                    child: Opacity(
                                      opacity: img.opacity,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                                          borderRadius: isCircle ? null : _getShapeBorderRadius(img.maskShape),
                                          border: img.borderWidth > 0
                                              ? Border.all(
                                                  color: _parseHexColor(img.borderColor),
                                                  width: img.borderWidth * scale,
                                                )
                                              : null,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: _localPhotoPath != null
                                            ? Image.file(
                                                File(_localPhotoPath!),
                                                fit: BoxFit.cover,
                                              )
                                            : (img.url.startsWith('http')
                                                ? Image.network(
                                                    _resolveImageUrl(img.url),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(color: AppTheme.borderSoft),
                                                  )
                                                : Container(
                                                    color: AppTheme.borderSoft,
                                                    child: const Icon(
                                                      Icons.person_rounded,
                                                      color: AppTheme.textSecondary,
                                                      size: 40,
                                                    ),
                                                  )),
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // Text layers (name and dates are dynamically updated by local states)
                              ..._textLayers.map((text) {
                                // Dynamically replace default texts with customized user inputs
                                // Dynamically replace default texts with customized user inputs
                                String displayContent = text.content;
                                if (text.id == '1') {
                                  displayContent = _startingLine;
                                } else if (text.id == '2') {
                                  displayContent = _deceasedName;
                                } else if (text.id == 'date') {
                                  displayContent = _lifespanDates;
                                } else if (text.id == 'message') {
                                  displayContent = _messageContent;
                                }

                                final isBold = text.fontWeight == 'bold';
                                final isItalic = text.fontStyle == 'italic';
                                final isUnderline = text.textDecoration == 'underline';

                                final isAutoWidth = text.width < 150;
                                final double? renderWidth = isAutoWidth ? null : text.width * scale;
                                final double? renderHeight = isAutoWidth ? null : text.height * scale;

                                return Positioned(
                                  left: text.x * scale,
                                  top: text.y * scale,
                                  width: renderWidth,
                                  child: Transform.rotate(
                                    angle: (text.rotation * math.pi) / 180,
                                    child: Opacity(
                                      opacity: text.opacity,
                                      child: isAutoWidth
                                          ? Text(
                                              displayContent,
                                              textAlign: text.alignment == 'left'
                                                  ? TextAlign.left
                                                  : text.alignment == 'right'
                                                      ? TextAlign.right
                                                      : TextAlign.center,
                                              style: _getTextStyle(text, scale, isBold, isItalic, isUnderline),
                                            )
                                          : SizedBox(
                                              width: renderWidth,
                                              child: Align(
                                                alignment: text.alignment == 'left'
                                                    ? Alignment.centerLeft
                                                    : text.alignment == 'right'
                                                        ? Alignment.centerRight
                                                        : Alignment.center,
                                                child: Text(
                                                  displayContent,
                                                  textAlign: text.alignment == 'left'
                                                      ? TextAlign.left
                                                      : text.alignment == 'right'
                                                          ? TextAlign.right
                                                          : TextAlign.center,
                                                  style: _getTextStyle(text, scale, isBold, isItalic, isUnderline),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Editor Form Panel
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Row for Photo Upload Button
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.sunlitCream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _localPhotoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_localPhotoPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.photo_library_rounded,
                              color: AppTheme.terracotta,
                            ),
                    ),
                    title: const Text(
                      'Cherished Photograph',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Choose a photo to insert into the frame',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      onPressed: _pickPhoto,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Choose'),
                    ),
                  ),
                  const Divider(color: AppTheme.borderSoft),
                  const SizedBox(height: 12),

                  // Starting Line Field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Starting Line",
                            prefixIcon: Icon(Icons.format_quote_rounded, color: AppTheme.textSecondary),
                          ),
                          controller: _startingLineController,
                          onChanged: (val) {
                            setState(() {
                              _startingLine = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _openTextEditor('1'),
                        icon: const Icon(Icons.format_paint_rounded, color: AppTheme.terracotta),
                        tooltip: 'Edit Style',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.terracotta.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Deceased's Name",
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textSecondary),
                          ),
                          controller: _nameController,
                          onChanged: (val) {
                            setState(() {
                              _deceasedName = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _openTextEditor('2'),
                        icon: const Icon(Icons.format_paint_rounded, color: AppTheme.terracotta),
                        tooltip: 'Edit Style',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.terracotta.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dates Field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Lifespan Dates",
                            prefixIcon: Icon(Icons.calendar_month_outlined, color: AppTheme.textSecondary),
                          ),
                          controller: _datesController,
                          onChanged: (val) {
                            setState(() {
                              _lifespanDates = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _openTextEditor('date'),
                        icon: const Icon(Icons.format_paint_rounded, color: AppTheme.terracotta),
                        tooltip: 'Edit Style',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.terracotta.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Message Field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Tribute Message",
                            prefixIcon: Icon(Icons.message_outlined, color: AppTheme.textSecondary),
                          ),
                          controller: _messageController,
                          maxLines: 3,
                          minLines: 1,
                          onChanged: (val) {
                            setState(() {
                              _messageContent = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _openTextEditor('message'),
                        icon: const Icon(Icons.format_paint_rounded, color: AppTheme.terracotta),
                        tooltip: 'Edit Style',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.terracotta.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Export Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isExporting ? null : _shareTribute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.terracotta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isExporting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward_rounded),
                                SizedBox(width: 8),
                                Text(
                                  'Generate Tribute & Export',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                  ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
