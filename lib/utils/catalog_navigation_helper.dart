import 'package:flutter/material.dart';

import '../models/catalog/catalog_item.dart';
import '../screens/catalog_item_detail_screen.dart';

/// Open a catalog item (Explore tab tap sink, routed here by the catalog
/// branches in `navigateToMediaItem` / `navigateToMediaItemDetails`).
///
/// Always lands on [CatalogItemDetailScreen]; the screen resolves library
/// availability itself and lists the matching libraries in place ("In these
/// libraries"), rather than redirecting matched items to a different screen.
Future<void> navigateToCatalogItem(BuildContext context, CatalogItem item) async {
  await Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogItemDetailScreen(item: item)));
}
