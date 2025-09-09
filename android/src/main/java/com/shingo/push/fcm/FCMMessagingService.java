package com.shingo.push.fcm;
import androidx.annotation.NonNull;
import com.google.firebase.messaging.FirebaseMessagingService;

public class FCMMessagingService extends FirebaseMessagingService {

    @Override
    public void onNewToken(@NonNull String token) {
    }
}
