chai = require 'chai'
chai.use require 'chai-as-promised'
expect = chai.expect
nock = require 'nock'
request = require 'request'
resourceClient = require '..'
serverUrl = 'http://resource-client.com'

describe 'resource-client validation', ->
  describe 'validating urlParamsSchema', ->
    it 'validates for GET', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        get:
          method: 'GET'
          params:
            _id: '@_id'
          urlParamsSchema:
            type: 'object'
            required: ['_id']
            properties:
              _id:
                type: 'string'
                format: 'objectid'

      expect(@Product.get({_id: '123abc'})).to.be.rejectedWith 'Url params validation failed for action \'get\': Format validation failed (objectid expected) at /_id'

    it 'validates for POST/PUT/DELETE class method', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        update:
          method: 'PUT'
          params:
            _id: '@_id'
          urlParamsSchema:
            type: 'object'
            required: ['_id']
            properties:
              _id:
                type: 'string'
                format: 'objectid'

      expect(@Product.update({_id: '123abc'})).to.be.rejectedWith 'Url params validation failed for action \'update\': Format validation failed (objectid expected) at /_id'

    it 'validates for POST/PUT/DELETE instance method', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        update:
          method: 'PUT'
          params:
            _id: '@_id'
          urlParamsSchema:
            type: 'object'
            required: ['_id']
            properties:
              _id:
                type: 'string'
                format: 'objectid'

      product = new @Product({_id: '123abc'})
      expect(product.update()).to.be.rejectedWith 'Url params validation failed for action \'update\': Format validation failed (objectid expected) at /_id'

  describe 'validating queryParamsSchema', ->
    it 'validates for GET', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        query:
          method: 'GET'
          isArray: true
          queryParamsSchema:
            type: 'object'
            required: ['foodhubSlug']
            properties:
              foodhubSlug:
                type: 'string'
              isActive:
                type: 'boolean'

      expect(@Product.query({isActive: true})).to.be.rejectedWith 'Query validation failed for action \'query\': Missing required property: foodhubSlug'

    it 'validates for POST/PUT/DELETE class method', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        update:
          method: 'PUT'
          queryParamsSchema:
            type: 'object'
            required: ['$select']
            properties:
              $select:
                type: 'string'

      expect(@Product.update({select: 'name'}, {name: 'apple'})).to.be.rejectedWith 'Query validation failed for action \'update\': Missing required property: $select'

    it 'validates for POST/PUT/DELETE instance method', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        update:
          method: 'PUT'
          queryParamsSchema:
            type: 'object'
            required: ['$select']
            properties:
              $select:
                type: 'string'

      product = new @Product({name: 'apple'})
      expect(product.update({select: 'name'})).to.be.rejectedWith 'Query validation failed for action \'update\': Missing required property: $select'

  describe 'validating requestBodySchema', ->
    it 'validates for PUT/POST/DELETE class methods', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        save:
          method: 'POST'
          requestBodySchema:
            type: 'object'
            required: ['name']
            properties:
              name:
                type: 'string'
              type:
                type: 'string'
                enum: ['just-in-time', 'wholesale', 'consignment']

      expect(@Product.save({}, {type: 'just-in-time'})).to.be.rejectedWith 'Request body validation failed for action \'save\': Missing required property: name'

    it 'validates for PUT/POST/DELETE instance methods', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        save:
          method: 'POST'
          requestBodySchema:
            type: 'object'
            required: ['name']
            properties:
              name:
                type: 'string'
              type:
                type: 'string'
                enum: ['just-in-time', 'wholesale', 'consignment']

      product = new @Product({type: 'just-in-time'})
      expect(product.save()).to.be.rejectedWith 'Request body validation failed for action \'save\': Missing required property: name'

  describe 'validating responseBodySchema', ->
    it 'validates for GET class methods', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        query:
          method: 'GET'
          isArray: true
          responseBodySchema:
            type: 'array'
            items:
              type: 'object'
              required: ['name']
              properties:
                name:
                  type: 'string'
                type:
                  type: 'string'
                  enum: ['just-in-time', 'wholesale']

      api = nock(serverUrl)
        .get('/api/products')
        .reply(201, {name: 'apples', type: 'consignment'}) # invalid enum

      expect(@Product.query()).to.be.rejectedWith 'Response body validation failed for action \'query\': Invalid type: object (expected array)'

    it 'validates for PUT/POST/DELETE class methods', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        save:
          method: 'POST'
          responseBodySchema:
            type: 'object'
            required: ['name']
            properties:
              name:
                type: 'string'
              type:
                type: 'string'
                enum: ['just-in-time', 'wholesale']

      api = nock(serverUrl)
        .post('/api/products', {name: 'apples', type: 'just-in-time'})
        .reply(201, {name: 'apples', type: 'consignment'}) # invalid enum

      expect(@Product.save({}, {name: 'apples', type: 'just-in-time'})).to.be.rejectedWith 'Response body validation failed for action \'save\': No enum match for: "consignment" at /type'

    it 'validates for PUT/POST/DELETE instance methods', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        save:
          method: 'POST'
          responseBodySchema:
            type: 'object'
            required: ['name']
            properties:
              name:
                type: 'string'
              type:
                type: 'string'
                enum: ['just-in-time', 'wholesale']

      api = nock(serverUrl)
        .post('/api/products', {name: 'apples', type: 'just-in-time'})
        .reply(201, {name: 'apples', type: 'consignment'}) # invalid enum

      product = new @Product({name: 'apples', type: 'just-in-time'})
      expect(product.save()).to.be.rejectedWith 'Response body validation failed for action \'save\': No enum match for: "consignment" at /type'

  describe 'banUnknownProperties', ->
    it 'does banUnknownProperties for all actions if true on resource config', ->
      @Product = resourceClient {
        url: "#{serverUrl}/api/products/:_id"
        banUnknownProperties: true
      }, {
        query:
          method: 'GET'
          isArray: true
          queryParamsSchema:
            type: 'object'
            required: ['foodhubSlug']
            properties:
              foodhubSlug:
                type: 'string'
              isActive:
                type: 'boolean'
      }


      expect(@Product.query({foodhubSlug: 'sfbay', isActive: true, search: 'apple'})).to.be.rejectedWith 'Query validation failed for action \'query\': Unknown property (not in schema) at /search'

    it 'does not banUnknownProperties if not configured', ->
      @Product = resourceClient {url: "#{serverUrl}/api/products/:_id"},
        query:
          method: 'GET'
          isArray: true
          queryParamsSchema:
            type: 'object'
            required: ['foodhubSlug']
            properties:
              foodhubSlug:
                type: 'string'
              isActive:
                type: 'boolean'

      api = nock(serverUrl)
        .get('/api/products?foodhubSlug=sfbay&isActive=true&search=apple')
        .reply(201, {name: 'apples', type: 'consignment'})
      expect(@Product.query({foodhubSlug: 'sfbay', isActive: true, search: 'apple'})).to.be.fulfilled
