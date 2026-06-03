import TVServices

private let appGroupId = "group.com.edde746.plezy"
private let itemsKey = "topShelfItems"

class TopShelfProvider: TVTopShelfContentProvider {
  override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
    let items = loadItems()
    let content = TVTopShelfInsetContent(items: items)
    completionHandler(content)
  }

  private func loadItems() -> [TVTopShelfItem] {
    guard
      let defaults = UserDefaults(suiteName: appGroupId),
      let data = defaults.data(forKey: itemsKey),
      let rawItems = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }

    return rawItems.compactMap(makeItem)
  }

  private func makeItem(_ raw: [String: Any]) -> TVTopShelfItem? {
    guard
      let contentId = raw["contentId"] as? String,
      let title = raw["title"] as? String
    else { return nil }

    let item = TVTopShelfItem(identifier: contentId)
    item.title = title

    if let imageUrlString = raw["imageUrl"] as? String, let imageUrl = URL(string: imageUrlString) {
      item.setImageURL(imageUrl, for: .screenScale1x)
    }

    var components = URLComponents()
    components.scheme = "plezy"
    components.host = "play"
    components.queryItems = [URLQueryItem(name: "content_id", value: contentId)]
    if let url = components.url {
      item.playAction = TVTopShelfAction(url: url)
    }

    return item
  }
}
