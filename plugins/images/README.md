# The Images plugin

This docpad plugin allows you to have per-document images easily accessible from within the document.
It provide access to an array of paths to the images associated with the current document.

## Install

`npm install docpad-plugin-images`

Change pathnames in images.plugin.coffee if you need to and comment out automatic folder creation if you don't want that.

## Dependencies

The Images plugin requires [underscore.js](http://documentcloud.github.com/underscore/). This dependency is automatically handled by npm.

## Usage

1. Create the `src/public/images` folder
2. For each document you see fit, create a corresponding folder in the newly create `images` directory. This folder name should be the `basename` of the document, i.e. the filename without the extensions
3. Place the images you want to use in each folder
4. Access these images through the `@document.images` array

Images that you place in `/src/public/images/[basename]/` will subsequently be accesible to the document with that `basename` during document rendering (i.e. in a template or in a plugin that is triggered after the initial `render` pass).

## Example

Say you have two documents in your docpad installation, `doc1.html.coffee` and `doc2.html.coffee`. Place the `img1.jpg` and `img2.jpg` images in the `/src/public/images/doc1/` folder. These 2 images can then be referenced from `doc1.html.coffee` like this (example in Coffeekup):

~~~
body ->
	div class: 'example', ->
		for image in @document.images
			img src: image
~~~

Renders to:

~~~
<body>
	<div class="example">
		<img src="/images/doc1/img1.jpg"><img src="/images/doc1/img2.jpg">
	</div>
</body>
~~~
