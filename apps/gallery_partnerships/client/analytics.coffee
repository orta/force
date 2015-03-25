{ track, trackForms, trackLinks, snowplowStruct } = require '../../../lib/analytics.coffee'
splitTest = require '../../../components/split_test/index.coffee'

module.exports = ->
  track.impression 'Gallery partnerships page'

  if splitTest('gallery_partnerships_apply').outcome() is 'inline'
    trackForms '.js-gallery-partnerships-apply-form', 'Submitted inline application form from /gallery-partnerships'
    trackForms '.js-gallery-partnerships-apply-form', '/gallery-partnerships CTA'
  else
    trackLinks '.gallery-partnerships-nav-apply-link', '/gallery-partnerships CTA'

  $('.gallery-partnerships-nav-link.internal').click (e) ->
    section = $(e.currentTarget).attr 'data-section'
    track.click 'Clicked nav link on gallery partnerships', section: section
    snowplowStruct 'gallery_partnerships', 'click_nav_link', 'section', section

  $('.gallery-partnerships-nav-apply-link').click ->
    track.click 'Clicked nav apply on gallery partnerships'
    snowplowStruct 'gallery_partnerships', 'click_nav_apply'

  $('.apply-button').click ->
    track.click 'Clicked bottom apply on gallery partnerships'
    snowplowStruct 'gallery_partnerships', 'click_bottom_apply'