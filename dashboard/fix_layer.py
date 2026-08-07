import os

file_path = 'src/app/creator/page.tsx'
with open(file_path, 'r') as f:
    content = f.read()

layer_old = """  isCustomWidth?: boolean;
}"""

layer_new = """  isCustomWidth?: boolean;
  hasShadow?: boolean;
  glowColor?: string;
  glowBlur?: number;
  echoColor?: string;
  echoOffsetX?: number;
  echoOffsetY?: number;
  neonColor?: string;
  neonIntensity?: number;
  curveIntensity?: number;
  frameStyle?: string;
}"""

content = content.replace(layer_old, layer_new)

with open(file_path, 'w') as f:
    f.write(content)

print("Layer interface fixed.")
