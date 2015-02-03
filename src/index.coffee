request = require 'request'
_ = require 'lodash'
UrlAssembler = require 'url-assembler'
defaultActions = require './default_actions'

module.exports = resourceClient = (options) ->
  url = options.url
  options.json ?= true
  resourceRequest = request.defaults options

  class Resource
    constructor: (newObject) ->
      _.assign(@, newObject)

  Resource.action = (actionName, options) ->
    url = options.url if options.url
    [baseUrl, idFields] = getUrlParts(url)

    actionRequest = resourceRequest.defaults options

    if options.method is 'GET' and not options.isArray
      Resource[actionName] = (paramConfig={}, queryParams={}, done) ->
        [..., done] = arguments
        requestUrl = UrlAssembler()
          .template(url)
          .param(paramConfig)
          .query(queryParams)
          .toString()
        actionRequest {url: requestUrl}, (err, response) ->
          handleResponse(err, response, null, done)

    else if options.method is 'GET' and options.isArray
      Resource[actionName] = (queryParams={}, done) ->
        [..., done] = arguments
        requestUrl = UrlAssembler()
          .template(baseUrl)
          .query(queryParams)
          .toString()
        actionRequest {url: requestUrl}, (err, response) ->
          handleResponse(err, response, null, done)

    else if options.method in ['PUT', 'POST', 'DELETE']
      actionUrl = if options.method is 'POST' then baseUrl else url

      # url = baseUrl if options.method is 'POST'
      Resource[actionName] = (body, queryParams={}, done) ->
        [..., done] = arguments
        requestUrl = do ->
          requestUrl = UrlAssembler().template(actionUrl)
          requestUrl.param(idField, body[idField]) for idField in idFields
          requestUrl.query(queryParams).toString()
        actionRequest {url: requestUrl, body: body}, (err, response) ->
          handleResponse(err, response, null, done)

      Resource::[actionName] = (queryParams={}, done) ->
        [..., done] = arguments
        requestUrl = do =>
          requestUrl = UrlAssembler().template(actionUrl)
          requestUrl.param(idField, @[idField]) for idField in idFields
          requestUrl.query(queryParams).toString()
        actionRequest {url: requestUrl, body: @}, (err, response) ->
          handleResponse(err, response, @, done)

  handleResponse = (err, response, originalObject, done) ->
    if err
      return done(err)
    else if 200 <= response.statusCode < 300
      if Array.isArray(response.body)
        resources = response.body.map (resource) -> new Resource(resource)
        return done null, resources
      else
        resource =
          if originalObject
            _.assign(originalObject, response.body)
          else
            new Resource(response.body)
        return done null, resource
    else if response.statusCode is 404
      return done(null, undefined)
    else
      return done(response.body)

  getUrlParts = (url) ->
    urlParts = url.split '/:'
    [urlParts[0], urlParts[1..]]

  for actionName, actionConfig of defaultActions
    Resource.action actionName, actionConfig

  return Resource
