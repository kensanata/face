#! /usr/bin/env perl
use strict;
use warnings;
use GD;

my $file = shift;
die "Usage: $0 scan.png" unless $file;
my $image;
$image = GD::Image->newFromPng($file) if $file =~ /\.png$/i;
$image = GD::Image->newFromJpeg($file) if $file =~ /\.jpe?g$/i;
die "Cannot read image from $file: $!" unless $image;

# assuming 300dpi, looking at 1.5in x 2.0in images
for my $y (0..4) {
  my $type = shift || die "Must provide five types ('eyes', 'nose', etc.)\n";
  for my $x (0..4) {
    my $element = new GD::Image(450,600);
    $element->copy($image, 0, 0, 450 * $x, 600 * $y, 450, 600);
    my $c = 1;
    $c++ while -f "elements/${type}_$c.png";
    open (my $fh, '>', "elements/${type}_$c.png")
	or die "Cannot write elements/${type}_$c.png: $!";
    binmode $fh;
    print $fh $element->png;
    close $fh;
  }
}

