Supplier = require '../supplier'

class LocalSupplier extends Supplier

  getProduct: (opts, callback) ->
    @tools.request opts.url, (err, resp, body) =>
      $ = @tools.cheerio.load body
      output =
        price: Number($('#unit_price').text().match(/([\d\.]+)$/)[1])
        currency: 'USD'
        in_stock: null 
      callback null, output

module.exports = LocalSupplier
