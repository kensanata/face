# Random Faces

This application goes through the files in the [elements](elements)
folder and picks out one of each for every element of a face.
Currently we're using the following elements:

* eyes
* nose
* mouth (includes beard, I guess?)
* hair (includes headwear, I guess?)

We ought to add ears, I guess.

We're using simple string matching, here. So, anything with "eyes" in
its filename, can be used. The images are more or less 370 × 470
pixels. I got that by scanning images that were about 3.2 × 4.0 cm.

The images have an alpha channel but I'm not sure how this is supposed
to work. Right now I'm telling the app to use white as the transparent
color.

Take a look at the
[scanned image](https://www.flickr.com/photos/kensanata/20972514994/in/dateposted/).
I cleaned that up by changing the scan's image mode from RGB to
"indexed" and providing my own palette of three colors: white, blue,
dark blue. I created this palette using the Palette Editor and simply
sampling two shades of blue from my paper.
