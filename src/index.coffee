Promise = require 'bluebird'
request = require 'request'
_ = require 'lodash'
urlBuilder = require './url_builder'
defaultActions = require './default_actions'

# remove all prototype properties, and undefined fields
clean = (resource) ->
  JSON.parse JSON.stringify resource

getUrlParams = (url) ->
  regex = /\/:(\w*)/g
  matches = []
  match = regex.exec(url)
  while match?
    matches.push(match[1])
    match = regex.exec(url)
  matches

getQueryParams = (params, actionParams, paramDefaults, url, body) ->
  allParams = _.assign({}, paramDefaults, actionParams, params)
  paramsToOmit = []

  # handle params with @ in value (e.g. {id: '@_id'})
  for param, value of allParams
    if typeof value is 'string' and value.indexOf('@') is 0
      # if @ value not in body, remove from query params
      if not body?[value.slice(1)]?
        paramsToOmit.push(param)
      # if @ value in body, reassign in query params with actual value
      else
        allParams[param] = body?[value.slice(1)]

  paramsToOmit = paramsToOmit.concat(getUrlParams(url))
  _.omit(allParams, paramsToOmit)

validate = (obj, schema, errorPrefix) ->
  banUnknownProperties = true if $window.settings?.env is 'test'
  if schema? and not validator.validate(obj, schema, null, banUnknownProperties)
    message = "#{errorPrefix}: #{validator.error.message}"
    message += " at #{validator.error.dataPath}" if validator.error.dataPath?.length
    throw new Error message

###
Create resource with default configuration
@param {Object} [resourceOptions] - configuration shared for all actions on this resource
###
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

  ###
  Register an action for the resource
  @param {String} actionName - name of action being registered
  @param {Object} [actionOptions] - configuration for this particular action
  ###
  Resource.action = (actionName, actionOptions) ->
    throw new Error 'actionName must be a string' unless typeof actionName is 'string'
    throw new Error 'actionOptions.method must be a GET POST PUT or DELETE' unless actionOptions.method in ['GET', 'POST', 'PUT', 'DELETE']

    actionOptions.params = {}
    actionUrl = actionOptions.url or resourceOptions.url

    actionRequest = Promise.promisify resourceRequest.defaults(actionOptions)

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
        actionRequest(requestOptions).spread (response) ->
          handleResponse({response, actionOptions})
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
        actionRequest(requestOptions).spread (response) ->
          handleResponse({response})
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
        actionRequest(requestOptions).spread (response) =>
          handleResponse({response, originalObject: @})
        .nodeify(done)

  handleResponse = ({response, originalObject, actionOptions}) ->
    actionOptions ?= {}

    if 200 <= response.statusCode < 300
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
      throw new Error(errorMessage)

  for actionName, actionConfig of defaultActions
    Resource.action actionName, actionConfig

  return Resource
