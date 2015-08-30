Supplier = require '../supplier'

class LocalSupplier extends Supplier

  getProduct: (opts, callback) ->
    @tools.request opts.url, (err, resp, body) =>
      $ = @tools.cheerio.load body
      if opts.query
        price = Number($(opts.query).html().match(/([\d\.]+)/)[1])
      else
        price = Number($('.price-num').html().match(/^([\d+\.]+)/)[1])

      output = 
        price: price
        currency: 'USD'
        in_stock: null

      callback null, output

module.exports = LocalSupplier
