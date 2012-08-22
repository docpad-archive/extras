module.exports = (BasePlugin) ->

    jsdom = require 'jsdom'
    balUtil = require 'bal-util'
    hljs = require 'highlight.js'

    highlight = (window, el, replaceTab, next) ->
        preOrCode = ['pre', 'code']
        parentEl = el
        childEl = el
        language = null

        # In a child element?
        if el.childElementCount and
            tag = (el.firstElementChild.tagName.toLowerCase()) in preOrCode
                childEl = el.firstElementChild

        # In a parent element?
        else if el.parentElement and
            tag = (el.parentElement.tagName.toLowerCase()) in preOrCode
                parentEl = el.parentElement

        # Next if already highlighted
        return next() if /highlighted/.test(parentEl.className)


        # Try to convert the language to a class name
        language = childEl.getAttribute('lang') or
            parentEl.getAttribute('lang')

        childEl.removeAttribute('lang')
        parentEl.removeAttribute('lang')
        el.removeAttribute('lang')

        if language
            # Trim language
            language = language.replace(/^\s+|\s+$/g, '')

            if el.className
                el.className += " language-#{language}"
            else
                el.className = "language-#{language}"

        # Unfortunately, Highlight.js uses the document global in a closure
        _document = global.document
        global.document = window.document

        hljs.highlightBlock(childEl, replaceTab)

        # Restore the document global
        global.document = _document


        if parentEl.className
            parentEl.className += " highlighted"
        else
            parentEl.className = "highlighted"

        return next()


    class HighlightjsPlugin extends BasePlugin
        name: 'highlightjs'

        config:
            replaceTab: null

        renderDocument: (opts, next) ->
            {extension, file} = opts
            replaceTab = @config.replaceTab

            if file.type is 'document' and extension is 'html'
                # Create DOM from content

                jsdom.env(
                    html: "<html><body>#{opts.content}</body></html>"
                    features:
                        QuerySelector: true
                    done: (err, window) ->
                        return next(err) if err

                        el = window.document.querySelectorAll(
                            'code pre, pre code, .highlight'
                        )

                        return next() if el.length is 0

                        tasks = new balUtil.Group (err) ->
                            return next(err) if err

                            opts.content = window.document.body.innerHTML

                            return next()

                        tasks.total = el.length

                        for element in el
                            highlight(
                                window,
                                element,
                                replaceTab,
                                tasks.completer()
                            )

                        # Success
                        true
                )
            else
                return next()
