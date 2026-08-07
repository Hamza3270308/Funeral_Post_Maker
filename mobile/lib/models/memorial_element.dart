import 'package:flutter/material.dart';

class MemorialVerse {
  final String id;
  final String category;
  final String title;
  final String text;

  const MemorialVerse({
    required this.id,
    required this.category,
    required this.title,
    required this.text,
  });
}

class MemorialGraphic {
  final String id;
  final String category;
  final String name;
  // For floral overlay images — URL path resolved at runtime
  final String? imageFile; // e.g. 'floral_white_roses.png'
  // Legacy icon fallback for non-image graphics
  final IconData? iconData;
  final Color defaultColor;
  final double defaultSize;

  const MemorialGraphic({
    required this.id,
    required this.category,
    required this.name,
    this.imageFile,
    this.iconData,
    this.defaultColor = const Color(0xFF2C3E50),
    this.defaultSize = 64.0,
  });

  /// Returns true if this graphic uses a real image from the backend
  bool get isImageOverlay => imageFile != null;
}

class CanvasOverlayItem {
  String id;
  final MemorialGraphic graphic;
  Offset position;
  double scale;
  double rotation;
  Color color;
  int zIndex;
  bool flipHorizontal;
  bool flipVertical;
  double opacity;
  bool hidden;
  bool locked;
  String? groupId;

  CanvasOverlayItem({
    required this.id,
    required this.graphic,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    required this.color,
    this.zIndex = 100, // Default to a high number so new overlays go on top initially
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.opacity = 1.0,
    this.hidden = false,
    this.locked = false,
    this.groupId,
  });

  CanvasOverlayItem clone() {
    return CanvasOverlayItem(
      id: id,
      graphic: graphic,
      position: Offset(position.dx, position.dy),
      scale: scale,
      rotation: rotation,
      color: color,
      zIndex: zIndex,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
      opacity: opacity,
      hidden: hidden,
      locked: locked,
      groupId: groupId,
    );
  }
}
