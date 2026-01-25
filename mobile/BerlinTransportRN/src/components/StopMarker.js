import React from 'react';
import { Marker, Callout } from 'react-native-maps';
import { View, Text, StyleSheet } from 'react-native';

const StopMarker = ({ stop }) => {
  return (
    <Marker
      coordinate={{
        latitude: stop.latitude,
        longitude: stop.longitude,
      }}
      title={stop.name}
      description={`ID: ${stop.id}`}
    >
      <Callout>
        <View style={styles.callout}>
          <Text style={styles.title}>{stop.name}</Text>
          <Text style={styles.subtitle}>Stop ID: {stop.id}</Text>
          {stop.products && (
            <View style={styles.products}>
              {stop.products.subway && <Text style={styles.product}>🚇</Text>}
              {stop.products.suburban && <Text style={styles.product}>🚆</Text>}
              {stop.products.tram && <Text style={styles.product}>🚊</Text>}
              {stop.products.bus && <Text style={styles.product}>🚌</Text>}
            </View>
          )}
        </View>
      </Callout>
    </Marker>
  );
};

const styles = StyleSheet.create({
  callout: {
    minWidth: 200,
    padding: 10,
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 12,
    color: '#666',
    marginBottom: 8,
  },
  products: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  product: {
    fontSize: 16,
  },
});

export default StopMarker;