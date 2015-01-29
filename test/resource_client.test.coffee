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

      it 'applies query parameters', fibrous ->
        products = @Product.sync.query({name: ['apple', 'banana']})
        expect(products).to.have.length 2

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
        products = @Product.sync.query()
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
