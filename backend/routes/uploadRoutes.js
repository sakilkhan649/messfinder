const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Multer storage config
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    cb(null, `${uuidv4()}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime'];
  if (allowed.includes(file.mimetype)) cb(null, true);
  else cb(new Error('Invalid file type'), false);
};

const upload = multer({ storage, fileFilter, limits: { fileSize: 20 * 1024 * 1024 } });

// POST /api/upload — single file
router.post('/', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

  const host = req.get('host');
  const protocol = host.includes('localhost') ? 'http' : 'https';
  const fileUrl = `${protocol}://${host}/uploads/${req.file.filename}`;
  return res.status(200).json({ url: fileUrl, filename: req.file.filename });
});

// POST /api/upload/multiple — up to 10 files
router.post('/multiple', upload.array('files', 10), (req, res) => {
  if (!req.files || req.files.length === 0)
    return res.status(400).json({ error: 'No files uploaded' });

  const host = req.get('host');
  const protocol = host.includes('localhost') ? 'http' : 'https';
  const urls = req.files.map(f => ({
    url: `${protocol}://${host}/uploads/${f.filename}`,
    filename: f.filename,
  }));
  return res.status(200).json({ urls });
});

module.exports = router;
