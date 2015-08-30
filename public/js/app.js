// Generated by CoffeeScript 1.9.3
var App, Product, ProductList, Vue, VueRouter, myApp, router;

Vue = require('Vue');

VueRouter = require('vue-router');

Vue.use(require('vue-resource'));

Vue.use(VueRouter);

Product = Vue.extend({
  template: require('jade!../../views/Product.html')(),
  data: {
    item: {
      name: 'xxxx'
    }
  },
  ready: function() {
    this.fx = require('money');
    this.fx.base = 'USD';
    return this.$http.get("/api/rates", (function(_this) {
      return function(fx) {
        console.log('rates set');
        _this.fx.rates = fx.rates;
        return _this.$http.get("/api/products/" + _this.$route.params.id, function(item) {
          return _this.$set('item', item);
        });
      };
    })(this));
  },
  filters: {
    formatPrice: function(item) {
      var baseCurrency, currency, newPrice, price;
      baseCurrency = 'USD';
      price = item.price;
      currency = item.currency;
      console.log(baseCurrency);
      console.log(price);
      console.log(currency);
      if (currency === baseCurrency) {
        return price + " " + currency;
      }
      newPrice = item.price_usd.toFixed(2);
      return newPrice + " " + baseCurrency + " (" + price + " " + currency + ")";
    }
  }
});

ProductList = Vue.extend({
  template: require('jade!../../views/ProductList.html')(),
  data: {
    title: 'blabla',
    items: []
  },
  ready: function() {
    return this.$http.get('/api/products', (function(_this) {
      return function(items, status, req) {
        return _this.$set('items', items);
      };
    })(this));
  },
  filters: {
    getVariants: function(product) {
      if (product.variants) {
        return _.keys(product.variants).length;
      } else {
        return 1;
      }
    },
    getPrice: function(product) {
      var max, min, pr, price, ref, variantId, x;
      min = 0;
      max = 0;
      if (product.variants) {
        ref = product.variants;
        for (variantId in ref) {
          x = ref[variantId];
          price = x.retail_price;
          if (price === void 0 && product.retail_price) {
            price = product.retail_price;
          }
          if (!price) {
            continue;
          }
          pr = price.CNY;
          if (pr > max) {
            max = pr;
          }
          if (pr < min || min === 0) {
            min = pr;
          }
        }
      } else if (product.retail_price) {
        max = min = product.retail_price.CNY;
      }
      if (max === 0) {
        return '';
      }
      if (max === min) {
        return max + " CNY";
      }
      return min + " - " + max + " CNY";
    }
  }
});

App = Vue.extend({});

router = new VueRouter();

router.map({
  '/': {
    component: ProductList
  },
  '/products/:id': {
    component: Product
  }
});

myApp = function() {
  return router.start(App, '#app');
};

window.onload = myApp;
