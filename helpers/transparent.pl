#!/usr/bin/env perl
use strict;
use warnings;
use GD;

if (not @ARGV) {
  die "Call this script with a bunch of PNG files\n";
}

for my $file (@ARGV) {

  my $image = GD::Image->new($file);

  if (not $image) {
    warn "$file is not a valid PNG image\n";
    next;
  }

  if ($image->transparent() != -1) {
    warn "$file has a transparent color\n";
    next;
  }
}
