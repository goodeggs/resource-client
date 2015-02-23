module.exports =
  'get':
    method: 'GET'
  'query':
    method: 'GET'
    isArray: true
  'queryOne':
    method: 'GET'
    isArray: true
    returnFirst: true
  'save':
    method: 'POST'
  'update':
    method: 'PUT'
  'remove':
    method: 'DELETE'
