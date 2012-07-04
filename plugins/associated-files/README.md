# Associated Files Plugin

This plugin streamlines finding associated files for a particular document, which is useful for:
- getting images for a gallery
- getting downloads for an article
- etc. etc.

The way it works is by looking into `src/files/associated-files/#{document.associatedFilesDirectory or document.basename}` for files. Where `associatedFilesDirectory` is set in your document's meta data, and if it doesn't exist it will use the document's basename (e.g. the basename of `my-holiday-2012.html.eco` is `my-holiday-2012`). Any files inside that path will be associated to your document, and retrieveable by `@getDocument().getAssociatedFiles()`

Lets see how this works, we have the document `src/documents/my-holiday-2012.html.eco`:

``` html
---
title: My Holiday in 2012
---

<h2>Here are some great photos from our trip</h2>

<% for file in @getDocument().getAssociatedFiles(): %>
<p>
	<h3><%= file.title or file.name %></h3>
	<img src="<%= file.url %>" title="<%= file.title or file.name %>" />
</p>
<% end %>
```

Then we will stick a few images inside our path: `src/files/associated-files/my-holiday-2012`. And we'll end up with the rendered result:

``` html
<h2>Here are some great photos from our trip</h2>

<p>
	<h3>sweet-sweet-beach.jpg</h3>
	<img src="/associated-files/my-holiday-2012/sweet-sweet-beach.jpg" title="sweet-sweet-beach.jpg" />
</p>

<p>
	<h3>sweet-sweet-icecream.jpg</h3>
	<img src="/associated-files/my-holiday-2012/sweet-sweet-icecream.jpg" title="sweet-sweet-icecream.jpg" />
</p>
```

Ins't that cool?



## Install
Inside your DocPad project's directory, run the following:

``` bash
npm install docpad-plugin-associated-files --save
```



## History
You can discover the history inside the `History.md` file


## License
Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)

## Contributors
- [Benjamin Lupton](http://balupton.com)
- [Morgan Sutherland](http://msutherl.net)
