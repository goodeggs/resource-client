request = require 'request'
_ = require 'lodash'
urlBuilder = require './url_builder'
defaultActions = require './default_actions'

module.exports = resourceClient = (resourceOptions) ->
  resourceOptions.params ?= {}
  resourceOptions.json ?= true
  resourceRequest = request.defaults resourceOptions

  class Resource
    constructor: (newObject) ->
      _.assign(@, newObject)

    # Strip prototype properties
    toObject: ->
      JSON.parse JSON.stringify @

  Resource.action = (actionName, actionOptions) ->
    actionOptions.params = {}
    actionUrl = actionOptions.url or resourceOptions.url

    actionRequest = resourceRequest.defaults actionOptions

    if actionOptions.method is 'GET' and not actionOptions.isArray
      ###
      # get single w/ params (class method).
      #
      # call w/ `({params}, {requestOptions}, callback)`
      #      OR `({params}, callback)`
      ###
      Resource[actionName] = (opts..., done) ->
        requestParams = opts.shift() or {}
        requestOptions = opts.pop() or {}
        requestOptions.url = do ->
          mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams)
        actionRequest.get requestOptions, (err, response) ->
          handleResponse(err, response, null, done)

    else if actionOptions.method is 'GET' and actionOptions.isArray
      ###
      # get multi w/o params (class method).
      #
      # call w/ `({params}, {requestOptions}, callback)`
      #      OR `({params}, callback)`
      #      OR `(callback)`
      ###
      Resource[actionName] = (opts..., done) ->
        requestParams = opts.shift() or {}
        requestOptions = opts.pop() or {}
        requestOptions.url = do ->
          mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams)
        actionRequest.get requestOptions, (err, response) ->
          handleResponse(err, response, null, done, actionOptions)

    else if actionOptions.method in ['PUT', 'POST', 'DELETE']
      do (methodFn = actionOptions.method.toLowerCase()) ->
        if methodFn is 'delete' then methodFn = 'del'
        ###
        # modify single (class method).
        #
        # call w/ `({params}, body, {requestOptions}, callback)`
        #      OR `({params}, body, callback)`
        #      OR `({params}, callback)`
        ###
        Resource[actionName] = (opts..., done) ->
          requestParams = opts.shift() or {}
          requestBody = opts.shift() or {}
          requestOptions = opts.pop() or {}
          requestOptions.body = requestBody
          requestOptions.url = do ->
            mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
            urlBuilder.build(actionUrl, mergedParams, requestOptions.body)
          actionRequest[methodFn] requestOptions, (err, response) ->
            handleResponse(err, response, null, done)

        ###
        # modify single (instance method).
        #
        # call w/ `({params}, {requestOptions}, callback)`
        #      OR `({params}, callback)`
        #      OR `(callback)`
        ###
        Resource::[actionName] = (opts..., done) ->
          requestParams = opts.shift() or {}
          requestOptions = opts.pop() or {}
          requestOptions.body = @
          requestOptions.url = do ->
            mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
            urlBuilder.build(actionUrl, mergedParams, requestOptions.body)
          actionRequest[methodFn] requestOptions, (err, response) ->
            handleResponse(err, response, @, done)

  handleResponse = (err, response, originalObject, done, actionOptions = {}) ->
    if err
      return done(err)

    else if 200 <= response.statusCode < 300
      if Array.isArray(response.body)
        resources = response.body.map (resource) -> new Resource(resource)
        resources = resources[0] if actionOptions.returnFirst
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

  for actionName, actionConfig of defaultActions
    Resource.action actionName, actionConfig

  return Resource
