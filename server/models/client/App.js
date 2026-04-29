import React from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, ImageBackground } from 'react-native';
import { BlurView } from 'expo-blur'; // Premium Glassmorphism ke liye

export default function App() {
  return (
    <View style={styles.container}>
      <View style={styles.darkOverlay}>
        <Text style={styles.logo}>THE TRINITY</Text>
        
        <Text style={styles.subtitle}>Premium Service & Commerce</Text>

        {/* Glassmorphic Login Card */}
        <View style={styles.glassCard}>
          <Text style={styles.loginTitle}>Welcome Back</Text>
          
          <TextInput 
            style={styles.input} 
            placeholder="Mobile Number" 
            placeholderTextColor="#888"
            keyboardType="numeric"
          />

          <TouchableOpacity style={styles.button}>
            <Text style={styles.buttonText}>Get OTP</Text>
          </TouchableOpacity>

          <Text style={styles.privacyText}>
            Your number is safe with us. No sharing, just privacy.
          </Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F0F0F', // Premium Deep Black
  },
  darkOverlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  logo: {
    fontSize: 40,
    fontWeight: 'bold',
    color: '#FFFFFF',
    letterSpacing: 5,
    marginBottom: 5,
  },
  subtitle: {
    color: '#888',
    marginBottom: 40,
    fontSize: 14,
    textTransform: 'uppercase',
  },
  glassCard: {
    width: '100%',
    padding: 30,
    borderRadius: 30,
    backgroundColor: 'rgba(255, 255, 255, 0.05)', // Minimalist transparent look
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  loginTitle: {
    fontSize: 22,
    color: '#FFF',
    marginBottom: 20,
    textAlign: 'center',
    fontWeight: '600',
  },
  input: {
    backgroundColor: 'rgba(0,0,0,0.3)',
    borderRadius: 15,
    padding: 15,
    color: '#FFF',
    fontSize: 16,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#333',
  },
  button: {
    backgroundColor: '#FFFFFF', // Clean White Button
    padding: 18,
    borderRadius: 15,
    alignItems: 'center',
  },
  buttonText: {
    color: '#000',
    fontWeight: 'bold',
    fontSize: 16,
  },
  privacyText: {
    color: '#555',
    fontSize: 12,
    textAlign: 'center',
    marginTop: 20,
  }
});
