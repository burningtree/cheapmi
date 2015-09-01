Hapi = require 'hapi'
API = require './lib/api'

api = new API()

server = new Hapi.Server()
server.connection port: 3030

server.register require('vision'), ->
  server.views
    engines:
      html: require 'jade'
    path: 'views'
    compileOptions:
      pretty: true

server.register require('inert'), ->
  server.route
    method: 'GET'
    path: '/components/{param*}'
    handler:
      directory:
        path: 'bower_components'
  server.route
    method: 'GET'
    path: '/app/{param*}'
    handler:
      directory:
        path: 'public'

server.route
  method: 'GET'
  path: '/'
  handler: (req, reply) ->
    reply.view 'layout',
      title: 'CheapMI - Xiaomi Products & Prices'

server.route
  method: 'GET'
  path: '/templates/{param}'
  handler: (req, reply) ->
    reply.view req.params.param, {}

server.route
  method: 'GET'
  path: '/api/products'
  handler: (req, reply) ->
    reply api.data.products

server.route
  method: 'GET'
  path: '/api/rates'
  handler: (req, reply) ->
    reply api.data.fx

server.route
  method: 'GET'
  path: '/api/products/{id}'
  handler: (req, reply) ->
    api.getProduct req.params.id, (err, output) ->
      reply output

server.route
  method: 'GET'
  path: '/check'
  handler: (req, reply) ->
    api.checkProducts (err, out) ->
      reply err, out

server.route
  method: 'GET'
  path: '/check-miband'
  handler: (req, reply) ->
    api.checkProduct { product: api.data.products[1] }, (err, out) ->
      reply err, out

api.start ->
  server.start ->
    console.log "Server running at #{server.info.uri}"

    setInterval ->
      api.checkProducts (err, out) ->
        console.log 'periodic check done'
    , ((60*15)*1000)

