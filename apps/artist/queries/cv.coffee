module.exports =
  """
  query artist($artist_id: String!, $shows: Boolean!, $articles: Boolean!) {
    artist(id: $artist_id) {
      ... on Artist @include(if: $shows) {
        group_shows: partner_shows(at_a_fair: false, solo_show:false, sort: start_at_desc, size: 99) {
          ... relatedShow
          ... relatedShowImage
        }
        solo_shows: partner_shows(at_a_fair: false, solo_show:true, sort: start_at_desc, size: 99) {
          ... relatedShow
          ... relatedShowImage
        }
        fair_booths: partner_shows(at_a_fair: true, sort: start_at_desc, size: 99) {
          ... relatedShow
          ... relatedShowImage
        }
      }
      articles (limit: 99, sort: PUBLISHED_AT_DESC) @include(if: $articles) {
        href
        thumbnail_title
        published_at
      }
    }
  }

  #{require './show_fragment.coffee'}
  #{require './related_show_image.coffee'}

  """