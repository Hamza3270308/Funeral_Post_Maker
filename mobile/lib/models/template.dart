class Template {
  final String id;
  final String title;
  final String status;
  final String thumbnailUrl;
  final double width;
  final double height;
  final Background background;
  final List<TextLayer> textLayers;
  final List<ImageLayer> imageLayers;
  final List<ShapeLayer> shapeLayers;

  Template({
    required this.id,
    required this.title,
    required this.status,
    required this.thumbnailUrl,
    required this.width,
    required this.height,
    required this.background,
    required this.textLayers,
    required this.imageLayers,
    required this.shapeLayers,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'draft',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      width: (json['width'] ?? 1080).toDouble(),
      height: (json['height'] ?? 1080).toDouble(),
      background: Background.fromJson(json['background'] ?? {}),
      textLayers: (json['textLayers'] as List<dynamic>?)?.map((l) => TextLayer.fromJson(l)).toList() ?? [],
      imageLayers: (json['imageLayers'] as List<dynamic>?)?.map((l) => ImageLayer.fromJson(l)).toList() ?? [],
      shapeLayers: (json['shapeLayers'] as List<dynamic>?)?.map((l) => ShapeLayer.fromJson(l)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'status': status,
      'thumbnailUrl': thumbnailUrl,
      'width': width,
      'height': height,
      'background': background.toJson(),
      'textLayers': textLayers.map((l) => l.toJson()).toList(),
      'imageLayers': imageLayers.map((l) => l.toJson()).toList(),
      'shapeLayers': shapeLayers.map((l) => l.toJson()).toList(),
    };
  }

  Template copyWith({
    String? title,
    String? thumbnailUrl,
    Background? background,
    List<TextLayer>? textLayers,
    List<ImageLayer>? imageLayers,
    List<ShapeLayer>? shapeLayers,
  }) {
    return Template(
      id: id,
      title: title ?? this.title,
      status: status,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      width: width,
      height: height,
      background: background ?? this.background,
      textLayers: textLayers ?? this.textLayers,
      imageLayers: imageLayers ?? this.imageLayers,
      shapeLayers: shapeLayers ?? this.shapeLayers,
    );
  }
}

class Background {
  final String type; // 'color' | 'image'
  final String value;

  Background({required this.type, required this.value});

  factory Background.fromJson(Map<String, dynamic> json) {
    return Background(
      type: json['type'] ?? 'color',
      value: json['value'] ?? '#FFFFFF',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }
}

class TextLayer {
  String id;
  String content;
  String fontFamily;
  double fontSize;
  String color;
  String alignment;
  double x;
  double y;
  double width;
  double height;
  String fontWeight;
  String fontStyle;
  String textDecoration;
  String textTransform;
  double opacity;
  double rotation;
  bool hasShadow;
  String shadowColor;
  double shadowBlur;
  double shadowOffsetX;
  double shadowOffsetY;
  double glowBlur;
  String glowColor;
  double echoOffsetX;
  double echoOffsetY;
  String echoColor;
  double neonIntensity;
  String neonColor;
  double curveIntensity;
  double outlineWidth;
  String outlineColor;
  String textBackgroundColor;
  double letterSpacing;
  double lineHeight;
  int zIndex;
  bool flipHorizontal;
  bool flipVertical;
  bool hidden;
  bool locked;
  String? groupId;

  TextLayer({
    required this.id,
    required this.content,
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    required this.alignment,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fontWeight,
    required this.fontStyle,
    required this.textDecoration,
    this.textTransform = 'none',
    required this.opacity,
    this.rotation = 0.0,
    this.hasShadow = false,
    this.shadowColor = '#000000',
    this.shadowBlur = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.glowBlur = 0.0,
    this.glowColor = '#ffffff',
    this.echoOffsetX = 0.0,
    this.echoOffsetY = 0.0,
    this.echoColor = '#000000',
    this.neonIntensity = 0.0,
    this.neonColor = '#000000',
    this.curveIntensity = 0.0,
    this.outlineWidth = 0.0,
    this.outlineColor = '#000000',
    this.textBackgroundColor = '',
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.zIndex = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.hidden = false,
    this.locked = false,
    this.groupId,
  });

  factory TextLayer.fromJson(Map<String, dynamic> json) {
    return TextLayer(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      fontFamily: json['fontFamily'] ?? 'Inter',
      fontSize: (json['fontSize'] ?? 16).toDouble(),
      color: json['color'] ?? '#000000',
      alignment: json['alignment'] ?? 'center',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 200).toDouble(),
      height: (json['height'] ?? 40).toDouble(),
      fontWeight: json['fontWeight'] ?? 'normal',
      fontStyle: json['fontStyle'] ?? 'normal',
      textDecoration: json['textDecoration'] ?? 'none',
      textTransform: json['textTransform'] ?? 'none',
      opacity: (json['opacity'] ?? 1.0).toDouble(),
      rotation: (json['rotation'] ?? 0.0).toDouble(),
      hasShadow: json['hasShadow'] ?? false,
      shadowColor: json['shadowColor'] ?? '#000000',
      shadowBlur: (json['shadowBlur'] ?? 0.0).toDouble(),
      shadowOffsetX: (json['shadowOffsetX'] ?? 0.0).toDouble(),
      shadowOffsetY: (json['shadowOffsetY'] ?? 0.0).toDouble(),
      glowBlur: (json['glowBlur'] ?? 0.0).toDouble(),
      glowColor: json['glowColor'] ?? '#ffffff',
      echoOffsetX: (json['echoOffsetX'] ?? 0.0).toDouble(),
      echoOffsetY: (json['echoOffsetY'] ?? 0.0).toDouble(),
      echoColor: json['echoColor'] ?? '#000000',
      neonIntensity: (json['neonIntensity'] ?? 0.0).toDouble(),
      neonColor: json['neonColor'] ?? '#000000',
      curveIntensity: (json['curveIntensity'] ?? 0.0).toDouble(),
      outlineWidth: (json['outlineWidth'] ?? 0.0).toDouble(),
      outlineColor: json['outlineColor'] ?? '#000000',
      textBackgroundColor: json['textBackgroundColor'] ?? '',
      letterSpacing: (json['letterSpacing'] ?? 0.0).toDouble(),
      lineHeight: (json['lineHeight'] ?? 1.2).toDouble(),
      zIndex: json['zIndex'] ?? 0,
      flipHorizontal: json['flipHorizontal'] ?? false,
      flipVertical: json['flipVertical'] ?? false,
      hidden: json['hidden'] ?? false,
      locked: json['locked'] ?? false,
      groupId: json['groupId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'color': color,
      'alignment': alignment,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'fontWeight': fontWeight,
      'fontStyle': fontStyle,
      'textDecoration': textDecoration,
      'textTransform': textTransform,
      'opacity': opacity,
      'rotation': rotation,
      'hasShadow': hasShadow,
      'shadowColor': shadowColor,
      'shadowBlur': shadowBlur,
      'shadowOffsetX': shadowOffsetX,
      'shadowOffsetY': shadowOffsetY,
      'glowBlur': glowBlur,
      'glowColor': glowColor,
      'echoOffsetX': echoOffsetX,
      'echoOffsetY': echoOffsetY,
      'echoColor': echoColor,
      'neonIntensity': neonIntensity,
      'neonColor': neonColor,
      'curveIntensity': curveIntensity,
      'zIndex': zIndex,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'hidden': hidden,
      'locked': locked,
      if (groupId != null) 'groupId': groupId,
    };
  }

  TextLayer copyWith({
    String? content,
    String? fontFamily,
    double? fontSize,
    String? fontWeight,
    String? fontStyle,
    String? textDecoration,
    String? alignment,
    String? color,
    double? x,
    double? y,
    double? width,
    double? height,
    double? opacity,
    double? rotation,
    int? zIndex,
    bool? flipHorizontal,
    bool? flipVertical,
    bool? hidden,
    bool? locked,
    String? groupId,
  }) {
    return TextLayer(
      id: this.id,
      content: content ?? this.content,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      alignment: alignment ?? this.alignment,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      textDecoration: textDecoration ?? this.textDecoration,
      textTransform: this.textTransform,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      hasShadow: this.hasShadow,
      shadowColor: this.shadowColor,
      shadowBlur: this.shadowBlur,
      shadowOffsetX: this.shadowOffsetX,
      shadowOffsetY: this.shadowOffsetY,
      glowBlur: this.glowBlur,
      glowColor: this.glowColor,
      echoOffsetX: this.echoOffsetX,
      echoOffsetY: this.echoOffsetY,
      echoColor: this.echoColor,
      neonIntensity: this.neonIntensity,
      neonColor: this.neonColor,
      curveIntensity: this.curveIntensity,
      outlineWidth: this.outlineWidth,
      outlineColor: this.outlineColor,
      textBackgroundColor: this.textBackgroundColor,
      letterSpacing: this.letterSpacing,
      lineHeight: this.lineHeight,
      zIndex: zIndex ?? this.zIndex,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      hidden: hidden ?? this.hidden,
      locked: locked ?? this.locked,
      groupId: groupId ?? this.groupId,
    );
  }
}

class ImageLayer {
  String id;
  String type; // 'frame' | 'sticker'
  String url;
  String maskShape; // 'none' | 'circle' | 'rounded_rect'
  double x;
  double y;
  double width;
  double height;
  double rotation;
  double opacity;
  double borderWidth;
  String borderColor;
  String mixBlendMode;
  int zIndex;
  bool flipHorizontal;
  bool flipVertical;
  bool hidden;
  bool locked;
  String? groupId;

  ImageLayer({
    required this.id,
    required this.type,
    required this.url,
    required this.maskShape,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.opacity,
    required this.borderWidth,
    required this.borderColor,
    this.mixBlendMode = 'normal',
    this.zIndex = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.hidden = false,
    this.locked = false,
    this.groupId,
  });

  factory ImageLayer.fromJson(Map<String, dynamic> json) {
    return ImageLayer(
      id: json['id'] ?? '',
      type: json['type'] ?? 'frame',
      url: json['url'] ?? '',
      maskShape: json['maskShape'] ?? 'none',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 100).toDouble(),
      height: (json['height'] ?? 100).toDouble(),
      rotation: (json['rotation'] ?? 0).toDouble(),
      opacity: (json['opacity'] ?? 1.0).toDouble(),
      borderWidth: (json['borderWidth'] ?? 0).toDouble(),
      borderColor: json['borderColor'] ?? '#000000',
      mixBlendMode: json['mixBlendMode'] ?? 'normal',
      zIndex: json['zIndex'] ?? 0,
      flipHorizontal: json['flipHorizontal'] ?? false,
      flipVertical: json['flipVertical'] ?? false,
      hidden: json['hidden'] ?? false,
      locked: json['locked'] ?? false,
      groupId: json['groupId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'maskShape': maskShape,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'opacity': opacity,
      'borderWidth': borderWidth,
      'borderColor': borderColor,
      'mixBlendMode': mixBlendMode,
      'zIndex': zIndex,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'hidden': hidden,
      'locked': locked,
      if (groupId != null) 'groupId': groupId,
    };
  }

  ImageLayer copyWith({
    String? url,
    double? borderWidth,
    String? borderColor,
    String? mixBlendMode,
    double? x,
    double? y,
    double? width,
    double? height,
    double? opacity,
    double? rotation,
    int? zIndex,
    bool? flipHorizontal,
    bool? flipVertical,
    bool? hidden,
    bool? locked,
    String? groupId,
  }) {
    return ImageLayer(
      id: id,
      type: type,
      url: url ?? this.url,
      maskShape: maskShape,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      mixBlendMode: mixBlendMode ?? this.mixBlendMode,
      zIndex: zIndex ?? this.zIndex,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      hidden: hidden ?? this.hidden,
      locked: locked ?? this.locked,
      groupId: groupId ?? this.groupId,
    );
  }
}

class ShapeLayer {
  final String id;
  final String shape; // 'circle' | 'square' | 'rounded-rectangle' | 'oval' | 'arch'
  String color;
  double x;
  double y;
  double width;
  double height;
  double opacity;
  final double borderWidth;
  final String borderColor;
  int zIndex;
  bool hidden;
  bool locked;
  String? groupId;

  ShapeLayer({
    required this.id,
    required this.shape,
    required this.color,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.opacity,
    required this.borderWidth,
    required this.borderColor,
    this.zIndex = 0,
    this.hidden = false,
    this.locked = false,
    this.groupId,
  });

  factory ShapeLayer.fromJson(Map<String, dynamic> json) {
    return ShapeLayer(
      id: json['id'] ?? '',
      shape: json['shape'] ?? 'square',
      color: json['color'] ?? '#C5A880',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 100).toDouble(),
      height: (json['height'] ?? 100).toDouble(),
      opacity: (json['opacity'] ?? 1.0).toDouble(),
      borderWidth: (json['borderWidth'] ?? 0).toDouble(),
      borderColor: json['borderColor'] ?? '#000000',
      zIndex: json['zIndex'] ?? 0,
      hidden: json['hidden'] ?? false,
      locked: json['locked'] ?? false,
      groupId: json['groupId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shape': shape,
      'color': color,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'opacity': opacity,
      'borderWidth': borderWidth,
      'borderColor': borderColor,
      'zIndex': zIndex,
      'hidden': hidden,
      'locked': locked,
      if (groupId != null) 'groupId': groupId,
    };
  }

  ShapeLayer copyWith({
    String? color,
    double? x,
    double? y,
    double? width,
    double? height,
    double? opacity,
    int? zIndex,
    bool? hidden,
    bool? locked,
    String? groupId,
  }) {
    return ShapeLayer(
      id: this.id,
      shape: this.shape,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
      borderWidth: this.borderWidth,
      borderColor: this.borderColor,
      zIndex: zIndex ?? this.zIndex,
      hidden: hidden ?? this.hidden,
      locked: locked ?? this.locked,
      groupId: groupId ?? this.groupId,
    );
  }
}
