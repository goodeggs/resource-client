expect = require('chai').expect
nock = require 'nock'
request = require 'request'
resourceClient = require '..'
fibrous = require 'fibrous'
serverUrl = 'http://resource-client.com'

describe 'resource-client', ->
  describe 'method GET, isArray', ->
    describe 'class method', ->
      beforeEach ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"

      it 'gets all products', fibrous ->
        api = nock(serverUrl)
          .get('/api/products')
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        products = @Product.sync.query()
        expect(products).to.have.length 2
        expect(api.isDone()).to.be.true

      it 'gets all products (promise)', ->
        api = nock(serverUrl)
          .get('/api/products')
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        @Product.query().then (products) ->
          expect(products).to.have.length 2
          expect(api.isDone()).to.be.true

      it 'can return first product', fibrous ->
        api = nock(serverUrl)
          .get('/api/products')
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        product = @Product.sync.queryOne()
        expect(product).not.to.be.an.instanceof(Array)
        expect(product.toObject()).to.deep.equal {name: 'apple'}
        expect(api.isDone()).to.be.true

      it 'applies query parameters', fibrous ->
        api = nock(serverUrl)
          .get('/api/products?' + encodeURI('name[0]=apple&name[1]=banana'))
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        products = @Product.sync.query({name: ['apple', 'banana']})
        expect(products).to.have.length 2
        expect(products[0].toObject()).to.deep.equal {name: 'apple'}
        expect(products[1].toObject()).to.deep.equal {name: 'orange'}
        expect(api.isDone()).to.be.true

      it 'instantiates every object as a resource', fibrous ->
        api = nock(serverUrl)
          .get('/api/products')
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        products = @Product.sync.query()
        products.forEach (product) =>
          expect(product).to.be.instanceOf @Product
        expect(api.isDone()).to.be.true

    describe 'instance method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"

      it 'is not defined', fibrous ->
        product = new @Product()
        expect(product.query).to.be.undefined

  describe 'method GET', ->
    describe 'class method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"

      it 'gets product with specified id', fibrous ->
        api = nock(serverUrl)
          .get('/api/products/1234')
          .reply(200, {_id: '1234', name: 'apple'})
        product = @Product.sync.get({_id: 1234})
        expect(product.toObject()).to.deep.equal {_id: '1234', name: 'apple'}
        expect(api.isDone()).to.be.true

      it 'gets product with specified id (promise)', ->
        api = nock(serverUrl)
          .get('/api/products/1234')
          .reply(200, {_id: '1234', name: 'apple'})
        @Product.get({_id: 1234}).then (product) ->
          expect(product.toObject()).to.deep.equal {_id: '1234', name: 'apple'}
          expect(api.isDone()).to.be.true

      it 'applies query parameters', fibrous ->
        api = nock(serverUrl)
          .get('/api/products/1234?' + encodeURI('select=price'))
          .reply(200, {_id: '1234', price: 2.5})
        product = @Product.sync.get({_id: '1234', select: 'price'})
        expect(product.toObject()).to.deep.equal {_id: '1234', price: 2.5}
        expect(api.isDone()).to.be.true

      it 'instantiates object as a resource', fibrous ->
        api = nock(serverUrl)
          .get('/api/products/1234')
          .reply(200, {_id: '1234', price: 2.5})
        product = @Product.sync.get({_id: '1234'})
        expect(product).to.be.instanceOf @Product
        expect(api.isDone()).to.be.true

    describe 'instance method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"

      it 'is not defined', fibrous ->
        product = new @Product()
        expect(product.get).to.be.undefined

  describe 'method PUT', ->
    describe 'class method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"
        @api = nock(serverUrl)
          .put('/api/products/1234', {_id: '1234', price: 2})
          .reply(201, {_id: '1234', price: 2})

      it 'sends PUT request with correct data', fibrous ->
        @product = @Product.sync.update({_id: '1234'}, {_id: '1234', price: 2})
        expect(@product.toObject()).to.deep.equal {_id: '1234', price: 2}
        expect(@api.isDone()).to.be.true

      it 'sends PUT request with correct data (promise)', ->
        @Product.update({_id: '1234'}, {_id: '1234', price: 2}).then (product) =>
          expect(product.toObject()).to.deep.equal {_id: '1234', price: 2}
          expect(@api.isDone()).to.be.true

      it 'returns instance of resource', fibrous ->
        @product = @Product.sync.update({_id: '1234'}, {_id: '1234', price: 2})
        expect(@product).be.an.instanceOf @Product

    describe 'instance method', ->
      beforeEach fibrous ->
        @Product = resourceClient
          url: "#{serverUrl}/api/products/:_id"
          params: {_id: '@_id'}

      it 'updates the product', fibrous ->
        api = nock(serverUrl)
          .put('/api/products/1234', {_id: '1234', price: 2})
          .reply(201, {_id: '1234', price: 2})
        product = new @Product {_id: '1234', price: 2}
        product.sync.update()
        expect(api.isDone()).to.be.true

  describe 'method POST', ->
    describe 'class method', ->
      it 'updates the passed object', fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"
        api = nock(serverUrl)
          .post('/api/products', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        product = @Product.sync.save({}, {price: 2})
        expect(api.isDone()).to.be.true

      it 'updates the passed object (promise)', ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"
        api = nock(serverUrl)
          .post('/api/products', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        @Product.save({}, {price: 2}).then (product) ->
          expect(api.isDone()).to.be.true

      it 'returns instance of resource', fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"
        api = nock(serverUrl)
          .post('/api/products', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        product = @Product.sync.save({}, {price: 2})
        expect(product).be.an.instanceOf @Product
        expect(api.isDone()).to.be.true

      it 'posts to urls with multiple variables', fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/store/:storeSlug/products/:_id"
        api = nock(serverUrl)
          .post('/api/store/sfbay/products', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        product = @Product.sync.save({storeSlug: 'sfbay'}, {price: 2})
        expect(product.toObject()).to.deep.equal {_id: '1234', price: 2}
        expect(api.isDone()).to.be.true

    describe 'instance method', ->
      it 'saves the object', fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"
        api = nock(serverUrl)
          .post('/api/products', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        product = new @Product({price: 2})
        product.sync.save()
        expect(api.isDone()).to.be.true

  describe 'method DELETE', ->
    describe 'class method', ->
      it 'deletes the passed object', fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"
        api = nock(serverUrl)
          .delete('/api/products/1234')
          .reply(200, {_id: '1234', price: 2})
        product = @Product.sync.remove(_id: '1234')
        expect(api.isDone()).to.be.true

      it 'deletes the passed object (promise)', ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"
        api = nock(serverUrl)
          .delete('/api/products/1234')
          .reply(200, {_id: '1234', price: 2})
        @Product.remove(_id: '1234').then ->
          expect(api.isDone()).to.be.true

    describe 'instance method', ->
      beforeEach fibrous ->
        @Product = resourceClient url: "#{serverUrl}/api/products/:_id"

      it 'deletes the object', fibrous ->
        @Product = resourceClient
          url: "#{serverUrl}/api/products/:_id"
          params: {_id: '@_id'}
        api = nock(serverUrl)
          .delete('/api/products/1234')
          .reply(200, {_id: '1234', price: 2})
        product = new @Product {_id: '1234'}
        product.sync.remove()
        expect(api.isDone()).to.be.true

  describe '@ params', ->
    it 'reads the value from the body if not in the params', fibrous ->
      @Product = resourceClient
        url: "#{serverUrl}/api/products/:_id"
        params: {_id: '@_id'}

      api = nock(serverUrl)
        .put('/api/products/1234', {_id: '1234'})
        .reply(200, {_id: '1234'})

      product = new @Product({_id: '1234'})
      product.sync.update()
      expect(api.isDone()).to.be.true

    it 'removes the param if not in the body', fibrous ->
      @Product = resourceClient
        url: "#{serverUrl}/api/products/:_id"
        params: {_id: '@_id'}

      api = nock(serverUrl)
        .put('/api/products', {price: 2})
        .reply(200, {_id: '1234', price: 2})

      product = new @Product({price: 2})
      product.sync.update()
      expect(api.isDone()).to.be.true

    it 'uses the request param if there is a request param', fibrous ->
      @Product = resourceClient
        url: "#{serverUrl}/api/products/:_id"
        params: {_id: '@_id'}

      api = nock(serverUrl)
        .put('/api/products/1234', {})
        .reply(200, {_id: '1234', price: 2})

      product = @Product.sync.update({_id: '1234'}, {})
      expect(api.isDone()).to.be.true

  describe 'custom action', ->
    describe 'custom POST action', ->
      it 'posts the correct data and URL', fibrous ->
        Subscription = resourceClient
          url: "#{serverUrl}/api/subscriptions/:subscriptionId"

        Subscription.action 'skipProduct',
          method: 'POST'
          url: "#{serverUrl}/api/subscriptions/:subscriptionId/products/:productId/skips"

        api = nock(serverUrl)
          .post('/api/subscriptions/1234/products/4321/skips', {date: '2014-04-01'})
          .reply(200, {_id: '1234'})

        Subscription.sync.skipProduct({subscriptionId: '1234', productId: '4321'}, {date: '2014-04-01'})
        expect(api.isDone()).to.be.true

    describe 'custom url in action', ->
      it 'doesnt pollute subsequent action urls', fibrous ->
        Product = resourceClient url: "#{serverUrl}/api/products/:_id"

        Product.action 'deliver',
          method: 'POST'
          url: "#{serverUrl}/api/products/deliver"

        Product.action 'save',
          method: 'POST'

        api = nock(serverUrl)
          .post('/api/products')
          .reply(200, {price: 2})
        product = new Product({price: 2})
        product.sync.save()
        expect(api.isDone()).to.be.true

  describe 'per-request options', ->
    beforeEach ->
      @Thing = resourceClient
        url: "#{serverUrl}/api/will-be-overridden/:_id"

      @Thing.action 'getWithHeader',
        method: 'GET'
        url: "#{serverUrl}/api/new-products"

    it 'includes headers and query params in request', fibrous ->
      api = nock(serverUrl, reqheaders: { 'x-auth': 'someone' })
        .get('/api/new-products?foo=bar')
        .reply(200, {_id: '1234', price: 2})
      response = @Thing.sync.getWithHeader \
        { 'foo': 'bar' },   # query params
        {},
        { headers: { 'x-auth': 'someone' } }  # other options
      expect(api.isDone()).to.be.true

  describe 'headers', ->
    beforeEach ->
      @Thing = resourceClient
        url: "#{serverUrl}/api/will-be-overridden"
        headers:
          'x-default': 'A'

      @Thing.action 'getMyHeaders',
        method: 'GET'
        url: "#{serverUrl}/api/new-products"
        headers:
          'x-action': 'B'

    it 'combines headers from resource, action, and request', fibrous ->
      api = nock(serverUrl, reqheaders: {
        'x-default': 'A'
        'x-action': 'B'
        'x-request': 'C'
      }).get('/api/new-products').reply(200, {})

      response = @Thing.sync.getMyHeaders \
        {},    # params
        {},    # query params
        { headers: { 'x-request': 'C' } }  # other options

      expect(api.isDone()).to.be.true

  describe 'error handling', ->
    beforeEach fibrous ->
      @Product = resourceClient
        url: "#{serverUrl}/api/products/:_id"
        headers:
          'X-Secret-Token': 'ABCD1234'

    it 'returns undefined if status 404 ', fibrous ->
      api = nock(serverUrl)
        .get('/api/products/1234')
        .reply(404, 'Not found')
      product = @Product.sync.get({_id: '1234'})
      expect(product).to.be.undefined

    it 'throws an error if status is for any other non-200 status code', fibrous ->
      api = nock(serverUrl)
        .get('/api/products/1234')
        .reply(500, 'Something went wrong')
      expect(=> @Product.sync.get({_id: '1234'})).to.throw /Something went wrong/

    it 'stringifies the error message if it is an object (for friendly error logging)', fibrous ->
      api = nock(serverUrl)
        .get('/api/products/1234')
        .reply(500, {message: 'Cast to ObjectId failed for value'})
      expect(=> @Product.sync.get({_id: '1234'})).to.throw /Cast to ObjectId failed for value/
