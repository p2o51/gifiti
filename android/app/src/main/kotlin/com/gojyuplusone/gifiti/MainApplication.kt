package com.gojyuplusone.gifiti

import androidx.multidex.MultiDexApplication
import android.os.StrictMode

class MainApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        
        // 设置允许主线程网络访问
        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
        StrictMode.setThreadPolicy(policy)
        
        // 设置HTTP属性
        System.setProperty("http.keepAlive", "true")
    }
} 