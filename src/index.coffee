Promise = require 'bluebird'
request = Promise.promisify require 'requestretry'
_ = require 'lodash'
requestValidator = require './request_validator'
urlBuilder = require './url_builder'
defaultActions = require './default_actions'


###
Create resource with default configuration
@param {Object} [resourceOptions] - configuration shared for all actions on this resource
###
module.exports = resourceClient = (resourceOptions) ->
  resourceOptions.params ?= {}
  resourceOptions.json ?= true
  resourceOptions.maxAttempts ?= 5
  resourceOptions.retryDelay ?= 5000
  resourceOptions.retryStrategy ?= request.RetryStrategies.NetworkError

  class Resource
    constructor: (newObject) ->
      _.assign(@, newObject)

    # Strip prototype properties
    toObject: ->
      JSON.parse JSON.stringify @

  ###
  Register an action for the resource
  @param {String} actionName - name of action being registered
  @param {Object} [actionOptions] - configuration for this particular action
  ###
  Resource.action = (actionName, actionOptions) ->
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'actionOptions.method must be GET POST PUT or DELETE' unless actionOptions.method in ['GET', 'POST', 'PUT', 'DELETE']

    actionOptions.params ?= {}
    actionUrl = actionOptions.url or resourceOptions.url

    if actionOptions.method is 'GET'
      ###
      Send a GET request with specified configuration
      @param {Object} [params] - url params and query params for this action
      @param {Object} [requestOptions] - custom options set for just this request (such as headers)
      @param {Function} [callback] - if you don't want to use promises. Can be first second, or third parameter.
      @returns {Promise} - resolves to returned resource(s)
      ###
      Resource[actionName] = (opts...) ->
        done = opts.pop() if typeof opts[opts.length - 1] is 'function'
        requestParams = opts.shift() or {}
        requestOptions = opts.pop() or {}
        requestOptions.url = do ->
          mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams)
        Promise.try =>
          requestValidator.validateUrlParams({requestParams, actionOptions, resourceOptions, actionName})
          requestValidator.validateQueryParams({requestParams, actionOptions, resourceOptions, actionName})
          mergedOptions = _.merge({}, resourceOptions, actionOptions, requestOptions)
          request(mergedOptions)
        .then (response) ->
          handleResponse({response, actionOptions, actionName})
        .nodeify(done)

    else # actionOptions.method is PUT, POST, or DELETE
      ###
      Send a PUT, POST, or DELETE request with specified configuration
      @param {Object} [params] - url params and query params for this action
      @param {Object} [body] - request body
      @param {Object} [requestOptions] - custom options set for just this request (such as headers)
      @param {Function} [callback] - if you don't want to use promises. Can be first second, third, or fourth parameter.
      @returns {Promise} - resolves to returned resource(s)
      ###
      Resource[actionName] = (opts...) ->
        done = opts.pop() if typeof opts[opts.length - 1] is 'function'
        requestParams = opts.shift() or {}
        requestBody = opts.shift() or {}
        requestOptions = opts.pop() or {}
        requestOptions.body = requestBody
        requestOptions.url = do ->
          mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams, requestOptions.body)
        Promise.try =>
          requestValidator.validateUrlParams({requestParams, actionOptions, resourceOptions, actionName, requestBody})
          requestValidator.validateQueryParams({requestParams, actionOptions, resourceOptions, actionName, requestBody})
          requestValidator.validateRequestBody({actionOptions, resourceOptions, actionName, requestBody})
          mergedOptions = _.merge({}, resourceOptions, actionOptions, requestOptions)
          request(mergedOptions)
        .then (response) =>
          handleResponse({response, actionOptions, actionName})
        .nodeify(done)

      ###
      Send a PUT, POST, or DELETE request with specified configuration. Sends the instantiated
      object as the body of the request
      @param {Object} [params] - url params and query params for this action
      @param {Object} [requestOptions] - custom options set for just this request (such as headers)
      @param {Function} [callback] - if you don't want to use promises. Can be first second, or third parameter.
      @returns {Promise} - resolves to returned resource
      ###
      Resource::[actionName] = (opts..., done) ->
        done = opts.pop() if typeof opts[opts.length - 1] is 'function'
        requestParams = opts.shift() or {}
        requestOptions = opts.pop() or {}
        requestOptions.body = @
        requestOptions.url = do ->
          mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams, requestOptions.body)
        Promise.try =>
          requestValidator.validateUrlParams({requestParams, actionOptions, resourceOptions, actionName, requestBody: @})
          requestValidator.validateQueryParams({requestParams, actionOptions, resourceOptions, actionName, requestBody: @})
          requestValidator.validateRequestBody({actionOptions, resourceOptions, actionName, requestBody: @})
          mergedOptions = _.merge({}, resourceOptions, actionOptions, requestOptions)
          request(mergedOptions)
        .then (response) =>
          handleResponse({response, actionOptions, resourceOptions, actionName, originalObject: @})
        .nodeify(done)


  ###
  @param {Object} response - request response object
  @param {Object} actionOptions
  @param {String} actionName
  @param {Object} [originalObject] - original resource instance that was saved
    - once successful, original instance will be updated in place with the response object
  ###
  handleResponse = ({response, actionOptions, actionName, originalObject}) ->
    throw new TypeError 'response must be an object' unless typeof response is 'object'
    throw new TypeError 'actionOptions must be an object' unless typeof actionOptions is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'originalObject must be an object' if originalObject? and typeof originalObject isnt 'object'

    actionOptions ?= {}

    if 200 <= response.statusCode < 300
      requestValidator.validateResponseBody({actionOptions, resourceOptions, actionName, responseBody: response.body})

      if Array.isArray(response.body)
        resources = response.body.map (resource) -> new Resource(resource)
        resources = resources[0] if actionOptions.returnFirst
        return resources
      else
        resource =
          if originalObject?
            _.assign(originalObject, response.body)
          else
            new Resource(response.body)
        return resource

    else if response.statusCode is 404
      return undefined

    else # 400s and 500s
      errorMessage = JSON.stringify(response.body)
      err = Error(errorMessage)
      err.statusCode = response.statusCode
      throw err

  ###
  Add default methods.
  ###
  for actionName, actionOptions of defaultActions
    Resource.action actionName, actionOptions

  return Resource
