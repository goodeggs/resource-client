chai = require 'chai'
chai.use require('chai-as-promised')
expect = chai.expect
nock = require 'nock'
request = require 'request'
resourceClient = require '..'
SERVER_URL = 'http://resource-client.com'

describe 'resource-client', ->
  describe 'method GET, isArray', ->
    beforeEach ->
      @Product = resourceClient {url: "#{SERVER_URL}/api/products/:_id"},
        query:
          method: 'GET',
          isArray: true
        queryOne:
          method: 'GET',
          isArray: true,
          returnFirst: true

    describe 'class method', ->
      it 'gets all products', ->
        api = nock(SERVER_URL)
          .get('/api/products')
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        @Product.query().then (products) ->
          expect(products).to.have.length 2
          expect(api.isDone()).to.be.true

      it 'can return first product', ->
        api = nock(SERVER_URL)
          .get('/api/products')
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        @Product.queryOne().then (product) ->
          expect(product).not.to.be.an.instanceof(Array)
          expect(product.toObject()).to.deep.equal {name: 'apple'}
          expect(api.isDone()).to.be.true

      it 'applies query parameters', ->
        api = nock(SERVER_URL)
          .get('/api/products?' + encodeURI('name[0]=apple&name[1]=banana'))
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        @Product.query({name: ['apple', 'banana']}).then (products) ->
          expect(products).to.have.length 2
          expect(products[0].toObject()).to.deep.equal {name: 'apple'}
          expect(products[1].toObject()).to.deep.equal {name: 'orange'}
          expect(api.isDone()).to.be.true

      it 'applies url attribute as a query parameter, if it is provided with an array', ->
        api = nock(SERVER_URL)
          .get('/api/products?' + encodeURI('_id[0]=123&_id[1]=456'))
          .reply(201, [
            {_id: '123'}
            {_id: '456'}
          ])
        @Product.query({_id: ['123', '456']}).then (products) ->
          expect(products).to.have.length 2
          expect(products[0].toObject()).to.deep.equal {_id: '123'}
          expect(products[1].toObject()).to.deep.equal {_id: '456'}
          expect(api.isDone()).to.be.true

      it 'instantiates every object as a resource', ->
        api = nock(SERVER_URL)
          .get('/api/products')
          .reply(201, [
            {name: 'apple'}
            {name: 'orange'}
          ])
        @Product.query().then (products) =>
          products.forEach (product) =>
            expect(product).to.be.instanceOf @Product
          expect(api.isDone()).to.be.true

    describe 'instance method', ->
      it 'is not defined', ->
        @Product = resourceClient url: "#{SERVER_URL}/api/products/:_id"
        product = new @Product()
        expect(product.query).to.be.undefined

  describe 'method GET', ->
    beforeEach ->
      @Product = resourceClient {url: "#{SERVER_URL}/api/products/:_id"},
        get:
          method: 'GET'

    describe 'class method', ->
      it 'gets product with specified id', ->
        api = nock(SERVER_URL)
          .get('/api/products/1234')
          .reply(200, {_id: '1234', name: 'apple'})
        @Product.get({_id: 1234}).then (product) ->
          expect(product.toObject()).to.deep.equal {_id: '1234', name: 'apple'}
          expect(api.isDone()).to.be.true

      it 'applies query parameters', ->
        api = nock(SERVER_URL)
          .get('/api/products/1234?' + encodeURI('select=price'))
          .reply(200, {_id: '1234', price: 2.5})
        @Product.get({_id: '1234', select: 'price'}).then (product) ->
          expect(product.toObject()).to.deep.equal {_id: '1234', price: 2.5}
          expect(api.isDone()).to.be.true

      it 'applies query with @ in the string (like emails)', ->
        api = nock(SERVER_URL)
          .get('/api/products/1234?email=test%40gmail.com')
          .reply(200, {_id: '1234', price: 2.5})
        @Product.get({_id: '1234', email: 'test@gmail.com'}).then (product) ->
          expect(product.toObject()).to.deep.equal {_id: '1234', price: 2.5}
          expect(api.isDone()).to.be.true

      it 'instantiates object as a resource', ->
        api = nock(SERVER_URL)
          .get('/api/products/1234')
          .reply(200, {_id: '1234', price: 2.5})
        @Product.get({_id: '1234'}).then (product) =>
          expect(product).to.be.instanceOf @Product
          expect(api.isDone()).to.be.true

    describe 'instance method', ->
      it 'is not defined', ->
        product = new @Product()
        expect(product.get).to.be.undefined

  describe 'method PUT', ->
    beforeEach ->
      @Product = resourceClient {
        url: "#{SERVER_URL}/api/products/:_id"
        params: {_id: '@_id'}
      }, {
        update:
          method: 'PUT'
      }

      @api = nock(SERVER_URL)
        .put('/api/products/1234', {_id: '1234', price: 2})
        .reply(201, {_id: '1234', price: 2})

    describe 'class method', ->
      it 'sends PUT request with correct data', ->
        @Product.update({_id: '1234'}, {_id: '1234', price: 2}).then (product) =>
          expect(product.toObject()).to.deep.equal {_id: '1234', price: 2}
          expect(@api.isDone()).to.be.true

      it 'returns instance of resource', ->
        @Product.update({_id: '1234'}, {_id: '1234', price: 2}).then (product) =>
          expect(product).be.an.instanceOf @Product

    describe 'instance method', ->
      it 'updates the product', ->
        product = new @Product {_id: '1234', price: 2}
        product.update().then =>
          expect(@api.isDone()).to.be.true

  describe 'method POST', ->
    beforeEach ->
      @Product = resourceClient {url: "#{SERVER_URL}/api/products/:_id"},
        'save':
          method: 'POST'

    describe 'class method', ->
      it 'updates the passed object', ->
        @api = nock(SERVER_URL)
          .post('/api/products', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        @Product.save({}, {price: 2}).then (product) =>
          expect(@api.isDone()).to.be.true

      it 'returns instance of resource', ->
        @api = nock(SERVER_URL)
          .post('/api/products', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        @Product.save({}, {price: 2}).then (product) =>
          expect(product).be.an.instanceOf @Product
          expect(@api.isDone()).to.be.true

      it 'posts to urls with multiple variables', ->
        @api = nock(SERVER_URL)
          .post('/api/products?storeSlug=sfbay', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        @Product.save({storeSlug: 'sfbay'}, {price: 2}).then (product) =>
          expect(product.toObject()).to.deep.equal {_id: '1234', price: 2}
          expect(@api.isDone()).to.be.true

    describe 'instance method', ->
      it 'saves the object', ->
        @api = nock(SERVER_URL)
          .post('/api/products', {price: 2})
          .reply(201, {_id: '1234', price: 2})
        product = new @Product({price: 2})
        product.save().then =>
          expect(@api.isDone()).to.be.true

  describe 'method DELETE', ->
    beforeEach ->
      @Product = resourceClient {
        url: "#{SERVER_URL}/api/products/:_id"
        params: {_id: '@_id'}
      }, {
        remove: {method: 'DELETE'}
      }

    describe 'class method', ->
      it 'deletes the passed object', ->
        api = nock(SERVER_URL)
          .delete('/api/products/1234')
          .reply(200, {_id: '1234', price: 2})
        @Product.remove(_id: '1234').then =>
          expect(api.isDone()).to.be.true

    describe 'instance method', ->
      it 'deletes the object', ->
        @Product = resourceClient {
          url: "#{SERVER_URL}/api/products/:_id"
          params: {_id: '@_id'}
        }, {
          remove: {method: 'DELETE'}
        }
        api = nock(SERVER_URL)
          .delete('/api/products/1234')
          .reply(200, {_id: '1234', price: 2})
        product = new @Product {_id: '1234'}
        product.remove().then ->
          expect(api.isDone()).to.be.true

  describe '@ params', ->
    it 'reads the value from the body if not in the params', ->
      @Product = resourceClient {
        url: "#{SERVER_URL}/api/products/:_id"
        params: {_id: '@_id'}
      }, {
        update: {method: 'PUT'}
      }

      api = nock(SERVER_URL)
        .put('/api/products/1234', {_id: '1234'})
        .reply(200, {_id: '1234'})

      product = new @Product({_id: '1234'})
      product.update().then ->
        expect(api.isDone()).to.be.true

    it 'removes the param if not in the body', ->
      @Product = resourceClient {
        url: "#{SERVER_URL}/api/products/:_id"
        params: {_id: '@_id'}
      }, {
        update: {method: 'PUT'}
      }

      api = nock(SERVER_URL)
        .put('/api/products', {price: 2})
        .reply(200, {_id: '1234', price: 2})

      product = new @Product({price: 2})
      product.update().then ->
        expect(api.isDone()).to.be.true

    it 'uses the request param if there is a request param', ->
      @Product = resourceClient {
        url: "#{SERVER_URL}/api/products/:_id"
        params: {_id: '@_id'}
      }, {
        update: {method: 'PUT'}
      }

      api = nock(SERVER_URL)
        .put('/api/products/1234', {})
        .reply(200, {_id: '1234', price: 2})

      @Product.update({_id: '1234'}, {}).then ->
        expect(api.isDone()).to.be.true

  describe 'custom action', ->
    describe 'custom url in action', ->
      it 'doesnt pollute subsequent action urls', ->
        Product = resourceClient {url: "#{SERVER_URL}/api/products/:_id"},
          'save':
            method: 'POST'

        api = nock(SERVER_URL)
          .post('/api/products')
          .reply(200, {price: 2})
        product = new Product({price: 2})
        product.save().then ->
          expect(api.isDone()).to.be.true

    describe 'complex url', ->
      it 'posts the correct data and URL', ->
        Subscription = resourceClient {
          url: "#{SERVER_URL}/api/subscriptions/:subscriptionId"
        }, {
          skipProduct:
            method: 'POST'
            url: "#{SERVER_URL}/api/subscriptions/:subscriptionId/products/:productId/skips"
        }

        api = nock(SERVER_URL)
          .post('/api/subscriptions/1234/products/4321/skips', {date: '2014-04-01'})
          .reply(200, {_id: '1234'})

        Subscription.skipProduct({subscriptionId: '1234', productId: '4321'}, {date: '2014-04-01'}).then ->
          expect(api.isDone()).to.be.true

  describe 'per-request options', ->
    beforeEach ->
      @Thing = resourceClient {
        url: "#{SERVER_URL}/api/will-be-overridden/:_id"
      }, {
        getWithHeader: {
          method: 'GET'
          url: "#{SERVER_URL}/api/new-products"
        }
      }

    it 'includes headers and query params in request', ->
      api = nock(SERVER_URL, reqheaders: {
          'x-auth': 'someone'
        })
        .get('/api/new-products?foo=bar')
        .reply(200, {_id: '1234', price: 2})
      @Thing.getWithHeader({ 'foo': 'bar' }, {}, { headers: { 'x-auth': 'someone' } }).then ->
        expect(api.isDone()).to.be.true

  describe 'headers', ->
    beforeEach ->
      @Thing = resourceClient {
        url: "#{SERVER_URL}/api/will-be-overridden"
        headers:
          'x-default': 'A'
      }, {
        'getMyHeaders': {
          method: 'GET'
          url: "#{SERVER_URL}/api/new-products"
          headers:
            'x-action': 'B'
        }
      }

    it 'combines headers from resource, action, and request', ->
      api = nock(SERVER_URL, reqheaders: {
        'x-default': 'A'
        'x-action': 'B'
        'x-request': 'C'
      }).get('/api/new-products').reply(200, {})

      response = @Thing.getMyHeaders({}, {}, { headers: { 'x-request': 'C' } }).then ->
        expect(api.isDone()).to.be.true

  describe 'error handling', ->
    beforeEach ->
      @Product = resourceClient {
        url: "#{SERVER_URL}/api/products/:_id"
        headers:
          'X-Secret-Token': 'ABCD1234'
      }, {
        'get': {method: 'GET'}
      }

    it 'returns undefined if status 404 ', ->
      api = nock(SERVER_URL)
        .get('/api/products/1234')
        .reply(404, 'Not found')
      @Product.get({_id: '1234'}).then (product) ->
        expect(product).to.be.undefined

    it 'throws an error if status is for any other non-200 status code', ->
      api = nock(SERVER_URL)
        .get('/api/products/1234')
        .reply(500, 'Something went wrong')
      expect(@Product.get({_id: '1234'})).to.be.rejectedWith /Internal Server Error/

    it 'includes the statusCode of the original response', ->
      api = nock(SERVER_URL)
        .get('/api/products/1234')
        .reply(500, {message: 'Cast to ObjectId failed for value'})
      @Product.get({_id: '1234'}).catch (err) ->
        expect(err.statusCode).to.equal 500
