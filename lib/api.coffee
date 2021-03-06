fs = require 'fs'
yaml = require 'js-yaml'
Path = require 'path'
async = require 'async'
_ = require 'lodash'
MongoClient = require('mongodb').MongoClient
fx = require 'money'
Supplier = require './supplier'

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
    suppliersDir = Path.resolve './data/suppliers'
    for fn in fs.readdirSync(suppliersDir)
      name = null

      if fn.match(/\.yaml$/)
        name = fn.match(/^(.+).yaml$/)[1]
        packPath = Path.resolve suppliersDir, name + '.yaml'
      else
        packPath = Path.resolve suppliersDir, fn, fn + '.yaml'
        name = fn

      if fs.existsSync(packPath)
        console.log "Loading supplier: #{name}"
        @data.suppliers[name] = yaml.load(fs.readFileSync(packPath))

    for supplierId, supplier of @data.suppliers
      supplier.id = supplierId
      fn = Path.resolve './lib', 'suppliers', supplier.id + '.coffee'
      if fs.existsSync(fn)
        supp = require fn
      else
        # default supplier
        supp = Supplier
      @suppliers[supplier.id] = new supp(supplier, @)

    console.log 'Suppliers loaded'
    callback null, true

  checkProducts: (callback) ->

    out = {}
    async.eachSeries @data.products, (product, nextProduct) =>

      @checkProduct { product: product }, (err, out) =>
        out[product.id] = out
        nextProduct()

    , ->
      callback null, { ok: true, data: out }

  checkProduct: (opts, callback) ->

    product = opts.product
    out = {}

    console.log '------------------------'
    console.log 'product: '+product.id
    console.log '------------------------'
    suppliers = {}
    for supplierId, sp of @data.suppliers
      if sp.targets?[product.id] then suppliers[supplierId] = sp.targets[product.id]

    @db.collection('prices').findOne { product: product.id }, (err, current) =>

      async.each _.keys(suppliers), (supplierId, nextTarget) =>
        target = suppliers[supplierId]
        console.log "checking #{product.id} on #{supplierId} (#{JSON.stringify(target)})"
        @checkProductSupplier
          product: product.id
          supplier: supplierId
          target: target
        , (err, result) ->
          out[supplierId] = result
          nextTarget()
      , () =>

        # cekneme zda se zmenily hodnoty
        if current
          for supplierId, sp of out
            cur = current.prices[supplierId]
            if (cur and sp?.price) and cur.price != sp.price
              console.log "price changed! [#{supplierId}] current: #{cur.price}, new: #{sp.price}"
              @db.collection('pricechanges').insert
                product: product.id
                supplier: supplierId
                old: cur
                new: sp
                created: new Date

        data =
          prices: out
          updated: new Date

        @db.collection('prices').update { product: product.id }, { $set: data }, { upsert: true }, () ->
          callback null, out

        data.product = product.id
        @db.collection('pricehistory').insert data


  checkProductSupplier: (opts, callback) ->
    
    supplier = @suppliers[opts.supplier]
    try
      supplier.getProduct opts.target, (err, product) ->
        callback null, product
    catch err
      console.log "ERROR!!!!: #{err}"
      callback null, {}

  getProducts: (callback) ->
    pIds = []
    for p in @data.products
      pIds.push p.id

    @db.collection('prices').find({ product: { $in: pIds }}).toArray (err, output) =>
      pData = {}
      for x in output
        cupp = []
        for supId, supData of x.prices
          supData.supplier = supId
          supData.price_usd = Number(fx.convert(supData.price, { from: supData.currency, to: 'USD' }).toFixed(2))
          cupp.push supData

        cupp = _.sortBy(cupp, (x) -> return x.price_usd)
        x.best = cupp[0]
        pData[x.product] = x

      out = []
      for p in @data.products
        cx = pData[p.id]
        p.price =
          best: cx.best
          updated: cx.updated
        out.push p
      
      callback null, out 

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
