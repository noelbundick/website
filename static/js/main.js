// To make images retina, add a class "2x" to the img element
// and add a <image-name>@2x.png image. Assumes jquery is loaded.
 
function isRetina() {
	var mediaQuery = "(-webkit-min-device-pixel-ratio: 1.5),\
					  (min--moz-device-pixel-ratio: 1.5),\
					  (-o-min-device-pixel-ratio: 3/2),\
					  (min-resolution: 1.5dppx)";
 
	if (window.devicePixelRatio > 1)
		return true;
 
	if (window.matchMedia && window.matchMedia(mediaQuery).matches)
		return true;
 
	return false;
};

function retinizeGravatar(path) {
	var match = path.match(/https:\/\/www.gravatar.com\/avatar\/(.*)?s=(\d+)/);
	if (match) {
		var size = match[2];
		var sizeInt = parseInt(match[2]) || 0;
		if (sizeInt > 0) {
			var newSize = sizeInt * 2;
			var searchValue = "?s=" + match[2];
			var replaceValue = "?s=" + newSize.toString();
			return path.replace(searchValue, replaceValue);
		}
	}

	return path;
}
 
 
function retina() {
	
	if (!isRetina())
		return;
	
	$("img.2x").map(function(i, image) {
		
		var path = $(image).attr("src");
		path = retinizeGravatar(path);
		
		path = path.replace(".png", "@2x.png");
		path = path.replace(".jpg", "@2x.jpg");
		
		$(image).attr("src", path);
	});
};
 
$(document).ready(retina);