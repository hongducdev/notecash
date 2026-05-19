package com.hongducdev.notecash

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class NotecashWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.notecash_widget).apply {
                // Set balance
                val balance = widgetData.getString("balance", "₫0")
                setTextViewText(R.id.widget_balance, balance)

                // Quick Entry button - opens add expense screen
                val addExpenseIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("notecash://add-expense")
                )
                setOnClickPendingIntent(R.id.widget_quick_entry, addExpenseIntent)
                
                // Clicking the balance - opens dashboard
                val dashboardIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("notecash://dashboard")
                )
                setOnClickPendingIntent(R.id.balance_container, dashboardIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
