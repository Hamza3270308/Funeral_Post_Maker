const mongoose = require('mongoose');

const Schema = mongoose.Schema;

// Sub-schemas for the structured layers
const TextLayerSchema = new Schema({
  id: { type: String, required: true },
  content: { type: String, required: true },
  fontFamily: { type: String, default: 'Inter' },
  fontSize: { type: Number, default: 16 },
  color: { type: String, default: '#2E3338' },
  alignment: { type: String, default: 'center' },
  x: { type: Number, required: true },
  y: { type: Number, required: true },
  width: { type: Number },
  height: { type: Number }
}, { _id: false });

const ImageLayerSchema = new Schema({
  id: { type: String, required: true },
  type: { type: String, enum: ['frame', 'sticker'], required: true },
  url: { type: String }, // Placeholder URL or actual sticker URL
  maskShape: { type: String, enum: ['none', 'circle', 'rounded_rect'], default: 'none' },
  x: { type: Number, required: true },
  y: { type: Number, required: true },
  width: { type: Number, required: true },
  height: { type: Number, required: true },
  rotation: { type: Number, default: 0 }
}, { _id: false });

const TemplateSchema = new Schema({
  title: { type: String, required: true },
  category: { type: String, required: true },
  status: { type: String, enum: ['draft', 'active'], default: 'draft' },
  
  // Background layer properties
  background: {
    type: { type: String, enum: ['color', 'image'], required: true },
    value: { type: String, required: true } // hex code or image URL
  },
  
  // The customizable layers
  textLayers: [TextLayerSchema],
  imageLayers: [ImageLayerSchema],
  
  // For mobile app to display a quick thumbnail
  thumbnailUrl: { type: String },
  
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Template', TemplateSchema);
