// mobile/web/firebase-messaging-sw.js
// Firebase Cloud Messaging Service Worker for Web Push Notifications

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCr2e3KIGxO2QYR4HPkB5nnyxBXRx9ZAnM",
  authDomain: "zikre-kidusan.firebaseapp.com",
  projectId: "zikre-kidusan",
  storageBucket: "zikre-kidusan.firebasestorage.app",
  messagingSenderId: "869520328580",
  appId: "1:869520328580:web:bfc4aa4957ef38b9e2ffd1",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message: ', payload);
  const notificationTitle = payload.notification ? payload.notification.title : 'New Notification';
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : '',
    icon: '/icons/Icon-192.png',
    data: payload.data,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
