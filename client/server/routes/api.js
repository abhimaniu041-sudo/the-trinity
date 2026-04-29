const express = require('express');
const router = express.Router();
const Product = require('../models/Product');

// Product list karne ke liye
router.post('/add-product', async (req, res) => {
    try {
        const { shopId, title, price, description, photos } = req.body;
        const newProduct = new Product({ shopId, title, price, description, photos });
        await newProduct.save();
        res.status(201).json({ message: "Product added!", product: newProduct });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Private Calling Bridge
router.post('/secure-call', (req, res) => {
    const { from, to } = req.body;
    // Bridge logic here
    res.json({ success: true, message: "Connecting via secure line..." });
});

module.exports = router;
