UrlAssembler = require 'url-assembler'

###
Build url from url template

@param urlTemplate - url that can contain variables such as /products/:_id
@param params - params to populate the url. Will fill url params first, and then
all remaining params will become query params
@param [body] - body object to use for populating params (when params are defined using @, eg. {_id: '@_id'})
###
module.exports.build = (urlTemplate, params, body={}) ->
  populateUrlParamsFromBody(params, body)
  url = UrlAssembler().template(urlTemplate).param(params).toString()
  stripRemainingUrlParams(url)

stripRemainingUrlParams = (url) ->
  url.replace(/\/\:\w+/g, '')

populateUrlParamsFromBody = (params, body) ->
  for param, value of params
    if typeof value is 'string' and value.indexOf('@') isnt -1
      lookupKey = value.replace('@', '')
      newValue = body[lookupKey]
      params[param] = newValue


