require('es6-promise').polyfill()
require 'isomorphic-fetch'
promiseRetry = require 'promise-retry'
_ = require 'lodash'
requestValidator = require './request_validator'
urlBuilder = require './url_builder'

###
Create resource with default configuration
@param {Object} [resourceOptions] - all fetch config options + maxAttempts, params, and url
###
module.exports = resourceClient = (resourceOptions, actionConfig) ->
  resourceOptions.params ?= {}
  # Support CORS by default on browser.
  # This option is ignored in a server context.
  # See https://github.com/bitinn/node-fetch/blob/master/LIMITS.md for details
  resourceOptions.credentials ?= 'include'
  resourceOptions.maxAttempts ?= 5

  class Resource
    constructor: (newObject) ->
      _.assign(@, newObject)

    # Strip prototype properties
    toObject: ->
      JSON.parse JSON.stringify @

  _.each actionConfig, (actionOptions, actionName) ->
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
        URL = do ->
          mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams)
        Promise.resolve().then =>
          requestValidator.validateUrlParams({requestParams, actionOptions, resourceOptions, actionName})
          requestValidator.validateQueryParams({requestParams, actionOptions, resourceOptions, actionName})
          mergedOptions = _.merge({}, resourceOptions, actionOptions, requestOptions)
          fetchRetry(URL, mergedOptions, mergedOptions.maxAttempts)
        .then (response) ->
          handleResponse({response, actionOptions, actionName})

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
        URL = do ->
          mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams, requestOptions.body)
        Promise.resolve().then =>
          requestValidator.validateUrlParams({requestParams, actionOptions, resourceOptions, actionName, requestBody})
          requestValidator.validateQueryParams({requestParams, actionOptions, resourceOptions, actionName, requestBody})
          requestValidator.validateRequestBody({actionOptions, resourceOptions, actionName, requestBody})
          mergedOptions = _.merge({}, resourceOptions, actionOptions, requestOptions)
          fetchRetry(URL, mergedOptions, mergedOptions.maxAttempts)
        .then (response) =>
          handleResponse({response, actionOptions, actionName})

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
        URL = do ->
          mergedParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
          urlBuilder.build(actionUrl, mergedParams, requestOptions.body)
        Promise.resolve().then =>
          requestValidator.validateUrlParams({requestParams, actionOptions, resourceOptions, actionName, requestBody: @})
          requestValidator.validateQueryParams({requestParams, actionOptions, resourceOptions, actionName, requestBody: @})
          requestValidator.validateRequestBody({actionOptions, resourceOptions, actionName, requestBody: @})
          mergedOptions = _.merge({}, resourceOptions, actionOptions, requestOptions)
          fetchRetry(URL, mergedOptions, mergedOptions.maxAttempts)
        .then (response) =>
          handleResponse({response, actionOptions, resourceOptions, actionName, originalObject: @})

  fetchRetry = (url, fetchOptions, maxRetryAttempts) ->
    fetchOptionsClone = _.assign({}, fetchOptions)
    if fetchOptions.body
      fetchOptionsClone.body = JSON.stringify(fetchOptions.body)
    promiseRetry (retry) ->
      fetch(url, fetchOptionsClone)
      .catch(retry)
    , {retries: maxRetryAttempts}

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
    if 200 <= response.status < 300
      return response.json().then (responseBody) ->
        requestValidator.validateResponseBody({actionOptions, resourceOptions, actionName, responseBody})

        if Array.isArray(responseBody)
          resources = responseBody.map (resource) -> new Resource(resource)
          resources = resources[0] if actionOptions.returnFirst
          return resources
        else
          resource =
            if originalObject?
              _.assign(originalObject, responseBody)
            else
              new Resource(responseBody)
          return resource

    else if response.status is 404
      return undefined

    else
      return response.text().then (responseBody) ->
        err = new Error(response.statusText)
        err.response = response
        err.statusCode = response.status
        err.responseBody = responseBody
        throw err

  return Resource
