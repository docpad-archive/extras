# Highlight.js Plugin for DocPad
This plugin enables [Highlight.js](https://github.com/isagalaev/highlight.js) syntax highlighting for [DocPad](https://docpad.org)

## Install

```
npm install --save docpad-plugin-highlightjs
```

## Configure
### Replacing Tabs
By default, this plugin does not expand `\t` characters to any number of spaces, etc.
This can be changed in your [DocPad configuration file](https://github.com/bevry/docpad/wiki/Configuration) by adding something similar to the following:
``` coffee
plugins:
    highlightjs:
        replaceTab: '    '
}
```
This will replace all `\t` characters to 4 spaces.

### Filtering Source Code
#### Using Functions
Sometimes the source code in files is not ready to be parsed for highlighting and requires an extra step, like removing extra indentation.
For situations like this, you can use a function like the following:
``` coffee
# balUtil = require('bal-util')
# ...
plugins:
    sourceFilter: (source, language) ->
        balUtil.removeIndentation(source)  if language in ['bash','coffee']
}
```
This will remove extra indentation if the language of the source code being highlighted is either `bash` or `coffeescript`

#### Using Arrays (and Regular Expressions)
You can also use an array for filtering source code. The first item of the array is the criteria to be matched and must be a **regular expression** *or* a **string**. The second item of the array is the **string** that will replace what matches.

For example:
``` coffee

plugins:
    sourceFilter: [/\(C\)/gm,"&copy;"]
}
```
This will replace all instances of `\(C\)` with `&copy;` on every line of code using a regular expression. *Using this array is equivalent to using* `.replace(/\(C\)/gm,"&copy;")` *on the source code.*

## History
You can discover the history inside the `History.md` file

## Special Thanks to
- Benjamin Lupton for [DocPad](https://docpad.org) and the [Pygments plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/pygments), after which the code for this plugin was modeled
- Ivan Sagalaev and contributors for [Highlight.js](https://github.com/isagalaev/highlight.js), which this plugin relies on for syntax highlighting


## License
Licensed under the incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Chase Colman](http://thedev.infinityatlas.com)
