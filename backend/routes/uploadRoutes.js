const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const sharp = require("sharp");

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB limit
});

// @desc    Upload & compress an asset (background, image, etc.)
// @route   POST /api/upload
router.post("/", upload.single("file"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: "No file uploaded" });
  }

  try {
    const ext = path.extname(req.file.originalname).toLowerCase();
    const rawBasename = path.basename(req.file.originalname, ext).replace(/[^a-zA-Z0-9_-]/g, "_");
    const timestamp = Date.now();
    const filename = `${rawBasename}-${timestamp}.webp`;
    const outputPath = path.join(uploadDir, filename);

    if (req.file.mimetype.startsWith("image/")) {
      await sharp(req.file.buffer)
        .rotate()
        .resize(1920, 1920, {
          fit: "inside",
          withoutEnlargement: true
        })
        .webp({ quality: 82, effort: 4 })
        .toFile(outputPath);
    } else {
      const fallbackFilename = `${rawBasename}-${timestamp}${ext}`;
      const fallbackPath = path.join(uploadDir, fallbackFilename);
      fs.writeFileSync(fallbackPath, req.file.buffer);
      return res.status(201).json({
        message: "File uploaded successfully",
        url: `/uploads/${fallbackFilename}`
      });
    }

    const filePath = `/uploads/${filename}`;
    res.status(201).json({
      message: "File uploaded and compressed successfully",
      url: filePath
    });
  } catch (err) {
    console.error("Image compression error:", err);
    res.status(500).json({ message: "Error processing image upload", error: err.message });
  }
});

module.exports = router;
