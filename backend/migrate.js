const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'seedTemplates.js');
const content = fs.readFileSync(filePath, 'utf8');

const match = content.match(/const templatesData = (\[[\s\S]*?\]);\n\nasync function seed\(\)/);
if (!match) {
  console.error("Could not find templatesData array.");
  process.exit(1);
}

// Convert string to actual JS object
const dataString = match[1];
const templates = eval(`(${dataString})`);

templates.forEach(t => {
  const w = t.width || 1080;
  const h = t.height || 1080;
  
  if (t.textLayers) {
    t.textLayers.forEach(layer => {
      if (layer.x > 1) layer.x = Number((layer.x / w).toFixed(4));
      if (layer.y > 1) layer.y = Number((layer.y / h).toFixed(4));
      if (layer.width && layer.width > 1) layer.width = Number((layer.width / w).toFixed(4));
      if (layer.height && layer.height > 1) layer.height = Number((layer.height / h).toFixed(4));
      if (layer.fontSize > 1) layer.fontSize = Number((layer.fontSize / w).toFixed(4));
      if (layer.shadowBlur && layer.shadowBlur > 1) layer.shadowBlur = Number((layer.shadowBlur / w).toFixed(4));
      if (layer.shadowOffsetX && layer.shadowOffsetX > 1) layer.shadowOffsetX = Number((layer.shadowOffsetX / w).toFixed(4));
      if (layer.shadowOffsetY && layer.shadowOffsetY > 1) layer.shadowOffsetY = Number((layer.shadowOffsetY / h).toFixed(4));
    });
  }
  
  if (t.imageLayers) {
    t.imageLayers.forEach(layer => {
      if (layer.x > 1) layer.x = Number((layer.x / w).toFixed(4));
      if (layer.y > 1) layer.y = Number((layer.y / h).toFixed(4));
      if (layer.width && layer.width > 1) layer.width = Number((layer.width / w).toFixed(4));
      if (layer.height && layer.height > 1) layer.height = Number((layer.height / h).toFixed(4));
      if (layer.borderWidth && layer.borderWidth > 1) layer.borderWidth = Number((layer.borderWidth / w).toFixed(4));
      if (layer.borderRadius && layer.borderRadius > 1) layer.borderRadius = Number((layer.borderRadius / w).toFixed(4));
    });
  }

  if (t.shapeLayers) {
    t.shapeLayers.forEach(layer => {
      if (layer.x > 1) layer.x = Number((layer.x / w).toFixed(4));
      if (layer.y > 1) layer.y = Number((layer.y / h).toFixed(4));
      if (layer.width && layer.width > 1) layer.width = Number((layer.width / w).toFixed(4));
      if (layer.height && layer.height > 1) layer.height = Number((layer.height / h).toFixed(4));
      if (layer.borderWidth && layer.borderWidth > 1) layer.borderWidth = Number((layer.borderWidth / w).toFixed(4));
      if (layer.borderRadius && layer.borderRadius > 1) layer.borderRadius = Number((layer.borderRadius / w).toFixed(4));
    });
  }
});

const newDataString = JSON.stringify(templates, null, 2);
const newContent = content.replace(dataString, newDataString);

fs.writeFileSync(filePath, newContent, 'utf8');
console.log("Migration complete.");
