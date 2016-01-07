_ = require 'lodash'
validator = require 'goodeggs-json-schema-validator'

module.exports =
  ###
  Throws if url params invalid
  @param {Object} requestParams
  @param {Object} actionOptions
  @param {Object} resourceOptions
  @param {String} actionName
  @param {Object} [requestBody] - if the request has a body, use for populating '@' url params
  ###
  validateUrlParams: ({requestParams, actionOptions, resourceOptions, actionName, requestBody}) ->
    throw new TypeError 'requestParams must be an object' unless typeof requestParams is 'object'
    throw new TypeError 'actionOptions must be an object' unless typeof actionOptions is 'object'
    throw new TypeError 'resourceOptions must be an object' unless typeof resourceOptions is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'requestBody must be a string' if requestBody? and typeof requestBody isnt 'object'

    return unless actionOptions.urlParamsSchema?
    urlParams = getUrlParamValues({requestParams, actionOptions, resourceOptions, requestBody})

    validate clean(urlParams), actionOptions.urlParamsSchema,
      errorPrefix: "Url params validation failed for action '#{actionName}'"
      banUnknownProperties: getBanUnkownProperties({actionOptions, resourceOptions})

  ###
  Throws if query params invalid
  @param {Object} requestParams
  @param {Object} actionOptions
  @param {Object} resourceOptions
  @param {String} actionName
  @param {Object} [requestBody] - if the request has a body, use for populating '@' query params
  ###
  validateQueryParams: ({requestParams, actionOptions, resourceOptions, actionName, requestBody}) ->
    throw new TypeError 'requestParams must be an object' unless typeof requestParams is 'object'
    throw new TypeError 'actionOptions must be an object' unless typeof actionOptions is 'object'
    throw new TypeError 'resourceOptions must be an object' unless typeof resourceOptions is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'requestBody must be a string' if requestBody? and typeof requestBody isnt 'object'

    return unless actionOptions.queryParamsSchema?
    queryParams = getQueryParamValues({requestParams, actionOptions, resourceOptions, requestBody})

    validate clean(queryParams), actionOptions.queryParamsSchema,
      errorPrefix: "Query validation failed for action '#{actionName}'"
      banUnknownProperties: getBanUnkownProperties({actionOptions, resourceOptions})

  ###
  Throws if request body invalid
  @param {Object} actionOptions
  @param {Object} resourceOptions
  @param {Object} actionName
  @param {Object} requestBody
  ###
  validateRequestBody: ({actionOptions, resourceOptions, actionName, requestBody}) ->
    throw new TypeError 'actionOptions must be an object' unless typeof actionOptions is 'object'
    throw new TypeError 'resourceOptions must be an object' unless typeof resourceOptions is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'requestBody must be an object' unless typeof requestBody is 'object'

    validate clean(requestBody), actionOptions.requestBodySchema,
      errorPrefix: "Request body validation failed for action '#{actionName}'"
      banUnknownProperties: getBanUnkownProperties({actionOptions, resourceOptions})

  ###
  Throws if response body invalid
  @param {Object} actionOptions
  @param {Object} resourceOptions
  @param {Object} actionName
  @param {Object} responseBody
  ###
  validateResponseBody: ({actionOptions, resourceOptions, actionName, responseBody}) ->
    throw new TypeError 'actionOptions must be an object' unless typeof actionOptions is 'object'
    throw new TypeError 'resourceOptions must be an object' unless typeof resourceOptions is 'object'
    throw new TypeError 'actionName must be a string' unless typeof actionName is 'string'
    throw new TypeError 'responseBody must be an object' unless typeof responseBody is 'object'

    validate clean(responseBody), actionOptions.responseBodySchema,
      errorPrefix: "Response body validation failed for action '#{actionName}'"
      banUnknownProperties: getBanUnkownProperties({actionOptions, resourceOptions})

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

getUrlParamValues = ({requestParams, actionOptions, resourceOptions, requestBody}) ->
  allParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
  url = if actionOptions.url? then actionOptions.url else resourceOptions.url
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

getBanUnkownProperties = ({actionOptions, resourceOptions}) ->
  if actionOptions.banUnknownProperties?
    actionOptions.banUnknownProperties
  else if resourceOptions.banUnknownProperties?
    resourceOptions.banUnknownProperties
  else
    false

getQueryParamValues = ({requestParams, actionOptions, resourceOptions, requestBody}) ->
  url = if actionOptions.url? then actionOptions.url else resourceOptions.url
  allParams = _.assign({}, resourceOptions.params, actionOptions.params, requestParams)
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
