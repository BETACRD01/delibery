package com.deliber.app

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d("FCM", "Mensaje recibido de: ${remoteMessage.from}")

        // Notificación
        remoteMessage.notification?.let {
            Log.d("FCM", "Título: ${it.title}")
            Log.d("FCM", "Cuerpo: ${it.body}")
        }

        // Data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d("FCM", "Data: ${remoteMessage.data}")
        }
    }

    override fun onNewToken(token: String) {
        Log.d("FCM", "Nuevo token FCM: $token")
        // TODO: Enviar este token a tu servidor
    }
}
