const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
  shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  title: String,
  price: Number,
  photos: [String], // Samaan ki photos ke URLs
  description: String,
  category: String,
  fittingAvailable: { type: Boolean, default: false }
});

module.exports = mongoose.model('Product', ProductSchema);
