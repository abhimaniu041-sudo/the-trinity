import React, { useState } from 'react';
import { View, StyleSheet } from 'react-native';
import Login from './screens/Login';
import RoleSelection from './screens/RoleSelection';
import Feed from './screens/Feed';

export default function App() {
  const [screen, setScreen] = useState('Login');
  const [user, setUser] = useState(null);

  // Jab Login successful ho jaye
  const handleLogin = (phoneNumber) => {
    setUser({ phone: phoneNumber });
    setScreen('RoleSelection');
  };

  // Jab User Role select kar le
  const handleRoleSelect = (selectedRole) => {
    setUser(prev => ({ ...prev, role: selectedRole }));
    setScreen('Feed');
  };

  return (
    <View style={styles.container}>
      {screen === 'Login' && <Login onLoginSuccess={handleLogin} />}
      {screen === 'RoleSelection' && <RoleSelection onRoleConfirm={handleRoleSelect} />}
      {screen === 'Feed' && <Feed currentUser={user} />}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' }
});
