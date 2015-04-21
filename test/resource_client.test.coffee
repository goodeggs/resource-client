# TODO the server here shouldn't be necessary –
# unit test this module and assume that request and express and resource-schema are tested elsewhere.
# (need to figure out how to stub the right `request` methods, b/c of `request.defaults` closures.)

request = require 'request'
resourceClient = require '..'
fibrous = require 'fibrous'

describe 'resource-client', ->
  describe 'method GET, isArray', ->
    describe 'class method', ->
      beforeEach fibrous ->
        @ProductModel.sync.create [
          {name: 'apple'}
          {name: 'orange'}
          {name: 'banana'}
        ]

        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'gets all products', fibrous ->
        products = @Product.sync.query()
        expect(products).to.have.length 3

      it 'can return first product', fibrous ->
        product = @Product.sync.queryOne()
        expect(product).not.to.be.an.instanceof(Array)

      it 'applies query parameters', fibrous ->
        products = @Product.sync.query({name: ['apple', 'banana']})
        expect(products).to.have.length 2
        expect(products[0]).to.have.property 'name', 'apple'
        expect(products[1]).to.have.property 'name', 'banana'

      it 'instantiates every object as a resource', fibrous ->
        products = @Product.sync.query()
        products.forEach (product) =>
          expect(product).to.be.instanceOf @Product

    describe 'instance method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'is not defined', fibrous ->
        product = new @Product()
        expect(product.query).to.be.undefined

  describe 'method GET', ->
    describe 'class method', ->
      beforeEach fibrous ->
        @apple = @ProductModel.sync.create {name: 'apple', price: 2}
        @orange = @ProductModel.sync.create {name: 'orange', price: 2.5}
        @banana = @ProductModel.sync.create {name: 'banana', price: 1}

        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'gets product with specified id', fibrous ->
        product = @Product.sync.get({_id: @orange._id})
        expect(product).to.have.property 'name', 'orange'

      it 'applies query parameters', fibrous ->
        product = @Product.sync.get({_id: @orange._id}, {$select: 'price'})
        expect(product).to.not.have.property 'name'
        expect(product).to.have.property 'price', 2.5

      it 'instantiates object as a resource', fibrous ->
        product = @Product.sync.get({_id: @orange._id})
        expect(product).to.be.instanceOf @Product

    describe 'instance method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'is not defined', fibrous ->
        product = new @Product()
        expect(product.get).to.be.undefined

  describe 'method PUT', ->
    describe 'class method', ->
      beforeEach fibrous ->
        @productModel = @ProductModel.sync.create {name: 'apple', price: 2}
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'updates the passed object', fibrous ->
        @productModel.name = 'pineapple'
        product = @Product.sync.update(@productModel)
        expect(product).to.have.property 'name', 'pineapple'

      it 'returns instance of resource', fibrous ->
        product = @Product.sync.update(@productModel)
        expect(product).be.an.instanceOf @Product

    describe 'instance method', ->
      beforeEach fibrous ->
        @productModel = @ProductModel.sync.create {name: 'apple', price: 2}
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'updates the product', fibrous ->
        product = @Product.sync.get(_id: @productModel._id)
        product.price = 3
        product.sync.update()
        expect(@ProductModel.sync.findById(@productModel)).to.have.property 'price', 3
        expect(product).to.have.property 'price', 3

  describe 'method POST', ->
    describe 'class method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'updates the passed object', fibrous ->
        product = @Product.sync.save({name: 'pineapple'})
        expect(@ProductModel.sync.count()).to.equal 1
        expect(@ProductModel.sync.findOne()).to.have.property 'name', 'pineapple'

      it 'returns instance of resource', fibrous ->
        product = @Product.sync.save({name: 'pineapple'})
        expect(product).be.an.instanceOf @Product

    describe 'instance method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'saves the object', fibrous ->
        product = new @Product({name: 'pineapple'})
        product.sync.save()
        expect(@ProductModel.sync.count()).to.equal 1
        expect(@ProductModel.sync.findOne()).to.have.property 'name', 'pineapple'

  describe 'method DELETE', ->
    describe 'class method', ->
      beforeEach fibrous ->
        @productModel = @ProductModel.sync.create {name: 'apple', price: 2}
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'deletes the passed object', fibrous ->
        expect(@ProductModel.sync.count()).to.equal 1
        product = @Product.sync.remove(_id: @productModel._id)
        expect(@ProductModel.sync.count()).to.equal 0

    describe 'instance method', ->
      beforeEach fibrous ->
        @productModel = @ProductModel.sync.create {name: 'apple', price: 2}
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"

      it 'deletes the object', fibrous ->
        expect(@ProductModel.sync.count()).to.equal 1
        product = @Product.sync.get(_id: @productModel._id)
        product.sync.remove()
        expect(@ProductModel.sync.count()).to.equal 0


  describe 'custom POST action method', ->
    describe 'class method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{@serverUrl}/api/products/:_id"
        @Product.action 'insert',
          method: 'POST'

      it 'creates the object', fibrous ->
        product = @Product.sync.insert({name: 'pineapple'})
        expect(@ProductModel.sync.count()).to.equal 1
        expect(@ProductModel.sync.findOne()).to.have.property 'name', 'pineapple'


  describe 'per-request options', ->
    beforeEach ->
      @Thing = resourceClient
        url: "#{@serverUrl}/api/will-be-overridden/:_id"

      @Thing.action 'getWithHeader',
        method: 'GET'
        url: "#{@serverUrl}/regurgitate"

    it 'includes headers and query params in request', fibrous ->
      response = @Thing.sync.getWithHeader \
        {_id: 'ignored'},   # params
        { 'foo': 'bar' },   # query params
        { headers: { 'x-auth': 'someone' } }  # other options
      expect(response).to.have.property 'headers'
      expect(response).to.have.property 'query'
      expect(response.query).to.have.property 'foo', 'bar'
      expect(response.headers).to.have.property 'x-auth', 'someone'


  describe 'headers', ->
    beforeEach ->
      @Thing = resourceClient
        url: "#{@serverUrl}/api/will-be-overridden"
        headers:
          'x-default': 'A'

      @Thing.action 'getMyHeaders',
        method: 'GET'
        url: "#{@serverUrl}/regurgitate"
        headers:
          'x-action': 'B'

    it 'combines headers from resource, action, and request', fibrous ->
      response = @Thing.sync.getMyHeaders \
        {},    # params
        {},    # query params
        { headers: { 'x-request': 'C' } }  # other options
      expect(response).to.have.property 'headers'
      expect(response.headers).to.have.property 'x-default', 'A'
      expect(response.headers).to.have.property 'x-action', 'B'
      expect(response.headers).to.have.property 'x-request', 'C'


  describe 'error handling', ->
    beforeEach fibrous ->
      @productModel = @ProductModel.sync.create {name: 'apple', price: 2}

      @Product = resourceClient
        url: "#{@serverUrl}/api/products/:_id"
        headers:
          'X-Secret-Token': 'ABCD1234'

    it 'returns undefined if status 404 ', fibrous ->
      product = @Product.sync.get({_id: '54cfba22ec7d8e00001bd7de'})
      expect(product).to.be.undefined

    it 'throws an error if status is for any other non-200 status code', fibrous ->
      # invalid object id
      expect(-> @Product.sync.get({_id: '1234'})).to.throw

    it 'stringifies the error message if it is an object (for friendly error logging)', fibrous ->
      testErr = null
      try
        # invalid object id
        @Product.sync.get({_id: '1234'})
      catch err
        testErr = err

      expect(testErr.stack).to.contain 'Cast to ObjectId failed for value'

  it 'exposes request module for testing', ->
    expect(resourceClient.request).to.deep.equal request
