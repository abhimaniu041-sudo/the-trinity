const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

// Humne jo naya auth.js banaya hai usse yahan connect kar rahe hain
const authRoutes = require('./routes/auth');

const app = express();
app.use(express.json());
app.use(cors());

// MongoDB Connection (Yeh .env file se link uthayega)
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("✅ The Trinity Database Connected!"))
  .catch(err => console.error("❌ Database Connection Error:", err));

// Routes
app.use('/api/auth', authRoutes);

app.get('/', (req, res) => {
  res.send('The Trinity Server is Running and Database is Connected!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});
