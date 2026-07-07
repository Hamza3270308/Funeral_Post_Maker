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
  height: { type: Number },
  // Styling extensions
  fontWeight: { type: String, default: 'normal' },
  fontStyle: { type: String, default: 'normal' },
  textDecoration: { type: String, default: 'none' },
  opacity: { type: Number, default: 1 },
  rotation: { type: Number, default: 0 },
  hasShadow: { type: Boolean, default: false },
  shadowColor: { type: String, default: 'rgba(0,0,0,0.5)' },
  shadowBlur: { type: Number, default: 4 }
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
  rotation: { type: Number, default: 0 },
  // Styling extensions
  opacity: { type: Number, default: 1 },
  borderWidth: { type: Number, default: 0 },
  borderColor: { type: String, default: '#000000' }
}, { _id: false });

const ShapeLayerSchema = new Schema({
  id: { type: String, required: true },
  shape: { type: String, enum: ['circle', 'square', 'rounded-rectangle', 'oval', 'arch', 'line', 'triangle'], default: 'square' },
  color: { type: String, default: '#4A6572' },
  x: { type: Number, required: true },
  y: { type: Number, required: true },
  width: { type: Number, required: true },
  height: { type: Number, required: true },
  // Styling extensions
  opacity: { type: Number, default: 1 },
  borderWidth: { type: Number, default: 0 },
  borderColor: { type: String, default: '#000000' },
  rotation: { type: Number, default: 0 }
}, { _id: false });

const TemplateSchema = new Schema({
  title: { type: String, required: true },
  category: { type: String, required: true },
  status: { type: String, enum: ['draft', 'active'], default: 'draft' },
  
  // Background layer properties
  background: {
    type: { type: String, enum: ['color', 'image', 'gradient'], required: true },
    value: { type: String, required: true } // hex code, image URL, or CSS gradient string
  },
  
  // The customizable layers
  textLayers: [TextLayerSchema],
  imageLayers: [ImageLayerSchema],
  shapeLayers: [ShapeLayerSchema],
  
  width: { type: Number, default: 1080 },
  height: { type: Number, default: 1920 },
  
  // For mobile app to display a quick thumbnail
  thumbnailUrl: { type: String },
  
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Template', TemplateSchema);
