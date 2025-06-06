package com.srk.aichat.repository

import android.util.Log
import com.srk.aichat.api.RetrofitClient
import com.srk.aichat.api.SearchResult
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import org.jsoup.Jsoup
import java.io.IOException
import java.net.URLEncoder
import java.util.concurrent.TimeoutException

class WikipediaRepository {
    private val TAG = "WikipediaRepository"
    private val TIMEOUT_MS = 10000 // 10 seconds
    
    // Hardcoded responses for common failures
    private val FALLBACK_RESPONSES = mapOf(
        "network" to "I'm having trouble connecting to my knowledge sources. Please check your internet connection and try again.",
        "timeout" to "It's taking longer than expected to find information. This might be due to network issues or high demand.",
        "not_found" to "I couldn't find specific information about that topic. Could you try asking about something else?",
        "general" to "I encountered an issue while retrieving information. Let me try a different approach next time."
    )
    
    private val wikipediaService = RetrofitClient.wikipediaService

    suspend fun getInformationAbout(query: String): String {
        return try {
            withContext(Dispatchers.IO) {
                val encodedQuery = URLEncoder.encode(query, "UTF-8")
                val searchUrl = "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$encodedQuery&format=json"
                
                // First get search results
                val searchResponse = fetchWithRetry(searchUrl)
                val searchJson = JSONObject(searchResponse)
                val searchResults = searchJson.getJSONObject("query").getJSONArray("search")
                
                if (searchResults.length() == 0) {
                    return@withContext FALLBACK_RESPONSES["not_found"] ?: "I couldn't find information about $query."
                }
                
                // Get the title of the first result
                val firstResult = searchResults.getJSONObject(0)
                val title = firstResult.getString("title")
                
                // Then get the actual content
                val contentUrl = "https://en.wikipedia.org/w/api.php?action=query&prop=extracts&exintro&explaintext&titles=${URLEncoder.encode(title, "UTF-8")}&format=json"
                val contentResponse = fetchWithRetry(contentUrl)
                val contentJson = JSONObject(contentResponse)
                
                val pages = contentJson.getJSONObject("query").getJSONObject("pages")
                val pageId = pages.keys().next()
                val extract = pages.getJSONObject(pageId).getString("extract")
                
                // Return a trimmed version if it's too long
                if (extract.length > 1500) {
                    extract.substring(0, 1500) + "..."
                } else {
                    extract
                }
            }
        } catch (e: TimeoutException) {
            Log.e(TAG, "Timeout while getting information", e)
            FALLBACK_RESPONSES["timeout"] ?: "Request timed out. Please try again."
        } catch (e: IOException) {
            Log.e(TAG, "Network error while getting information", e)
            FALLBACK_RESPONSES["network"] ?: "Network error. Please check your connection."
        } catch (e: CancellationException) {
            // Don't catch cancellation exceptions - they should propagate
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Error getting information", e)
            FALLBACK_RESPONSES["general"] ?: "I encountered an issue while retrieving information about $query."
        }
    }
    
    private suspend fun fetchWithRetry(url: String, maxRetries: Int = 2): String {
        var lastException: Exception? = null
        for (attempt in 0..maxRetries) {
            try {
                val connection = Jsoup.connect(url)
                    .ignoreContentType(true)
                    .timeout(TIMEOUT_MS)
                val response = connection.execute()
                return response.body()
            } catch (e: Exception) {
                lastException = e
                if (attempt < maxRetries) {
                    // Exponential backoff - wait longer for each retry
                    val waitTime = (100L * (2.0.pow(attempt))).toLong()
                    kotlinx.coroutines.delay(waitTime)
                }
            }
        }
        throw lastException ?: IOException("Unknown error fetching data")
    }
    
    suspend fun getSuggestions(query: String): List<String> {
        if (query.isBlank()) return emptyList()
        
        return try {
            withContext(Dispatchers.IO) {
                val encodedQuery = URLEncoder.encode(query, "UTF-8")
                val url = "https://en.wikipedia.org/w/api.php?action=opensearch&search=$encodedQuery&limit=5&format=json"
                
                val response = fetchWithRetry(url)
                val jsonArray = org.json.JSONArray(response)
                
                val suggestions = mutableListOf<String>()
                if (jsonArray.length() > 1) {
                    val suggestionsArray = jsonArray.getJSONArray(1)
                    for (i in 0 until suggestionsArray.length()) {
                        suggestions.add(suggestionsArray.getString(i))
                    }
                }
                
                suggestions
            }
        } catch (e: CancellationException) {
            // Don't catch cancellation exceptions
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Error getting suggestions", e)
            emptyList()
        }
    }
    
    private fun Double.pow(exponent: Int): Double {
        var result = 1.0
        repeat(exponent) { result *= this }
        return result
    }
} 