Product = require './product'
global.expect = require('chai').expect

beforeEach (done) ->
  @ProductModel = Product
  @serverUrl = 'http://127.0.0.1:4005'
  Product.remove({}, done)
