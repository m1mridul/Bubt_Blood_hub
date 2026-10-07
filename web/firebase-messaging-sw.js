importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: 'AIzaSyDL5p8mHPGRg9xW5e_E0-4HL3PrFwwHhXw',
  appId: '1:838439547919:web:13b725c620fff5ef8e9f7a',
  messagingSenderId: '838439547919',
  projectId: 'bloodhub-56778',
  authDomain: 'bloodhub-56778.firebaseapp.com',
  storageBucket: 'bloodhub-56778.firebasestorage.app',
  measurementId: 'G-7L1EWREMMK',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
