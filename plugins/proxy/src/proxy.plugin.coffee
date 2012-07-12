# Export Plugin
module.exports = (BasePlugin) ->

  request = require('request')
  urlUtil = require('url')

  class ProxyPlugin extends BasePlugin

    name: 'proxy'

    serverAfter: (opts) ->
      {server} = opts
      proxy = @
      proxy.config.proxies or= {}

      for key, value of proxy.config.proxies
        server.all value.path, (req, res) ->
          proxyUrl = urlUtil.parse(value.domain)
          proxyUrl.path = proxyUrl.pathname = req.url
          newUrl = urlUtil.format(proxyUrl)

          req.pipe(request(newUrl).pipe(res))


