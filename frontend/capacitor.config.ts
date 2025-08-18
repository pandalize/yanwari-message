import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.yanwari.message',
  appName: 'やんわり伝言',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: "#4f46e5",
      showSpinner: true,
      androidSpinnerStyle: "large",
      iosSpinnerStyle: "small"
    }
  }
};

export default config;
