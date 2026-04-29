const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, unique: true, required: true },
  role: { 
    type: String, 
    enum: ['customer', 'shopkeeper', 'worker'], 
    default: 'customer' 
  },
  profilePic: String,
  isVerified: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
