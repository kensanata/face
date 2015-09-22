# Random Faces

This application goes through the files in the [elements](elements)
folder and picks out one of each for every element of a face.
Currently we're using the following elements:

* eyes
* nose
* ears
* mouth
* chin
* hair

We're using simple string matching, here. So, anything with "eyes" in
its filename, can be used. The images are more or less 370 × 470
pixels. I got that by scanning images that were about 3.2 × 4.0 cm.

The images have an alpha channel but I'm not sure how this is supposed
to work. Right now I'm telling the app to use white as the transparent
color.

# Adding Elements

Print out a copy of the [empty PDF](empty.pdf) with those egg-heads.
Use a blue fountain pen to draw a row of eyes, a row of noses, a row
of mouths (maybe with mustaches), a row of hair (maybe with hats), and
a row of ears or chins (maybe with beards).

1. Scan the image and crop it using [The Gimp](http://www.gimp.org/)
   or whatever else you feel comfortable with. Cropping is important.
   The result should be an image more or less 5 × 450 = 2250 pixels
   wide and 5 × 600 = 3000 pixels high. Examples
   [by Alex](https://www.flickr.com/photos/kensanata/21419974480/in/dateposted/)
   and
   [by Claudia](https://www.flickr.com/photos/kensanata/21419975330/in/photostream/).

2. Clean up the image using [ImageMagick](http://www.imagemagick.org/)
   and the following command line: `convert -blur 0x1 +dither -remap
   tintenblau.png scan1.jpg source1.png` – this forces the image to
   use the [Tintenblau](tintenblau.png) Palette (and loses the grid).

3. Cut the image into elements using [cutter.pl](cutter.pl). It cuts
   the scan into 5 × 5 images of 450 × 600 pixels each and labels them
   by row. You'd invoke it as follows: `perl cutter.pl source1.png
   eyes nose mouth hair chin` or `perl cutter.pl source2.png eyes
   nose mouth hair ears`.

4. If you think that some of your samples are specific to a particular
   phenotype, add the type to the filename. If you have a beard, for
   example, rename it from `chin_1.png` to `chin_male_1.png` or if you
   have ears that are fit for elves only, rename it from `ears_2.png`
   to `ears_elf_2.png`.

# Dependencies

The CGI script depends on [Mojolicious](http://mojolicio.us/) (perhaps
this is too old: `sudo apt-get install libmojolicious-perl` – I used
`cpan Mojolicious` instead). Cutter depends on
[GD](https://metacpan.org/pod/GD) (`sudo apt-get install
libgd-gd2-perl`). The clean up instructions depend on
[ImageMagick](http://www.imagemagick.org/) (`sudo apt-get install
imagemagick`).
