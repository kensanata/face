#!/usr/bin/env perl
use strict;
use warnings;
use GD;

if (not @ARGV) {
  die "Call this script with a bunch of PNG files\n";
}

 FILE:
    for my $file (@ARGV) {
      my $image = GD::Image->newFromPng($file,1);

      if (not $image) {
	warn "$file is not a valid PNG image\n";
	next;
      }

      my $limit = $image->height * $image->width;
      my $color1;
      for (my $y = 0; $y < $image->height - 1; $y++) {
	for (my $x = 0; $x < $image->width -1; $x++) {
	  my $index = $image->getPixel($x, $y);
	  if (not defined $color1) {
	    $color1 = $index;
	  } elsif ($color1 != $index) {
	    next FILE;
	  }
	}
      }
      print "$file\n";
}
