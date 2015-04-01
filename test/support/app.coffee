express = require 'express'
bodyParser = require 'body-parser'

app = express()
app.use bodyParser.json()
app.use bodyParser.urlencoded()

app.use '/api/products', require './products'

app.get '/regurgitate', (req, res) ->
  res.send
    headers: req.headers
    query: req.query
    body: req.body

app.use (err, req, res, next) -> # add standard error-catching middleware
  #console.log {err}
  throw err unless err.isBoom
  #console.error err.output.payload
  res.status err.output.statusCode
  res.send err.output.payload

app.listen 4005, ->
  console.log 'server started on 127.0.0.1:4005'
