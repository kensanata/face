use GD;
use strict;
use warnings;

sub main {
 FILE:
  for my $f (@ARGV) {
    my $image = GD::Image->new($f);
    my $white = $image->colorClosest(255,255,255);
    my $limit = $image->height * $image->width * 0.1;
    my $n = 0;
    for (my $y = 0; $y < $image->height - 1; $y++) {
      for (my $x = 0; $x < $image->width -1; $x++) {
	my $index = $image->getPixel($x, $y);
	$n++ if $index != $white;
	if ($n > $limit) {
	  print "$f has more than 10% non-white pixels!\n";
	  next FILE;
	}
      }
    }
  }
}

print "Usage: perl non-white.pl *.png\n" unless @ARGV;

main();
