module.exports = (BasePlugin) ->

    html5 = require 'html5'
    jsdom = require 'jsdom'
    balUtil = require 'bal-util'
    hljs = require 'highlight.js'

    highlight = (doc, el, replaceTab, next) ->
        parentEl = el
        childEl = el
        language = null

        elIsPreOrCode = el.tagName.toLowerCase() in ['pre', 'code']

        # In a child element?
        if el.hasChildNodes() and
            el.childNodes[0].tagName and
            el.childNodes[0].tagName.toLowerCase() in ['pre', 'code']
                childEl = el.childNodes[0]

        # In a parent element?
        else if el.parentNode and
            el.parentNode.tagName and
            el.parentNode.tagName.toLowerCase() in ['pre', 'code']
                parentEl = el.parentNode

        # Next if already highlighted
        return next() if /highlighted/.test(parentEl.className)

        # Try to convert Marked-style class names
        if childEl.className
            childEl.className =
                childEl.className.replace(/(\s*)lang-(\S+)(\s*)/,
                                          "$1language-$2$3")

        if parentEl.className
            parentEl.className =
                parentEl.className.replace(/(\s*)lang-(\S+)(\s*)/,
                                          "$1language-$2$3")

        if el.className
            el.className =
                el.className.replace(/(\s*)lang-(\S+)(\s*)/,
                                          "$1language-$2$3")

        # Try to convert the language to a class name
        language = childEl.getAttribute('lang') or
            parentEl.getAttribute('lang') or
            el.getAttribute('lang')

        childEl.removeAttribute('lang')
        parentEl.removeAttribute('lang')
        el.removeAttribute('lang')

        if language
            # Trim language
            language = language.replace(/^\s+|\s+$/g, '')

            if hljs.LANGUAGES[language]
                if elIsPreOrCode
                    if childEl.className
                        childEl.className += " language-#{language}"
                    else
                        childEl.className = "language-#{language}"
                else
                    if el.className
                        el.className += " language-#{language}"
                    else
                        el.className = "language-#{language}"


        # Unfortunately, Highlight.js uses the document global in a closure
        _document = global.document
        global.document = doc

        hljs.highlightBlock(`elIsPreOrCode ? childEl : el`, replaceTab)

        childEl.removeAttribute('lang')
        parentEl.removeAttribute('lang')
        el.removeAttribute('lang')

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

                doc = jsdom.jsdom(
                    opts.content, null,
                    {
                        parser: html5
                        features:
                            QuerySelector: true
                            MutationEvents: false
                    })

                el = doc.querySelectorAll 'code pre, pre code, .highlight'

                return next() if el.length is 0

                tasks = new balUtil.Group (err) ->
                    return next(err) if err

                    opts.content = doc.innerHTML


                    return next()

                tasks.total = el.length

                for element in el
                    highlight doc, element, replaceTab, tasks.completer()

                # Success
                true
            else
                return next()
