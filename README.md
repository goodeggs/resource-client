# Resource Client

Easily create node API clients for your APIs. Inspired by [Angular Resource](https://docs.angularjs.org/api/ngResource/service/$resource) and [Angular Validated Resource](https://github.com/goodeggs/angular-validated-resource).

[![NPM version](http://img.shields.io/npm/v/resource-client.svg?style=flat-square)](https://www.npmjs.org/package/resource-client)
[![Build Status](http://img.shields.io/travis/goodeggs/resource-client.svg?style=flat-square)](https://travis-ci.org/goodeggs/resource-client)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/goodeggs/resource-client/blob/master/LICENSE.md)

## Usage

```
npm install resource-client --save
```

```javascript
var resourceClient = require('resource-client');

var Product = resourceClient({
  url: 'http://www.mysite.com/api/products/:_id',
  headers: {
    'X-Secret-Token': 'ABCD1234'
  }
});

Product.query({isActive: true}, function(err, products) {
  product = products[0];
  product.name = 'apple';
  product.save();
});

// or with a promise...
Product.query({isActive: true}).then(function (products) {
  product = products[0];
  product.name = 'apple';
  product.save();
}).catch(function (err) {
  if (err) console.log err;
});
```

You can also configure the resource to use JSON schema validation for every request:

```javascript
var resourceClient = require('resource-client');

var Product = resourceClient({
  url: 'http://www.mysite.com/api/products/:_id',
  headers: {
    'X-Secret-Token': 'ABCD1234'
  }
  // recommended that you do not allow unkown properties when testing.
  banUnknownProperties: true
});

Product.action('update', {
  method: 'PUT'
  // will reject or pass error to callback if validation fails for any of the below
  urlParamsSchema: require('./product_schemas/update/url_params.json')
  queryParamsSchema: require('./product_schemas/update/query_params.json')
  requestBodySchema: require('./product_schemas/update/request_body.json')
  responseBodySchema: require('./product_schemas/update/response_body.json')
})
```

## Creating a Resource

### resourceClient(options)

- **options** - default request options for this resource. You can use any option from the [request][request] module, with a few additions:
  - **url** - same as request url but can contain variables prefixed with a colon such as `products/:name`
  - **params** - First used to populate url params, then any leftover are added as query params. Note, you can define a param using '@' to read the param value off the request body `{_id: '@_id'}`.
  - **json** - set to true by default


```javascript
var resourceClient = require('resource-client');

var Product = resourceClient({
  url: 'http://www.mysite.com/api/products/:_id',
  params: {_id: '@_id'}
  headers: {'X-Secret-Token': 'ABCD1234'}
})
```

## Defining Resource Actions

### Resource.action(name, options)

- **name** - name of action
- **options** - default request options for this action. Merges with defaults set for the resource. You can use any option from the [request](https://github.com/request/request) module, with a few additions:
  - **url** - same as request url but can contain variables prefixed with a colon such as `products/:name`
  - **params** - First used to populate url params, then any leftover are added as query params. Note, you can define a param using '@' to read the param value off the request body `{_id: '@_id'}`.
  - **isArray** - resource is an array. It will not populate variables in the url.
  - **returnFirst** - resource is an array. It will return the first result from the array

```javascript
var resourceClient = require('resource-client');

var Product = resourceClient({
  url: 'http://www.mysite.com/api/products/:_id',
  headers: {
    'X-Secret-Token': 'ABCD1234'
  }
});

Product.action('getActive', {
  method: 'GET'
  isArray: true
  params: {isActive: true}
});

Product.action('queryOne', {
  method: 'GET'
  isArray: true
  returnFirst: true
});
```

If the method is GET, you can use it as a class method:

- `Class.method([params], [options], callback)`

```javascript
Product.action('get', {
  method: 'GET'
});

// class method
Product.get({_id: 1234}, function (err, product) { ... })
```

If the method is PUT, POST, or DELETE, you can use it as both a class or an instance method:

- `Class.method([params], [body], [options], callback)`
- `instance.method([params], [options], callback)`

```javascript
Product.action('save', {
  method: 'POST'
});

// class method
Product.save({name: 'apple'}, function (err, product) { ... });

// instance method
product = new Product({name: 'apple'});
product.save(function(err) { ... });
```

## Default Actions

Every new resource will come with these methods by default. However, we recommend
you explicitly define an action for each endpoint exposed by your API.

- **get** - {method: 'GET'}
- **query** - {method: 'GET', isArray: true}
- **queryOne** - {method: 'GET', isArray: true, returnFirst: true}
- **update** - {method: 'PUT'}
- **save** - {method: 'POST'}
- **remove** - {method: 'DELETE'}


## Additional per-request options

If you need to pass custom [request][request] options for an individual request,
(for example, to identify a user with an authentication token),
the action methods also take optional parameters, like so:

```javascript
Product.save(
  {},                 // params
  {name: 'apple'},    // body
  { headers: {} },    // options
  function (err, product) { ... }
 );

Product.getById(urlParams, queryParams, otherOptions, callback);
```


## Contributing

Please follow our [Code of Conduct](https://github.com/goodeggs/mongoose-webdriver/blob/master/CODE_OF_CONDUCT.md)
when contributing to this project.

```
$ git clone https://github.com/goodeggs/resource-client && cd resource-client
$ npm install
$ npm test
```

_Module scaffold generated by [generator-goodeggs-npm](https://github.com/goodeggs/generator-goodeggs-npm)._


[request]: https://github.com/request/request
