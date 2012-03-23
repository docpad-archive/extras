# docpad-images

docpad plugin

## Usage

Give your documents a 'name' meta-data item.

~~~
---
title: Yay! 
template: default
name: yay
___

# Yay
~~~

This is now accessible as <code>@document.name</code> in templates or <code>file.name</code> in the plugin.

In a template (example in Coffeekup):

~~~
body ->
	div class: 'example', ->
		for image in @document.images
			img src: document.url, -> document.title
~~~

Renders to:

~~~
<body>
	<div class="example">
		<img src="/images/img1.jpg"><img src="/images/img2.jpg">< ... etc.
	</div>
</body>
~~~
