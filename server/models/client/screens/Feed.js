import React from 'react';
import { StyleSheet, Text, View, FlatList, Image, TouchableOpacity, Dimensions } from 'react-native';

const { width } = Dimensions.get('window');

// Dummy Data (Baad mein Database se aayega)
const PRODUCTS = [
  { id: '1', title: 'Luxury Sofa', price: '₹45,000', photo: 'https://via.placeholder.com/300', shop: 'Royal Interiors' },
  { id: '2', title: 'Smart AC', price: '₹32,000', photo: 'https://via.placeholder.com/300', shop: 'Electro Hub' },
];

export default function Feed() {
  return (
    <View style={styles.container}>
      <Text style={styles.header}>DISCOVER</Text>
      
      <FlatList 
        data={PRODUCTS}
        keyExtractor={item => item.id}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Image source={{ uri: item.photo }} style={styles.image} />
            <View style={styles.info}>
              <Text style={styles.shopName}>{item.shop}</Text>
              <Text style={styles.title}>{item.title}</Text>
              <View style={styles.priceRow}>
                <Text style={styles.price}>{item.price}</Text>
                <TouchableOpacity style={styles.buyBtn}>
                  <Text style={styles.buyText}>View Details</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000', paddingHorizontal: 15 },
  header: { fontSize: 28, fontWeight: 'bold', color: '#FFF', marginTop: 50, marginBottom: 20, letterSpacing: 3 },
  card: { 
    backgroundColor: '#111', 
    borderRadius: 25, 
    marginBottom: 20, 
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#222'
  },
  image: { width: '100%', height: 250, resizeMode: 'cover' },
  info: { padding: 15 },
  shopName: { color: '#888', fontSize: 12, textTransform: 'uppercase' },
  title: { color: '#FFF', fontSize: 20, fontWeight: '600', marginVertical: 5 },
  priceRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 10 },
  price: { color: '#FFF', fontSize: 18, fontWeight: 'bold' },
  buyBtn: { backgroundColor: '#FFF', paddingVertical: 8, paddingHorizontal: 15, borderRadius: 10 },
  buyText: { color: '#000', fontWeight: 'bold', fontSize: 14 }
});
