import React, { useState, useEffect } from 'react';
import { View, StyleSheet, Platform } from 'react-native';
import MapView, { PROVIDER_DEFAULT } from 'react-native-maps';
import { getStops, getVehicles } from '../api/vbb';
import WebStopMarker from './WebStopMarker';
import WebVehicleMarker from './WebVehicleMarker';

const BERLIN_REGION = {
  latitude: 52.5200,
  longitude: 13.4050,
  latitudeDelta: 0.0922,
  longitudeDelta: 0.0421,
};

const WebMapView = () => {
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

  // Web-specific provider configuration
  const mapProvider = Platform.OS === 'web' ? undefined : PROVIDER_DEFAULT;

  return (
    <View style={styles.container}>
      <MapView
        style={styles.map}
        provider={mapProvider}
        region={region}
        onRegionChangeComplete={handleRegionChange}
        showsUserLocation={Platform.OS !== 'web'} // Disable on web for simplicity
        showsMyLocationButton={Platform.OS !== 'web'}
        zoomEnabled={true}
        scrollEnabled={true}
        mapType={Platform.OS === 'web' ? 'standard' : undefined}
      >
        {stops.map((stop) => (
          <WebStopMarker key={stop.id} stop={stop} />
        ))}
        {vehicles.map((vehicle) => (
          <WebVehicleMarker key={vehicle.id} vehicle={vehicle} />
        ))}
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

export default WebMapView;