BanggoodSupplier = require './banggood'

class LocalSupplier extends BanggoodSupplier

  local:
    warehouse: 'CN'
    baseUrl: 'http://www.banggood.com/'

module.exports = LocalSupplier
