import { db, auth } from './AuthService';
import { collection, doc, getDoc, setDoc, updateDoc, arrayUnion, arrayRemove, onSnapshot } from 'firebase/firestore';

// Types
interface FavoriteStop {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
}

interface JourneyHistory {
  id: string;
  from: string;
  to: string;
  timestamp: Date;
  mode: string;
}

// Sync favorites
export const syncFavorites = async () => {
  const user = auth.currentUser;
  if (!user) throw new Error('User not authenticated');

  const userDocRef = doc(db, 'users', user.uid);
  const userDoc = await getDoc(userDocRef);

  if (userDoc.exists()) {
    const data = userDoc.data();
    return data.favorites || [];
  } else {
    // Initialize user document
    await setDoc(userDocRef, { favorites: [] });
    return [];
  }
};

export const addFavorite = async (favorite: FavoriteStop) => {
  const user = auth.currentUser;
  if (!user) throw new Error('User not authenticated');

  const userDocRef = doc(db, 'users', user.uid);
  await updateDoc(userDocRef, {
    favorites: arrayUnion(favorite)
  });
};

export const removeFavorite = async (favoriteId: string) => {
  const user = auth.currentUser;
  if (!user) throw new Error('User not authenticated');

  const userDocRef = doc(db, 'users', user.uid);
  const userDoc = await getDoc(userDocRef);
  if (userDoc.exists()) {
    const favorites = userDoc.data().favorites || [];
    const updatedFavorites = favorites.filter((fav: FavoriteStop) => fav.id !== favoriteId);
    await updateDoc(userDocRef, { favorites: updatedFavorites });
  }
};

// Sync journey history
export const syncHistory = async () => {
  const user = auth.currentUser;
  if (!user) throw new Error('User not authenticated');

  const userDocRef = doc(db, 'users', user.uid);
  const userDoc = await getDoc(userDocRef);

  if (userDoc.exists()) {
    const data = userDoc.data();
    return data.history || [];
  } else {
    await setDoc(userDocRef, { history: [] });
    return [];
  }
};

export const addJourney = async (journey: JourneyHistory) => {
  const user = auth.currentUser;
  if (!user) throw new Error('User not authenticated');

  const userDocRef = doc(db, 'users', user.uid);
  await updateDoc(userDocRef, {
    history: arrayUnion(journey)
  });
};

// Listen for real-time updates
export const subscribeToFavorites = (callback: (favorites: FavoriteStop[]) => void) => {
  const user = auth.currentUser;
  if (!user) return () => {};

  const userDocRef = doc(db, 'users', user.uid);
  return onSnapshot(userDocRef, (doc) => {
    if (doc.exists()) {
      const data = doc.data();
      callback(data.favorites || []);
    }
  });
};

export const subscribeToHistory = (callback: (history: JourneyHistory[]) => void) => {
  const user = auth.currentUser;
  if (!user) return () => {};

  const userDocRef = doc(db, 'users', user.uid);
  return onSnapshot(userDocRef, (doc) => {
    if (doc.exists()) {
      const data = doc.data();
      callback(data.history || []);
    }
  });
};