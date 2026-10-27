package com.kmart.staffportal

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "kmart_staff/notifications"
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 3001

    companion object {
        private const val CHANNEL_ID = "kmart_staff_orders"
        private const val CHANNEL_NAME = "Order & Delivery Alerts"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Kmart Staff"
                    val body = call.argument<String>("body") ?: ""
                    val notificationId = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                    try {
                        createNotificationChannel()

                        val intent = Intent(this, MainActivity::class.java).apply {
                            action = Intent.ACTION_MAIN
                            addCategory(Intent.CATEGORY_LAUNCHER)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }

                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }
                        val pendingIntent = PendingIntent.getActivity(this, notificationId, intent, flags)

                        val smallIconResId = applicationInfo.icon
                        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

                        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
                            .setSmallIcon(smallIconResId)
                            .setColor(0xFFE53935.toInt()) // Kmart Red
                            .setContentTitle(title)
                            .setContentText(body)
                            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                            .setPriority(NotificationCompat.PRIORITY_HIGH)
                            .setSound(defaultSoundUri)
                            .setVibrate(longArrayOf(0, 350, 150, 350))
                            .setDefaults(NotificationCompat.DEFAULT_ALL)
                            .setContentIntent(pendingIntent)
                            .setAutoCancel(true)

                        val largeIcon = getAppIconBitmap()
                        if (largeIcon != null) {
                            builder.setLargeIcon(largeIcon)
                        }

                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        notificationManager.notify(notificationId, builder.build())
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                NOTIFICATION_PERMISSION_REQUEST_CODE
                            )
                        }
                        result.success(granted)
                    } else {
                        result.success(true)
                    }
                }
                "checkNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    } else {
                        val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                        result.success(enabled)
                    }
                }
                "cancelNotification" -> {
                    val id = call.argument<Int>("id")
                    if (id != null) {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        notificationManager.cancel(id)
                    }
                    result.success(true)
                }
                "cancelAll" -> {
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    notificationManager.cancelAll()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getAppIconBitmap(): Bitmap? {
        return try {
            val drawable = ContextCompat.getDrawable(this, applicationInfo.icon) ?: return null
            if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 192
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 192
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bitmap
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()

                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alerts for new orders to pack and deliveries"
                    enableLights(true)
                    lightColor = 0xFFE53935.toInt()
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 350, 150, 350)
                    setSound(soundUri, audioAttributes)
                }
                notificationManager.createNotificationChannel(channel)
            }
        }
    }
}
