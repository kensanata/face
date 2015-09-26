#! /usr/bin/env perl
use strict;
use warnings;
use GD;

my $file = shift;
my $artist = shift;
die "Usage: $0 scan.png artist type [types...]" unless $artist;
my $image;
$image = GD::Image->newFromPng($file) if $file =~ /\.png$/i;
$image = GD::Image->newFromJpeg($file) if $file =~ /\.jpe?g$/i;
die "Cannot read image from $file: $!" unless $image;

# assuming 300dpi, looking at 1.5in x 2.0in images
my $type;
for my $y (0..4) {
  $type = shift || $type || die "Must provide five types ('eyes', 'nose', etc.)\n";
  for my $x (0..4) {
    my $element = new GD::Image(450,600);
    $element->copy($image, 0, 0, 450 * $x, 600 * $y, 450, 600);
    my $c = 1;
    $c++ while -f "elements/$artist/${type}_$c.png";
    open (my $fh, '>', "elements/$artist/${type}_$c.png")
	or die "Cannot write elements/$artist/${type}_$c.png: $!";
    binmode $fh;
    print $fh $element->png;
    close $fh;
  }
}
