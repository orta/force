_ = require 'underscore'
sd = require('sharify').data
Backbone = require 'backbone'
ModalView = require '../modal/view.coffee'
mediator = require '../../lib/mediator.coffee'
Form = require '../mixins/form.coffee'
CurrentUser = require '../../models/current_user.coffee'
LoggedOutUser = require '../../models/logged_out_user.coffee'
analyticsHooks = require '../../lib/analytics_hooks.coffee'
FlashMessage = require '../flash/index.coffee'

template = -> require('./templates/index.jade') arguments...

module.exports = class ContactView extends ModalView
  _.extend @prototype, Form

  className: 'contact'

  template: template
  headerTemplate: -> 'Comments'
  formTemplate: -> 'Override `formTemplate` to fill in this form'

  defaults: ->
    width: '470px'
    successMessage: 'Thank you. Your message has been sent.'
    placeholder: 'Your message'
    url: "#{sd.API_URL}/api/v1/feedback"

  events: -> _.extend super,
    'submit form': 'submit'
    'click #contact-submit': 'submit'
    'mouseenter #contact-submit': 'logHover'

  initialize: (options = {}) ->
    @options = _.defaults options, @defaults()

    @user = CurrentUser.orNull()

    @model = new Backbone.Model
    @model.url = @options.url

    _.extend @templateData,
      user: @user
      placeholder: @options.placeholder

    @on 'click:close', ->
      analyticsHooks.trigger 'contact:close-x'
    @on 'click:backdrop', ->
      analyticsHooks.trigger 'contact:close-back'

    super @options

  logHover: ->
    analyticsHooks.trigger 'contact:hover'

  postRender: ->
    @renderTemplates()

  renderTemplates: ->
    @$('#contact-header').html @headerTemplate(@templateData)
    @$('#contact-form').html @formTemplate(@templateData)

  submit: (e) ->
    return unless @validateForm()
    return if @formIsSubmitting()

    e.preventDefault()

    @$submit ?= @$('#contact-submit')
    @$errors ?= @$('#contact-errors')

    @$submit.attr 'data-state', 'loading'

    # Set the data but don't persist it yet
    @model.set @serializeForm()

    @model.save null,
      success: =>
        @close =>
          new FlashMessage message: @options.successMessage
      error: (model, xhr, options) =>
        @reenableForm()
        @$errors.text @errorMessage(xhr)
        @$submit.attr 'data-state', 'error'
        @updatePosition()

    analyticsHooks.trigger 'contact:submitted', attributes: @model.attributes

  focusTextareaAfterCopy: =>
    return unless @autofocus()
    val = ($textarea = @$('textarea')).val()
    $textarea.focus().val('').val val
