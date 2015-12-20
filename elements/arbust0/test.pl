#!/bin/env perl
use strict;
use warnings;
use GD;

my $image = GD::Image->newFromPng("face_all_001.png",1);
$image->alphaBlending(1);
$image->saveAlpha(1);
my $layer = GD::Image->newFromPng("eyes_all_004.png", 1);
$image->copy($layer, 0, 0, 0, 0, $layer->width, $layer->height);
open(my $fh, '>', 'result.png') or die;
binmode($fh);
print $fh $image->png(9);
close($fh);
