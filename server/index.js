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

// Routes Import
const authRoutes = require('./routes/auth');
const uploadRoutes = require('./routes/upload');
const apiRoutes = require('./routes/api');

// Routes Usage
app.use('/api/auth', authRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/main', apiRoutes);

app.get('/', (req, res) => {
  res.send('The Trinity Server is Live and Connected!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
