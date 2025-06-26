// Firebase configuration and initialization
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';
import { getAnalytics, isSupported } from 'firebase/analytics';

// Firebase configuration
    const firebaseConfig = {
      apiKey: "AIzaSyBbErRqwrcX6-ogwmnmr98E3Q4H8KP4w9Q",
      authDomain: "thesis-generator-web.firebaseapp.com",
      projectId: "thesis-generator-web",
      storageBucket: "thesis-generator-web.firebasestorage.app",
      messagingSenderId: "1098826060423",
      appId: "1:1098826060423:web:7ee70dc121234297f05e22",
      measurementId: "G-BY0DNNV0K3"
    };

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase Authentication
export const auth = getAuth(app);

// Initialize Cloud Firestore
export const db = getFirestore(app);

// Initialize Analytics (only if supported)
let analytics = null;
isSupported().then((supported) => {
  if (supported) {
    analytics = getAnalytics(app);
  }
});

export { analytics };

// Development mode emulator connections
if (window.location.hostname === 'localhost') {
  // Connect to emulators in development
  try {
    connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
    connectFirestoreEmulator(db, 'localhost', 8080);
    console.log('🔧 Connected to Firebase emulators');
  } catch (error) {
    console.log('⚠️ Emulators not available, using production Firebase');
  }
}

// Export the app instance
export default app;

console.log('🔥 Firebase initialized successfully');
