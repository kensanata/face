# Random Faces

This application goes through the files in the [elements](elements)
folder for a given artist and picks out one of each for every
*element* of a face.

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
`element_type_stuff.png`, such as `ears_elf_2.png`. Each of these is a
*component* of a particular face.

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
   hats), and a row of ears or chins (maybe with beards). Or just draw
   a sheet with just one element. Fifty components (two sheets) per
   element seems to be a good starting point.

3. Scan the image and crop it using [The Gimp](http://www.gimp.org/)
   or whatever else you feel comfortable with. Cropping is important.
   The result should be an image more or less 5 × 450 = 2250 pixels
   wide and 5 × 600 = 3000 pixels high. Rescale the image if
   necessary. Examples
   [on Flickr](https://www.flickr.com/search/?user_id=80148151%40N00&sort=date-taken-desc&advanced=1&tags=rpg%20face%20generator&view_all=1).

4. Clean up the image using [ImageMagick](http://www.imagemagick.org/)
   and the following command line: `convert -blur 0x1 +dither -remap
   tintenblau.png scan1.jpg source1.png` – this forces the image to
   use the [Tintenblau](tintenblau.png) Palette (and loses the grid).
   We're also moving from JPG (which is what your scanner probably
   produced) to PNG. Don't worry about transparency: *white* is
   considered to be *transparent* when merging the various elements.

5. Cut the image into elements using [cutter.pl](helpers/cutter.pl).
   It cuts the scan into 5 × 5 images of 450 × 600 pixels each and
   labels them by row. You'd invoke it as follows: `perl
   helpers/cutter.pl source1.png alex eyes_all nose_all mouth_all
   hair_all chin_all` or `perl helpers/cutter.pl source2.png alex
   eyes_all nose_all mouth_all hair_all ears_all`. In other words:
   First is the source image, then the artist name, and then you
   provide the element for every row. If the remaining rows are all
   the same element, you don't need to repeat it. Thus, if you've
   drawn a sheet full of eyes, just use `perl helpers/cutter.pl
   source4.png alex eyes_all` and you're good.

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

# Installation

You can simply install it as a CGI script on your web server.

If you want to edit images using the script ("Face Debugging"), you'll
need to add accounts to the config file. You'll have to create this
file. The file must be called `face.conf` and it must reside in the
same directory as `face.pl`, providing **usernames** and
**passwords**. Every artist can have an account.

Session information is stored in an encrypted cookie. The encryption
for the cookie also depends on a secret, so you should also provide a
**secret** with which the cookie will be encrypted.

Here's an example for the config file, `face.conf`:

```
{
  secret => '*a random string*',
  users => {
    'alex' => '*secret*',
    'berta' => '*secret*',
  },
}
```

As the [script](face.pl) is a [Mojolicious](http://mojolicio.us/) app,
there are many other ways to deploy it. There is a
[Cookbook](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#DEPLOYMENT)
with a section on deployment. The following is a quick summary.

This runs the script as a server on
[localhost:3000](http://localhost:3000/):

```
perl face.pl daemon
```

This runs the script as a server on
[localhost:3000](http://localhost:3000/) and reloads it every time you
change it:

```
morbo face.pl
```

This runs the script as a server on port 8080, writing a pid file:

```
hypnotoad face.pl
```

Whenever you repeat this `hypnotoad` command, the server will be
restarted. There's no need to kill it.

You can configure `hypnotoad` to listen on a different port by adding
an additional item to the config file:

```
{
  hypnotoad => {listen => ['http://*:8082'],},
  secret => '*a random string*',
  users => {
    'alex' => '*secret*',
    'berta' => '*secret*',
  },
}
```

# Finding and fixing misaligned elements: the easy way

If you're an artist and you're logged in, the main menu will have a
new item: **Face Debugging**. Follow the link, pick an element type,
view the gallery, pick an element that is misaligned and klick it.
You're now on the Element Edit page. Click on the upper half of the
image to move the element up by ten pixels, click on the lower half of
the image to move the element down by ten pixels.

# Finding and fixing elements: the hard way

I start the script using morbo and visit the gallery URLs with the
debug parameter set to 1:

```
http://localhost:3000/gallery/man?debug=1
```

Then I just reload until I find a face where things are misaligned. I
right-click and pick "Show Graphic". This leads me to a link like the
following:

```
http://localhost:3000/face/alex/empty_all.png,eyes_all_72.png,mouth_all_49.png,chin_man_30.png,ears_all_5.png,nose_all_20.png,hair_man_21.png
```

This shows me which elements were used to create the face I'm looking
at.

If you've found just a single misaligned element, you can change it in
place by providing the same file name twice to
[ImageMagick](http://www.imagemagick.org/):

```
convert -page +0+10 -background white -flatten elements/alex/chin_man_30.png elements/alex/chin_man_30.png
```

If it turns out that you scanned a bunch of elements and they're all
shifted by some amount, you can use the shell to make your life
easier. Here is what I used to shift some old eye elements down by 35
pixels:

```
for n in `seq 34`; do
  convert -page +0+35 -background white -flatten elements/alex/eyes_all_$n.png eyes_all_$n.png
done
```

This will create copies in your current directory. If you're happy,
move them back into the elements folder.

If you need help figuring out by how much you might want to shift
images, you can use [top.pl](helpers/top.pl) and
[bottom.pl](helpers/bottom.pl). They cound how many white lines there
are at the top and at the bottom, respectively.

Example usage:

```
perl helpers/top.pl elements/alex/eyes_all_*
```

# Alternative look

For [my images](elements/alex) I enforced a blue color map because I
was doing my drawings using a blue fountain pen. This is the command
line I used in my example above: `convert -blur 0x1 +dither -remap
tintenblau.png scan1.jpg source1.png`

If you do your drawings using a pencil, you might want to keep the
pencil look. I'll suggest the following command line: `convert -blur
0x1 +dither -level 30%,80% scan1.jpg source1.png`. Like in the
previous example, I used a 1px blur and then I adjusted levels:
anything below 30% is black and anything above 80% is white. It looks
OK. No trace of the helping lines left and it keeps the pencil gray.

If you do your drawings using a pencil but you'd like to give it an
inked look, you migh want to increase the percentage for the black
level. I'll suggest the following comand line: `convert -blur 0x1
+dither -level 50%,80% -grayscale rec709luma scan1.jpg source1.png`.
Now anything below 50% is black. I also converted it to grayscale at
the end because the very light pixles seemed to have random colors.
