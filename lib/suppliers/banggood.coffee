Supplier = require '../supplier'

class LocalSupplier extends Supplier

  local:
    warehouse: 'CN'
    baseUrl: 'http://www.banggood.com/'

  getProduct: (opts, callback) ->

    url = @local.baseUrl + "index.php?com=product&t=stockMessage&sku=#{opts.sku}&warehouse=#{@local.warehouse}&products_id=#{opts.id}"
    console.log "Getting #{url}"
    try
      @tools.request url, (err, resp, body) =>
        data = JSON.parse body
        console.log data.hideBuy
        output =
          price: data.final_price
          currency: 'USD'
          in_stock: data.hideBuy == 0
        callback null, output
    catch err
      callback err

module.exports = LocalSupplier
