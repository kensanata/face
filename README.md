# Random Faces

This application goes through the files in the [elements](elements)
folder and picks out one of each for every *element* of a face:

* eyes
* nose
* ears
* mouth
* chin
* hair
* extra (only 10% of all faces)

We also want to allow filtering by *type*.

* woman
* man
* elf
* dwarf

We're depending on a simple file name format:
`element_type_stuff.png`, such as `ears_elf_2.png`.

If we're requesting an element of a particular type and no such
element exists, we'll take any element with type "all". Thus, if we're
going to request elf ears, we'll get `ears_elf_2.png`. If we request
dwarf ears and there are no special dwarf ears, we might get
`ears_all_1.png`, for example.

If we're don't determine a type, this is equivalent to asking for the
"all" type. We might get `ears_all_1.png` but we won't get
`ears_elf_2.png`.

This results in a problem when adding a type when there was none. At
first, we just had `hair_all_*.png`. Then we decided that here was a
hairdo for a woman and created `hair_woman_3.png`. From now on, the
"all" type will no longer be considered for women. You could use a
symbolic link called `hair_woman_1.png` for `hair_all_1.png` or you
could rename `hair_all_1.png` to hair_all_woman_1.png`.

# Adding Elements

Check out [How to Draw a Face](http://www.wikihow.com/Draw-a-Face) or
a similar resource.

1. Print out a copy of the [empty PDF](empty.pdf) with those
   egg-heads. Do not scale to fit! Use a scale of 100%. This PDF has
   some helping guidelines to make sure all the elements are more or
   less in the right place. The smaller horizontal lines are for the
   tip of the nose and the bottom of the mouth. See the
   [example](example.png).

2. Use a blue fountain pen to draw a row of eyes, a row of noses, a
   row of mouths (maybe with mustaches), a row of hair (maybe with
   hats), and a row of ears or chins (maybe with beards).

3. Scan the image and crop it using [The Gimp](http://www.gimp.org/)
   or whatever else you feel comfortable with. Cropping is important.
   The result should be an image more or less 5 × 450 = 2250 pixels
   wide and 5 × 600 = 3000 pixels high. Rescale the image if
   necessary. Examples
   [by Alex](https://www.flickr.com/photos/kensanata/21419974480/in/dateposted/)
   and
   [by Claudia](https://www.flickr.com/photos/kensanata/21419975330/in/photostream/).

4. Clean up the image using [ImageMagick](http://www.imagemagick.org/)
   and the following command line: `convert -blur 0x1 +dither -remap
   tintenblau.png scan1.jpg source1.png` – this forces the image to
   use the [Tintenblau](tintenblau.png) Palette (and loses the grid).
   We're also moving from JPG (which is what your scanner probably
   produced) to PNG. Don't worry about transparency: *white* is
   considered to be *transparent* when merging the various elements.

5. Cut the image into elements using [cutter.pl](cutter.pl). It cuts
   the scan into 5 × 5 images of 450 × 600 pixels each and labels them
   by row. You'd invoke it as follows: `perl cutter.pl source1.png
   eyes nose mouth hair chin` or `perl cutter.pl source2.png eyes nose
   mouth hair ears`. If the remaining rows are all the same type, you
   don't need to repeat it. Thus, if you've drawn a sheet full of
   eyes, just use `perl cutter.pl source4.png eyes` and you're good.

6. If you think that some of your samples are specific to a particular
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

# Moving stuff around

If it turns out that you scanned a bunch of elements and they're all
shifted by some amount, you can use the command line to make your life
easier. Here is what I used to shift some old eye elements down by 35
pixels:

```
for n in `seq 34`; do
  convert -page +0+35 -background white -flatten elements/eyes_all_$n.png eyes_all_$n.png
done
```
