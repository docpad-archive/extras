# Highlight.js Plugin for DocPad
This plugin enables [Highlight.js](https://github.com/isagalaev/highlight.js) syntax highlighting for [DocPad](https://github.com/bevry/docpad)

## Install

```
npm install --save docpad-plugin-highlightjs
```

## Configure
### Disabled by Default
Like the [Pygments Plugin for DocPad](https://github.com/bevry/docpad-extras/tree/master/plugins/pygments) this plugin is disabled by default. (not everyone automatically wants syntax highlighting, or they aren't sure if they prefer [Pygments](http://pygments.org/)); to enable it, add the following to your website's `package.json` file:
      ``` javascript
      "docpad": {
              "enabledPlugins": {
                      "highlightjs": true
              }
      }
      ```

## History
You can discover the histroy inside the `History.md` file

## License
Licensed under the [MIT License](http://creativecommons.org/licenses/MIT)

Copyright (c) 2012 Chase Colman

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

**THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.**