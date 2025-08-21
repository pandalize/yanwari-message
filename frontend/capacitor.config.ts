import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.yanwari.message',
  appName: 'やんわり伝言',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    // 開発環境: 実機からMacのローカルサーバーへアクセス許可
    allowNavigation: ['http://192.168.11.18:8080', 'http://localhost:8080'],
    iosScheme: 'http'
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
