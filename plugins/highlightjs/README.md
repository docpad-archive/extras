# Highlight.js Plugin for DocPad
This plugin enables [Highlight.js](https://github.com/isagalaev/highlight.js) syntax highlighting for [DocPad](https://github.com/bevry/docpad)

## Install

```
npm install --save docpad-plugin-highlightjs
```

## Configure
### Replacing Tabs
By default, this plugin does not expand `\t` characters to any number of spaces, etc.
This can be changed in a website's `docpad.conf` by adding something similar to the following:
``` coffeescript
plugins:
      highlightjs:
		replaceTab: '    '
}
```
This will replace all `\t` characters to 4 spaces.

## History
You can discover the history inside the `History.md` file

## Special Thanks to
- Benjamin Lupton for [DocPad](https://github.com/bevry/docpad) and the [Pygments plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/pygments), after which the code for this plugin is modeled
- Ivan Sagalaev and contributors for [Highlight.js](https://github.com/isagalaev/highlight.js), which this plugin relies on for syntax highlighting

## License
Licensed under the [MIT License](http://creativecommons.org/licenses/MIT)

Copyright (c) 2012 Chase Colman

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

**THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.**