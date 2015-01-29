mongoose = require 'mongoose'

mongooseConnection = mongoose.createConnection 'mongodb://localhost/resource-client-test'

module.exports = mongooseConnection.model 'Product',
  name: String
  price: Number
