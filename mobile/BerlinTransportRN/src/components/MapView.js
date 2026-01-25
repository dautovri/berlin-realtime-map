import React, { useState, useEffect } from 'react';
import { View, StyleSheet } from 'react-native';
import MapView, { PROVIDER_DEFAULT } from 'react-native-maps';
import { getStops, getVehicles } from '../api/vbb';

const BERLIN_REGION = {
  latitude: 52.5200,
  longitude: 13.4050,
  latitudeDelta: 0.0922,
  longitudeDelta: 0.0421,
};

const MapViewComponent = () => {
  const [stops, setStops] = useState([]);
  const [vehicles, setVehicles] = useState([]);
  const [region, setRegion] = useState(BERLIN_REGION);

  useEffect(() => {
    loadStops();
    loadVehicles();

    // Update vehicles every 30 seconds
    const interval = setInterval(loadVehicles, 30000);
    return () => clearInterval(interval);
  }, []);

  const loadStops = async () => {
    try {
      const stopsData = await getStops(
        region.latitude,
        region.longitude,
        2000,
        50
      );
      setStops(stopsData);
    } catch (error) {
      console.error('Error loading stops:', error);
    }
  };

  const loadVehicles = async () => {
    try {
      const vehiclesData = await getVehicles();
      setVehicles(vehiclesData);
    } catch (error) {
      console.error('Error loading vehicles:', error);
    }
  };

  const handleRegionChange = (newRegion) => {
    setRegion(newRegion);
  };

  return (
    <View style={styles.container}>
      <MapView
        style={styles.map}
        provider={PROVIDER_DEFAULT}
        region={region}
        onRegionChangeComplete={handleRegionChange}
        showsUserLocation={true}
        showsMyLocationButton={true}
        zoomEnabled={true}
        scrollEnabled={true}
      >
        {/* Stops and vehicles markers will be added in child components */}
      </MapView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
});

export default MapViewComponent;