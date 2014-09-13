angular.module 'jtg'

# ## Provider
# ---
# Representation of authentication (and perhaps api) providers
.service 'Provider', (jtg, lock) ->
  class Provider
    @cache = {}

    @create = (args...) =>
      provider = new this args...
      @cache[provider.slug] = provider

    constructor: (@name, @slug) ->
      @slug ?= @name.toLowerCase()

    connect: =>
      jtg.auth.connect @slug

.directive 'provider', ->
  restrict: 'E'
  templateUrl: 'app/provider/provider.html'
