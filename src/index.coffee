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
      #
      # get single w/ params (class method).
      #
      # call w/ `({params}, {query}, {otherOptions}, callback)`
      #      OR `({params}, {query}, callback)`
      #      OR `({params}, callback)`
      #
      Resource[actionName] = (params, opts..., done) ->
        queryParams = opts.shift() or {}
        reqOptions = opts.pop() or {}
        reqOptions.url = UrlAssembler()
          .template(url)
          .param(params)
          .query(queryParams)
          .toString()
        actionRequest.get reqOptions, (err, response) ->
          handleResponse(err, response, null, done)

    else if options.method is 'GET' and options.isArray
      #
      # get multi w/o params (class method).
      #
      # call w/ `({query}, {otherOptions}, callback)`
      #      OR `({query}, callback)`
      #      OR `(callback)`
      #
      Resource[actionName] = (opts..., done) ->
        queryParams = opts.shift() or {}
        reqOptions = opts.pop() or {}
        reqOptions.url = UrlAssembler()
          .template(baseUrl)
          .query(queryParams)
          .toString()
        actionRequest.get reqOptions, (err, response) ->
          handleResponse(err, response, null, done, options)

    else if options.method in ['PUT', 'POST', 'DELETE']
      actionUrl = if options.method is 'POST' then baseUrl else url

      do (methodFn = options.method.toLowerCase()) ->
        if methodFn is 'delete' then methodFn = 'del'
        #
        # modify single (class method).
        #
        # call w/ `(body, {query}, {otherOptions}, callback)`
        #      OR `(body, {query}, callback)`
        #      OR `(body, callback)`
        #
        Resource[actionName] = (body, opts..., done) ->
          queryParams = opts.shift() or {}
          reqOptions = opts.pop() or {}
          reqOptions.body = body
          reqOptions.url = do ->
            requestUrl = UrlAssembler().template(actionUrl)
            requestUrl.param(idField, body[idField]) for idField in idFields
            requestUrl.query(queryParams).toString()
          actionRequest[methodFn] reqOptions, (err, response) ->
            handleResponse(err, response, null, done)

        #
        # modify single (instance method).
        #
        # call w/ `({query}, {otherOptions}, callback)`
        #      OR `({query}, callback)`
        #      OR `(callback)`
        #
        Resource::[actionName] = (opts..., done) ->
          queryParams = opts.shift() or {}
          reqOptions = opts.pop() or {}
          reqOptions.body = @
          reqOptions.url = do =>
            requestUrl = UrlAssembler().template(actionUrl)
            requestUrl.param(idField, @[idField]) for idField in idFields
            requestUrl.query(queryParams).toString()
          actionRequest[methodFn] reqOptions, (err, response) ->
            handleResponse(err, response, @, done)


  handleResponse = (err, response, originalObject, done, options = {}) ->
    if err
      return done(err)

    else if 200 <= response.statusCode < 300
      if Array.isArray(response.body)
        resources = response.body.map (resource) -> new Resource(resource)
        resources = resources[0] if options.returnFirst
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
      errorMessage = JSON.stringify(response.body)
      return done(new Error(errorMessage))

  getUrlParts = (url) ->
    urlParts = url.split '/:'
    [urlParts[0], urlParts[1..]]

  for actionName, actionConfig of defaultActions
    Resource.action actionName, actionConfig

  return Resource
