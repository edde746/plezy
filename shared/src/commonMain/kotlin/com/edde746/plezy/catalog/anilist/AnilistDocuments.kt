package com.edde746.plezy.catalog.anilist

/** The GraphQL documents of the AniList catalog (docs.anilist.co). */
internal object AnilistDocuments {
    /** Cast carried on row items, so a detail screen opened from a row needs no characters. */
    const val ROW_CAST_LIMIT = 6

    /** Staff edges read for credits on the detail screen. */
    const val DETAIL_STAFF_LIMIT = 8

    /** The media fields every row and the detail body select. */
    private const val CATALOG_MEDIA_FIELDS = """
    id
    idMal
    title {
      english
      romaji
      native
      userPreferred
    }
    synonyms
    format
    status
    episodes
    duration
    description
    averageScore
    meanScore
    popularity
    favourites
    trending
    season
    seasonYear
    startDate {
      year
      month
      day
    }
    endDate {
      year
      month
      day
    }
    genres
    isAdult
    source
    countryOfOrigin
    coverImage {
      extraLarge
      large
      color
    }
    bannerImage
    studios(isMain: true) {
      nodes {
        name
      }
    }
    trailer {
      id
      site
    }
    nextAiringEpisode {
      episode
      airingAt
      timeUntilAiring
    }
    rankings {
      rank
      type
      format
      year
      season
      allTime
      context
    }
"""

    /** A row's first characters: about 1.6× the row's bytes, against a characters request per detail screen. */
    private const val ROW_CHARACTER_FIELDS = """
    characters(
      page: 1
      perPage: $ROW_CAST_LIMIT
      sort: [ROLE, RELEVANCE]
    ) {
      edges {
        role
        node {
          name {
            full
          }
          image {
            large
            medium
          }
        }
      }
    }
"""

    private const val ROW_MEDIA_FIELDS = CATALOG_MEDIA_FIELDS + ROW_CHARACTER_FIELDS

    private const val DETAIL_CHARACTER_FIELDS = $$"""
    characters(page: 1, perPage: $castPerPage, sort: [ROLE, RELEVANCE]) {
      edges {
        role
        node {
          name {
            full
          }
          image {
            large
            medium
          }
        }
      }
    }
"""

    /** Recommendation and relation cards keep a compact shape: every row field, nested, would multiply the body. */
    private const val RELATED_MEDIA_FIELDS = """
    id
    idMal
    title {
      english
      romaji
      userPreferred
      native
    }
    format
    status
    episodes
    duration
    description
    averageScore
    season
    seasonYear
    startDate {
      year
    }
    genres
    synonyms
    isAdult
    coverImage {
      extraLarge
      large
    }
    bannerImage
    studios(isMain: true) {
      nodes {
        name
      }
    }
    trailer {
      id
      site
    }
"""

    /** Tags have no pagination, so they are selected only on the one-item detail body (and at most 20 kept). */
    private const val DETAIL_MEDIA_FIELDS = $$"""
    tags {
      name
      rank
      isMediaSpoiler
    }
    externalLinks {
      site
      url
    }
    streamingEpisodes {
      title
      thumbnail
      url
      site
    }
    staff(page: 1, perPage: $staffPerPage) {
      edges {
        role
        node {
          name {
            full
          }
        }
      }
    }
"""

    /** A page of anime, adult titles excluded; [includeRowCast] adds the row cast. */
    fun animePage(includeRowCast: Boolean): String = $$"""
query(
  $page: Int
  $perPage: Int
  $sort: [MediaSort!]
  $search: String
  $season: MediaSeason
  $seasonYear: Int
) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
    }
    media(
      type: ANIME
      isAdult: false
      sort: $sort
      search: $search
      season: $season
      seasonYear: $seasonYear
    ) {
$${if (includeRowCast) ROW_MEDIA_FIELDS else CATALOG_MEDIA_FIELDS}
    }
  }
}
"""

    /** The viewer's Planning list, newest first; [idsOnly] selects just the ids (the membership snapshot). */
    fun planningList(idsOnly: Boolean): String = $$"""
query($userId: Int!, $chunk: Int, $perChunk: Int) {
  MediaListCollection(
    userId: $userId
    type: ANIME
    status: PLANNING
    sort: [ADDED_TIME_DESC]
    chunk: $chunk
    perChunk: $perChunk
  ) {
    hasNextChunk
    lists {
      isCustomList
      entries {
        media {
$${if (idsOnly) "id idMal" else ROW_MEDIA_FIELDS}
        }
      }
    }
  }
}
"""

    /** One anime with detail fields, recommendations and relations; [includeCharacters] adds its cast. */
    fun detail(includeCharacters: Boolean): String = $$"""
query(
  $id: Int!
  $${if (includeCharacters) "\$castPerPage: Int" else ""}
  $relatedPerPage: Int
  $staffPerPage: Int
) {
  Media(id: $id, type: ANIME) {
$$CATALOG_MEDIA_FIELDS
$$DETAIL_MEDIA_FIELDS
$${if (includeCharacters) DETAIL_CHARACTER_FIELDS else ""}
    recommendations(page: 1, perPage: $relatedPerPage) {
      nodes {
        mediaRecommendation {
$$RELATED_MEDIA_FIELDS
        }
      }
    }
    relations(page: 1, perPage: $relatedPerPage) {
      edges {
        relationType(version: 2)
        node {
$$RELATED_MEDIA_FIELDS
        }
      }
    }
  }
}
"""

    const val VIEWER_ID = "query { Viewer { id } }"

    /** Sets the list status without touching progress, which would reset an active entry. */
    const val SET_STATUS = $$"""
mutation($mediaId: Int, $status: MediaListStatus) {
  SaveMediaListEntry(mediaId: $mediaId, status: $status) {
    id
  }
}
"""

    const val LIST_ENTRY = $$"""
query($mediaId: Int) {
  Media(id: $mediaId, type: ANIME) {
    mediaListEntry {
      id
      status
    }
  }
}
"""

    const val DELETE_ENTRY = $$"""
mutation($id: Int) {
  DeleteMediaListEntry(id: $id) {
    deleted
  }
}
"""
}
