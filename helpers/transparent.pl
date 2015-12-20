#!/usr/bin/env perl
use strict;
use warnings;
use GD;

if (not @ARGV) {
  die "Call this script with a bunch of PNG files\n";
}

for my $file (@ARGV) {

  my $image = GD::Image->newFromPng($file, 1);

  if (not $image) {
    warn "$file is not a valid PNG image\n";
    next;
  }

  warn "$file is true color\n" if $image->isTrueColor;

  warn "$file has a transparent color\n" if $image->transparent() != -1;
}
