## History
- v0.1.3 September 8, 2012
  - Fixed the document loop error which occurred when processing documents not
    containing code
  - Fixed the handling of [the new default Marked plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/markdown)

- v0.1.2 August 25, 2012
  - Changed to the HTML5 parser because jsdom's default HTML parser occasionally failed on the provided tests
  - Better handle [the default Markdown plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/markdown)'s HTML output
  	- Languages like Coffeescript get butchered in fenced code because it doesn't continue the code block properly

- v0.1.1 August 23, 2012
  - If an unrecognized language tag is used, the plugin falls back to
    Highlight.js's autodetection feature
  - Tests!

- v0.1.0 August 21, 2012
  - The [Highlight.js](https://github.com/isagalaev/highlight.js) Syntax
    Highlighting Plugin is Created
