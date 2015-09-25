use GD;
use strict;
use warnings;

sub line_is_white {
  my ($image, $y, $white) = @_;
  my $count = 0;
  for (my $x = 0; $x < $image->width -1; $x++) {
    my $index = $image->getPixel($x, $y);
    $count++ if $index != $white;
    return '' if $count > 5;
  }
  return 1;
}

sub main {
 FILE:
  for my $f (@ARGV) {
    my $image = GD::Image->new($f);
    my $white = $image->colorClosest(255,255,255);
    for (my $y = $image->height - 1; $y > 0; $y--) {
      if (not line_is_white($image, $y, $white)) {
	print "$f: $y\n";
	next FILE;
      }
    }
    print "$f is totally white!?\n";
  }
}

main();
