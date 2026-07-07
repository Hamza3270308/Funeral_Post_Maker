class Template {
  final String id;
  final String title;
  final String category;
  final String status;
  final double width;
  final double height;
  final Background background;
  final List<TextLayer> textLayers;
  final List<ImageLayer> imageLayers;
  final List<ShapeLayer> shapeLayers;

  Template({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
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
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 1080.0,
      height: (json['height'] as num?)?.toDouble() ?? 1920.0,
      background: Background.fromJson(json['background'] ?? {}),
      textLayers: (json['textLayers'] as List? ?? [])
          .map((item) => TextLayer.fromJson(item))
          .toList(),
      imageLayers: (json['imageLayers'] as List? ?? [])
          .map((item) => ImageLayer.fromJson(item))
          .toList(),
      shapeLayers: (json['shapeLayers'] as List? ?? [])
          .map((item) => ShapeLayer.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'status': status,
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
    double? width,
    double? height,
    Background? background,
    List<TextLayer>? textLayers,
    List<ImageLayer>? imageLayers,
    List<ShapeLayer>? shapeLayers,
  }) {
    return Template(
      id: id,
      title: title ?? this.title,
      category: category,
      status: status,
      width: width ?? this.width,
      height: height ?? this.height,
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
  final String id;
  final String content;
  final String fontFamily;
  final double fontSize;
  final String color;
  final String alignment;
  final double x;
  final double y;
  final double width;
  final double height;
  final String fontWeight;
  final String fontStyle;
  final String textDecoration;
  final double opacity;
  final double rotation;
  final bool hasShadow;
  final String shadowColor;
  final double shadowBlur;

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
    required this.opacity,
    required this.rotation,
    required this.hasShadow,
    required this.shadowColor,
    required this.shadowBlur,
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
      opacity: (json['opacity'] ?? 1.0).toDouble(),
      rotation: (json['rotation'] ?? 0).toDouble(),
      hasShadow: json['hasShadow'] ?? false,
      shadowColor: json['shadowColor'] ?? 'rgba(0,0,0,0.5)',
      shadowBlur: (json['shadowBlur'] ?? 4).toDouble(),
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
      'opacity': opacity,
      'rotation': rotation,
      'hasShadow': hasShadow,
      'shadowColor': shadowColor,
      'shadowBlur': shadowBlur,
    };
  }

  TextLayer copyWith({
    String? content,
    String? fontFamily,
    double? fontSize,
    String? color,
    String? alignment,
    double? x,
    double? y,
    double? width,
    double? height,
    String? fontWeight,
    String? fontStyle,
    String? textDecoration,
    double? opacity,
    double? rotation,
    bool? hasShadow,
    String? shadowColor,
    double? shadowBlur,
  }) {
    return TextLayer(
      id: id,
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
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
    );
  }
}

class ImageLayer {
  final String id;
  final String type; // 'frame' | 'sticker'
  final String url;
  final String maskShape; // 'none' | 'circle' | 'rounded_rect'
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double opacity;
  final double borderWidth;
  final String borderColor;

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
    };
  }

  ImageLayer copyWith({String? url}) {
    return ImageLayer(
      id: id,
      type: type,
      url: url ?? this.url,
      maskShape: maskShape,
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
      opacity: opacity,
      borderWidth: borderWidth,
      borderColor: borderColor,
    );
  }
}

class ShapeLayer {
  final String id;
  final String shape; // 'circle' | 'square' | 'rounded-rectangle' | 'oval' | 'arch' | 'line' | 'triangle'
  final String color;
  final double x;
  final double y;
  final double width;
  final double height;
  final double opacity;
  final double borderWidth;
  final String borderColor;
  final double rotation;

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
    required this.rotation,
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
      rotation: (json['rotation'] ?? 0).toDouble(),
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
      'rotation': rotation,
    };
  }
}
