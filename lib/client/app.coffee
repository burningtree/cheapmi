Vue = require 'Vue'
VueRouter = require 'vue-router'

Vue.use require('vue-resource')
Vue.use VueRouter

Product = Vue.extend
  template: require('jade!../../views/Product.html')()
  data:
    item:
      name: 'xxxx'
  props: [ 'currency' ]
  ready: () ->

    @currency = @$parent.currency
    @fx = require 'money'
    @fx.base = 'USD'
    @$http.get "/api/rates", (fx) =>
      console.log 'rates set'
      @fx.rates = fx.rates

      @$http.get "/api/products/#{@$route.params.id}", (item) =>
        @$set 'item', item

    @$watch '$parent.currency', (newCur, oldCur) =>
      @currency = newCur
      olditem = @item
      @$set 'item', null
      @$set 'item', olditem

  filters:
    formatPrice: (item, currency) ->
      
      console.log 'sel cur: '+currency
      baseCurrency = currency || 'USD'
      price = item.price
      currency = item.currency

      #console.log baseCurrency
      #console.log price
      #console.log currency

      if currency == baseCurrency
        return "#{price} #{currency}"

      newPrice = (0+@fx.convert(price, { from: currency, to: baseCurrency })).toFixed(2)
      #newPrice = item.price_usd.toFixed(2)

      return "#{newPrice} #{baseCurrency} (#{price} #{currency})"

ProductList = Vue.extend
  template: require('jade!../../views/ProductList.html')()
  data:
    title: 'blabla'
    items: []
  ready: () ->
    @$http.get '/api/products', (items, status, req) =>
      @$set 'items', items
  filters:
    getVariants: (product) ->
      if product.variants
        return _.keys(product.variants).length
      else return 1

    getBestPrice: (p) ->
      if not p.price.best
        return "n/a"
      return "#{p.price.best.price} #{p.price.best.currency} (#{p.price.best.supplier})"

    getPrice: (product) ->
      min = 0
      max = 0
      if product.variants
        for variantId, x of product.variants
          price = x.retail_price
          if price == undefined and product.retail_price
            price = product.retail_price

          if not price then continue
          pr = price.CNY

          if pr > max then max = pr
          if pr < min or min == 0 then min = pr
      else if product.retail_price
        max = min = product.retail_price.CNY

      if max == 0 then return ''
      if max == min then return "#{max} CNY"
      return "#{min} - #{max} CNY"

App = Vue.extend
  data: () ->
    return {
      currency: 'CZK'
    }

router = new VueRouter
  alwaysRefresh: true

router.map
  '/':
    component: ProductList
    alwaysRefresh: true
  '/products/:id':
    component: Product
    alwaysRefresh: true

window.onload = ->
  router.start App, '#app'

