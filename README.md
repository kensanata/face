# Random Faces

This application goes through the files in the [elements](elements)
folder and picks out one of each for every element of a face.
Currently we're using the following elements:

* eyes
* nose
* mouth (includes beard, I guess?)
* hair (includes headwear, I guess?)

We ought to add ears and chin (and more beard), I guess. I'm not sure
we need much else?

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

# Adding Elements

Print out a copy of the [empty PDF](empty.pdf) with those egg-heads.
Use a blue fountain pen to draw a row of eyes, a row of noses, a row
of mouths (maybe with mustaches), a row of hair (maybe with hats), and
a row of ears or chins (maybe with beards).

1. Scan the image and crop it using [The Gimp](http://www.gimp.org/)
   or whatever else you feel comfortable with.

2. Cut the image into elements using [cutter.pl](cutter.pl).

3. Clean up the files by using a three color palette [TODO].
