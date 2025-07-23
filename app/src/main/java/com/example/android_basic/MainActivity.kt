// MainActivity.kt
// This is the main entry point for your Android app's UI.
// It displays the "Hello World!" screen and handles window insets for modern edge-to-edge layouts.
//jdj
package com.yourcompany.yourapp
////65577
// Import essential Android and Jetpack libraries
import android.os.Bundle
import androidx.activity.enableEdgeToEdge // For drawing behind system bars
import androidx.appcompat.app.AppCompatActivity // Base class for activities using the support library action bar features
import androidx.core.view.ViewCompat // For window inset listener
import androidx.core.view.WindowInsetsCompat // For handling system window insets

// MainActivity is the main screen shown when the app launches
class MainActivity : AppCompatActivity() {
    // onCreate is called when the activity is first created
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState) // Always call the superclass first

        // Enable edge-to-edge display (draw behind status/navigation bars)
        enableEdgeToEdge()

        // Set the layout for this activity. The layout file is located at res/layout/activity_main.xml
        setContentView(R.layout.activity_main)

        // Apply window insets (padding) to the root view so content isn't hidden by system bars
        // This is important for modern Android design
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            // Get the size of system bars (status bar, navigation bar, etc.)
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            // Set padding so content is not overlapped by system bars
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets // Return the insets object
        }
    }
}