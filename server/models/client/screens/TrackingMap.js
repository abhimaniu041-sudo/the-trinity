import React from 'react';
import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import MapView, { Marker } from 'react-native-maps';

export default function TrackingMap() {
  return (
    <View style={styles.container}>
      {/* Premium Dark Styled Map */}
      <MapView 
        style={styles.map}
        initialRegion={{
          latitude: 28.6139,
          longitude: 77.2090,
          latitudeDelta: 0.05,
          longitudeDelta: 0.05,
        }}
        customMapStyle={mapStyle} // Dark premium theme
      >
        <Marker coordinate={{ latitude: 28.6139, longitude: 77.2090 }}>
          <View style={styles.markerCircle} />
        </Marker>
      </MapView>

      {/* Floating Worker Info Card (Glassmorphism) */}
      <View style={styles.infoCard}>
        <Text style={styles.workerName}>Worker: Amit Kumar</Text>
        <Text style={styles.status}>Status: On the way (ETA 5 mins)</Text>
        <TouchableOpacity style={styles.callButton}>
          <Text style={styles.callText}>Secure Call</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const mapStyle = [ { "elementType": "geometry", "stylers": [ { "color": "#212121" } ] }, { "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] } ];

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { width: '100%', height: '100%' },
  markerCircle: { width: 20, height: 20, borderRadius: 10, backgroundColor: '#FFF', borderWidth: 3, borderColor: '#000' },
  infoCard: {
    position: 'absolute',
    bottom: 40,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(0,0,0,0.8)',
    borderRadius: 25,
    padding: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)'
  },
  workerName: { color: '#FFF', fontSize: 18, fontWeight: 'bold' },
  status: { color: '#888', marginTop: 5 },
  callButton: { backgroundColor: '#FFF', padding: 12, borderRadius: 12, marginTop: 15, alignItems: 'center' },
  callText: { color: '#000', fontWeight: 'bold' }
});
