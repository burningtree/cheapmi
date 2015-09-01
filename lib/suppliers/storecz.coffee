Supplier = require '../supplier'

class LocalSupplier extends Supplier

  getProduct: (opts, callback) ->
    @tools.request opts, (err, resp, body) =>
      $ = @tools.cheerio.load body
      output =
        price: Number($(".our_price_display").text().match(/([\d\,\.\s]+)/)[1].replace(',', '.').replace(/\s+/, ''))
        currency: 'CZK'
        in_stock: null 
      callback null, output

module.exports = LocalSupplier
