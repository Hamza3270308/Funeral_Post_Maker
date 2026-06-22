const express = require('express');
const router = express.Router();
const {
  getTemplates,
  getAdminTemplates,
  getTemplateById,
  createTemplate,
  updateTemplate,
  deleteTemplate
} = require('../controllers/templateController');

// Define routes
router.get('/', getTemplates);
router.get('/admin', getAdminTemplates);
router.get('/:id', getTemplateById);
router.post('/', createTemplate);
router.put('/:id', updateTemplate);
router.delete('/:id', deleteTemplate);

module.exports = router;
