import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/template.dart';
import '../models/memorial_element.dart';
import '../data/memorial_elements_library.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import 'export_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_settings_service.dart';
enum SelectedElementType {
  none,
  photo,
  header,
  name,
  dates,
  tribute,
  overlay,
  templateImage,
  shape,
}

enum ActiveTrayType {
  none,
  templates,
  verses,
  flowers,
  text,       // Item 7: Scrollable Canva Typography suite
  frame,      // Item 8: Custom uploaded frame border
  photo,      // Compact Photo Tray (~13% height)
  background, // Item 10: Dedicated Background Tray
  overlay,    // Added overlay tray
  fonts,
  colors,
  theme,      // Item 5 & 9: Snug Theme tray with Custom Color picker
}

class TextLayerStyle {
  String font;
  Color color;
  double size;
  bool bold;
  bool italic;
  bool underline;
  bool uppercase;
  double letterSpacing;
  double lineHeight;
  bool shadow;
  TextAlign align;

  TextLayerStyle({
    required this.font,
    required this.color,
    required this.size,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.uppercase = false,
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.shadow = false,
    this.align = TextAlign.center,
  });
}

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
  String? _localBackgroundPath;    // Item 10: Uploaded Custom Background
  String? _customFrameImagePath;   // Item 8: Uploaded Custom Frame
  bool _isExporting = false;
  bool _isLayersPanelOpen = false;

  // Item 11: Design Title with Rename capability
  String _designTitle = 'Editing Studio';

  // Selected element state
  SelectedElementType _selectedType = SelectedElementType.none;
  String? _selectedOverlayId;

  // Active Tray State
  ActiveTrayType _activeTray = ActiveTrayType.none;

  // UNDO/REDO STATE
  final List<EditorStateSnapshot> _history = [];
  int _historyIndex = -1;

  void _saveState() {
    // If we're not at the end of the history (i.e. we undid something and are now making a new change),
    // we must discard all future redo states.
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    _history.add(EditorStateSnapshot(
      templateJson: widget.template.toJson(),
      overlayItems: _overlayItems.map((item) => item.clone()).toList(),
      frameShapeIndex: _frameShapeIndex,
      customFrameImagePath: _customFrameImagePath,
      localBackgroundPath: _localBackgroundPath,
      localPhotoPath: _localPhotoPath,
    ));
    _historyIndex++;
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _restoreState(_history[_historyIndex]);
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _restoreState(_history[_historyIndex]);
      });
    }
  }

  void _restoreState(EditorStateSnapshot snapshot) {
    // We update the template fields manually to trigger a re-render without breaking references if needed,
    // or just re-assign the template objects by parsing the json.
    final restoredTemplate = Template.fromJson(snapshot.templateJson);
    widget.template.textLayers.clear();
    widget.template.textLayers.addAll(restoredTemplate.textLayers);
    widget.template.imageLayers.clear();
    widget.template.imageLayers.addAll(restoredTemplate.imageLayers);
    widget.template.shapeLayers.clear();
    widget.template.shapeLayers.addAll(restoredTemplate.shapeLayers);

    _overlayItems.clear();
    _overlayItems.addAll(snapshot.overlayItems.map((item) => item.clone()));
    _frameShapeIndex = snapshot.frameShapeIndex;
    _customFrameImagePath = snapshot.customFrameImagePath;
    _localBackgroundPath = snapshot.localBackgroundPath;
    _localPhotoPath = snapshot.localPhotoPath;

    // Sync local text strings
    final layers = widget.template.textLayers;
    _startingLine = layers.isNotEmpty ? layers[0].content : '';
    _deceasedName = layers.length > 1 ? layers[1].content : '';
    _lifespanDates = layers.length > 2 ? layers[2].content : '';
    _messageContent = layers.length > 3 ? layers[3].content : '';
    
    // Update text controller if something is selected
    if (_selectedType == SelectedElementType.header) _textEditingController.text = _startingLine;
    if (_selectedType == SelectedElementType.name) _textEditingController.text = _deceasedName;
    if (_selectedType == SelectedElementType.dates) _textEditingController.text = _lifespanDates;
    if (_selectedType == SelectedElementType.tribute) _textEditingController.text = _messageContent;

    // We may need to re-derive text styles based on the restored template
    _rebuildTextStyles();
    
    // Unselect if the selected item no longer exists
    if (_selectedType == SelectedElementType.overlay && !_overlayItems.any((i) => i.id == _selectedOverlayId)) {
      _deselectAll();
    }
  }

  void _rebuildTextStyles() {
    // FIX #6 logic duplicated for restore
    final layers = widget.template.textLayers;
    TextLayerStyle styleFromLayer(TextLayer l) {
      Color col = Colors.white;
      try {
        final hex = l.color.replaceFirst('#', '');
        col = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
      final displaySize = (l.fontSize * 1080).clamp(12.0, 64.0);
      return TextLayerStyle(
        font: l.fontFamily.isNotEmpty ? l.fontFamily : 'Inter',
        color: col,
        size: displaySize,
        bold: l.fontWeight == 'bold',
        italic: l.fontStyle == 'italic',
        underline: l.textDecoration == 'underline',
        uppercase: l.textTransform == 'uppercase',
        letterSpacing: l.letterSpacing,
        lineHeight: l.lineHeight,
        shadow: l.hasShadow,
        align: l.alignment == 'center'
            ? TextAlign.center
            : (l.alignment == 'right' ? TextAlign.right : TextAlign.left),
      );
    }

    _textStyles = {
      SelectedElementType.header: layers.isNotEmpty
          ? styleFromLayer(layers[0])
          : TextLayerStyle(font: 'Cinzel', color: const Color(0xFF1B2430), size: 18.0, bold: true),
      SelectedElementType.name: layers.length > 1
          ? styleFromLayer(layers[1])
          : TextLayerStyle(font: 'Great Vibes', color: const Color(0xFF1B2430), size: 38.0, bold: true),
      SelectedElementType.dates: layers.length > 2
          ? styleFromLayer(layers[2])
          : TextLayerStyle(font: 'Cinzel', color: const Color(0xFF3B4856), size: 16.0),
      SelectedElementType.tribute: layers.length > 3
          ? styleFromLayer(layers[3])
          : TextLayerStyle(font: 'Inter', color: const Color(0xFF2C353F), size: 14.0, lineHeight: 1.4),
    };
  }

  // Controller for live Text Editing
  final TextEditingController _textEditingController = TextEditingController();

  // Added Flowers & Graphics on canvas
  final List<CanvasOverlayItem> _overlayItems = [];

  // Frame shape for photo:
  // 0 = Circle, 1 = Oval, 2 = Rounded Square, 3 = Arch, 4 = Soft Hex, 5 = Custom Uploaded Frame
  int _frameShapeIndex = 0;
  double _customBorderRadius = 32.0;

  // Vibrant Lime Green / Neon Chartreuse Accent from user screenshot
  static const Color _limeAccent = Color(0xFFBAFF00);
  static const Color _darkBlack = Color(0xFF0F172A);

  // All 35 Web Dashboard Google Fonts
  static const List<String> allWebGoogleFonts = [
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
    'Bodoni Moda',
    'Cinzel Decorative',
    'Cormorant Infant',
    'Crimson Text',
    'Marcellus',
    'Montserrat Alternates',
    'Cardo',
    'Italiana',
    'Prata',
    'Allura',
    'Sacramento',
    'WindSong',
    'Reenie Beanie',
    'Satisfy',
    'Petit Formal Script',
    'Rouge Script',
  ];

  late Map<SelectedElementType, TextLayerStyle> _textStyles;
  TextLayer? _activeTextLayer;
  
  // Gesture scale state variables
  double _baseScale = 1.0;
  double _baseWidth = 0.5;
  double _baseHeight = 0.5;

  // Current theme palette background tint (off-white cream default)
  Color _canvasBgTint = const Color(0xFFFAF9F6);

  @override
  void initState() {
    super.initState();
    if (widget.template.title.isNotEmpty) {
      _designTitle = widget.template.title;
    }
    final layers = widget.template.textLayers;
    _startingLine = layers.isNotEmpty ? layers[0].content : 'IN LOVING MEMORY';
    _deceasedName = layers.length > 1 ? layers[1].content : 'Olivia Wilson';
    _lifespanDates = layers.length > 2 ? layers[2].content : 'July 14, 1968 - August 09, 2030';
    _messageContent = layers.length > 3
        ? layers[3].content
        : 'May your soul find eternal peace, and may your light continue to shine in our hearts forever.';

    // FIX #6: Build _textStyles from actual DB layer values, not hardcoded defaults
    TextLayerStyle _styleFromLayer(TextLayer l) {
      Color col = Colors.white;
      try {
        final hex = l.color.replaceFirst('#', '');
        col = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
      // l.fontSize is a normalized fraction (e.g. 0.074 = 7.4% of canvas width).
      // Convert to a display point size clamped to the slider range (12–64pt).
      // We use a reference canvas width of 1080px for consistency.
      final displaySize = (l.fontSize * 1080).clamp(12.0, 64.0);
      return TextLayerStyle(
        font: l.fontFamily.isNotEmpty ? l.fontFamily : 'Inter',
        color: col,
        size: displaySize,
        bold: l.fontWeight == 'bold',
        italic: l.fontStyle == 'italic',
        underline: l.textDecoration == 'underline',
        uppercase: l.textTransform == 'uppercase',
        letterSpacing: l.letterSpacing,
        lineHeight: l.lineHeight,
        shadow: l.hasShadow,
        align: l.alignment == 'center'
            ? TextAlign.center
            : (l.alignment == 'right' ? TextAlign.right : TextAlign.left),
      );
    }

    _textStyles = {
      SelectedElementType.header: layers.isNotEmpty
          ? _styleFromLayer(layers[0])
          : TextLayerStyle(font: 'Cinzel', color: const Color(0xFF1B2430), size: 18.0, bold: true),
      SelectedElementType.name: layers.length > 1
          ? _styleFromLayer(layers[1])
          : TextLayerStyle(font: 'Great Vibes', color: const Color(0xFF1B2430), size: 38.0, bold: true),
      SelectedElementType.dates: layers.length > 2
          ? _styleFromLayer(layers[2])
          : TextLayerStyle(font: 'Cinzel', color: const Color(0xFF3B4856), size: 16.0),
      SelectedElementType.tribute: layers.length > 3
          ? _styleFromLayer(layers[3])
          : TextLayerStyle(font: 'Inter', color: const Color(0xFF2C353F), size: 14.0, lineHeight: 1.4),
    };

    // FIX #14: Pre-load all Google Fonts used in this template to avoid flicker
    final usedFonts = layers.map((l) => l.fontFamily).toSet();
    for (final fontName in usedFonts) {
      try {
        GoogleFonts.getFont(fontName); // triggers async font load
      } catch (_) {} // not a Google Font — fine
    }

    // Initialize portrait frame shape from saved maskShape in DB
    final frameLayer = widget.template.imageLayers
        .where((l) => l.type == 'frame')
        .cast<ImageLayer?>()
        .firstWhere((_) => true, orElse: () => null);
    if (frameLayer != null) {
      switch (frameLayer.maskShape) {
        case 'circle': _frameShapeIndex = 0; break;
        case 'rounded_rect': _frameShapeIndex = 2; break;
        default: _frameShapeIndex = 2; break;
      }
    }

    // Restore stickers from imageLayers back to _overlayItems
    final stickerLayers = widget.template.imageLayers.where((l) => l.type == 'sticker').toList();
    for (var layer in stickerLayers) {
      if (layer.url.isNotEmpty) {
        final filename = layer.url.split('/').last;
        final graphic = MemorialElementsLibrary.graphics.firstWhere(
          (g) => g.imageFile == filename,
          orElse: () => MemorialElementsLibrary.graphics.first, // fallback
        );
        _overlayItems.add(CanvasOverlayItem(
          id: layer.id,
          graphic: graphic,
          position: Offset(layer.x * widget.template.width, layer.y * widget.template.height),
          scale: layer.width / 0.9,
          rotation: layer.rotation,
          opacity: layer.opacity,
          color: graphic.defaultColor,
          zIndex: layer.zIndex,
        ));
      }
    }
    widget.template.imageLayers.removeWhere((l) => l.type == 'sticker');
    
    // Save initial state for undo system
    _saveState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _deselectAll() {
    setState(() {
      _selectedType = SelectedElementType.none;
      _selectedOverlayId = null;
      _activeTray = ActiveTrayType.none;
    });
    FocusScope.of(context).unfocus();
  }

  void _deleteSelectedElement() {
    setState(() {
      if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
        _overlayItems.removeWhere((i) => i.id == _selectedOverlayId);
      } else if (_selectedType == SelectedElementType.templateImage && _selectedOverlayId != null) {
        widget.template.imageLayers.removeWhere((i) => i.id == _selectedOverlayId);
      } else if (_selectedType == SelectedElementType.header || 
                 _selectedType == SelectedElementType.name ||
                 _selectedType == SelectedElementType.dates ||
                 _selectedType == SelectedElementType.tribute) {
        
        TextLayer? targetLayer = _activeTextLayer;
        if (targetLayer == null) {
          if (_selectedType == SelectedElementType.header && widget.template.textLayers.isNotEmpty) targetLayer = widget.template.textLayers[0];
          else if (_selectedType == SelectedElementType.name && widget.template.textLayers.length > 1) targetLayer = widget.template.textLayers[1];
          else if (_selectedType == SelectedElementType.dates && widget.template.textLayers.length > 2) targetLayer = widget.template.textLayers[2];
          else if (_selectedType == SelectedElementType.tribute && widget.template.textLayers.length > 3) targetLayer = widget.template.textLayers[3];
        }

        if (targetLayer != null) {
           widget.template.textLayers.remove(targetLayer);
        }

        if (_selectedType == SelectedElementType.header) _startingLine = '';
        if (_selectedType == SelectedElementType.name) _deceasedName = '';
        if (_selectedType == SelectedElementType.dates) _lifespanDates = '';
        if (_selectedType == SelectedElementType.tribute) _messageContent = '';
        
      } else if (_selectedType == SelectedElementType.photo) {
        _localPhotoPath = null;
        _customFrameImagePath = null;
        widget.template.imageLayers.removeWhere((l) => l.type == 'frame');
        _frameShapeIndex = 0;
      }
      _selectedType = SelectedElementType.none;
      _selectedOverlayId = null;
      _activeTextLayer = null;
      _activeTray = ActiveTrayType.none;
    });
    _saveState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Element deleted'), duration: Duration(seconds: 1)),
    );
  }

  // Item 11: Rename Design Dialog
  void _showRenameDialog() {
    final c = TextEditingController(text: _designTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Memorial Design', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: c,
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
                if (c.text.trim().isNotEmpty) {
                  _designTitle = c.text.trim();
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _limeAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // Item 9: Pick Custom Background Tint Color
  // Item 9: Pick Custom Background Tint Color with RGB Sliders
  void _showCustomColorPicker() {
    int r = 255;
    int g = 255;
    int b = 255;
    
    if (widget.template.background.type == 'color') {
      try {
        final hex = widget.template.background.value;
        final col = _parseHexColor(hex);
        r = col.red;
        g = col.green;
        b = col.blue;
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentColor = Color.fromARGB(255, r, g, b);
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Choose Canvas Color', style: TextStyle(fontWeight: FontWeight.w800, color: _darkBlack)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    pickerColor: currentColor,
                    onColorChanged: (color) {
                      setDialogState(() {
                        r = color.red;
                        g = color.green;
                        b = color.blue;
                      });
                    },
                    colorPickerWidth: 300.0,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: false,
                    displayThumbColor: true,
                    showLabel: true,
                    paletteType: PaletteType.hsvWithHue,
                    pickerAreaBorderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2.0),
                      topRight: Radius.circular(2.0),
                    ),
                  ),

                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.template.background.type = 'color';
                    widget.template.background.value = '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}${g.toRadixString(16).padLeft(2, '0').toUpperCase()}${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
                    _localBackgroundPath = null;
                  });
                  _saveState();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _limeAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: _darkBlack, width: 1.5),
                  ),
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Toggle tray off when clicking the same option again
  void _toggleTray(ActiveTrayType type) {
    setState(() {
      if (_activeTray == type) {
        _activeTray = ActiveTrayType.none;
      } else {
        _activeTray = type;
        if (type == ActiveTrayType.text) {
          // If we open the text tray from the dock, assume it's to add new text
          _activeTextLayer = null;
          _selectedType = SelectedElementType.none;
          _messageContent = '';
          _textEditingController.clear();
          // Automatically create a new text box for them
          _updateActiveTextProperty((l) {}, insertIfMissing: true);
        }
      }
    });
  }

  // Add a Flower or Graphic sticker to canvas
  void _addOverlayGraphic(MemorialGraphic g) {
    final w = widget.template.width;
    final h = widget.template.height;
    // Fix scaling math: default should be 1.0. 
    // And since it renders at `w * 0.9 * scale`, a default scale of ~0.44 gives ~40% canvas width.
    final defaultScale = g.isImageOverlay ? 0.45 : 1.0;
    
    final newItem = CanvasOverlayItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      graphic: g,
      position: g.isImageOverlay
          ? Offset(w * 0.05, h * 0.05)
          : const Offset(80, 80),
      scale: defaultScale,
      rotation: 0.0,
      color: g.defaultColor,
    );
    
    setState(() {
      if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
        // Replace the currently selected flower instead of piling them up
        final existingIndex = _overlayItems.indexWhere((i) => i.id == _selectedOverlayId);
        if (existingIndex != -1) {
          final oldItem = _overlayItems[existingIndex];
          newItem.position = oldItem.position;
          newItem.scale = oldItem.scale;
          _overlayItems[existingIndex] = newItem;
        } else {
          _overlayItems.add(newItem);
        }
      } else {
        _overlayItems.add(newItem);
      }
      
      _selectedType = SelectedElementType.overlay;
      _selectedOverlayId = newItem.id;
      // Change to the new overlay tray (Item 10 -> ActiveTrayType.overlay)
      // We will build this new tray to have the size slider
      _activeTray = ActiveTrayType.overlay;
    });
    _saveState();
  }

  CanvasOverlayItem? get _currentOverlay {
    if (_selectedOverlayId == null) return null;
    try {
      return _overlayItems.firstWhere((i) => i.id == _selectedOverlayId);
    } catch (_) {
      return null;
    }
  }

  // Pick photo from gallery
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image != null) {
      setState(() {
        _localPhotoPath = image.path;
      });
      _saveState();
    }
  }

  // Item 10: Pick Custom Background Photo from gallery
  Future<void> _pickBackgroundPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image != null) {
      setState(() {
        _localBackgroundPath = image.path;
      });
      _saveState();
    }
  }

  // Item 8: Pick Custom Frame PNG from gallery
  Future<void> _pickCustomFrameImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image != null) {
      setState(() {
        _customFrameImagePath = image.path;
        _frameShapeIndex = 5; // Switch to custom frame
      });
      _saveState();
    }
  }

  // Export & Share full canvas at 3x resolution
  Future<void> _exportAndShare() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showGuestLoginDialog();
      return;
    }

    _deselectAll();
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() => _isExporting = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData?.buffer.asUint8List();

      if (buffer != null) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/memorial_post_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(buffer);

        if (mounted) {
          // Sync overlays to image layers as stickers so they save to the backend
          final w = widget.template.width.toDouble();
          final h = widget.template.height.toDouble();
          
          final List<ImageLayer> stickerLayers = _overlayItems.map<ImageLayer>((item) {
            final isImage = item.graphic.isImageOverlay;
            final layerW = isImage ? 0.9 * item.scale : (item.graphic.defaultSize * item.scale) / w;
            final layerH = isImage ? 0.9 * item.scale : (item.graphic.defaultSize * item.scale) / h;
            return ImageLayer(
              id: item.id,
              type: 'sticker',
              url: item.graphic.imageFile != null ? '/flowers/${item.graphic.imageFile}' : '',
              maskShape: 'none',
              x: item.position.dx / w,
              y: item.position.dy / h,
              width: layerW,
              height: layerH,
              rotation: item.rotation,
              opacity: item.opacity,
              borderWidth: 0.0,
              borderColor: '#000000',
              zIndex: item.zIndex,
            );
          }).toList();
          
          widget.template.imageLayers.removeWhere((l) => l.type == 'sticker');
          widget.template.imageLayers.addAll(stickerLayers);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExportScreen(
                imagePath: filePath,
                template: widget.template,
                deceasedName: _deceasedName,
                lifespanDates: _lifespanDates,
                designTitle: _designTitle, // Item 11: Pass editable title
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showGuestLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign In Required', style: TextStyle(color: Colors.white)),
        content: Text(
          'Guests can explore and edit, but downloading designs requires a Google account.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isExporting = true);
              final credential = await AuthService.instance.signInWithGoogle();
              setState(() => _isExporting = false);
              
              if (credential != null) {
                await UserSettingsService.instance.setGuest(false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully signed in! You can now download your design.')),
                  );
                }
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.g_mobiledata, size: 24),
                const SizedBox(width: 4),
                const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Item 5: Content-Adaptive Dynamic Tray Heights (snug fit, no bottom empty space!)
  double _getTrayHeight(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    switch (_activeTray) {
      case ActiveTrayType.photo:
      case ActiveTrayType.background:
        return 110.0; // Compact ~13% height!
      case ActiveTrayType.frame:
        return _frameShapeIndex == 5 ? 160.0 : 110.0; // Adapt for custom upload button
      case ActiveTrayType.templates:
      case ActiveTrayType.colors:
      case ActiveTrayType.overlay:
        return 135.0; // Compact ~16% height!
      case ActiveTrayType.theme:
        return 175.0; // Item 5: Snug height for 16 swatches + Custom Color button
      case ActiveTrayType.text:
        return 260.0; // Item 7: Proportioned height for Scrollable Canva Typography Suite
      case ActiveTrayType.verses:
      case ActiveTrayType.flowers:
      case ActiveTrayType.fonts:
        return h * 0.28; // Standard scrollable list height
      case ActiveTrayType.none:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false, // FIX #11: handle bottom inset manually on the dock
        child: Column(
          children: [
            _buildTopStudioHeader(),
            
            // ADVANCED SECONDARY TOOLBAR
            if (_selectedType != SelectedElementType.none && !_isLayersPanelOpen)
              _buildSecondaryToolbar(),
            
            // TOP CANVAS WORKSPACE
            Expanded(
              child: GestureDetector(
                onTap: _deselectAll,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubicEmphasized,
                  // FIX #4: _canvasBgTint belongs on the workspace area, not the canvas itself
                  color: _canvasBgTint,
                  padding: EdgeInsets.symmetric(
                    horizontal: _activeTray != ActiveTrayType.none ? 8 : 10,
                    vertical: _activeTray != ActiveTrayType.none ? 6 : 14,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: widget.template.width.toDouble(),
                      height: widget.template.height.toDouble(),
                      child: _buildFullCanvasWorkspace(),
                    ),
                  ),
                ),
              ),
            ),
            
            // DYNAMIC LAYERS PANEL OR STANDARD DOCK
            if (_isLayersPanelOpen)
              SizedBox(
                // Ensure exactly 45% of screen height
                height: MediaQuery.of(context).size.height * 0.45,
                child: _buildLayersPanel(),
              )
            else ...[
              // DYNAMIC CONTENT-ADAPTIVE TRAY OR STANDARD DOCK
              if (_activeTray != ActiveTrayType.none) _buildActiveTrayPanel(),
              Padding(
                // 96px bottom offset keeps the dock above the home screen's
                // floating nav bar (70px height + 24px bottom offset = 94px).
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 94,
                ),
                child: _buildMainStudioDock(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // TOP STUDIO NAVBAR (Crisp Light Theme + Item 1 Delete + Item 11 Rename)
  Widget _buildTopStudioHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkBlack, size: 18),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                // Item 11: Tappable Design Title with Pencil Rename Icon
                Flexible(
                  child: InkWell(
                    onTap: _showRenameDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _designTitle,
                              style: const TextStyle(
                                color: _darkBlack,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, color: _darkBlack, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item 1: Prominent Canva-Style Delete Button when an element is selected
              if (_selectedType != SelectedElementType.none)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  tooltip: 'Delete Selected Element',
                  onPressed: _deleteSelectedElement,
                ),
              IconButton(
                icon: Icon(Icons.undo_rounded, color: _historyIndex > 0 ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1), size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                onPressed: _historyIndex > 0 ? _undo : null,
              ),
              IconButton(
                icon: Icon(Icons.redo_rounded, color: _historyIndex < _history.length - 1 ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1), size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                onPressed: _historyIndex < _history.length - 1 ? _redo : null,
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportAndShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _limeAccent, // Vibrant Lime Green Accent
                  foregroundColor: Colors.black, // Crisp Black Text
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: _darkBlack, width: 1.5),
                  ),
                ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 16),
                label: const Text(
                  'Share',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // FIX #4 + #12: Canvas is transparent — background comes from _buildTemplateBackground.
  // Double FittedBox removed — outer build() already sizes and scales via FittedBox+SizedBox.
  Widget _buildFullCanvasWorkspace() {
    final renderWidth = widget.template.width;
    final renderHeight = widget.template.height;

    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        // No explicit width/height: parent SizedBox(1080,1920) + outer FittedBox handles sizing
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(child: _buildTemplateBackground()),
            ..._buildSortedLayers(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSortedLayers() {
    final allLayers = <Map<String, dynamic>>[];
    for (var layer in widget.template.imageLayers) {
      if (!layer.hidden) allLayers.add({'zIndex': layer.zIndex, 'widget': _buildImageLayer(layer)});
    }
    for (var layer in widget.template.shapeLayers) {
      if (!layer.hidden) allLayers.add({'zIndex': layer.zIndex, 'widget': _buildShapeLayer(layer)});
    }
    for (var layer in widget.template.textLayers) {
      if (!layer.hidden) allLayers.add({'zIndex': layer.zIndex, 'widget': _buildSelectableText(layer: layer)});
    }
    for (var layer in _overlayItems) {
      if (!layer.hidden) allLayers.add({'zIndex': layer.zIndex, 'widget': _buildSingleOverlayWidget(layer)});
    }
    
    allLayers.sort((a, b) => (a['zIndex'] as int).compareTo(b['zIndex'] as int));
    return allLayers.map((e) => e['widget'] as Widget).toList();
  }

  // Item 10: Supports both template background and user-uploaded custom background photo
  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }

  // ROUTE IMAGE LAYERS: portrait frames go to _buildSelectablePhoto, stickers are rendered directly
  Widget _buildImageLayer(ImageLayer layer) {
    if (layer.type == 'frame') {
      return _buildSelectablePhoto(layer: layer);
    }
    // Sticker: resolve URL and render a positioned image
    final w = widget.template.width;
    final h = widget.template.height;
    final resolvedUrl = ApiService.resolveImageUrl(layer.url);

    Widget imageWidget;
      if (resolvedUrl.startsWith('data:image/svg+xml')) {
      // SVG data URI: decode from base64 after the comma
      try {
        final base64Str = resolvedUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          color: layer.mixBlendMode == 'multiply' ? Colors.black.withOpacity(0.0) : null,
          colorBlendMode: layer.mixBlendMode == 'multiply' ? BlendMode.multiply : null,
        );
      } catch (_) {
        imageWidget = const SizedBox.shrink();
      }
    } else if (resolvedUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        resolvedUrl,
        fit: BoxFit.fill,
        color: layer.mixBlendMode == 'multiply' ? Colors.black.withOpacity(0.0) : null,
        colorBlendMode: layer.mixBlendMode == 'multiply' ? BlendMode.multiply : null,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } else if (resolvedUrl.startsWith('http')) {
      imageWidget = Image.network(
        resolvedUrl,
        fit: BoxFit.fill, // Match web dashboard's objectFit: 'fill' to preserve layout
        color: layer.mixBlendMode == 'multiply' ? Colors.black.withOpacity(0.0) : null,
        colorBlendMode: layer.mixBlendMode == 'multiply' ? BlendMode.multiply : null,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } else {
      imageWidget = const SizedBox.shrink();
    }

    imageWidget = Opacity(
      opacity: layer.opacity,
      child: Transform.scale(
        scaleX: layer.flipHorizontal ? -1.0 : 1.0,
        scaleY: layer.flipVertical ? -1.0 : 1.0,
        child: imageWidget,
      ),
    );

    final isSelected = _selectedType == SelectedElementType.templateImage && _selectedOverlayId == layer.id && !layer.locked;

    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      height: layer.height * h,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedType == SelectedElementType.templateImage && _selectedOverlayId == layer.id) {
              _selectedType = SelectedElementType.none;
              _selectedOverlayId = null;
            } else {
              _selectedType = SelectedElementType.templateImage;
              _selectedOverlayId = layer.id;
            }
          });
        },
        onScaleStart: (details) {
          _handleScaleStart(layer, details);
        },
        onScaleUpdate: (details) {
          _handleScaleUpdate(layer, details, w, h);
        },
        onScaleEnd: (details) {
          _handleScaleEnd(layer, details);
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: _limeAccent, width: 2.5),
                  borderRadius: BorderRadius.circular(8),
                  color: _limeAccent.withOpacity(0.12),
                )
              : null,
          child: Opacity(
            opacity: layer.opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: layer.rotation * (3.14159 / 180),
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeLayer(ShapeLayer layer) {
    final w = widget.template.width;
    final h = widget.template.height;

    final colorStr = layer.color.trim();
    BoxDecoration decoration;

    if (colorStr.startsWith('linear-gradient')) {
      final match = RegExp(r'linear-gradient\((\d+)deg,\s*(#[0-9a-fA-F]{6}),\s*(#[0-9a-fA-F]{6}|transparent)\)')
          .firstMatch(colorStr);
      final angle = match != null ? double.tryParse(match.group(1)!) ?? 135 : 135;
      final c1 = match != null ? _parseHexColor(match.group(2)!) : Colors.grey;
      final c2Str = match?.group(3) ?? 'transparent';
      final c2 = c2Str == 'transparent' ? Colors.transparent : _parseHexColor(c2Str);
      final rad = angle * (pi / 180);
      decoration = _applyShapeDecoration(layer, gradient: LinearGradient(
        begin: Alignment(sin(rad), -cos(rad)),
        end: Alignment(-sin(rad), cos(rad)),
        colors: [c1, c2],
      ));
    } else {
      decoration = _applyShapeDecoration(layer, solidColor: _parseHexColor(colorStr));
    }

    final isSelected = _selectedType == SelectedElementType.shape && _selectedOverlayId == layer.id && !layer.locked;

    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      height: layer.height * h,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedType == SelectedElementType.shape && _selectedOverlayId == layer.id) {
              _selectedType = SelectedElementType.none;
              _selectedOverlayId = null;
            } else {
              _selectedType = SelectedElementType.shape;
              _selectedOverlayId = layer.id;
            }
          });
        },
        onScaleStart: (details) {
          _handleScaleStart(layer, details);
        },
        onScaleUpdate: (details) {
          _handleScaleUpdate(layer, details, w, h);
        },
        onScaleEnd: (details) {
          _handleScaleEnd(layer, details);
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: _limeAccent, width: 2.5),
                  borderRadius: BorderRadius.circular(8),
                  color: _limeAccent.withOpacity(0.12),
                )
              : null,
          child: Opacity(
            opacity: layer.opacity.clamp(0.0, 1.0),
            child: Container(decoration: decoration),
          ),
        ),
      ),
    );
  }

  BoxDecoration _applyShapeDecoration(ShapeLayer layer, {Color? solidColor, Gradient? gradient}) {
    final border = layer.borderWidth > 0
        ? Border.all(color: _parseHexColor(layer.borderColor), width: layer.borderWidth * layer.width)
        : null;
    switch (layer.shape) {
      case 'circle':
      case 'oval':
        return BoxDecoration(shape: BoxShape.circle, color: solidColor, gradient: gradient, border: border);
      case 'rounded-rectangle':
        return BoxDecoration(borderRadius: BorderRadius.circular(24), color: solidColor, gradient: gradient, border: border);
      case 'arch':
        return BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(200), topRight: Radius.circular(200)),
          color: solidColor, gradient: gradient,
        );
      default:
        return BoxDecoration(color: solidColor, gradient: gradient, border: border);
    }
  }


  Widget _buildTemplateBackground() {
    if (_localBackgroundPath != null) {
      return Image.file(
        File(_localBackgroundPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    
    final bg = widget.template.background;
    if (bg.type == 'color' && bg.value.startsWith('#')) {
      try {
        final hexStr = bg.value.replaceFirst('#', '');
        return Container(color: Color(int.parse('FF$hexStr', radix: 16)));
      } catch (_) {}
    }

    final bgValue = ApiService.resolveImageUrl(bg.value);
    if (bgValue.isNotEmpty && (bgValue.startsWith('http') || bgValue.startsWith('assets/'))) {
      final imageProvider = bgValue.startsWith('http')
          ? NetworkImage(bgValue)
          : AssetImage(bgValue) as ImageProvider;
      return Image(
        image: imageProvider,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }

  // Helper to map standard web fonts to Google Fonts available in Flutter
  String _getFontFamily(String originalFont) {
    final lower = originalFont.toLowerCase();
    if (lower.contains('georgia')) return 'Lora';
    if (lower.contains('times new roman') || lower.contains('times')) return 'Merriweather';
    if (lower.contains('arial') || lower.contains('helvetica')) return 'Inter';
    if (lower.contains('courier')) return 'Space Mono';
    if (lower.contains('brush script') || lower.contains('cursive')) return 'Dancing Script';
    return originalFont; // Try the original string if no mapping found
  }

  // SELECTABLE TEXT WIDGET WITH LIME GREEN BOUNDING BOX
  Widget _buildSelectableText({required TextLayer layer}) {
    final isSelected = _activeTextLayer?.id == layer.id && !layer.locked;
    final w = widget.template.width;
    final h = widget.template.height;

    final displayContent = layer.textTransform == 'uppercase' ? layer.content.toUpperCase() : layer.content;
    final align = layer.alignment == 'center' ? TextAlign.center : (layer.alignment == 'right' ? TextAlign.right : TextAlign.left);
    
    final mappedFont = _getFontFamily(layer.fontFamily);

    TextStyle getBaseStyle() {
      try {
        final style = GoogleFonts.getFont(
          mappedFont,
          fontSize: layer.fontSize * w,
          fontWeight: layer.fontWeight == 'bold' ? FontWeight.w700 : FontWeight.w400,
          fontStyle: layer.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
          decoration: layer.textDecoration == 'underline' ? TextDecoration.underline : TextDecoration.none,
          color: _parseHexColor(layer.color),
          letterSpacing: layer.letterSpacing * w,
          height: layer.lineHeight,
          shadows: layer.hasShadow
              ? [Shadow(
                  color: _parseHexColor(layer.shadowColor),
                  blurRadius: layer.shadowBlur * w,
                  offset: Offset(layer.shadowOffsetX * w, layer.shadowOffsetY * h),
                )]
              : null,
        );
        return style;
      } catch (_) {
        // Not a Google Font — fall back to system font with the requested family name
        return TextStyle(
          fontFamily: mappedFont,
          fontSize: layer.fontSize * w,
          fontWeight: layer.fontWeight == 'bold' ? FontWeight.w700 : FontWeight.w400,
          fontStyle: layer.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
          decoration: layer.textDecoration == 'underline' ? TextDecoration.underline : TextDecoration.none,
          color: _parseHexColor(layer.color),
          letterSpacing: layer.letterSpacing * w,
          height: layer.lineHeight,
          shadows: layer.hasShadow
              ? [Shadow(
                  color: _parseHexColor(layer.shadowColor),
                  blurRadius: layer.shadowBlur * w,
                  offset: Offset(layer.shadowOffsetX * w, layer.shadowOffsetY * h),
                )]
              : null,
        );
      }
    }

    // Build content widget — support curved text, outline, plain
    Widget buildTextContent({bool forOutline = false}) {
      final style = forOutline
          ? getBaseStyle().copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = layer.outlineWidth * w * 2
                ..color = _parseHexColor(layer.outlineColor),
              color: null,
            )
          : getBaseStyle();

      if (layer.curveIntensity != 0.0) {
        double radius = 15000 / (layer.curveIntensity.abs() < 1 ? 1 : layer.curveIntensity.abs());
        return ArcText(
          radius: radius,
          text: displayContent,
          textStyle: style,
          startAngle: -3.14159 / 2,
          startAngleAlignment: StartAngleAlignment.center,
          placement: layer.curveIntensity > 0 ? Placement.outside : Placement.inside,
          direction: layer.curveIntensity > 0 ? Direction.clockwise : Direction.counterClockwise,
        );
      }
      return Text(displayContent, style: style, textAlign: align, softWrap: true);
    }

    // Stack outline stroke behind fill text if outline is set
    Widget contentWidget;
    if (layer.outlineWidth > 0) {
      contentWidget = Stack(children: [buildTextContent(forOutline: true), buildTextContent()]);
    } else {
      contentWidget = buildTextContent();
    }

    // Wrap with background color if set
    Widget innerChild = contentWidget;
    if (layer.textBackgroundColor.isNotEmpty) {
      try {
        final bgColor = _parseHexColor(layer.textBackgroundColor);
        innerChild = Container(
          color: bgColor.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: contentWidget,
        );
      } catch (_) {}
    }

    // Wrap with Opacity and Flip Transformations
    innerChild = Opacity(
      opacity: layer.opacity,
      child: Transform.scale(
        scaleX: layer.flipHorizontal ? -1.0 : 1.0,
        scaleY: layer.flipVertical ? -1.0 : 1.0,
        child: innerChild,
      ),
    );

    // elementType mapping by layer index position
    final layerIndex = widget.template.textLayers.indexOf(layer);
    final elementType = layerIndex == 0
        ? SelectedElementType.header
        : layerIndex == 1
            ? SelectedElementType.name
            : layerIndex == 2
                ? SelectedElementType.dates
                : SelectedElementType.tribute;

    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      // No fixed height — web uses overflow:visible; canvas Clip.hardEdge handles boundary
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_activeTextLayer?.id == layer.id) {
              _activeTextLayer = null;
              _selectedType = SelectedElementType.none;
              _activeTray = ActiveTrayType.none;
            } else {
              _activeTextLayer = layer;
              _selectedType = elementType;
              _selectedOverlayId = null;
              _openIntegratedTextTrayFor(elementType);
            }
          });
        },
        onScaleStart: (details) {
          _handleScaleStart(layer, details);
        },
        onScaleUpdate: (details) {
          _handleScaleUpdate(layer, details, w, h);
        },
        onScaleEnd: (details) {
          _handleScaleEnd(layer, details);
        },
        // Only apply selection decoration when selected
        child: isSelected
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -12,
                    top: -6,
                    right: -12,
                    bottom: -6,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _limeAccent, width: 2.5),
                        borderRadius: BorderRadius.circular(6),
                        color: _limeAccent.withOpacity(0.18),
                      ),
                    ),
                  ),
                  innerChild,
                  _buildCornerResizeHandle(
                    alignment: Alignment.topLeft,
                    onPanUpdate: (details) {
                      final dx = details.delta.dx / w;
                      setState(() {
                        final oldRight = layer.x + layer.width;
                        layer.width -= dx;
                        if (layer.width < 0.1) {
                          layer.width = 0.1;
                          layer.x = oldRight - 0.1;
                        } else {
                          layer.x += dx;
                        }
                      });
                    },
                  ),
                  _buildCornerResizeHandle(
                    alignment: Alignment.topRight,
                    onPanUpdate: (details) {
                      final dx = details.delta.dx / w;
                      setState(() {
                        layer.width += dx;
                        if (layer.width < 0.1) layer.width = 0.1;
                      });
                    },
                  ),
                  _buildCornerResizeHandle(
                    alignment: Alignment.bottomLeft,
                    onPanUpdate: (details) {
                      final dx = details.delta.dx / w;
                      setState(() {
                        final oldRight = layer.x + layer.width;
                        layer.width -= dx;
                        if (layer.width < 0.1) {
                          layer.width = 0.1;
                          layer.x = oldRight - 0.1;
                        } else {
                          layer.x += dx;
                        }
                      });
                    },
                  ),
                  _buildCornerResizeHandle(
                    alignment: Alignment.bottomRight,
                    onPanUpdate: (details) {
                      final dx = details.delta.dx / w;
                      setState(() {
                        layer.width += dx;
                        if (layer.width < 0.1) layer.width = 0.1;
                      });
                    },
                  ),
                ],
              )
            : innerChild,
      ),
    );
  }


  // SELECTABLE PHOTO WITH LIME GREEN BOUNDING BOX + ITEM 8 CUSTOM FRAME IMAGE
  Widget _buildSelectablePhoto({required ImageLayer layer}) {
    final isSelected = _selectedType == SelectedElementType.photo && !layer.locked;
    final w = widget.template.width;
    final h = widget.template.height;

    // 0=Circle, 1=Oval, 2=Rounded Square, 3=Arch, 4=Soft Hex, 5=Custom Frame
    // We already initialized _frameShapeIndex from maskShape in initState.
    // Now we must always respect _frameShapeIndex so the user's manual selection works.
    final effectiveShapeIndex = _frameShapeIndex;

    BorderRadius getRadius() {
      if (effectiveShapeIndex == 0) return BorderRadius.circular(9999); // pure circle via ClipOval below
      if (effectiveShapeIndex == 1) {
        return const BorderRadius.all(Radius.elliptical(120, 160));
      }
      if (effectiveShapeIndex == 2) return BorderRadius.circular(24);
      if (effectiveShapeIndex == 3) {
        return const BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(100),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        );
      }
      if (effectiveShapeIndex == 4) return BorderRadius.circular(44);
      return BorderRadius.circular(_customBorderRadius);
    }

    final isCircle = effectiveShapeIndex == 0;

    Widget clipContent = isCircle
        ? ClipOval(child: _buildPhotoContent(layer))
        : ClipRRect(borderRadius: getRadius(), child: _buildPhotoContent(layer));

    clipContent = Opacity(
      opacity: layer.opacity,
      child: Transform.scale(
        scaleX: layer.flipHorizontal ? -1.0 : 1.0,
        scaleY: layer.flipVertical ? -1.0 : 1.0,
        child: clipContent,
      ),
    );

    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      height: layer.height * h,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedType == SelectedElementType.photo) {
              _selectedType = SelectedElementType.none;
              _selectedOverlayId = null;
              _activeTray = ActiveTrayType.none;
            } else {
              _selectedType = SelectedElementType.photo;
              _selectedOverlayId = null;
              _activeTray = ActiveTrayType.photo;
            }
          });
        },
        onScaleStart: (details) {
          _handleScaleStart(layer, details);
        },
        onScaleUpdate: (details) {
          _handleScaleUpdate(layer, details, w, h);
        },
        onScaleEnd: (details) {
          _handleScaleEnd(layer, details);
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: layer.width * w,
              height: layer.height * h,
              // FIX #5: No hardcoded padding — it shrinks the clip area and creates a ring
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: _limeAccent, width: 3),
                      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: isCircle ? null : getRadius(),
                      color: _limeAccent.withOpacity(0.18),
                    )
                  : BoxDecoration(
                      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: isCircle ? null : getRadius(),
                      border: Border.all(color: Colors.transparent, width: 0),
                    ),
              child: clipContent,
            ),
            // Item 8: Custom Uploaded Frame Border Overlay
            if (effectiveShapeIndex == 5 && _customFrameImagePath != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: getRadius(),
                  child: Image.file(
                    File(_customFrameImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (isSelected) ...[
              _buildCornerResizeHandle(
                alignment: Alignment.topLeft,
                onPanUpdate: (details) {
                  final dx = details.delta.dx / w;
                  final dy = details.delta.dy / h;
                  setState(() {
                    final oldRight = layer.x + layer.width;
                    final oldBottom = layer.y + layer.height;
                    layer.width -= dx;
                    layer.height -= dy;
                    if (layer.width < 0.1) {
                      layer.width = 0.1;
                      layer.x = oldRight - 0.1;
                    } else {
                      layer.x += dx;
                    }
                    if (layer.height < 0.1) {
                      layer.height = 0.1;
                      layer.y = oldBottom - 0.1;
                    } else {
                      layer.y += dy;
                    }
                  });
                },
              ),
              _buildCornerResizeHandle(
                alignment: Alignment.topRight,
                onPanUpdate: (details) {
                  final dx = details.delta.dx / w;
                  final dy = details.delta.dy / h;
                  setState(() {
                    final oldBottom = layer.y + layer.height;
                    layer.width += dx;
                    layer.height -= dy;
                    if (layer.width < 0.1) layer.width = 0.1;
                    if (layer.height < 0.1) {
                      layer.height = 0.1;
                      layer.y = oldBottom - 0.1;
                    } else {
                      layer.y += dy;
                    }
                  });
                },
              ),
              _buildCornerResizeHandle(
                alignment: Alignment.bottomLeft,
                onPanUpdate: (details) {
                  final dx = details.delta.dx / w;
                  final dy = details.delta.dy / h;
                  setState(() {
                    final oldRight = layer.x + layer.width;
                    layer.width -= dx;
                    layer.height += dy;
                    if (layer.height < 0.1) layer.height = 0.1;
                    if (layer.width < 0.1) {
                      layer.width = 0.1;
                      layer.x = oldRight - 0.1;
                    } else {
                      layer.x += dx;
                    }
                  });
                },
              ),
              _buildCornerResizeHandle(
                alignment: Alignment.bottomRight,
                onPanUpdate: (details) {
                  final dx = details.delta.dx / w;
                  final dy = details.delta.dy / h;
                  setState(() {
                    layer.width += dx;
                    layer.height += dy;
                    if (layer.width < 0.1) layer.width = 0.1;
                    if (layer.height < 0.1) layer.height = 0.1;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoContent(ImageLayer layer) {
    if (_localPhotoPath != null) {
      return Image.file(
        File(_localPhotoPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPortraitPlaceholder(),
      );
    }
    
    // Check if the template has a remote URL for the frame
    final resolvedUrl = ApiService.resolveImageUrl(layer.url);
    if (resolvedUrl.isNotEmpty) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPortraitPlaceholder(),
      );
    }
    
    return _buildPortraitPlaceholder();
  }

  // Item 4: Generous interior padding & centered text so it never clips any shape edge!
  Widget _buildPortraitPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C353F), Color(0xFF1E242B)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            size: 52,
            color: AppTheme.goldAccent.withOpacity(0.85),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap to\nUpload',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // DRAGGABLE FLORAL IMAGE OVERLAYS (or legacy icon overlays)
  Widget _buildSingleOverlayWidget(CanvasOverlayItem item) {
      final isSelected = _selectedType == SelectedElementType.overlay &&
          _selectedOverlayId == item.id && !item.locked;
      final w = widget.template.width;
      final h = widget.template.height;

      Widget overlayChild;
      if (item.graphic.isImageOverlay) {
        // Real PNG floral image from backend
        final imageUrl = '${ApiService.baseUrl}/flowers/${item.graphic.imageFile}';
        final imgW = w * 0.9 * item.scale;
        overlayChild = SizedBox(
          width: imgW,
          // Removed height: imgH to allow the bounding box to shrink-wrap the image aspect ratio
          child: Opacity(
            opacity: item.opacity,
            child: Transform.scale(
              scaleX: item.flipHorizontal ? -1.0 : 1.0,
              scaleY: item.flipVertical ? -1.0 : 1.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                color: Colors.black.withOpacity(0.0), // transparent tint
                colorBlendMode: BlendMode.multiply,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      } else {
        // Legacy icon overlay
        overlayChild = Icon(
          item.graphic.iconData ?? Icons.star_rounded,
          size: item.graphic.defaultSize * item.scale,
          color: item.color,
        );
      }

      return Positioned(
        left: item.position.dx,
        top: item.position.dy,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedType == SelectedElementType.overlay && _selectedOverlayId == item.id) {
                _selectedType = SelectedElementType.none;
                _selectedOverlayId = null;
                _activeTray = ActiveTrayType.none;
              } else {
                _selectedType = SelectedElementType.overlay;
                _selectedOverlayId = item.id;
                if (!item.graphic.isImageOverlay) {
                  _activeTray = ActiveTrayType.colors;
                }
              }
            });
          },
        onScaleStart: (details) {
          _handleScaleStart(item, details);
        },
        onScaleUpdate: (details) {
          _handleScaleUpdate(item, details, w, h);
        },
        onScaleEnd: (details) {
          _handleScaleEnd(item, details);
        },
        child: isSelected 
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: _limeAccent, width: 2.5),
                      borderRadius: BorderRadius.circular(8),
                      color: _limeAccent.withOpacity(0.12),
                    ),
                    child: overlayChild,
                  ),
                  _buildCornerResizeHandle(
                    alignment: Alignment.topLeft,
                    onPanUpdate: (details) {
                      setState(() {
                        item.scale -= details.delta.dx / w;
                        if (item.scale < 0.1) item.scale = 0.1;
                      });
                    },
                  ),
                  _buildCornerResizeHandle(
                    alignment: Alignment.topRight,
                    onPanUpdate: (details) {
                      setState(() {
                        item.scale += details.delta.dx / w;
                        if (item.scale < 0.1) item.scale = 0.1;
                      });
                    },
                  ),
                  _buildCornerResizeHandle(
                    alignment: Alignment.bottomLeft,
                    onPanUpdate: (details) {
                      setState(() {
                        item.scale -= details.delta.dx / w;
                        if (item.scale < 0.1) item.scale = 0.1;
                      });
                    },
                  ),
                  _buildCornerResizeHandle(
                    alignment: Alignment.bottomRight,
                    onPanUpdate: (details) {
                      setState(() {
                        item.scale += details.delta.dx / w;
                        if (item.scale < 0.1) item.scale = 0.1;
                      });
                    },
                  ),
                ],
              )
              : Container(
                  padding: const EdgeInsets.all(4),
                  child: overlayChild,
                ),
        ),
      );
    }

  void _handleScaleStart(dynamic layer, ScaleStartDetails details) {
    if (layer is CanvasOverlayItem) {
      _baseScale = layer.scale;
    } else if (layer is TextLayer) {
      _baseWidth = layer.width;
    } else if (layer is ImageLayer) {
      _baseWidth = layer.width;
      _baseHeight = layer.height;
    }
  }

  void _handleScaleUpdate(dynamic layer, ScaleUpdateDetails details, double w, double h) {
    if (layer.locked) return;

    if (details.pointerCount == 2) {
      // Two-finger pinch to scale
      setState(() {
        if (layer is CanvasOverlayItem) {
          layer.scale = (_baseScale * details.scale).clamp(0.1, 5.0);
        } else if (layer is TextLayer) {
          layer.width = (_baseWidth * details.scale).clamp(0.1, 1.0);
        } else if (layer is ImageLayer) {
          layer.width = (_baseWidth * details.scale).clamp(0.1, 1.0);
          layer.height = (_baseHeight * details.scale).clamp(0.1, 1.0);
        }
      });
    } else if (details.pointerCount == 1) {
      // One-finger drag to pan
      final dx = details.focalPointDelta.dx / w;
      final dy = details.focalPointDelta.dy / h;
      final absDx = details.focalPointDelta.dx;
      final absDy = details.focalPointDelta.dy;

      setState(() {
        final groupId = layer.groupId;
        if (groupId != null && groupId.isNotEmpty) {
          // Move all items in this group
          for (var l in widget.template.imageLayers) {
            if (l.groupId == groupId && !l.locked) { l.x += dx; l.y += dy; }
          }
          for (var l in widget.template.shapeLayers) {
            if (l.groupId == groupId && !l.locked) { l.x += dx; l.y += dy; }
          }
          for (var l in widget.template.textLayers) {
            if (l.groupId == groupId && !l.locked) { l.x += dx; l.y += dy; }
          }
          for (var l in _overlayItems) {
            if (l.groupId == groupId && !l.locked) { l.position = Offset(l.position.dx + absDx, l.position.dy + absDy); }
          }
        } else {
          // Move only this item
          if (layer is CanvasOverlayItem) {
            layer.position = Offset(layer.position.dx + absDx, layer.position.dy + absDy);
          } else {
            layer.x += dx;
            layer.y += dy;
          }
        }
      });
    }
  }

  void _handleScaleEnd(dynamic layer, ScaleEndDetails details) {
    if (!layer.locked) _saveState();
  }

  // DYNAMIC HEIGHT INTEGRATED TRAY (White + Lime Green Theme)
  Widget _buildActiveTrayPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      height: _getTrayHeight(context),
      decoration: const BoxDecoration(
        color: Colors.white, // Crisp White Light Theme!
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
      child: _buildTrayContent(),
    );
  }

  Widget _buildTrayContent() {
    switch (_activeTray) {
      case ActiveTrayType.templates:
        return _buildTemplatesTray();
      case ActiveTrayType.verses:
        return _buildVersesTray();
      case ActiveTrayType.flowers:
        return _buildFlowersTray();
      case ActiveTrayType.text:
        return _buildTextTray();
      case ActiveTrayType.frame:
        return _buildFrameShapeTray();
      case ActiveTrayType.photo:
        return _buildPhotoTray();
      case ActiveTrayType.background:
        return _buildBackgroundTray(); // Item 10: Dedicated Background tool
      case ActiveTrayType.fonts:
        return _buildFontsTray();
      case ActiveTrayType.colors:
        return _buildColorsTray();
      case ActiveTrayType.theme:
        return _buildThemeTray();
      case ActiveTrayType.overlay:
        return _buildOverlayTray();
      case ActiveTrayType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverlayTray() {
    final item = _currentOverlay;
    if (item == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.photo_size_select_large_rounded, color: _darkBlack, size: 20),
              const SizedBox(width: 8),
              const Text('Sticker Size', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const Spacer(),
              Text('${(item.scale * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w800, color: _limeAccent, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: _darkBlack,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: _limeAccent,
              overlayColor: _limeAccent.withOpacity(0.2),
            ),
            child: Slider(
              min: 0.1,
              max: item.graphic.isImageOverlay ? 5.0 : 3.0,
              value: item.scale,
              onChanged: (val) {
                setState(() => item.scale = val);
              },
              onChangeEnd: (_) => _saveState(),
            ),
          ),
        ],
      ),
    );
  }

  // 1. TEMPLATES TRAY (Crisp Light Theme + Lime Green Accent)
  Widget _buildTemplatesTray() {
    return FutureBuilder<List<Template>>(
      future: ApiService.fetchTemplates(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final templates = snapshot.data!;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: templates.length,
          itemBuilder: (context, idx) {
            final t = templates[idx];
            return GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => EditorScreen(template: t)),
                );
              },
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Light slate card
                  border: Border.all(color: _darkBlack, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.style_rounded, color: _darkBlack, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      t.title,
                      style: const TextStyle(color: _darkBlack, fontWeight: FontWeight.w800, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. VERSES TRAY (Item 2: Tick button & card change into solid dark color when selected!)
  Widget _buildVersesTray() {
    const allVerses = MemorialElementsLibrary.verses;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: allVerses.length,
      itemBuilder: (context, idx) {
        final verse = allVerses[idx];
        final isSelected = _messageContent == verse.text;
        return Card(
          color: isSelected ? _limeAccent.withOpacity(0.2) : const Color(0xFFF8FAFC),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? _darkBlack : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              verse.title,
              style: const TextStyle(color: _darkBlack, fontWeight: FontWeight.w800, fontSize: 13),
            ),
            subtitle: Text(
              '"${verse.text}"',
              style: const TextStyle(color: Color(0xFF334155), fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Item 2: Solid dark black tick inside a vibrant lime green circle badge when selected!
            trailing: IconButton(
              icon: isSelected
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _limeAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _darkBlack, width: 1.5),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.black, size: 16),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF94A3B8), size: 20),
              onPressed: () {
                setState(() {
                  _messageContent = verse.text;
                  // Fix #4: Always add as a NEW text layer instead of overwriting the currently selected one
                  _activeTextLayer = null;
                  _selectedType = SelectedElementType.none;
                });
                _updateActiveTextProperty((layer) => layer.content = verse.text, insertIfMissing: true);
                // Fix: ensure the text tray is completely closed so it doesn't confusingly switch trays
                setState(() {
                  _activeTray = ActiveTrayType.none;
                });
              },
            ),
            onTap: () {
              setState(() {
                _messageContent = verse.text;
              });
            },
          ),
        );
      },
    );
  }

  // 3. FLOWERS TRAY — Real floral images from the backend (matches web dashboard)
  Widget _buildFlowersTray() {
    const allGraphics = MemorialElementsLibrary.graphics;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,       // 2 columns — same as web dashboard grid
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,   // Landscape card to show image comfortably
      ),
      itemCount: allGraphics.length,
      itemBuilder: (context, idx) {
        final g = allGraphics[idx];
        final imageUrl = '${ApiService.baseUrl}/flowers/${g.imageFile}';
        return InkWell(
          onTap: () => _addOverlayGraphic(g),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Checkerboard bg to show transparency of floral PNGs
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8E8E8), Color(0xFFF5F5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Actual floral image from backend
                Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.local_florist_rounded, size: 40, color: Color(0xFF94A3B8)),
                  ),
                ),
                // Label at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                    ),
                    child: Text(
                      g.name,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateSelectedTextContent(String val) {
    setState(() {
      if (_selectedType == SelectedElementType.header) _startingLine = val;
      if (_selectedType == SelectedElementType.name) _deceasedName = val;
      if (_selectedType == SelectedElementType.dates) _lifespanDates = val;
      if (_selectedType == SelectedElementType.tribute || _selectedType == SelectedElementType.none) {
        _messageContent = val;
      }
      if (_activeTextLayer != null) {
        _activeTextLayer!.content = val;
      }
    });
  }

  void _updateActiveTextProperty(void Function(TextLayer) update, {bool saveState = true, bool insertIfMissing = false}) {
    TextLayer? targetLayer = _activeTextLayer;
    if (targetLayer == null) {
      if (_selectedType == SelectedElementType.header && widget.template.textLayers.isNotEmpty) targetLayer = widget.template.textLayers[0];
      else if (_selectedType == SelectedElementType.name && widget.template.textLayers.length > 1) targetLayer = widget.template.textLayers[1];
      else if (_selectedType == SelectedElementType.dates && widget.template.textLayers.length > 2) targetLayer = widget.template.textLayers[2];
      else if (_selectedType == SelectedElementType.tribute && widget.template.textLayers.length > 3) targetLayer = widget.template.textLayers[3];
    }
    
    if (targetLayer != null) {
      setState(() {
        update(targetLayer!);
      });
      if (saveState) {
        _saveState();
      }
    } else {
      if (insertIfMissing) {
        // Automatically insert a new text layer if none exists!
        setState(() {
          final newLayer = TextLayer(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '',
            x: 0.1,
            y: 0.45,
            width: 0.8,
            height: 0.1,
            fontFamily: 'Inter',
            fontSize: 50 / widget.template.width,
            fontWeight: 'normal',
            fontStyle: 'normal',
            textDecoration: 'none',
            opacity: 1.0,
            color: '#000000',
            alignment: 'center',
          );
          update(newLayer);
          widget.template.textLayers.add(newLayer);
          _activeTextLayer = newLayer;
          _selectedType = SelectedElementType.tribute;
          if (_textStyles.containsKey(_selectedType)) {
            _textStyles[_selectedType]!.size = 50.0;
          }
          _textEditingController.text = newLayer.content;
        });
        if (saveState) _saveState();
      } else if (saveState) {
        // Only show snackbar for distinct actions, never for continuous slider drags!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a text element on the canvas first.', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Item 7: SCROLLABLE CANVA-STYLE TEXT TYPOGRAPHY SUITE
  Widget _buildTextTray() {
    final currentType = _selectedType != SelectedElementType.none &&
            _textStyles.containsKey(_selectedType)
        ? _selectedType
        : SelectedElementType.tribute;
    final style = _textStyles[currentType]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 0: Add New Text Button
          // Section 0: Add New Text Button (Always Visible)
          Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _activeTextLayer = null;
                    _selectedType = SelectedElementType.none;
                    _messageContent = '';
                    _textEditingController.clear();
                  });
                  _updateActiveTextProperty((l) {}, insertIfMissing: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _limeAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: _darkBlack, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Text Box', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),

          // Section 1: Prominent multi-line text input field
          TextField(
            controller: _textEditingController,
            style: const TextStyle(color: _darkBlack, fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 1,
            decoration: InputDecoration(
              hintText: 'Type your text here...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _darkBlack, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _darkBlack, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: _darkBlack, size: 18),
                onPressed: () {
                  _textEditingController.clear();
                  _updateSelectedTextContent('');
                },
              ),
            ),
            onChanged: (val) {
              _updateSelectedTextContent(val);
            },
          ),
          const SizedBox(height: 8),

          // Section 2: Quick Font Name Button & Quick Color Swatch Button
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _activeTray = ActiveTrayType.fonts),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: _darkBlack,
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: _darkBlack, width: 1.5),
                    ),
                  ),
                  icon: const Icon(Icons.font_download_outlined, size: 18, color: _darkBlack),
                  label: Text(
                    'Font: ${style.font}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _activeTray = ActiveTrayType.colors),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: _darkBlack,
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: _darkBlack, width: 1.5),
                    ),
                  ),
                  icon: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: style.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: _darkBlack, width: 1),
                    ),
                  ),
                  label: const Text('Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Section 3: Font Size Control with smooth Slider and - / + steps
          Row(
            children: [
              const Text('Size:', style: TextStyle(color: _darkBlack, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              _buildLargeActionBtn(
                icon: Icons.remove_rounded,
                onTap: () => _changeTextSize(-2.0),
              ),
              Expanded(
                child: Slider(
                  value: style.size.clamp(12.0, 400.0),
                  min: 12.0,
                  max: 400.0,
                  activeColor: _darkBlack,
                  thumbColor: _limeAccent,
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (val) {
                    setState(() => style.size = val);
                    _updateActiveTextProperty((layer) {
                      layer.fontSize = val / 1080;
                    }, saveState: false);
                  },
                  onChangeEnd: (_) => _saveState(),
                ),
              ),
              _buildLargeActionBtn(
                icon: Icons.add_rounded,
                onTap: () => _changeTextSize(2.0),
              ),
              const SizedBox(width: 8),
              Text('${style.size.toInt()}pt', style: const TextStyle(color: _darkBlack, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),

          // Section 4: Formatting (B, I, U, AA) & Alignment (Left, Center, Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStyleToggle(
                    icon: Icons.format_align_left_rounded,
                    isActive: style.align == TextAlign.left,
                    onTap: () {
                      setState(() => style.align = TextAlign.left);
                      _updateActiveTextProperty((layer) => layer.alignment = 'left');
                    },
                  ),
                  _buildStyleToggle(
                    icon: Icons.format_align_center_rounded,
                    isActive: style.align == TextAlign.center,
                    onTap: () {
                      setState(() => style.align = TextAlign.center);
                      _updateActiveTextProperty((layer) => layer.alignment = 'center');
                    },
                  ),
                  _buildStyleToggle(
                    icon: Icons.format_align_right_rounded,
                    isActive: style.align == TextAlign.right,
                    onTap: () {
                      setState(() => style.align = TextAlign.right);
                      _updateActiveTextProperty((layer) => layer.alignment = 'right');
                    },
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStyleToggle(
                    icon: Icons.format_bold_rounded,
                    isActive: style.bold,
                    onTap: () {
                      setState(() => style.bold = !style.bold);
                      _updateActiveTextProperty((layer) => layer.fontWeight = style.bold ? 'bold' : 'normal');
                    },
                  ),
                  _buildStyleToggle(
                    icon: Icons.format_italic_rounded,
                    isActive: style.italic,
                    onTap: () {
                      setState(() => style.italic = !style.italic);
                      _updateActiveTextProperty((layer) => layer.fontStyle = style.italic ? 'italic' : 'normal');
                    },
                  ),
                  _buildStyleToggle(
                    icon: Icons.format_underlined_rounded,
                    isActive: style.underline,
                    onTap: () {
                      setState(() => style.underline = !style.underline);
                      _updateActiveTextProperty((layer) => layer.textDecoration = style.underline ? 'underline' : 'none');
                    },
                  ),
                  _buildStyleToggle(
                    icon: Icons.keyboard_capslock_rounded,
                    isActive: style.uppercase,
                    onTap: () {
                      setState(() => style.uppercase = !style.uppercase);
                      _updateActiveTextProperty((layer) => layer.textTransform = style.uppercase ? 'uppercase' : 'none');
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Section 5: Interactive Sliders for Letter Spacing and Line Height
          Row(
            children: [
              const Text('Spacing:', style: TextStyle(color: _darkBlack, fontSize: 12, fontWeight: FontWeight.w800)),
              Expanded(
                child: Slider(
                  value: style.letterSpacing,
                  min: 0.0,
                  max: 10.0,
                  activeColor: _darkBlack,
                  thumbColor: _limeAccent,
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (val) {
                    setState(() => style.letterSpacing = val);
                    _updateActiveTextProperty((layer) => layer.letterSpacing = val / widget.template.width, saveState: false);
                  },
                  onChangeEnd: (_) => _saveState(),
                ),
              ),
              Text(style.letterSpacing.toStringAsFixed(1), style: const TextStyle(color: _darkBlack, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(width: 14),
              const Text('Line:', style: TextStyle(color: _darkBlack, fontSize: 12, fontWeight: FontWeight.w800)),
              Expanded(
                child: Slider(
                  value: style.lineHeight,
                  min: 1.0,
                  max: 2.5,
                  activeColor: _darkBlack,
                  thumbColor: _limeAccent,
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (val) {
                    setState(() => style.lineHeight = val);
                    _updateActiveTextProperty((layer) => layer.lineHeight = val, saveState: false);
                  },
                  onChangeEnd: (_) => _saveState(),
                ),
              ),
              Text(style.lineHeight.toStringAsFixed(1), style: const TextStyle(color: _darkBlack, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeActionBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: _darkBlack, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _darkBlack, size: 18),
      ),
    );
  }

  // Item 6: Inactive = Dark Slate Border, Active = Lime Green Fill WITH Dark Slate Border
  Widget _buildStyleToggle({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? _limeAccent : const Color(0xFFF1F5F9),
            border: Border.all(
              color: _darkBlack,
              width: isActive ? 2.0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.black : const Color(0xFF475569),
            size: 18,
          ),
        ),
      ),
    );
  }

  void _openIntegratedTextTrayFor(SelectedElementType type) {
    setState(() {
      _activeTray = ActiveTrayType.text;
      if (type == SelectedElementType.header) _textEditingController.text = _startingLine;
      if (type == SelectedElementType.name) _textEditingController.text = _deceasedName;
      if (type == SelectedElementType.dates) _textEditingController.text = _lifespanDates;
      if (type == SelectedElementType.tribute) _textEditingController.text = _messageContent;
      
      if (_activeTextLayer != null) {
        _textEditingController.text = _activeTextLayer!.content;
      }
    });
  }

  // Item 8: FRAME SHAPE TRAY ("Custom" means upload custom frame border image!)
  Widget _buildFrameShapeTray() {
    final frames = [
      {'name': 'Circle', 'icon': Icons.circle_outlined},
      {'name': 'Oval', 'icon': Icons.crop_portrait_rounded},
      {'name': 'Square', 'icon': Icons.crop_square_rounded},
      {'name': 'Arch', 'icon': Icons.architecture_rounded},
      {'name': 'Diamond', 'icon': Icons.diamond_outlined},
      {'name': 'Custom', 'icon': Icons.add_photo_alternate_rounded}, // Upload custom frame!
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: frames.length,
            itemBuilder: (context, idx) {
              final frame = frames[idx];
              final isSel = _frameShapeIndex == idx;
              return GestureDetector(
                onTap: () {
                  if (idx == 5) {
                    _pickCustomFrameImage();
                  } else {
                    setState(() {
                      _frameShapeIndex = idx;
                      if (!widget.template.imageLayers.any((l) => l.type == 'frame')) {
                        widget.template.imageLayers.add(ImageLayer(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          url: '',
                          type: 'frame',
                          maskShape: 'rounded_rect',
                          x: 0.2, y: 0.2, width: 0.6, height: 0.6,
                          rotation: 0.0,
                          opacity: 1.0, 
                          borderWidth: 0.0,
                          borderColor: '#000000',
                          flipHorizontal: false, flipVertical: false, locked: false,
                        ));
                        _selectedType = SelectedElementType.photo;
                      }
                    });
                    _saveState();
                  }
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSel ? _limeAccent : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: _darkBlack,
                      width: isSel ? 2.0 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(frame['icon'] as IconData, color: isSel ? Colors.black : const Color(0xFF475569), size: 26),
                      const SizedBox(height: 4),
                      Text(
                        frame['name'] as String,
                        style: TextStyle(
                          color: isSel ? Colors.black : const Color(0xFF0F172A),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_frameShapeIndex == 5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickCustomFrameImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _limeAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: _darkBlack, width: 1.5),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      _customFrameImagePath != null ? 'Frame Uploaded (Tap to change)' : 'Upload Frame from Gallery',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 6. PHOTO TRAY (Crisp Light Theme + Lime Green Button)
  Widget _buildPhotoTray() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: ElevatedButton.icon(
          onPressed: _pickPhoto,
          style: ElevatedButton.styleFrom(
            backgroundColor: _limeAccent, // Vibrant Lime Green Accent
            foregroundColor: Colors.black, // Crisp Bold Black text
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _darkBlack, width: 1.5),
            ),
          ),
          icon: const Icon(Icons.photo_library_rounded, size: 22),
          label: const Text(
            'Select Portrait Photo',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }

  // Item 10: DEDICATED BACKGROUND TRAY
  Widget _buildBackgroundTray() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickBackgroundPhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _limeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: _darkBlack, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.wallpaper_rounded, size: 20),
                label: const Text(
                  'Upload Background Photo',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _activeTray = ActiveTrayType.theme),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: _darkBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: _darkBlack, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.color_lens_outlined, size: 20),
                label: const Text(
                  'Background Color',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Item 3: FONTS TRAY (Includes "← Back to Text Settings" button!)
  Widget _buildFontsTray() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF8FAFC),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _activeTray = ActiveTrayType.text),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_rounded, color: _darkBlack, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Back to Text Settings',
                      style: TextStyle(color: _darkBlack, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: allWebGoogleFonts.length,
            itemBuilder: (context, idx) {
              final font = allWebGoogleFonts[idx];
              final isSel = _isFontSelected(font);
              return ListTile(
                dense: true,
                title: Builder(
                  builder: (context) {
                    try {
                      return Text(
                        font,
                        style: GoogleFonts.getFont(
                          _getFontFamily(font),
                          color: isSel ? _darkBlack : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                        ),
                      );
                    } catch (_) {
                      return Text(
                        font,
                        style: TextStyle(
                          color: isSel ? _darkBlack : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                        ),
                      );
                    }
                  }
                ),
                trailing: isSel
                    ? Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: _limeAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.black, size: 16),
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_selectedType == SelectedElementType.header) _textStyles[SelectedElementType.header]!.font = font;
                    if (_selectedType == SelectedElementType.name) _textStyles[SelectedElementType.name]!.font = font;
                    if (_selectedType == SelectedElementType.dates) _textStyles[SelectedElementType.dates]!.font = font;
                    if (_selectedType == SelectedElementType.tribute) _textStyles[SelectedElementType.tribute]!.font = font;
                  });
                  _updateActiveTextProperty((layer) => layer.fontFamily = font);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isFontSelected(String font) {
    if (_textStyles.containsKey(_selectedType)) {
      return _textStyles[_selectedType]!.font == font;
    }
    return false;
  }

  // Item 3: COLORS TRAY (Includes "← Back to Text Settings" button!)
  Widget _buildColorsTray() {
    final colors = [
      const Color(0xFF1B2430),
      const Color(0xFF3B4856),
      const Color(0xFFBAFF00), // Lime green in palette too!
      const Color(0xFFD4AF37),
      const Color(0xFF8B5A5A),
      const Color(0xFF2C5E3B),
      const Color(0xFF4A5568),
      const Color(0xFFFFFFFF),
      const Color(0xFF000000),
    ];
    return Column(
      children: [
        if (_selectedType != SelectedElementType.overlay)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _activeTray = ActiveTrayType.text),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_rounded, color: _darkBlack, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Back to Text Settings',
                        style: TextStyle(color: _darkBlack, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: colors.map((c) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_textStyles.containsKey(_selectedType)) {
                          _textStyles[_selectedType]!.color = c;
                        }
                        if (_selectedType == SelectedElementType.overlay) {
                          final ov = _currentOverlay;
                          if (ov != null) ov.color = c;
                        }
                      });
                      _updateActiveTextProperty((layer) {
                        layer.color = '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: _darkBlack, width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Item 5 & 9: SNUG THEME TRAY WITH CUSTOM COLOR PICKER BAR (Zero bottom empty space!)
  Widget _buildThemeTray() {
    final palettes = [
      {'name': 'Pure White', 'color': Colors.white},
      {'name': 'Off-White', 'color': const Color(0xFFFAF9F6)},
      {'name': 'Soft Ivory', 'color': const Color(0xFFFFFDD0)},
      {'name': 'Marble', 'color': const Color(0xFFF9F6F0)},
      {'name': 'Soft Peach', 'color': const Color(0xFFFDF2ED)},
      {'name': 'Rose Quartz', 'color': const Color(0xFFF7EBF0)},
      {'name': 'Dove Grey', 'color': const Color(0xFFF1F5F9)},
      {'name': 'Slate Pearl', 'color': const Color(0xFFE2E8F0)},
      {'name': 'Sage Green', 'color': const Color(0xFFEDF4ED)},
      {'name': 'Dusty Blue', 'color': const Color(0xFFEBF3F8)},
      {'name': 'Navy Tint', 'color': const Color(0xFFE2E8F0)},
      {'name': 'Gold Tint', 'color': const Color(0xFFFBF8EE)},
    ];
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: GestureDetector(
              onTap: () => setState(() => _activeTray = ActiveTrayType.background),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF1E293B)),
                  SizedBox(width: 6),
                  Text('Back to Background', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                ],
              ),
            ),
          ),
          // Item 9: Interactive Custom Color Bar
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Canvas Color:', style: TextStyle(color: _darkBlack, fontSize: 13, fontWeight: FontWeight.w800)),
              ElevatedButton.icon(
                onPressed: _showCustomColorPicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _limeAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _darkBlack, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.colorize_rounded, size: 16),
                label: const Text('Custom Color +', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: palettes.length,
            itemBuilder: (context, idx) {
              final p = palettes[idx];
              final color = p['color'] as Color;
              final hexValue = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              final name = p['name'] as String;
              final isSel = widget.template.background.type == 'color' && 
                            widget.template.background.value.toUpperCase() == hexValue;
              return InkWell(
                onTap: () => setState(() {
                  widget.template.background.type = 'color';
                  widget.template.background.value = hexValue;
                  _localBackgroundPath = null;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel ? _limeAccent : _darkBlack,
                      width: isSel ? 2.5 : 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name,
                    style: TextStyle(
                      color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                      fontSize: 10,
                      fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
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

  // DEFAULT MAIN STUDIO DOCK (White + Lime Green Pill Indicator + Item 10 Background tool!)
  Widget _buildMainStudioDock() {
    return Container(
      height: 84, // Increased from 74 to prevent RenderFlex overflow
      padding: const EdgeInsets.symmetric(vertical: 6), // Restored comfortable padding
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16), // Padding for scroll edges
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildDockItem(
            icon: Icons.dashboard_outlined,
            label: 'Templates',
            isActive: _activeTray == ActiveTrayType.templates,
            onTap: () => _toggleTray(ActiveTrayType.templates),
          ),
          _buildDockItem(
            icon: Icons.menu_book_rounded,
            label: 'Verses',
            isActive: _activeTray == ActiveTrayType.verses,
            onTap: () => _toggleTray(ActiveTrayType.verses),
          ),
          _buildDockItem(
            icon: Icons.local_florist_rounded,
            label: 'Flowers',
            isActive: _activeTray == ActiveTrayType.flowers,
            onTap: () => _toggleTray(ActiveTrayType.flowers),
          ),
          _buildDockItem(
            icon: Icons.title_rounded,
            label: 'Text',
            isActive: _activeTray == ActiveTrayType.text,
            onTap: () => _toggleTray(ActiveTrayType.text),
          ),
          _buildDockItem(
            icon: Icons.crop_square_rounded,
            label: 'Frame',
            isActive: _activeTray == ActiveTrayType.frame,
            onTap: () => _toggleTray(ActiveTrayType.frame),
          ),
          _buildDockItem(
            icon: Icons.photo_library_outlined,
            label: 'Photo',
            isActive: _activeTray == ActiveTrayType.photo,
            onTap: () => _toggleTray(ActiveTrayType.photo),
          ),
          _buildDockItem(
            icon: Icons.wallpaper_rounded,
            label: 'Background',
            isActive: _activeTray == ActiveTrayType.background,
            onTap: () => _toggleTray(ActiveTrayType.background),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // decreased padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 4, vertical: isActive ? 4 : 2),
              decoration: isActive
                  ? BoxDecoration(
                      color: _limeAccent, // Vibrant Lime Green Pill from screenshot!
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _darkBlack, width: 1.5),
                    )
                  : null,
              child: Icon(
                icon,
                color: isActive ? Colors.black : const Color(0xFF475569),
                size: 24, // Decreased icon size slightly
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : const Color(0xFF475569),
                fontSize: 11, // Increased text size
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeTextSize(double delta) {
    setState(() {
      if (_textStyles.containsKey(_selectedType)) {
        final style = _textStyles[_selectedType]!;
        style.size = (style.size + delta).clamp(10.0, 120.0);
      }
    });
  }

  void _showPositionSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 116.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Position', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionChip(Icons.vertical_align_top, 'Top', () => _alignSelected('top')),
                _buildActionChip(Icons.vertical_align_center, 'Center', () => _alignSelected('center')),
                _buildActionChip(Icons.vertical_align_bottom, 'Bottom', () => _alignSelected('bottom')),
                _buildActionChip(Icons.align_horizontal_left, 'Left', () => _alignSelected('left')),
                _buildActionChip(Icons.align_horizontal_right, 'Right', () => _alignSelected('right')),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Arrange', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => _moveZIndex(1), child: const Text('Forward'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => _moveZIndex(-1), child: const Text('Backward'))),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showNudgeSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 116.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nudge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            IconButton(icon: const Icon(Icons.arrow_upward), onPressed: () => _nudgeSelected(0, -1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _nudgeSelected(-1, 0)),
                const SizedBox(width: 48),
                IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => _nudgeSelected(1, 0)),
              ],
            ),
            IconButton(icon: const Icon(Icons.arrow_downward), onPressed: () => _nudgeSelected(0, 1)),
          ],
        ),
      ),
    );
  }

  void _showOpacitySheet() {
    // We need state inside the bottom sheet to update the slider
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          double currentOpacity = 1.0;
          if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
            currentOpacity = _overlayItems.firstWhere((i) => i.id == _selectedOverlayId).opacity;
          } else if (_activeTextLayer != null) {
            currentOpacity = _activeTextLayer!.opacity;
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 124.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transparency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${(currentOpacity * 100).toInt()}%'),
                  ],
                ),
                Slider(
                  value: currentOpacity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (val) {
                    setSheetState(() => currentOpacity = val);
                    setState(() {
                      if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
                        _overlayItems.firstWhere((i) => i.id == _selectedOverlayId).opacity = val;
                      } else if (_activeTextLayer != null) {
                        _activeTextLayer!.opacity = val;
                      }
                    });
                  },
                  onChangeEnd: (_) => _saveState(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }

  void _alignSelected(String position) {
    setState(() {
      final w = widget.template.width;
      final h = widget.template.height;

      void alignItem(dynamic item, double itemW, double itemH, bool isAbsolute) {
        if (isAbsolute) {
           if (position == 'left') item.position = Offset(0, item.position.dy);
           if (position == 'right') item.position = Offset(w - itemW, item.position.dy);
           if (position == 'center') item.position = Offset((w - itemW) / 2, item.position.dy);
           if (position == 'top') item.position = Offset(item.position.dx, 0);
           if (position == 'bottom') item.position = Offset(item.position.dx, h - itemH);
        } else {
           if (position == 'left') item.x = 0.0;
           if (position == 'right') item.x = 1.0 - (itemW / w);
           if (position == 'center') item.x = 0.5 - ((itemW / w) / 2);
           if (position == 'top') item.y = 0.0;
           if (position == 'bottom') item.y = 1.0 - (itemH / h);
        }
      }

      if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
        final item = _overlayItems.firstWhere((i) => i.id == _selectedOverlayId);
        if (!item.locked) alignItem(item, w * 0.9 * item.scale, h * 0.9 * item.scale, true);
      } else if (_selectedType == SelectedElementType.templateImage && _selectedOverlayId != null) {
        final layer = widget.template.imageLayers.firstWhere((i) => i.id == _selectedOverlayId);
        if (!layer.locked) alignItem(layer, layer.width * w, layer.height * h, false);
      } else if (_activeTextLayer != null) {
        if (!_activeTextLayer!.locked) alignItem(_activeTextLayer!, _activeTextLayer!.width * w, _activeTextLayer!.height * h, false);
      }
    });
    _saveState();
    Navigator.pop(context);
  }

  void _moveZIndex(int delta) {
    setState(() {
      final all = _getAllLayersMetadata();
      all.sort((a, b) => (a['zIndex'] as int).compareTo(b['zIndex'] as int));

      int selectedIdx = -1;
      for (int i = 0; i < all.length; i++) {
        if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
          if (all[i]['id'] == _selectedOverlayId) selectedIdx = i;
        } else if (_selectedType == SelectedElementType.photo && _selectedOverlayId != null) {
          if (all[i]['id'] == _selectedOverlayId) selectedIdx = i;
        } else if (_selectedType == SelectedElementType.shape && _selectedOverlayId != null) {
          if (all[i]['id'] == _selectedOverlayId) selectedIdx = i;
        } else if (_selectedType == SelectedElementType.templateImage && _selectedOverlayId != null) {
          if (all[i]['id'] == _selectedOverlayId) selectedIdx = i;
        } else if (_activeTextLayer != null) {
          if (all[i]['id'] == _activeTextLayer!.id) selectedIdx = i;
        }
      }

      if (selectedIdx != -1) {
        int targetIdx = selectedIdx + delta;
        if (targetIdx >= 0 && targetIdx < all.length) {
          final item = all.removeAt(selectedIdx);
          all.insert(targetIdx, item);

          for (int i = 0; i < all.length; i++) {
            final obj = all[i]['obj'];
            final newZ = i + 1;
            if (obj is TextLayer) obj.zIndex = newZ;
            else if (obj is ImageLayer) obj.zIndex = newZ;
            else if (obj is ShapeLayer) obj.zIndex = newZ;
            else if (obj is CanvasOverlayItem) obj.zIndex = newZ;
          }
          _saveState();
        }
      }
    });
  }
  void _nudgeSelected(double dx, double dy) {
    setState(() {
      final double speed = 35.0; // Increased speed for noticeable movement
      final moveX = dx * speed;
      final moveY = dy * speed;

      if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
        final item = _overlayItems.firstWhere((i) => i.id == _selectedOverlayId);
        if (!item.locked) item.position = Offset(item.position.dx + moveX, item.position.dy + moveY);
      } else if ((_selectedType == SelectedElementType.templateImage || _selectedType == SelectedElementType.shape) && _selectedOverlayId != null) {
        // Try image layers
        try {
          final layer = widget.template.imageLayers.firstWhere((i) => i.id == _selectedOverlayId);
          if (!layer.locked) {
            layer.x += (moveX / widget.template.width);
            layer.y += (moveY / widget.template.height);
          }
        } catch (e) {
          // If not in image layers, try shape layers
          try {
            final layer = widget.template.shapeLayers.firstWhere((i) => i.id == _selectedOverlayId);
            if (!layer.locked) {
              layer.x += (moveX / widget.template.width);
              layer.y += (moveY / widget.template.height);
            }
          } catch (e) {}
        }
      } else if (_activeTextLayer != null) {
        if (!_activeTextLayer!.locked) {
          _activeTextLayer!.x += (moveX / widget.template.width);
          _activeTextLayer!.y += (moveY / widget.template.height);
        }
      }
    });
    _saveState();
  }

  void _showFlipSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 124.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Flip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionChip(Icons.flip_rounded, 'Flip Horizontal', () {
                  setState(() {
                    if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
                      final item = _overlayItems.firstWhere((i) => i.id == _selectedOverlayId);
                      item.flipHorizontal = !item.flipHorizontal;
                    } else if (_activeTextLayer != null) {
                      _activeTextLayer!.flipHorizontal = !_activeTextLayer!.flipHorizontal;
                    }
                    _saveState();
                  });
                  Navigator.pop(context);
                }),
                _buildActionChip(Icons.flip_rounded, 'Flip Vertical', () {
                  // Actually should be a vertically flipped icon, but flip_rounded is standard
                  setState(() {
                    if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
                      final item = _overlayItems.firstWhere((i) => i.id == _selectedOverlayId);
                      item.flipVertical = !item.flipVertical;
                    } else if (_activeTextLayer != null) {
                      _activeTextLayer!.flipVertical = !_activeTextLayer!.flipVertical;
                    }
                    _saveState();
                  });
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _cropSelectedImage() async {
    if (_selectedType != SelectedElementType.photo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cropping is only supported for the main photo.')),
      );
      return;
    }

    String? imagePath = _localPhotoPath;

    if (imagePath == null) {
      // Download the template's default frame photo
      final layer = widget.template.imageLayers.firstWhere((i) => i.type == 'frame');
      final url = layer.url;
      if (url != null && url.isNotEmpty) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading photo for cropping...')),
          );
          final response = await http.get(Uri.parse(url));
          final documentDirectory = await getTemporaryDirectory();
          final file = File("${documentDirectory.path}/temp_photo_to_crop.png");
          await file.writeAsBytes(response.bodyBytes);
          imagePath = file.path;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error downloading image: $e')),
          );
          return;
        }
      }
    }

    if (imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo first to crop.')),
      );
      return;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: _darkBlack,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _localPhotoPath = croppedFile.path;
        });
        _saveState();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cropping failed: $e')),
      );
    }
  }

  Widget _buildSecondaryToolbar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildSecondaryToolbarButton(
            icon: Icons.layers_outlined,
            label: 'Layers',
            onTap: () {
              setState(() {
                _isLayersPanelOpen = true;
              });
            },
          ),
          _buildSecondaryToolbarButton(
            icon: Icons.compress_rounded,
            label: 'Position',
            onTap: _showPositionSheet,
          ),
          _buildSecondaryToolbarButton(
            icon: Icons.open_with_rounded,
            label: 'Nudge',
            onTap: _showNudgeSheet,
          ),
          _buildSecondaryToolbarButton(
            icon: Icons.opacity_rounded,
            label: 'Transparency',
            onTap: _showOpacitySheet,
          ),
          _buildSecondaryToolbarButton(
            icon: Icons.crop_rotate_rounded,
            label: 'Crop',
            onTap: _cropSelectedImage,
          ),
          _buildSecondaryToolbarButton(
            icon: Icons.flip_rounded,
            label: 'Flip',
            onTap: _showFlipSheet,
          ),
          _buildSecondaryToolbarButton(
            icon: Icons.copy_rounded,
            label: 'Duplicate',
            onTap: _duplicateSelected,
          ),
          _buildSecondaryToolbarButton(
            icon: Icons.group_work_outlined,
            label: 'Group',
            onTap: _showGroupSheet,
          ),
        ],
      ),
    );
  }

  void _duplicateSelected() {
    setState(() {
      if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
        final item = _overlayItems.firstWhere((i) => i.id == _selectedOverlayId);
        final newItem = item.clone();
        newItem.id = 'item_${DateTime.now().millisecondsSinceEpoch}';
        newItem.position = Offset(item.position.dx + 20, item.position.dy + 20);
        _overlayItems.add(newItem);
        _selectedOverlayId = newItem.id;
      } else if (_selectedType == SelectedElementType.templateImage && _selectedOverlayId != null) {
        final layer = widget.template.imageLayers.firstWhere((i) => i.id == _selectedOverlayId);
        final newLayer = layer.copyWith(
          x: layer.x + 0.02,
          y: layer.y + 0.02,
        );
        newLayer.id = 'img_${DateTime.now().millisecondsSinceEpoch}';
        widget.template.imageLayers.add(newLayer);
        _selectedOverlayId = newLayer.id;
      } else if (_activeTextLayer != null) {
        final newTextLayer = _activeTextLayer!.copyWith(
          x: _activeTextLayer!.x + 0.02,
          y: _activeTextLayer!.y + 0.02,
        );
        newTextLayer.id = 'txt_${DateTime.now().millisecondsSinceEpoch}';
        widget.template.textLayers.add(newTextLayer);
        _selectedType = SelectedElementType.overlay; // We don't have a generic text selection type, wait!
        // Actually for text layers, _selectedType is header/name/dates/tribute. If it's cloned, it loses its special type.
        // It becomes a generic text layer. For now just clone it.
      }
    });
    _saveState();
  }

  void _showGroupSheet() {
    // Find currently active/selected layer id and its groupId
    String? selectedId;
    String? selectedGroupId;
    
    if (_selectedType == SelectedElementType.overlay && _selectedOverlayId != null) {
      selectedId = _selectedOverlayId;
      try {
        final item = _overlayItems.firstWhere((i) => i.id == selectedId);
        selectedGroupId = item.groupId;
      } catch (_) {}
    } else if (_activeTextLayer != null) {
      selectedId = _activeTextLayer!.id;
      selectedGroupId = _activeTextLayer!.groupId;
    } else if (_selectedType == SelectedElementType.photo) {
      try {
        final layer = widget.template.imageLayers.firstWhere((i) => i.type == 'frame');
        selectedId = layer.id;
        selectedGroupId = layer.groupId;
      } catch (_) {}
    }

    final allLayers = _getAllLayersMetadata();
    
    // Set of selected layer IDs in the checklist
    final checkedIds = <String>{};
    
    // Pre-populate checkedIds
    if (selectedGroupId != null && selectedGroupId.isNotEmpty) {
      for (var l in allLayers) {
        final obj = l['obj'];
        String? gid;
        if (obj is TextLayer) gid = obj.groupId;
        else if (obj is ImageLayer) gid = obj.groupId;
        else if (obj is ShapeLayer) gid = obj.groupId;
        else if (obj is CanvasOverlayItem) gid = obj.groupId;
        
        if (gid == selectedGroupId) {
          checkedIds.add(l['id'] as String);
        }
      }
    } else if (selectedId != null) {
      checkedIds.add(selectedId);
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 116.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Group Layers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBlack)),
                    if (selectedGroupId != null && selectedGroupId.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent, size: 18),
                        label: const Text('Ungroup All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() {
                            for (var l in widget.template.textLayers) {
                              if (l.groupId == selectedGroupId) l.groupId = null;
                            }
                            for (var l in widget.template.imageLayers) {
                              if (l.groupId == selectedGroupId) l.groupId = null;
                            }
                            for (var l in widget.template.shapeLayers) {
                              if (l.groupId == selectedGroupId) l.groupId = null;
                            }
                            for (var l in _overlayItems) {
                              if (l.groupId == selectedGroupId) l.groupId = null;
                            }
                          });
                          _saveState();
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Select the items you want to group together. Moving any item in the group will move them all.', 
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25),
                  child: ListView(
                    shrinkWrap: true,
                    children: allLayers.map((l) {
                      final id = l['id'] as String;
                      final isChecked = checkedIds.contains(id);
                      return CheckboxListTile(
                        value: isChecked,
                        activeColor: _limeAccent,
                        checkColor: Colors.black,
                        title: Text(l['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        secondary: Icon(l['icon'] as IconData, color: isChecked ? _limeAccent : const Color(0xFF64748B)),
                        onChanged: (val) {
                          setSheetState(() {
                            if (val == true) {
                              checkedIds.add(id);
                            } else {
                              checkedIds.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _limeAccent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: _darkBlack, width: 1.5),
                          ),
                        ),
                        onPressed: checkedIds.length < 2 ? null : () {
                          final newGroupId = DateTime.now().millisecondsSinceEpoch.toString();
                          setState(() {
                            // Assign groupId to checked elements, clear for unchecked elements that were part of this group
                            for (var l in widget.template.textLayers) {
                              if (checkedIds.contains(l.id)) {
                                l.groupId = newGroupId;
                              } else if (l.groupId == selectedGroupId) {
                                l.groupId = null;
                              }
                            }
                            for (var l in widget.template.imageLayers) {
                              if (checkedIds.contains(l.id)) {
                                l.groupId = newGroupId;
                              } else if (l.groupId == selectedGroupId) {
                                l.groupId = null;
                              }
                            }
                            for (var l in widget.template.shapeLayers) {
                              if (checkedIds.contains(l.id)) {
                                l.groupId = newGroupId;
                              } else if (l.groupId == selectedGroupId) {
                                l.groupId = null;
                              }
                            }
                            for (var l in _overlayItems) {
                              if (checkedIds.contains(l.id)) {
                                l.groupId = newGroupId;
                              } else if (l.groupId == selectedGroupId) {
                                l.groupId = null;
                              }
                            }
                          });
                          _saveState();
                          Navigator.pop(context);
                        },
                        child: const Text('Group Selected', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryToolbarButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1E293B)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerResizeHandle({
    required Alignment alignment,
    required void Function(DragUpdateDetails details) onPanUpdate,
  }) {
    double? left, top, right, bottom;
    if (alignment == Alignment.topLeft) {
      left = -24;
      top = -24;
    } else if (alignment == Alignment.topRight) {
      right = -24;
      top = -24;
    } else if (alignment == Alignment.bottomLeft) {
      left = -24;
      bottom = -24;
    } else if (alignment == Alignment.bottomRight) {
      right = -24;
      bottom = -24;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        onPanEnd: (_) => _saveState(),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF94A3B8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAllLayersMetadata() {
    final all = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.template.textLayers.length; i++) {
      final layer = widget.template.textLayers[i];
      final title = i == 0 ? 'Header' : i == 1 ? 'Name' : i == 2 ? 'Dates' : 'Tribute';
      all.add({
        'id': layer.id,
        'zIndex': layer.zIndex,
        'type': 'text',
        'title': 'Text: $title',
        'icon': Icons.text_fields_rounded,
        'obj': layer,
      });
    }
    for (var layer in widget.template.imageLayers) {
      all.add({
        'id': layer.id,
        'zIndex': layer.zIndex,
        'type': 'image',
        'title': layer.type == 'frame' ? 'Custom Photo' : 'Image Overlay',
        'icon': Icons.image_rounded,
        'obj': layer,
      });
    }
    for (var layer in widget.template.shapeLayers) {
      all.add({
        'id': layer.id,
        'zIndex': layer.zIndex,
        'type': 'shape',
        'title': 'Shape',
        'icon': Icons.category_rounded,
        'obj': layer,
      });
    }
    for (var layer in _overlayItems) {
      all.add({
        'id': layer.id,
        'zIndex': layer.zIndex,
        'type': 'flower',
        'title': layer.graphic.name,
        'icon': Icons.local_florist_rounded,
        'obj': layer,
      });
    }
    all.sort((a, b) => (b['zIndex'] as int).compareTo(a['zIndex'] as int)); // Highest zIndex at top
    return all;
  }

  Widget _buildLayersPanel() {
    final allLayers = _getAllLayersMetadata();
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced vertical padding
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Layers',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)), // Reduced font size slightly
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: () {
                    setState(() {
                      _isLayersPanelOpen = false;
                    });
                  },
                ),
              ],
            ),
          ),
          // Draggable List
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = allLayers.removeAt(oldIndex);
                allLayers.insert(newIndex, item);
                
                // Re-assign z-indexes based on new list order (reversed since highest zIndex is at top)
                setState(() {
                  for (int i = 0; i < allLayers.length; i++) {
                    final newZ = allLayers.length - i;
                    final obj = allLayers[i]['obj'];
                    if (obj is TextLayer) obj.zIndex = newZ;
                    else if (obj is ImageLayer) obj.zIndex = newZ;
                    else if (obj is ShapeLayer) obj.zIndex = newZ;
                    else if (obj is CanvasOverlayItem) obj.zIndex = newZ;
                  }
                  _saveState();
                });
              },
              children: allLayers.map((layer) {
                final obj = layer['obj'];
                bool isHidden = false;
                bool isLocked = false;
                if (obj is TextLayer) { isHidden = obj.hidden; isLocked = obj.locked; }
                else if (obj is ImageLayer) { isHidden = obj.hidden; isLocked = obj.locked; }
                else if (obj is ShapeLayer) { isHidden = obj.hidden; isLocked = obj.locked; }
                else if (obj is CanvasOverlayItem) { isHidden = obj.hidden; isLocked = obj.locked; }
                bool isSelected = false;
                if (obj is TextLayer && _activeTextLayer?.id == obj.id) isSelected = true;
                if (obj is ImageLayer && _selectedOverlayId == obj.id) isSelected = true;
                if (obj is ShapeLayer && _selectedOverlayId == obj.id) isSelected = true;
                if (obj is CanvasOverlayItem && _selectedOverlayId == obj.id) isSelected = true;

                return ListTile(
                  key: ValueKey(layer['id']),
                  selected: isSelected,
                  selectedTileColor: _limeAccent.withOpacity(0.12),
                  onTap: () {
                    setState(() {
                      if (obj is TextLayer) {
                        _activeTextLayer = obj;
                        _selectedOverlayId = null;
                        final layerIndex = widget.template.textLayers.indexOf(obj);
                        _selectedType = layerIndex == 0 ? SelectedElementType.header : layerIndex == 1 ? SelectedElementType.name : layerIndex == 2 ? SelectedElementType.dates : SelectedElementType.tribute;
                        _openIntegratedTextTrayFor(_selectedType);
                      } else if (obj is ImageLayer) {
                        _selectedOverlayId = obj.id;
                        _selectedType = obj.type == 'frame' ? SelectedElementType.photo : SelectedElementType.templateImage;
                        _activeTray = obj.type == 'frame' ? ActiveTrayType.photo : ActiveTrayType.none;
                      } else if (obj is ShapeLayer) {
                        _selectedOverlayId = obj.id;
                        _selectedType = SelectedElementType.shape;
                        _activeTray = ActiveTrayType.none;
                      } else if (obj is CanvasOverlayItem) {
                        _selectedOverlayId = obj.id;
                        _selectedType = SelectedElementType.overlay;
                        if (!obj.graphic.isImageOverlay) _activeTray = ActiveTrayType.colors;
                      }
                      // Close layers panel when an item is selected
                      // _isLayersPanelOpen = false; // optional, users might want it to stay open
                    });
                  },
                  leading: Icon(layer['icon'] as IconData, color: isSelected ? _limeAccent : const Color(0xFF64748B)),
                  title: Text(layer['title'] as String, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                        onPressed: () {
                          setState(() {
                            if (obj is TextLayer) obj.hidden = !obj.hidden;
                            else if (obj is ImageLayer) obj.hidden = !obj.hidden;
                            else if (obj is ShapeLayer) obj.hidden = !obj.hidden;
                            else if (obj is CanvasOverlayItem) obj.hidden = !obj.hidden;
                          });
                          _saveState();
                        },
                      ),
                      IconButton(
                        icon: Icon(isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 20),
                        onPressed: () {
                          setState(() {
                            if (obj is TextLayer) obj.locked = !obj.locked;
                            else if (obj is ImageLayer) obj.locked = !obj.locked;
                            else if (obj is ShapeLayer) obj.locked = !obj.locked;
                            else if (obj is CanvasOverlayItem) obj.locked = !obj.locked;
                          });
                          _saveState();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            if (obj is TextLayer) widget.template.textLayers.remove(obj);
                            else if (obj is ImageLayer) widget.template.imageLayers.remove(obj);
                            else if (obj is ShapeLayer) widget.template.shapeLayers.remove(obj);
                            else if (obj is CanvasOverlayItem) _overlayItems.remove(obj);
                            
                            if (obj is TextLayer && _activeTextLayer?.id == obj.id) { _activeTextLayer = null; _selectedType = SelectedElementType.none; }
                            if ((obj is ImageLayer || obj is ShapeLayer || obj is CanvasOverlayItem) && _selectedOverlayId == obj.id) { _selectedOverlayId = null; _selectedType = SelectedElementType.none; }
                          });
                          _saveState();
                        },
                      ),
                      const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// UNDO/REDO STATE SNAPSHOT
class EditorStateSnapshot {
  final Map<String, dynamic> templateJson;
  final List<CanvasOverlayItem> overlayItems;
  final int frameShapeIndex;
  final String? customFrameImagePath;
  final String? localBackgroundPath;
  final String? localPhotoPath;

  EditorStateSnapshot({
    required this.templateJson,
    required this.overlayItems,
    required this.frameShapeIndex,
    this.customFrameImagePath,
    this.localBackgroundPath,
    this.localPhotoPath,
  });
}
