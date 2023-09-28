#! /usr/bin/env perl
use Modern::Perl;
use File::Slurper qw(write_binary);
use GD;

my $file = shift;
my $artist = shift;
die "Usage: $0 scan.png artist type [types...]" unless $artist;
my $image;
$image = GD::Image->newFromPng($file, 1) if $file =~ /\.png$/i;
$image = GD::Image->newFromJpeg($file, 1) if $file =~ /\.jpe?g$/i;
die "Cannot read image from $file: $!" unless $image;

# assuming 300dpi, looking at 1.5in x 2.0in images

sub process {
  my @types = @_;
  my $type;
  for my $y (0..4) {
    last if 600 * ($y + 1) > $image->height;
    $type = shift(@types) || $type || die "You must provide at least one type ('eyes', 'nose', etc.)\n";
    for my $x (0..4) {
      last if 450 * ($x + 1) > $image->width;
      my $element = new GD::Image(450,600);
      $element->copy($image, 0, 0, 450 * $x, 600 * $y, 450, 600);
      my $c = 1;
      $c++ while -f "share/$artist/${type}_$c.png";
      write_binary("share/$artist/${type}_$c.png", $element->png);
    }
  }
}

process(@ARGV);
