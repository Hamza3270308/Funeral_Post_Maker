import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/template.dart';
import '../services/api_service.dart';

class TemplateCardPreview extends StatelessWidget {
  final Template template;

  const TemplateCardPreview({
    super.key,
    required this.template,
  });

  Color _parseHexColor(String hexString, {Color fallback = Colors.transparent}) {
    try {
      final buffer = StringBuffer();
      if (hexString.startsWith('#')) {
        if (hexString.length == 7) buffer.write('ff');
        buffer.write(hexString.replaceFirst('#', ''));
      } else if (hexString.length == 6 || hexString.length == 8) {
        if (hexString.length == 6) buffer.write('ff');
        buffer.write(hexString);
      } else {
        return fallback;
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (template.thumbnailUrl.isNotEmpty &&
        (template.thumbnailUrl.startsWith('http') ||
         template.thumbnailUrl.startsWith('/') ||
         template.thumbnailUrl.startsWith('assets/'))) {
      final resolvedUrl = ApiService.resolveImageUrl(template.thumbnailUrl);
      return CachedNetworkImage(
        imageUrl: resolvedUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildLiveCanvas(context),
        errorWidget: (_, __, ___) => _buildLiveCanvas(context),
      );
    }

    return _buildLiveCanvas(context);
  }

  Widget _buildLiveCanvas(BuildContext context) {
    final w = template.width > 0 ? template.width : 1080.0;
    final h = template.height > 0 ? template.height : 1920.0;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(child: _buildBackground(w, h)),
              ..._buildSortedLayers(w, h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(double w, double h) {
    final bg = template.background;
    if (bg.type == 'image' && bg.value.isNotEmpty) {
      final resolved = ApiService.resolveImageUrl(bg.value);
      if (resolved.startsWith('assets/')) {
        return Image.asset(
          resolved,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.white),
        );
      }
      return CachedNetworkImage(
        imageUrl: resolved,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: const Color(0xFFF1F5F9)),
        errorWidget: (_, __, ___) => Container(color: Colors.white),
      );
    }

    if (bg.type == 'color' && bg.value.isNotEmpty) {
      return Container(
        color: _parseHexColor(bg.value, fallback: Colors.white),
      );
    }

    return Container(color: Colors.white);
  }

  List<Widget> _buildSortedLayers(double w, double h) {
    final items = <Map<String, dynamic>>[];

    for (var layer in template.shapeLayers) {
      if (!layer.hidden) {
        items.add({
          'zIndex': layer.zIndex,
          'widget': _buildShapeLayer(layer, w, h),
        });
      }
    }

    for (var layer in template.imageLayers) {
      if (!layer.hidden) {
        items.add({
          'zIndex': layer.zIndex,
          'widget': _buildImageLayer(layer, w, h),
        });
      }
    }

    for (var layer in template.textLayers) {
      if (!layer.hidden) {
        items.add({
          'zIndex': layer.zIndex,
          'widget': _buildTextLayer(layer, w, h),
        });
      }
    }

    items.sort((a, b) => (a['zIndex'] as int).compareTo(b['zIndex'] as int));
    return items.map((e) => e['widget'] as Widget).toList();
  }

  Widget _buildShapeLayer(ShapeLayer layer, double w, double h) {
    final colorStr = layer.color.trim();
    BoxDecoration decoration;

    final shapeRadius = (layer.borderRadius ?? 0) > 0 ? (layer.borderRadius! * w) : 0.0;

    if (colorStr.startsWith('linear-gradient')) {
      final match = RegExp(r'linear-gradient\((\d+)deg,\s*(#[0-9a-fA-F]{6}),\s*(#[0-9a-fA-F]{6}|transparent)\)')
          .firstMatch(colorStr);
      final angle = match != null ? double.tryParse(match.group(1)!) ?? 135 : 135;
      final c1 = match != null ? _parseHexColor(match.group(2)!) : Colors.grey;
      final c2Str = match?.group(3) ?? 'transparent';
      final c2 = c2Str == 'transparent' ? Colors.transparent : _parseHexColor(c2Str);
      final rad = angle * (pi / 180);

      decoration = BoxDecoration(
        shape: layer.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: layer.shape != 'circle' && shapeRadius > 0
            ? BorderRadius.circular(shapeRadius)
            : null,
        gradient: LinearGradient(
          begin: Alignment(sin(rad), -cos(rad)),
          end: Alignment(-sin(rad), cos(rad)),
          colors: [c1, c2],
        ),
        border: layer.borderWidth > 0
            ? Border.all(
                color: _parseHexColor(layer.borderColor, fallback: Colors.black),
                width: layer.borderWidth * w,
              )
            : null,
      );
    } else {
      decoration = BoxDecoration(
        shape: layer.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: layer.shape != 'circle' && shapeRadius > 0
            ? BorderRadius.circular(shapeRadius)
            : null,
        color: _parseHexColor(colorStr, fallback: const Color(0xFF4A6572)),
        border: layer.borderWidth > 0
            ? Border.all(
                color: _parseHexColor(layer.borderColor, fallback: Colors.black),
                width: layer.borderWidth * w,
              )
            : null,
      );
    }

    Widget shapeWidget = Opacity(
      opacity: layer.opacity.clamp(0.0, 1.0),
      child: Container(decoration: decoration),
    );

    if (layer.rotation != 0) {
      shapeWidget = Transform(
        alignment: Alignment.topLeft,
        transform: Matrix4.rotationZ(layer.rotation * (pi / 180.0)),
        child: shapeWidget,
      );
    }

    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      height: layer.height * h,
      child: shapeWidget,
    );
  }

  Widget _buildImageLayer(ImageLayer layer, double w, double h) {
    final isSticker = layer.type == 'sticker';
    final resolvedUrl = ApiService.resolveImageUrl(layer.url);
    Widget imageContent;

    if (isSticker) {
      if (resolvedUrl.startsWith('assets/')) {
        imageContent = Image.asset(
          resolvedUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      } else if (resolvedUrl.contains('/flowers/')) {
        final cleanFileName = resolvedUrl.split('/flowers/').last.split('?').first;
        imageContent = Image.asset(
          'assets/flowers/$cleanFileName',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => CachedNetworkImage(
            imageUrl: resolvedUrl,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      } else if (resolvedUrl.isNotEmpty) {
        imageContent = CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        );
      } else {
        imageContent = const SizedBox.shrink();
      }
    } else {
      Widget rawPhoto;
      if (resolvedUrl.startsWith('assets/')) {
        rawPhoto = Image.asset(resolvedUrl, fit: BoxFit.cover);
      } else if (resolvedUrl.isNotEmpty) {
        rawPhoto = CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildPlaceholderPhoto(),
        );
      } else {
        rawPhoto = _buildPlaceholderPhoto();
      }

      if (layer.maskShape == 'circle') {
        imageContent = ClipOval(child: rawPhoto);
      } else if (layer.maskShape == 'rounded_rect') {
        imageContent = ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: rawPhoto,
        );
      } else {
        imageContent = rawPhoto;
      }

      if (layer.borderWidth > 0) {
        imageContent = Container(
          decoration: BoxDecoration(
            shape: layer.maskShape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: layer.maskShape == 'rounded_rect'
                ? BorderRadius.circular(16.0)
                : null,
            border: Border.all(
              color: _parseHexColor(layer.borderColor, fallback: Colors.black),
              width: layer.borderWidth * w,
            ),
          ),
          child: imageContent,
        );
      }
    }

    Widget interactiveChild = Opacity(
      opacity: layer.opacity.clamp(0.0, 1.0),
      child: imageContent,
    );

    if (layer.rotation != 0) {
      interactiveChild = Transform(
        alignment: Alignment.topLeft,
        transform: Matrix4.rotationZ(layer.rotation * (pi / 180.0)),
        child: interactiveChild,
      );
    }

    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      height: layer.height * h,
      child: interactiveChild,
    );
  }

  Widget _buildPlaceholderPhoto() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 48,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildTextLayer(TextLayer layer, double w, double h) {
    Color textColor = _parseHexColor(layer.color, fallback: Colors.black87);
    TextStyle style;

    try {
      style = GoogleFonts.getFont(
        layer.fontFamily,
        fontSize: layer.fontSize * w,
        fontWeight: layer.fontWeight == 'bold' ? FontWeight.w700 : FontWeight.w400,
        fontStyle: layer.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
        decoration: layer.textDecoration == 'underline' ? TextDecoration.underline : TextDecoration.none,
        color: textColor,
        letterSpacing: layer.letterSpacing * w,
        height: layer.lineHeight,
      );
    } catch (_) {
      style = TextStyle(
        fontFamily: layer.fontFamily,
        fontSize: layer.fontSize * w,
        fontWeight: layer.fontWeight == 'bold' ? FontWeight.w700 : FontWeight.w400,
        fontStyle: layer.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
        decoration: layer.textDecoration == 'underline' ? TextDecoration.underline : TextDecoration.none,
        color: textColor,
        letterSpacing: layer.letterSpacing * w,
        height: layer.lineHeight,
      );
    }

    Widget textWidget = Text(
      layer.textTransform == 'uppercase' ? layer.content.toUpperCase() : layer.content,
      style: style,
      textAlign: layer.alignment == 'center'
          ? TextAlign.center
          : (layer.alignment == 'right' ? TextAlign.right : TextAlign.left),
      overflow: TextOverflow.clip,
    );

    if (layer.rotation != 0) {
      textWidget = Transform(
        alignment: Alignment.topLeft,
        transform: Matrix4.rotationZ(layer.rotation * (pi / 180.0)),
        child: textWidget,
      );
    }

    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width > 0 ? layer.width * w : null,
      child: textWidget,
    );
  }
}
