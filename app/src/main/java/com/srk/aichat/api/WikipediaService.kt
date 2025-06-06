package com.srk.aichat.api

import com.google.gson.annotations.SerializedName
import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Query

interface WikipediaService {
    @GET("w/api.php")
    suspend fun searchWikipedia(
        @Query("action") action: String = "query",
        @Query("format") format: String = "json",
        @Query("prop") prop: String = "extracts",
        @Query("exintro") exintro: String = "1",
        @Query("explaintext") explaintext: String = "1",
        @Query("redirects") redirects: String = "1",
        @Query("titles") title: String,
        @Query("exsectionformat") exsectionformat: String = "plain",
        @Query("utf8") utf8: String = "1"
    ): Response<WikipediaResponse>
    
    @GET("w/api.php")
    suspend fun searchByQuery(
        @Query("action") action: String = "query",
        @Query("format") format: String = "json",
        @Query("list") list: String = "search",
        @Query("srsearch") srsearch: String,
        @Query("srlimit") srlimit: Int = 5,
        @Query("utf8") utf8: String = "1"
    ): Response<SearchResponse>
    
    @GET("w/api.php")
    suspend fun searchSuggestions(
        @Query("action") action: String = "opensearch",
        @Query("format") format: String = "json",
        @Query("search") search: String,
        @Query("limit") limit: Int = 5,
        @Query("namespace") namespace: Int = 0,
        @Query("utf8") utf8: String = "1"
    ): Response<List<Any>>
}

data class WikipediaResponse(
    val batchcomplete: String? = null,
    val query: QueryResponse? = null,
    val error: ErrorResponse? = null
)

data class SearchResponse(
    val batchcomplete: String? = null,
    val `continue`: ContinueInfo? = null,
    val query: SearchQueryResponse? = null,
    val error: ErrorResponse? = null
)

data class ContinueInfo(
    val sroffset: Int? = null,
    val `continue`: String? = null
)

data class SearchQueryResponse(
    val search: List<SearchResult>? = null,
    val searchinfo: SearchInfo? = null
)

data class SearchInfo(
    val totalhits: Int? = null
)

data class SearchResult(
    val ns: Int? = null,
    val title: String? = null,
    val pageid: Int? = null,
    val size: Int? = null,
    val wordcount: Int? = null,
    val snippet: String? = null,
    val timestamp: String? = null
)

data class QueryResponse(
    val pages: Map<String, PageResponse>? = null,
    val normalized: List<NormalizedTitle>? = null
)

data class NormalizedTitle(
    val from: String? = null,
    val to: String? = null
)

data class PageResponse(
    val pageid: Int? = null,
    val ns: Int? = null,
    val title: String? = null,
    val extract: String? = null,
    val missing: String? = null
)

data class ErrorResponse(
    val code: String? = null,
    val info: String? = null
) 