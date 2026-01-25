import { Platform } from 'react-native';

// Platform detection
export const isIOS = Platform.OS === 'ios';
export const isAndroid = Platform.OS === 'android';

// Platform-specific features
export const supportsWidgets = isIOS; // iOS has widgets
export const supportsShortcuts = isAndroid; // Android has app shortcuts

// Feature availability
export const getPlatformFeatures = () => {
  return {
    widgets: supportsWidgets,
    shortcuts: supportsShortcuts,
    hapticFeedback: true, // Both platforms support
    biometricAuth: true, // Assuming both support
  };
};

// Conditional feature integration
export const getPlatformSpecificConfig = () => {
  if (isIOS) {
    return {
      widgetRefreshInterval: 15 * 60 * 1000, // 15 minutes
      shortcutActions: [], // No shortcuts on iOS, use widgets
    };
  } else if (isAndroid) {
    return {
      shortcutMaxCount: 4, // Android allows up to 4 dynamic shortcuts
      widgetRefreshInterval: 30 * 60 * 1000, // 30 minutes (widgets less common on Android)
    };
  }
  return {};
};