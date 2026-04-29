import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity } from 'react-native';

export default function Login({ onLoginSuccess }) {
  const [phone, setPhone] = useState('');

  return (
    <View style={styles.container}>
      <Text style={styles.logo}>THE TRINITY</Text>
      <View style={styles.card}>
        <Text style={styles.label}>Phone Number</Text>
        <TextInput 
          style={styles.input} 
          placeholder="Enter mobile number" 
          placeholderTextColor="#444"
          keyboardType="numeric"
          onChangeText={setPhone}
        />
        <TouchableOpacity style={styles.button} onPress={() => onLoginSuccess(phone)}>
          <Text style={styles.buttonText}>GET OTP</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000', justifyContent: 'center', padding: 20 },
  logo: { color: '#FFF', fontSize: 35, fontWeight: 'bold', textAlign: 'center', letterSpacing: 8, marginBottom: 50 },
  card: { backgroundColor: '#0A0A0A', padding: 30, borderRadius: 20, borderWidth: 1, borderColor: '#1A1A1A' },
  label: { color: '#888', marginBottom: 10, fontSize: 12, textTransform: 'uppercase' },
  input: { backgroundColor: '#111', color: '#FFF', padding: 15, borderRadius: 12, marginBottom: 20, fontSize: 16 },
  button: { backgroundColor: '#FFF', padding: 18, borderRadius: 12, alignItems: 'center' },
  buttonText: { color: '#000', fontWeight: 'bold', letterSpacing: 1 }
});
