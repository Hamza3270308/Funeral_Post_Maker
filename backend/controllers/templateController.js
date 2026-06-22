const Template = require('../models/Template');

// @desc    Get all active templates
// @route   GET /api/templates
// @access  Public (for mobile app)
exports.getTemplates = async (req, res) => {
  try {
    const templates = await Template.find({ status: 'active' }).sort({ createdAt: -1 });
    res.json(templates);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// @desc    Get all templates (including drafts)
// @route   GET /api/templates/admin
// @access  Admin (for web dashboard)
exports.getAdminTemplates = async (req, res) => {
  try {
    const templates = await Template.find().sort({ createdAt: -1 });
    res.json(templates);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// @desc    Get single template by ID
// @route   GET /api/templates/:id
// @access  Public
exports.getTemplateById = async (req, res) => {
  try {
    const template = await Template.findById(req.params.id);
    if (!template) {
      return res.status(404).json({ message: 'Template not found' });
    }
    res.json(template);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// @desc    Create new template
// @route   POST /api/templates
// @access  Admin
exports.createTemplate = async (req, res) => {
  try {
    const newTemplate = new Template(req.body);
    const savedTemplate = await newTemplate.save();
    res.status(201).json(savedTemplate);
  } catch (error) {
    res.status(400).json({ message: 'Validation Error', error: error.message });
  }
};

// @desc    Update template
// @route   PUT /api/templates/:id
// @access  Admin
exports.updateTemplate = async (req, res) => {
  try {
    const template = await Template.findByIdAndUpdate(
      req.params.id, 
      { $set: req.body, updatedAt: Date.now() }, 
      { new: true, runValidators: true }
    );
    if (!template) {
      return res.status(404).json({ message: 'Template not found' });
    }
    res.json(template);
  } catch (error) {
    res.status(400).json({ message: 'Update Error', error: error.message });
  }
};

// @desc    Delete template
// @route   DELETE /api/templates/:id
// @access  Admin
exports.deleteTemplate = async (req, res) => {
  try {
    const template = await Template.findByIdAndDelete(req.params.id);
    if (!template) {
      return res.status(404).json({ message: 'Template not found' });
    }
    res.json({ message: 'Template removed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};
