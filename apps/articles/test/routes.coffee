_ = require 'underscore'
sinon = require 'sinon'
moment = require 'moment'
Backbone = require 'backbone'
Article = require '../../../models/article'
Articles = require '../../../collections/articles'
routes = require '../routes'
fixtures = require '../../../test/helpers/fixtures.coffee'
describe 'Article routes', ->

  beforeEach ->
    sinon.stub Backbone, 'sync'
    @req = { params: {} }
    @res = { render: sinon.stub(), locals: { sd: {} }, redirect: sinon.stub() }
    @next = sinon.stub()
    sinon.stub Article.prototype, 'fetchWithRelated'

  afterEach ->
    Backbone.sync.restore()
    Article::fetchWithRelated.restore()

  describe '#article', ->

    it 'redirects old slugs', ->
      @req.params.slug = 'foo'
      routes.article @req, @res
      Article::fetchWithRelated.args[0][0].success(
        article: new Article(_.extend fixtures.article, title: 'Foo', slug: 'bar')
        footerArticles: new Articles([_.extend fixtures.article, title: 'Bar'])
      )
      @res.redirect.args[0][0].should.equal '/article/bar'

   it 'fetches an article, its related content, and renders it', ->
      @req.params.slug = 'bar'
      routes.article @req, @res
      Article::fetchWithRelated.args[0][0].success(
        article: new Article(_.extend fixtures.article, title: 'Foo', slug: 'bar')
        footerArticles: new Articles([_.extend fixtures.article, title: 'Bar'])
      )
      @res.render.args[0][0].should.equal 'article'
      @res.render.args[0][1].article.get('title').should.equal 'Foo'
      @res.render.args[0][1].footerArticles.first().get('title')
        .should.equal 'Bar'

  describe '#articles', ->

    it 'fetches published articles', (done) ->
      routes.articles @req, @res, @next
      Backbone.sync.args[0][2].success results: [fixtures.section]
      Backbone.sync.args[1][2].success results: [
        { tier: 1, id: 'a' }
        { tier: 1, id: 'b' }
        { tier: 1, id: 'c' }
        { tier: 1, id: 'd' }
        { tier: 2, id: 'e' }
        { tier: 2, id: 'f' }
        { tier: 1, id: 'g' }
        { tier: 2, id: 'h' }
      ]
      _.defer => _.defer =>
        @res.render.args[0][1].articles.should.have.lengthOf 8
        done()

    xit 'gets the running section', (done) ->
      routes.articles @req, @res, @next
      section = _.extend(_.clone(fixtures.section), {
        title: 'Foo Bar'
        start_at: moment().subtract(1, 'days')
        end_at: moment().add(1, 'days')
      })
      Backbone.sync.args[0][2].success results: [section]
      Backbone.sync.args[1][2].success results: [
        { tier: 1, id: 'a' }
        { tier: 1, id: 'b' }
        { tier: 1, id: 'c' }
        { tier: 1, id: 'd' }
        { tier: 2, id: 'e' }
        { tier: 2, id: 'f' }
        { tier: 1, id: 'g' }
        { tier: 2, id: 'h' }
      ]
      setTimeout =>
        @res.render.args[0][1].section.get('title').should.equal 'Foo Bar'
        done()

    it 'requests less than 100 pages!', ->
      routes.articles @req, @res, @next
      Backbone.sync.args[1][2].data.limit.should.be.below 100

  describe '#section', ->

    it 'renders the section with its articles', ->
      section = _.extend _.clone(fixtures.section), slug: 'foo'
      @req.params.slug = 'foo'
      routes.section @req, @res, @next
      Backbone.sync.args[0][2].success section
      Backbone.sync.args[1][2].data.section_id.should.equal section.id
      Backbone.sync.args[1][2].success fixtures.articles
      @res.render.args[0][0].should.equal 'section'
      @res.render.args[0][1].section.get('title').should.equal section.title

    it 'nexts for an error b/c it uses a root url that should be passed on', ->
      routes.section @req, @res, @next
      Backbone.sync.args[0][2].error()
      @next.called.should.be.ok()

  describe '#redirectPost', ->

    it 'redirects posts to articles', ->
      @req.url = 'post/foo'
      routes.redirectPost @req, @res, @next
      @res.redirect.args[0][1].should.containEql 'article/foo'
