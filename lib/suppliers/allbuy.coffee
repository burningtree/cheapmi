Supplier = require '../supplier'

class LocalSupplier extends Supplier

  getProduct: (opts, callback) ->
    @tools.request opts.url, (err, resp, body) =>
      output =
        price: Number(body.match(/"price": "([\d\.]+)"/)[1])
        currency: 'USD'
        in_stock: null 
      callback null, output

module.exports = LocalSupplier
