express = require 'express'
ResourceSchema = require 'resource-schema'
Product = require './product'

module.exports = app = express()

products = new ResourceSchema Product, {
  '_id'
  'name'
  'price'
}

app.get '/', products.get(), products.send
app.get '/:_id', products.get('_id'), products.send
app.put '/:_id', products.put('_id'), products.send
app.post '/', products.post(), products.send
app.delete '/:_id', products.delete('_id'), products.send
