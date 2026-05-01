const express = require('express');
const router = express.Router();
const Product = require('../models/Product'); // Ensure you have a Product model

// 1. Get All Products (Customer Dashboard ke liye)
router.get('/products', async (req, res) => {
    try {
        const products = await Product.find().sort({ createdAt: -1 });
        res.json(products);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 2. Add New Product (Shopkeeper Console ke liye)
router.post('/products/add', async (req, res) => {
    try {
        const newProduct = new Product(req.body);
        await newProduct.save();
        res.status(200).json({ message: "Product Synced to Cloud!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
