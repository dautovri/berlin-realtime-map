package com.berlintransport

import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import androidx.core.content.ContextCompat

class Shortcuts(private val context: Context) {

    private val shortcutManager = context.getSystemService(ShortcutManager::class.java)

    fun createShortcuts() {
        val shortcuts = listOf(
            createShortcut(
                id = "nearby_stops",
                shortLabel = "Nearby Stops",
                longLabel = "Find nearby transport stops",
                iconResId = R.drawable.ic_stops,
                intent = Intent(context, MainActivity::class.java).apply {
                    action = "ACTION_NEARBY_STOPS"
                }
            ),
            createShortcut(
                id = "view_favorites",
                shortLabel = "Favorites",
                longLabel = "View favorite stops",
                iconResId = R.drawable.ic_favorites,
                intent = Intent(context, MainActivity::class.java).apply {
                    action = "ACTION_VIEW_FAVORITES"
                }
            ),
            createShortcut(
                id = "check_departures",
                shortLabel = "Departures",
                longLabel = "Check upcoming departures",
                iconResId = R.drawable.ic_departures,
                intent = Intent(context, MainActivity::class.java).apply {
                    action = "ACTION_CHECK_DEPARTURES"
                }
            )
        )

        shortcutManager?.dynamicShortcuts = shortcuts
    }

    private fun createShortcut(
        id: String,
        shortLabel: String,
        longLabel: String,
        iconResId: Int,
        intent: Intent
    ): ShortcutInfo {
        return ShortcutInfo.Builder(context, id)
            .setShortLabel(shortLabel)
            .setLongLabel(longLabel)
            .setIcon(Icon.createWithResource(context, iconResId))
            .setIntent(intent)
            .build()
    }

    fun updateShortcut(id: String, newIntent: Intent) {
        shortcutManager?.reportShortcutUsed(id)
        // Update if needed
    }
}