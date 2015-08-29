Vue = require 'Vue'
VueRouter = require 'vue-router'

Vue.use require('vue-resource')
Vue.use VueRouter

Product = Vue.extend
  template: require('jade!../../views/Product.html')()
  data:
    item:
      name: 'xxxx'
  ready: () ->
    @$http.get "/api/products/#{@$route.params.id}", (item) =>
      @$set 'item', item

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

App = Vue.extend {}
router = new VueRouter()
router.map
  '/':
    component: ProductList
  '/products/:id':
    component: Product

myApp = () ->
  router.start App, '#app'

window.onload = myApp
