# This is a rest api adapter for proper resources.
#
# .factory 'api', (rest) ->
#   new rest '/api/v1'
#
# .factory 'Book', (api) ->
#   api.model 'books'
#
# .factory 'Property' (api) ->
#   api.model 'properties', 'property'
#
# TODO decide on inheritance vs composition, in this case for the eventemitter
angular.module 'rest', [
  'events'
]

.factory 'Rest', (EventEmitter) ->
  class Rest extends EventEmitter
    constructor: ->
      @apis = {}

    register: (api) ->
      @apis[api.name] = api
      @emit 'Api:new', api

.service 'rest', (Rest) ->
  new Rest

.factory 'Api', ($http, $q, rest, EventEmitter) ->
  class Api extends EventEmitter
    constructor: (@name, @endpoint) ->
      @models = {}

      rest.register this

    register: (Model) =>
      @models[Model.plural] = Model
      @emit 'Model:new', Model

    http: (method, url, data) =>
      $http
        url: "#{@endpoint}#{url}.json"
        method: method
        data: data
      .then ({data}) ->
        console.log 'rest', method, url, data
        data
      .catch ({data}) ->
        data
      .catch ({code, reason}) ->
        console.log 'rest.catch', code, reason

    get:  (url, query) -> @http 'get', url, query
    post: (url, params) -> @http 'post', url, params
    put:  (url, params) -> @http 'put',  url, params
    del:  (url) -> @http 'delete', url

    model: (plural, singular, parent) ->
      api = this

      class Model extends EventEmitter
        @plural = plural
        @singular = singular ?= plural[...plural.length - 1] # Strip trailing s from plural unless given

        @endpoint = '/' + plural

        @cache = {}

        # TODO
        # These are not used atm, but could be a way to define model fields
        # to send on create/update, or even marshal the data.
        @fields = []
        @schema = {}

        api.register this

        ### Class Methods ###
        @index: (query) ->
          api.get @endpoint, query
          .then (data) =>
            new this obj for obj in data[@plural]

        @show: (id) ->
          if obj = @cache[id]
            dfd = $q.defer()
            dfd.resolve obj
            return dfd.promise

          api.get "#{@endpoint}/#{id}"
          .then (data) =>
            new this data

        @update: (id, data) ->
          params = {}
          params[@singular] = data
          api.put "#{@endpoint}", params

        @destroy: (id) ->
          api.del "#{@endpoint}/#{id}"
          .then (data) =>
            delete @cache[id]

        ### Instance Methods ###

        constructor: (data, uncached=false) ->
          angular.extend this, data
          @init()

          # TODO we don't want to cache the minis I guess...
          return if uncached

          @constructor.cache[@id] = this if @id

        init: ->
          null

        create: (owner) ->
          prefix = if owner then "#{owner.constructor.endpoint}/#{owner.id}" else ''
          console.log "CREATING", 'owner', owner
          console.log 'prefix', prefix

          params = {}
          obj = params[@constructor.singular] = this
          api.post "#{prefix}/#{@constructor.endpoint}", params
          .then (data) =>
            obj.id = data.id
            obj
          .then (obj) =>
            console.log 'OBJ', obj
            console.log '@constructor', @constructor
            @constructor.cache[obj.id] = obj
          .then (obj) =>
            (owner[@constructor.plural] ?= []).push obj if owner
            obj

        update: ->
          @constructor.update @id, this

        destroy: ->
          @constructor.destroy @id

.factory 'restSocket', (socket, session) ->
  # TODO unsketch
  subscribe: (Model) ->
    socket.subscribe "/rocket/#{session.user.id}/#{Model.plural}", (obj) ->
      Model.cache[obj.id] ?= {}
      Model.cache[obj.id].extend obj

