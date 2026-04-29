const express = require('express');
const router = express.Router();
const User = require('../models/User');

// Login ya Signup logic
router.post('/login', async (req, res) => {
    try {
        const { phone, role, name } = req.body;

        // 1. Check karein ki user pehle se hai ya nahi
        let user = await User.findOne({ phone });

        if (!user) {
            // Agar naya user hai toh register karein
            user = new User({ phone, role, name });
            await user.save();
        }

        // Dummy OTP for testing
        res.status(200).json({ 
            message: "OTP sent successfully to " + phone,
            otp: "123456", 
            user 
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
