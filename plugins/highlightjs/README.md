# Highlight.js Plugin for DocPad
This plugin enables [Highlight.js](https://github.com/isagalaev/highlight.js) syntax highlighting for [DocPad](https://docpad.org)

## Install

```
npm install --save docpad-plugin-highlightjs
```

## Configure
### Replacing Tabs
By default, this plugin does not expand `\t` characters to any number of spaces, etc.
This can be changed in your [docpad configuration file](https://github.com/bevry/docpad/wiki/Configuration) by adding something similar to the following:
``` coffee
plugins:
	highlightjs:
		replaceTab: '    '
}
```
This will replace all `\t` characters to 4 spaces.

## History
You can discover the history inside the `History.md` file

## Special Thanks to
- Benjamin Lupton for [DocPad](https://docpad.org) and the [Pygments plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/pygments), after which the code for this plugin is modeled
- Ivan Sagalaev and contributors for [Highlight.js](https://github.com/isagalaev/highlight.js), which this plugin relies on for syntax highlighting


## License
Licensed under the incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Chase Colman](http://thedev.infinityatlas.com)
