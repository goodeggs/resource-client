_ = require 'lodash'
Promise = require 'bluebird'
validator = require 'goodeggs-json-schema-validator'


module.exports =

  ###
  Throws if url params invalid
  @param {Object} requestParams
  @param {Object} actionConfig
  @param {Object} resourceConfig
  @param {String} actionName
  @param {Object} [requestBody] - if the request has a body, use for populating '@' url params
  ###
  validateUrlParams: ({requestParams, actionConfig, resourceConfig, actionName, requestBody}) ->
    throw new TypeError 'requestParams must be an object' unless typeof requestParams is 'object'
    throw new TypeError 'actionConfig must be an object' unless typeof actionConfig is 'object'
    throw new TypeError 'resourceConfig must be an object' unless typeof resourceConfig is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'requestBody must be a string' if requestBody? and typeof requestBody isnt 'object'

    return unless actionConfig.urlParamsSchema?
    urlParams = getUrlParamValues({requestParams, actionConfig, resourceConfig, requestBody})

    validate clean(urlParams), actionConfig.urlParamsSchema,
      errorPrefix: "Url params validation failed for action '#{actionName}'"
      banUnknownProperties: getBanUnkownProperties({actionConfig, resourceConfig})


  ###
  Throws if query params invalid
  @param {Object} requestParams
  @param {Object} actionConfig
  @param {Object} resourceConfig
  @param {String} actionName
  @param {Object} [requestBody] - if the request has a body, use for populating '@' query params
  ###
  validateQueryParams: ({requestParams, actionConfig, resourceConfig, actionName, requestBody}) ->
    throw new TypeError 'requestParams must be an object' unless typeof requestParams is 'object'
    throw new TypeError 'actionConfig must be an object' unless typeof actionConfig is 'object'
    throw new TypeError 'resourceConfig must be an object' unless typeof resourceConfig is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'requestBody must be a string' if requestBody? and typeof requestBody isnt 'object'

    return unless actionConfig.queryParamsSchema?
    queryParams = getQueryParamValues({requestParams, actionConfig, resourceConfig, requestBody})

    validate clean(queryParams), actionConfig.queryParamsSchema,
      errorPrefix: "Query validation failed for action '#{actionName}'"
      banUnknownProperties: getBanUnkownProperties({actionConfig, resourceConfig})


  ###
  Throws if request body invalid
  @param {Object} actionConfig
  @param {Object} resourceConfig
  @param {Object} actionName
  @param {Object} requestBody
  ###
  validateRequestBody: ({actionConfig, resourceConfig, actionName, requestBody}) ->
    throw new TypeError 'actionConfig must be an object' unless typeof actionConfig is 'object'
    throw new TypeError 'resourceConfig must be an object' unless typeof resourceConfig is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'requestBody must be an object' unless typeof requestBody is 'object'

    validate clean(requestBody), actionConfig.requestBodySchema,
      errorPrefix: "Request body validation failed for action '#{actionName}'"
      banUnknownProperties: getBanUnkownProperties({actionConfig, resourceConfig})


  ###
  Throws if response body invalid
  @param {Object} actionConfig
  @param {Object} resourceConfig
  @param {Object} actionName
  @param {Object} responseBody
  ###
  validateResponseBody: ({actionConfig, resourceConfig, actionName, responseBody}) ->
    throw new TypeError 'actionConfig must be an object' unless typeof actionConfig is 'object'
    throw new TypeError 'resourceConfig must be an object' unless typeof resourceConfig is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'responseBody must be an object' unless typeof responseBody is 'object'

    validate clean(responseBody), actionConfig.responseBodySchema,
      errorPrefix: "Response body validation failed for action '#{actionName}'"
      banUnknownProperties: getBanUnkownProperties({actionConfig, resourceConfig})


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


getUrlParamValues = ({requestParams, actionConfig, resourceConfig, requestBody}) ->
  allParams = _.assign({}, resourceConfig.params, actionConfig.params, requestParams)
  url = if actionConfig.url? then actionConfig.url else resourceConfig.url
  urlParams = getUrlParams(url)
  paramsToOmit = []

  # handle params with @ in value (e.g. {id: '@_id'})
  for param, value of allParams
    if param not in urlParams
      paramsToOmit.push(param)
    else if typeof value is 'string' and value.indexOf('@') is 0
      # if @ value not in requestBody, remove from url params
      if not requestBody?[value.slice(1)]?
        paramsToOmit.push(param)
      # if @ value in requestBody, reassign in url params with actual value
      else
        allParams[param] = requestBody?[value.slice(1)]
  _.omit(allParams, paramsToOmit)


getBanUnkownProperties = ({actionConfig, resourceConfig}) ->
  if actionConfig.banUnknownProperties?
    actionConfig.banUnknownProperties
  else if resourceConfig.banUnknownProperties?
    resourceConfig.banUnknownProperties
  else
    false


getQueryParamValues = ({requestParams, actionConfig, resourceConfig, requestBody}) ->
  url = if actionConfig.url? then actionConfig.url else resourceConfig.url
  allParams = _.assign({}, resourceConfig.params, actionConfig.params, requestParams)
  paramsToOmit = []

  # handle params with @ in value (e.g. {id: '@_id'})
  for param, value of allParams
    if typeof value is 'string' and value.indexOf('@') is 0
      # if @ value not in requestBody, remove from query params
      if not requestBody?[value.slice(1)]?
        paramsToOmit.push(param)
      # if @ value in requestBody, reassign in query params with actual value
      else
        allParams[param] = requestBody?[value.slice(1)]

  paramsToOmit = paramsToOmit.concat(getUrlParams(url))
  _.omit(allParams, paramsToOmit)


###
Throws if validation fails
###
validate = (obj, schema, {errorPrefix, banUnknownProperties}) ->
  banUnknownProperties ?= false
  if schema? and not validator.validate(obj, schema, null, banUnknownProperties)
    message = "#{errorPrefix}: #{validator.error.message}"
    message += " at #{validator.error.dataPath}" if validator.error.dataPath?.length
    throw new Error message

