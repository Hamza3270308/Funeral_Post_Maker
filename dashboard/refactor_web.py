import os

file_path = 'src/app/creator/page.tsx'
with open(file_path, 'r') as f:
    content = f.read()

# FETCH LOGIC
fetch_old = """        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const loadedText = (data.textLayers || []).map((l: any) => ({
          id: l.id,"""

fetch_new = """        const w = data.width || 1080;
        const h = data.height || 1080;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const loadedText = (data.textLayers || []).map((l: any) => ({
          id: l.id,"""
content = content.replace(fetch_old, fetch_new)

text_fetch_old = """          fontSize: l.fontSize,
          color: l.color,
          alignment: l.alignment,
          x: l.x,
          y: l.y,
          width: l.width,
          height: l.height,"""

text_fetch_new = """          fontSize: l.fontSize * w,
          color: l.color,
          alignment: l.alignment,
          x: l.x * w,
          y: l.y * h,
          width: l.width ? l.width * w : undefined,
          height: l.height ? l.height * h : undefined,"""
content = content.replace(text_fetch_old, text_fetch_new)

text_shadow_old = """          shadowBlur: l.shadowBlur || 4,
          shadowOffsetX: l.shadowOffsetX || 0,
          shadowOffsetY: l.shadowOffsetY || 0,
          glowBlur: l.glowBlur || 0,"""

text_shadow_new = """          shadowBlur: (l.shadowBlur || 0) * w,
          shadowOffsetX: (l.shadowOffsetX || 0) * w,
          shadowOffsetY: (l.shadowOffsetY || 0) * h,
          glowBlur: (l.glowBlur || 0) * w,"""
content = content.replace(text_shadow_old, text_shadow_new)

image_fetch_old = """          x: l.x,
          y: l.y,
          width: l.width,
          height: l.height,"""
image_fetch_new = """          x: l.x * w,
          y: l.y * h,
          width: l.width * w,
          height: l.height * h,"""
content = content.replace(image_fetch_old, image_fetch_new)

shape_fetch_old = """          x: l.x,
          y: l.y,
          width: l.width,
          height: l.height,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: l.borderWidth || 0,"""
shape_fetch_new = """          x: l.x * w,
          y: l.y * h,
          width: l.width * w,
          height: l.height * h,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: (l.borderWidth || 0) * w,"""
content = content.replace(shape_fetch_old, shape_fetch_new)


# SAVE LOGIC
save_old = """  const handleSave = async (isAutoSave = false, targetStatus?: 'active' | 'draft') => {
    if (!templateName.trim()) {
      alert('Please enter a template name.');
      return;
    }

    const textLayers: any[] = [];
    const imageLayers: any[] = [];
    const shapeLayers: any[] = [];

    layers.forEach(l => {"""

save_new = """  const handleSave = async (isAutoSave = false, targetStatus?: 'active' | 'draft') => {
    if (!templateName.trim()) {
      alert('Please enter a template name.');
      return;
    }
    const w = canvasWidth;
    const h = canvasHeight;

    const textLayers: any[] = [];
    const imageLayers: any[] = [];
    const shapeLayers: any[] = [];

    layers.forEach(l => {"""
content = content.replace(save_old, save_new)

text_save_old = """        textLayers.push({
          id: l.id,
          content: l.content,
          fontFamily: l.fontFamily,
          fontSize: Math.round(l.fontSize || 16),
          color: l.color || '#000000',
          alignment: l.alignment || 'center',
          x: Math.round(l.x),
          y: Math.round(l.y),
          width: l.width ? Math.round(l.width) : undefined,
          height: l.height ? Math.round(l.height) : undefined,"""
text_save_new = """        textLayers.push({
          id: l.id,
          content: l.content,
          fontFamily: l.fontFamily,
          fontSize: (l.fontSize || 16) / w,
          color: l.color || '#000000',
          alignment: l.alignment || 'center',
          x: l.x / w,
          y: l.y / h,
          width: l.width ? (l.width / w) : undefined,
          height: l.height ? (l.height / h) : undefined,"""
content = content.replace(text_save_old, text_save_new)

text_save_shadow_old = """          hasShadow: l.hasShadow || false,
          shadowColor: l.shadowColor || 'rgba(0,0,0,0.5)',
          shadowBlur: l.shadowBlur || 4,
          shadowOffsetX: l.shadowOffsetX || 0,
          shadowOffsetY: l.shadowOffsetY || 0,
          glowBlur: l.glowBlur || 0,"""
text_save_shadow_new = """          hasShadow: l.hasShadow || false,
          shadowColor: l.shadowColor || 'rgba(0,0,0,0.5)',
          shadowBlur: (l.shadowBlur || 4) / w,
          shadowOffsetX: (l.shadowOffsetX || 0) / w,
          shadowOffsetY: (l.shadowOffsetY || 0) / h,
          glowBlur: (l.glowBlur || 0) / w,"""
content = content.replace(text_save_shadow_old, text_save_shadow_new)


image_save_old = """          maskShape: l.shape === 'circle' ? 'circle' : l.shape === 'rounded-rectangle' ? 'rounded_rect' : 'none',
          x: Math.round(l.x),
          y: Math.round(l.y),
          width: Math.round(l.width),
          height: Math.round(l.height),
          rotation: l.rotation || 0,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: l.borderWidth || 0,"""
image_save_new = """          maskShape: l.shape === 'circle' ? 'circle' : l.shape === 'rounded-rectangle' ? 'rounded_rect' : 'none',
          x: l.x / w,
          y: l.y / h,
          width: l.width / w,
          height: l.height / h,
          rotation: l.rotation || 0,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: (l.borderWidth || 0) / w,"""
content = content.replace(image_save_old, image_save_new)

shape_save_old = """          shape: l.shape || 'square',
          color: l.color || '#4A6572',
          x: Math.round(l.x),
          y: Math.round(l.y),
          width: Math.round(l.width),
          height: Math.round(l.height),
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: l.borderWidth || 0,"""
shape_save_new = """          shape: l.shape || 'square',
          color: l.color || '#4A6572',
          x: l.x / w,
          y: l.y / h,
          width: l.width / w,
          height: l.height / h,
          opacity: l.opacity !== undefined ? l.opacity : 1,
          borderWidth: (l.borderWidth || 0) / w,"""
content = content.replace(shape_save_old, shape_save_new)


with open(file_path, 'w') as f:
    f.write(content)
print("Web refactored.")
