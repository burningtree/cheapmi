BanggoodSupplier = require './banggood'

class LocalSupplier extends BanggoodSupplier

  local:
    warehouse: 'UK'
    baseUrl: 'http://www.banggood.com/'

module.exports = LocalSupplier
