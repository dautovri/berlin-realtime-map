const BASE_URL = 'https://v6.vbb.transport.rest';

export async function getStops(latitude, longitude, maxDistance = 2000, maxLocations = 50) {
  try {
    const response = await fetch(`${BASE_URL}/locations/nearby?latitude=${latitude}&longitude=${longitude}&distance=${maxDistance}&results=${maxLocations}&linesOfStops=false&language=en`);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    return data.map(stop => ({
      id: stop.id,
      name: stop.name,
      latitude: stop.location.latitude,
      longitude: stop.location.longitude,
      type: stop.type,
      products: stop.products
    }));
  } catch (error) {
    console.error('Error fetching stops:', error);
    throw error;
  }
}

export async function getDepartures(stopId, maxDepartures = 20) {
  try {
    const response = await fetch(`${BASE_URL}/stops/${stopId}/departures?duration=30&results=${maxDepartures}&linesOfStops=false&language=en`);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    return data.map(departure => ({
      tripId: departure.tripId,
      direction: departure.direction,
      line: departure.line,
      product: departure.product,
      when: departure.when,
      plannedWhen: departure.plannedWhen,
      delay: departure.delay,
      platform: departure.platform
    }));
  } catch (error) {
    console.error('Error fetching departures:', error);
    throw error;
  }
}

export async function getVehicles() {
  try {
    // This endpoint might not exist; VBB API may not have direct vehicle positions
    // For now, return empty array or implement radar endpoint if available
    const response = await fetch(`${BASE_URL}/radar?north=52.6755&west=13.0884&south=52.3382&east=13.7601`);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    return data.map(vehicle => ({
      id: vehicle.tripId,
      line: vehicle.line,
      product: vehicle.product,
      latitude: vehicle.location.latitude,
      longitude: vehicle.location.longitude,
      direction: vehicle.direction,
      delay: vehicle.delay
    }));
  } catch (error) {
    console.error('Error fetching vehicles:', error);
    throw error;
  }
}