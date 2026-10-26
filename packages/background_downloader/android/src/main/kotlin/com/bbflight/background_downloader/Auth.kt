package com.bbflight.background_downloader

import android.net.Uri
import kotlinx.serialization.InternalSerializationApi
import kotlinx.serialization.Serializable

@Serializable
@Suppress("unused")
@OptIn(InternalSerializationApi::class)
class Auth(
    private var accessToken: String? = null,
    private var accessHeaders: Map<String, String> = emptyMap(),
    private var accessQueryParams: Map<String, String> = emptyMap(),
    private var accessTokenExpiryTime: Long? = null,
    private var refreshToken: String? = null,
    private var refreshHeaders: Map<String, String> = emptyMap(),
    private var refreshQueryParams: Map<String, String> = emptyMap(),
    private var refreshUrl: String? = null,
    private var onAuthRawHandle: Long? = null
) {

    /**
     * Returns the headers specified for the access request, with the
     * template `{accessToken}` and `{refreshToken}` replaced.
     */
    fun getExpandedAccessHeaders(): Map<String, String> = expandMap(accessHeaders)

    /**
     * Returns the query parameters specified for the access request, with the
     * template `{accessToken}` and `{refreshToken}` replaced.
     */
    fun getExpandedAccessQueryParams(): Map<String, String> = expandMap(accessQueryParams)

    /**
     * Add/update the query parameters in this [url] with [queryParams]
     * and return the new uri
     */
    fun addOrUpdateQueryParams(
        url: String,
        queryParams: Map<String, String> = emptyMap()
    ): Uri {
        val startUri = Uri.parse(url)
        if (queryParams.isEmpty()) {
            return startUri
        }
        val updatedQueryParams =
            startUri.queryParameterNames.associateWith { startUri.getQueryParameter(it) }
                .toMutableMap()
        updatedQueryParams.putAll(queryParams)
        return startUri.buildUpon().clearQuery().apply {
            updatedQueryParams.forEach { (key, value) ->
                appendQueryParameter(key, value)
            }
        }.build()
    }


    /**
     * Returns true if the [accessTokenExpiryTime is after now plus
     * the [bufferTime], otherwise returns false
     */
    fun isTokenExpired(bufferTime: Long = 10000): Boolean {
        val expiry = accessTokenExpiryTime ?: return false
        val expiryTimeWithBuffer = System.currentTimeMillis() + bufferTime
        return expiryTimeWithBuffer > expiry
    }

    /**
     * Expands the [mapToExpand] by replacing {accessToken} and {refreshToken}
     *
     * Returns the expanded map, without changing the original
     */
    private fun expandMap(mapToExpand: Map<String, String>): Map<String, String> {
        val newMap = mutableMapOf<String, String>()
        mapToExpand.forEach { (key, value) ->
            var newValue = value
            if (accessToken != null) {
                newValue = newValue.replace("{accessToken}", accessToken!!)
            }
            if (refreshToken != null) {
                newValue = newValue.replace("{refreshToken}", refreshToken!!)
            }
            newMap[key] = newValue
        }
        return newMap
    }

    /**
     * True if this Auth object has an 'onAuth' callback that can be called to refresh the
     * access token
     */
    fun hasOnAuthCallback(): Boolean = onAuthRawHandle != null

}