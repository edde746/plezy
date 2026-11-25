package com.edde746.plezy.model

import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject

/** The [MediaItem.raw] key under which an item synthesized from a catalog entry keeps that entry's JSON. */
const val CATALOG_ITEM_RAW_KEY: String = "plezyCatalog"

/**
 * Whether this item is a rendering-only stand-in for a catalog entry. Such items have no server behind them: taps and
 * menus route through catalog paths, never server ones.
 */
val MediaItem.isCatalogItem: Boolean get() = raw?.get(CATALOG_ITEM_RAW_KEY).let { it != null && it !is JsonNull }

/** The catalog entry's JSON a stand-in carries; null when it is not an object. */
val MediaItem.catalogItemJson: JsonObject? get() = raw?.get(CATALOG_ITEM_RAW_KEY) as? JsonObject
