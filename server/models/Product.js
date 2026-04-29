const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
  shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  title: String,
  price: Number,
  description: String,
  images: [String],
  category: String
});

module.exports = mongoose.model('Product', ProductSchema);
