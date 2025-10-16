package com.example.sales_ordering_app



import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example/location"
    private lateinit var locationManager: LocationManager
    private lateinit var result: MethodChannel.Result

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getCurrentLocation") {
                this.result = result
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), 1)
                } else {
                    getLocation()
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getLocation() {
        locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        var bestLocation: Location? = null
        val providers = locationManager.getProviders(true)

        for (provider in providers) {
            val l = locationManager.getLastKnownLocation(provider) ?: continue
            if (bestLocation == null || l.accuracy < bestLocation!!.accuracy) {
                bestLocation = l
            }
        }

        if (bestLocation != null) {
            result.success(mapOf("latitude" to bestLocation.latitude, "longitude" to bestLocation.longitude))
        } else {
            result.error("LOCATION_ERROR", "Could not get location", null)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            1 -> {
                if ((grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)) {
                    getLocation()
                } else {
                    result.error("PERMISSION_DENIED", "Location permission denied", null)
                }
                return
            }
        }
    }
}