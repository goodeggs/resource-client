Promise = require 'bluebird'
request = require 'request'
_ = require 'lodash'
requestValidator = require './request_validator'
urlBuilder = require './url_builder'
defaultActions = require './default_actions'


###
Create resource with default configuration
@param {Object} [resourceConfig] - configuration shared for all actions on this resource
###
module.exports = resourceClient = (resourceConfig) ->
  resourceConfig.params ?= {}
  resourceConfig.json ?= true
  resourceRequest = request.defaults resourceConfig

  class Resource
    constructor: (newObject) ->
      _.assign(@, newObject)

    # Strip prototype properties
    toObject: ->
      JSON.parse JSON.stringify @

  ###
  Register an action for the resource
  @param {String} actionName - name of action being registered
  @param {Object} [actionConfig] - configuration for this particular action
  ###
  Resource.action = (actionName, actionConfig) ->
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'actionConfig.method must be GET POST PUT or DELETE' unless actionConfig.method in ['GET', 'POST', 'PUT', 'DELETE']

    actionConfig.params ?= {}
    actionUrl = actionConfig.url or resourceConfig.url

    actionRequest = Promise.promisify resourceRequest.defaults(actionConfig)

    if actionConfig.method is 'GET'
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
          mergedParams = _.assign({}, resourceConfig.params, actionConfig.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams)
        Promise.try =>
          requestValidator.validateUrlParams({requestParams, actionConfig, resourceConfig, actionName})
          requestValidator.validateQueryParams({requestParams, actionConfig, resourceConfig, actionName})
          actionRequest(requestOptions)
        .spread (response) ->
          handleResponse({response, actionConfig, actionName})
        .nodeify(done)

    else # actionConfig.method is PUT, POST, or DELETE
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
          mergedParams = _.assign({}, resourceConfig.params, actionConfig.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams, requestOptions.body)
        Promise.try =>
          requestValidator.validateUrlParams({requestParams, actionConfig, resourceConfig, actionName, requestBody})
          requestValidator.validateQueryParams({requestParams, actionConfig, resourceConfig, actionName, requestBody})
          requestValidator.validateRequestBody({actionConfig, resourceConfig, actionName, requestBody})
          actionRequest(requestOptions)
        .spread (response) =>
          handleResponse({response, actionConfig, actionName})
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
          mergedParams = _.assign({}, resourceConfig.params, actionConfig.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams, requestOptions.body)
        Promise.try =>
          requestValidator.validateUrlParams({requestParams, actionConfig, resourceConfig, actionName, requestBody: @})
          requestValidator.validateQueryParams({requestParams, actionConfig, resourceConfig, actionName, requestBody: @})
          requestValidator.validateRequestBody({actionConfig, resourceConfig, actionName, requestBody: @})
          actionRequest(requestOptions)
        .spread (response) =>
          handleResponse({response, actionConfig, resourceConfig, actionName, originalObject: @})
        .nodeify(done)


  ###
  @param {Object} response - request response object
  @param {Object} actionConfig
  @param {String} actionName
  @param {Object} [originalObject] - original resource instance that was saved
    - once successful, original instance will be updated in place with the response object
  ###
  handleResponse = ({response, actionConfig, actionName, originalObject}) ->
    throw new TypeError 'response must be an object' unless typeof response is 'object'
    throw new TypeError 'actionConfig must be an object' unless typeof actionConfig is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'originalObject must be an object' if originalObject? and typeof originalObject isnt 'object'

    actionConfig ?= {}

    if 200 <= response.statusCode < 300
      requestValidator.validateResponseBody({actionConfig, resourceConfig, actionName, responseBody: response.body})

      if Array.isArray(response.body)
        resources = response.body.map (resource) -> new Resource(resource)
        resources = resources[0] if actionConfig.returnFirst
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
      throw new Error(errorMessage)

  ###
  Add default methods.
  ###
  for actionName, actionConfig of defaultActions
    Resource.action actionName, actionConfig

  return Resource
