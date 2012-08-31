# Markdown Plugin for DocPad
Adds support for the [Markdown](http://daringfireball.net/projects/markdown/) markup language to [DocPad](https://github.com/bevry/docpad)

Convention:  `.html.md|markdown`


## Install

```
npm install --save docpad-plugin-markdown
```

## Options

You can pass marked options. Put followings in your `package.json` of docpad project:

```
...
  "docpad": {
    "plugins": {
      "markdown": {
        "gfm": true,
        "pedantic": false,
        "sanitize": true,
        "highlight": false //for highlighting markdown's code block
      }
    }
...
```

It will override default options (See details on https://github.com/chjj/marked).

### Highlighting

It depends on '[highlight.js](https://github.com/isagalaev/highlight.js)' module. If you want to highlight your site, do following steps:

Turn on highlight feature in your `package.json`:

```
...
  "docpad": {
    "plugins": {
      "markdown": {
        "highlight": true
      }
    }
...
```

Find your style on [test page](http://softwaremaniacs.org/media/soft/highlight/test.html). You can download your [style](https://github.com/isagalaev/highlight.js/tree/master/src/styles).

## History
You can discolver the history inside the `History.md` file


## License
Licensed under the incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)
<br/>Copyright &copy; 2011 [Benjamin Lupton](http://balupton.com)
