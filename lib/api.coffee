fs = require 'fs'
yaml = require 'js-yaml'
Path = require 'path'
async = require 'async'
_ = require 'lodash'
MongoClient = require('mongodb').MongoClient
fx = require 'money'

class API
  data: {}
  suppliers: {}

  start: (callback) ->

    MongoClient.connect 'mongodb://localhost:27017/cheapmi', (err, @db) =>
      console.log 'Database connected'

      @loadData =>
        @loadSuppliers ->
          callback null, true

  loadData: (callback) ->

    datasets = [ 'products', 'suppliers' ]
    for ds in datasets
      fn = Path.resolve './data', ds+'.yaml'
      file = fs.readFileSync fn
      @data[ds] = yaml.load file

    # exchange rates
    @data.fx = JSON.parse(fs.readFileSync(Path.resolve('./data/rates.json')))
    fx.base = 'USD'
    fx.rates = @data.fx.rates

    console.log 'Data loaded'
    callback null, true

  loadSuppliers: (callback) ->

    for supplierId, supplier of @data.suppliers
      supplier.id = supplierId
      fn = Path.resolve './lib', 'suppliers', supplier.id
      supp = require fn
      @suppliers[supplier.id] = new supp(supplier)

    console.log 'Suppliers loaded'
    callback null, true

  checkProducts: (callback) ->

    out = {}
    async.eachSeries @data.products, (product, nextProduct) =>
      console.log '------------------------'
      console.log 'product: '+product.id
      console.log '------------------------'
      suppliers = {}
      for supplierId, sp of @data.suppliers
        if sp.targets?[product.id] then suppliers[supplierId] = sp.targets[product.id]

      out[product.id] = {}

      async.each _.keys(suppliers), (supplierId, nextTarget) =>
        target = suppliers[supplierId]
        console.log "checking #{product.id} on #{supplierId} (#{JSON.stringify(target)})"
        @checkProduct
          product: product.id
          supplier: supplierId
          target: target
        , (err, result) ->
          out[product.id][supplierId] = result
          nextTarget()
      , () =>
        data =
          prices: out[product.id]
          updated: new Date
        @db.collection('prices').update { product: product.id }, { $set: data }, { upsert: true }, () ->
          setTimeout ->
            nextProduct()
          , 0
    , ->
      callback null, { ok: true, data: out }

  checkProduct: (opts, callback) ->
    
    supplier = @suppliers[opts.supplier]
    supplier.getProduct opts.target, (err, product) ->
      callback null, product

  getProduct: (id, callback) ->
    product = null
    for p in @data.products
      if p.id == id
        product = p

    if !product
      return callback null, { err: 'not found' }
    
    @db.collection('prices').findOne { product: id }, (err, output) =>

      if output
        suppliers = []
        prices = []
        for supplier, p of output.prices
          p.supplier = supplier
          p.price_usd = fx.convert p.price, { from: p.currency, to: fx.base }

          prices.push p
          if p.supplier not in suppliers
            suppliers.push p.supplier

        product.prices = prices
        product.prices_updated = output.updated

        product.suppliers = {}
        for sp in suppliers
          product.suppliers[sp] = @data.suppliers[sp]

      callback null, product

      


module.exports = API
