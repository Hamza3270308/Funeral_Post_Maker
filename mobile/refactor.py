import os

file_path = 'lib/screens/editor_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Replace _buildShapeLayer
shape_old = """  Widget _buildShapeLayer(ShapeLayer layer) {
    return Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.height,"""

shape_new = """  Widget _buildShapeLayer(ShapeLayer layer) {
    final w = widget.template.width;
    final h = widget.template.height;
    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      height: layer.height * h,"""
content = content.replace(shape_old, shape_new)

# Replace _buildSelectablePhoto
photo_old = """  Widget _buildSelectablePhoto({required ImageLayer layer}) {
    final isSelected = _selectedType == SelectedElementType.photo;"""
photo_new = """  Widget _buildSelectablePhoto({required ImageLayer layer}) {
    final isSelected = _selectedType == SelectedElementType.photo;
    final w = widget.template.width;
    final h = widget.template.height;"""
content = content.replace(photo_old, photo_new)

photo_pos_old = """    return Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.height,"""
photo_pos_new = """    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      height: layer.height * h,"""
content = content.replace(photo_pos_old, photo_pos_new)

photo_container_old = """            Container(
              width: layer.width,
              height: layer.height,"""
photo_container_new = """            Container(
              width: layer.width * w,
              height: layer.height * h,"""
content = content.replace(photo_container_old, photo_container_new)

# Replace _buildSelectableText
text_old = """  Widget _buildSelectableText({required TextLayer layer}) {
    final isSelected = _activeTextLayer?.id == layer.id;

    final displayContent = layer.textTransform == 'uppercase' ? layer.content.toUpperCase() : layer.content;
    final align = layer.alignment == 'center' ? TextAlign.center : (layer.alignment == 'right' ? TextAlign.right : TextAlign.left);

    TextStyle getStyle() {"""
text_new = """  Widget _buildSelectableText({required TextLayer layer}) {
    final isSelected = _activeTextLayer?.id == layer.id;
    final w = widget.template.width;
    final h = widget.template.height;

    final displayContent = layer.textTransform == 'uppercase' ? layer.content.toUpperCase() : layer.content;
    final align = layer.alignment == 'center' ? TextAlign.center : (layer.alignment == 'right' ? TextAlign.right : TextAlign.left);

    TextStyle getStyle() {"""
content = content.replace(text_old, text_new)

content = content.replace("fontSize: layer.fontSize,", "fontSize: layer.fontSize * w,")
content = content.replace("blurRadius: layer.shadowBlur,", "blurRadius: layer.shadowBlur * w,")
content = content.replace("offset: Offset(layer.shadowOffsetX, layer.shadowOffsetY),", "offset: Offset(layer.shadowOffsetX * w, layer.shadowOffsetY * h),")

text_pos_old = """    return Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.curveIntensity != 0.0 ? layer.height + 100 : layer.height,"""
text_pos_new = """    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width != null ? layer.width! * w : null,
      height: layer.height != null ? (layer.curveIntensity != 0.0 ? layer.height! * h + 100 : layer.height! * h) : null,"""
content = content.replace(text_pos_old, text_pos_new)

with open(file_path, 'w') as f:
    f.write(content)
print("Flutter refactored.")
