
API = require './lib/api'
async = require 'async'
_ = require 'lodash'
prompt = require 'prompt'
request = require 'request'
URL = require 'url'
google = require 'google'
yaml = require 'js-yaml'
fs = require 'fs'

prompt.start()
deprecatedSuppliers = [ 'mi-cn', 'mi-global' ]

api = new API()
api.start ->
  console.log "API started\n"

  async.eachSeries api.data.products, (product, nextProduct) ->
    console.log "#### #{product.name} ####"
    async.eachSeries _.keys(api.data.suppliers), (supplierId, nextSupplier) -> 
      supplier = api.data.suppliers[supplierId]
      supplier.id = supplierId
      if supplier.id in deprecatedSuppliers
        return nextSupplier()

      domain = supplier.domain || URL.parse(supplier.url).host

      if !supplier.targets[product.id]
        q = "xiaomi #{product.name} site:#{domain}"
        google q, (err, res, links) ->
          if err
            return nextSupplier()
          console.log '-- '+supplier.id
          for i in [ 1, 2, 3, 4, 5 ]
            if links[i]
              console.log "(#{i}) #{links[i-1].title}\n    #{links[i-1].link}"

          prompt.get [ { name:'agree', description: 'Please specify number or (n)ext ((q)uit, sq-savequit) (default: (n)ext)' } ], (err, result) ->
            if result.agree in [ '1', '2', '3', '4', '5' ]
              suppliersFile = './data/suppliers.yaml'
              sups = yaml.load(fs.readFileSync(suppliersFile))
              
              sups[supplier.id].targets[product.id] =
                url: links[result.agree-1].link

              fs.writeFileSync suppliersFile, yaml.dump(sups)
              console.log 'supliers saved'

            if result.agree == 'sq'
              process.exit()

            if result.agree == 'q'
              process.exit()

            nextSupplier()
      else
        nextSupplier()

    , () ->
      nextProduct()
  , () ->
    process.exit()

