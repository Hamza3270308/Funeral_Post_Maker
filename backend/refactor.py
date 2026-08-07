import re

with open('/Users/mc/Documents/Projects/Funeral_Post_Maker/backend/seedTemplates.js', 'r') as f:
    content = f.read()

colors = ['#1E252B', '#FDFBF7', '#E8ECEF', '#1E252B', '#FFFFFF', '#1E252B', '#FDFBF7', '#1E252B', '#F8F5F2', '#1E252B']
flowers = ['floral_gold_leaves', 'floral_cherry_blossom', 'floral_forget_me_not', 'floral_white_roses', 'floral_lavender', 'floral_peonies', 'floral_ferns_corner', 'floral_lilies_frame', 'floral_olive_branch', 'floral_daisy_divider']

idx = 0
def replace_bg(match):
    global idx
    color = colors[idx % len(colors)]
    idx += 1
    return f'''background: {{
      type: "color",
      value: "{color}"
    }}'''

content = re.sub(r'background:\s*\{\s*type:\s*"image",\s*value:\s*"[^"]+"\s*\}', replace_bg, content)

idx = 0
def inject_flower(match):
    global idx
    flower = flowers[idx % len(flowers)]
    idx += 1
    
    flower_layer = f'''{{
        id: "flower_{idx}",
        type: "image",
        url: "http://localhost:3000/flowers/{flower}.png",
        x: 0,
        y: 0,
        width: 1080,
        height: 1080,
        rotation: 0,
        opacity: 1,
        mixBlendMode: "multiply",
        visible: true
      }},'''
    return f'imageLayers: [\n      {flower_layer}'

content = re.sub(r'imageLayers:\s*\[', inject_flower, content)

with open('/Users/mc/Documents/Projects/Funeral_Post_Maker/backend/seedTemplates.js', 'w') as f:
    f.write(content)

print("Template refactoring completed successfully.")
