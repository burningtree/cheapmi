Supplier = require '../supplier'

class LocalSupplier extends Supplier

  getProduct: (opts, callback) ->
    @tools.request opts.url, (err, resp, body) =>
      $ = @tools.cheerio.load body
      output =
        price: Number($('#our_price_display').text().match(/([\d\,]+)/)[1].replace(',','.'))
        currency: 'EUR'
        in_stock: null 
      callback null, output

module.exports = LocalSupplier
