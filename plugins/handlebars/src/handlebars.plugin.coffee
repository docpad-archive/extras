module.exports = (BasePlugin) ->

  # Define Plugin
  class HandlebarsPlugin extends BasePlugin

    # Plugin name
    name: 'handlebars'

    # Plugin priority
    priority: 725

    # Handlebars
    Handlebars: null

    # Constructor
    constructor: ->
      super
      docpad = @docpad
      config = @config

      Handlebars = @Handlebars = require 'handlebars'

      # Add helpers, if defined in docpad.cson
      if @config.helpers
        Handlebars.registerHelper(name, helper) for name, helper of @config.helpers

    # Render some content
    render: (opts, next) ->
      # Prepare
      {inExtension,outExtension,templateData,file,content} = opts
      Handlebars = @Handlebars

      try
        if inExtension in ['hb', 'hbs', 'handlebars']
          opts.content = Handlebars.compile(content)(templateData)

        return next()

      catch err
        return next(err)
