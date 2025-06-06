package com.srk.aichat.api

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object RetrofitClient {
    // Use the proper api endpoint for Wikipedia API
    private const val BASE_URL = "https://en.wikipedia.org/"
    
    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }
    
    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .addInterceptor { chain ->
            // Add origin parameter to all requests to avoid CORS issues
            val original = chain.request()
            val originalHttpUrl = original.url
            
            val url = originalHttpUrl.newBuilder()
                .addQueryParameter("origin", "*")
                .build()
                
            val requestBuilder = original.newBuilder()
                .url(url)
                .header("Accept", "application/json")
                .header("Content-Type", "application/json")
                
            val request = requestBuilder.build()
            chain.proceed(request)
        }
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()
    
    private val retrofit = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
    
    val wikipediaService: WikipediaService = retrofit.create(WikipediaService::class.java)
} 