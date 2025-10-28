// Firebase configuration for Arborist Assistant
// Real Firebase project configuration

const firebaseConfig = {
  apiKey: "AIzaSyBXJtx-6F1lhbdNSEV8G38bAVHPWbdODU4",
  authDomain: "arborist-assistant.firebaseapp.com",
  projectId: "arborist-assistant",
  storageBucket: "arborist-assistant.firebasestorage.app",
  messagingSenderId: "512062345870",
  appId: "1:512062345870:web:5a0832241950935e77afdf"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase services
const auth = firebase.auth();
const db = firebase.firestore();
const storage = firebase.storage();

// Export for use in other scripts
window.firebase = firebase;
window.auth = auth;
window.db = db;
window.storage = storage;
