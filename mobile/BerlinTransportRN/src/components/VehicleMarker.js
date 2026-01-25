import React from 'react';
import { Marker, Callout } from 'react-native-maps';
import { View, Text, StyleSheet } from 'react-native';

const getVehicleIcon = (product) => {
  switch (product) {
    case 'subway':
      return '🚇';
    case 'suburban':
      return '🚆';
    case 'tram':
      return '🚊';
    case 'bus':
      return '🚌';
    default:
      return '🚗';
  }
};

const VehicleMarker = ({ vehicle }) => {
  return (
    <Marker
      coordinate={{
        latitude: vehicle.latitude,
        longitude: vehicle.longitude,
      }}
      title={`${vehicle.line.name} ${vehicle.direction}`}
      description={`Delay: ${vehicle.delay || 0} min`}
      pinColor="blue"
    >
      <View style={styles.marker}>
        <Text style={styles.icon}>{getVehicleIcon(vehicle.product)}</Text>
      </View>
      <Callout>
        <View style={styles.callout}>
          <Text style={styles.title}>{vehicle.line.name}</Text>
          <Text style={styles.direction}>{vehicle.direction}</Text>
          <Text style={styles.delay}>
            Delay: {vehicle.delay ? `${vehicle.delay} min` : 'On time'}
          </Text>
        </View>
      </Callout>
    </Marker>
  );
};

const styles = StyleSheet.create({
  marker: {
    backgroundColor: 'blue',
    borderRadius: 20,
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'white',
  },
  icon: {
    color: 'white',
    fontSize: 16,
  },
  callout: {
    minWidth: 150,
    padding: 10,
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  direction: {
    fontSize: 14,
    color: '#333',
    marginBottom: 4,
  },
  delay: {
    fontSize: 12,
    color: vehicle.delay > 0 ? 'red' : 'green',
  },
});

export default VehicleMarker;