package com.edde746.plezy.shared

import android.graphics.PixelFormat
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup

object FlutterOverlayHelper {

    /**
     * Find the FlutterView container in the content view hierarchy.
     * First tries to match by class name (works in debug builds),
     * then falls back to picking the last ViewGroup with children
     * (needed for release builds where FlutterView may be obfuscated).
     */
    fun findFlutterContainer(contentView: ViewGroup, excludeView: View? = null): ViewGroup? {
        // First pass: look for FlutterView by name (debug builds)
        for (i in 0 until contentView.childCount) {
            val child = contentView.getChildAt(i)
            if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                return child
            }
        }

        // Fallback for release (FlutterView may be obfuscated): pick the last ViewGroup
        // that is not our video container and has children.
        for (i in contentView.childCount - 1 downTo 0) {
            val child = contentView.getChildAt(i)
            if (child is ViewGroup && child != excludeView && child.childCount > 0) {
                return child
            }
        }

        return null
    }

    /**
     * Configure z-ordering so the Flutter UI renders above the video surface.
     *
     * @param zOrderOnTop true for MPV (Flutter needs to be fully on top),
     *                    false for ExoPlayer (subtitle layer sits between video and Flutter)
     */
    fun configureFlutterZOrder(contentView: ViewGroup, container: ViewGroup, zOrderOnTop: Boolean) {
        contentView.bringChildToFront(container)
        for (j in 0 until container.childCount) {
            val flutterChild = container.getChildAt(j)
            if (flutterChild is SurfaceView) {
                flutterChild.setZOrderOnTop(zOrderOnTop)
                flutterChild.setZOrderMediaOverlay(true)
                flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                break
            } else if (flutterChild is TextureView) {
                flutterChild.isOpaque = false
                break
            }
        }
    }
}
