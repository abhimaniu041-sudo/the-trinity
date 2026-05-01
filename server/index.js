const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

// Database Connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("✅ Trinity Database Connected!"))
  .catch(err => console.error("❌ DB Error:", err));

// Schema for Products (Taaki data save ho sake)
const ProductSchema = new mongoose.Schema({
  name: String,
  price: String,
  disc: String,
  qty: String,
  imgs: [String],
  shopName: String
});
const Product = mongoose.model('Product', ProductSchema);

// --- API ROUTES ---

// 1. Get all products (Customer ke liye)
app.get('/api/products', async (req, res) => {
  const products = await Product.find();
  res.json(products);
});

// 2. Add product (Shopkeeper ke liye)
app.post('/api/products/add', async (req, res) => {
  const newP = new Product(req.body);
  await newP.save();
  res.status(200).json({ message: "Product Sync Successful!" });
});

app.get('/', (req, res) => res.send("Trinity Server is Live 🚀"));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on ${PORT}`));
