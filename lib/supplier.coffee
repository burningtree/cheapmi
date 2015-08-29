request = require 'request'

class Supplier

  constructor: (@data) ->

    @tools =
      request: require 'request'
      cheerio: require 'cheerio'

    @tools.request.defaults
      headers:
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.78 Safari/537.36'

module.exports = Supplier
