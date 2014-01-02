# CraftStudio.js

## Model Viewer

The model viewer can be embedded into any HTML page as an iframe, like so:

```html
<iframe src="viewer.html?model=PATH_TO_MODEL&animation=PATH_TO_ANIMATION&bgColor=HEX_COLOR&ssao=BOOLEAN" width="WIDTH" height="HEIGHT" seamless />
```

All arguments are optional except for ```model```. The paths to the model and animation shouldn't include the extension.

To export models from [CraftStudio](http://craftstud.io/) for use with CraftStudio.js, use the following commands in the model editor:

 * ```/export json model``` to export the model in JSON format
 * ```/export texture``` to export the texture (name it the same as the model file and place it in the same folder)
 * ```/export json animation``` to export the currently active animation