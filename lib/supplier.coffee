request = require 'request'

class Supplier

  constructor: (@data) ->

    @tools =
      request: require 'request'
      cheerio: require 'cheerio'

    @tools.request.defaults
      headers:
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.78 Safari/537.36'

  getProduct: (opts, callback) ->
    @getProductDefault opts, callback

  getProductDefault: (opts, callback) ->

    url = opts.url
    if @data.config.urlSuffix
      url = url + @data.config.urlSuffix

    @tools.request url, (err, resp, body) =>
      console.log opts.url
      $ = @tools.cheerio.load body

      query = false
      match = false

      if opts.match
        match = opts.match
      else if opts.query
        query = opts.query
      else if @data.config.match
        match = @data.config.match
      else if @data.config.query
        query = @data.config.query

      if match
        price = Number(body.match(new RegExp(match))[1])
      else if query
        price = Number($(query).html().match(/([\d\.]+)/)[1])
      else
        callback 'no data'

      output = 
        price: price
        currency: @data.config.currency || 'USD'
        in_stock: null

      callback null, output

module.exports = Supplier
