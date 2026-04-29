const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

// Database Connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("✅ The Trinity Database Connected!"))
  .catch(err => console.error("❌ Database Connection Error:", err));

// --- Routes Configuration ---
// Note: Hum try-catch use kar rahe hain taaki agar koi file na mile toh server crash na ho

// Auth Routes
try {
    const authRoutes = require('./routes/auth');
    app.use('/api/auth', authRoutes);
} catch (e) {
    console.log("⚠️ Auth routes file not found yet.");
}

// Upload Routes
try {
    const uploadRoutes = require('./routes/upload');
    app.use('/api/upload', uploadRoutes);
} catch (e) {
    console.log("⚠️ Upload routes file not found yet.");
}

// API/Main Routes
try {
    const apiRoutes = require('./routes/api');
    app.use('/api/main', apiRoutes);
} catch (e) {
    console.log("⚠️ API routes file not found yet.");
}

// Home Route for Testing
app.get('/', (req, res) => {
  res.send('The Trinity Server is Live and Connected!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
