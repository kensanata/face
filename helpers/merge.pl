#! /usr/bin/env perl
use Modern::Perl;
use GD;

my $one = shift;
my $two = shift;
my $target = shift;
die "Usage: $0 one two three\nMerges ONE and TWO into THREE\n" unless $target;

my $image;
$image = GD::Image->newFromPng($one) if $one =~ /\.png$/i;
$image = GD::Image->newFromJpeg($one) if $one =~ /\.jpe?g$/i;
die "Cannot read image $one: $!" unless $image;

my $layer;
$layer = GD::Image->newFromPng($two) if $one =~ /\.png$/i;
$layer = GD::Image->newFromJpeg($two) if $one =~ /\.jpe?g$/i;
die "Cannot read image $one: $!" unless $layer;

if ($layer->isTrueColor == 0 and $layer->transparent == -1) {
  my $white = $layer->colorClosest(255,255,255);
  $layer->transparent($white);
}

$image->alphaBlending(1);
$image->saveAlpha(1);
$image->copy($layer, 0, 0, 0, 0, $layer->getBounds());

open(my $fh, '>:raw', $target) or die "Cannot write $target: $!";
print $fh $image->png();
close($fh);

say "Wrote $target";
