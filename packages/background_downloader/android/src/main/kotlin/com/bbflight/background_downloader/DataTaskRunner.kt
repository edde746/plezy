package com.bbflight.background_downloader

import android.util.Log
import java.net.HttpURLConnection

class DataTaskRunner(context: TaskJobContext) : TaskRunner(context) {

    /** Process the response to the GET or POST request on this [connection]
     *
     * Returns the [TaskStatus]
     */
    override suspend fun process(
        connection: HttpURLConnection,
    ): TaskStatus {
        responseStatusCode = connection.responseCode
        if (responseStatusCode!! in 200..206) {
            extractResponseHeaders(connection.headerFields)
            extractContentType(connection.headerFields)
            // transfer the bytes from the server to the temp file
            return try {
                responseBody = connection.inputStream.bufferedReader().readText()
                TaskStatus.complete
            } catch (e: Exception) {
                Log.i(
                    TAG,
                    "Could not read response content: $e"
                )
                taskException = TaskException(ExceptionType.connection, description = "Could not read response content: $e")
                TaskStatus.failed
            }
        } else {
            // HTTP response code not OK
            Log.i(
                TAG,
                "Response code ${connection.responseCode} for taskId ${task.taskId}"
            )
            val errorContent = responseErrorContent(connection)
            taskException = TaskException(
                ExceptionType.httpResponse, httpResponseCode = connection.responseCode,
                description = if (errorContent?.isNotEmpty() == true) errorContent else connection.responseMessage
            )
            return if (responseStatusCode == 404) {
                responseBody = errorContent
                TaskStatus.notFound
            } else {
                TaskStatus.failed
            }
        }
    }
}
