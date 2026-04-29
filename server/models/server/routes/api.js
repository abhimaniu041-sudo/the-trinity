const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Product = require('../models/Product');

// 1. Samaan bechne ke liye (Product Upload)
router.post('/add-product', async (req, res) => {
    try {
        const { shopId, title, price, photos, fittingAvailable } = req.body;
        const newProduct = new Product({ shopId, title, price, photos, fittingAvailable });
        await newProduct.save();
        res.status(201).json({ message: "Product listed successfully!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 2. Secret Calling Logic (Number Masking)
router.post('/make-private-call', async (req, res) => {
    const { fromUser, toUser } = req.body;
    // Yahan Twilio ya Exotel ka bridge connect hoga
    // Abhi ke liye hum sirf status bhejenge
    console.log(`Connecting ${fromUser} to ${toUser} via Bridge...`);
    res.json({ success: true, bridgeNumber: "+91-XXXXXXXXXX" });
});

module.exports = router;
