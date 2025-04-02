# Keep Nearby Connections classes
-keep class com.google.android.gms.nearby.** { *; }
-keep class com.pkmnapps.nearby_connections.** { *; }

# Keep callback classes that use reflection
-keep class * implements com.google.android.gms.nearby.connection.ConnectionLifecycleCallback { *; }
-keep class * implements com.google.android.gms.nearby.connection.EndpointDiscoveryCallback { *; }
-keep class * implements com.google.android.gms.nearby.connection.PayloadCallback { *; }

# Don't warn about ServiceLoader calls
-dontnote com.google.android.gms.nearby.**