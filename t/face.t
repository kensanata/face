#!/usr/bin/env perl

# Copyright (C) 2015 Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

use Test::More;
use Test::Mojo;
use FindBin;
use GD;
use strict;
use warnings;

# Fix path for 'perl t/face.t'
$ENV{MOJO_HOME} = "$FindBin::Bin/..";
require "$FindBin::Bin/../face.pl";

my $t = Test::Mojo->new;

sub png_images_ok {
  my $images = shift;

  for my $image (@$images) {
    
    my $url = $image->attr('src');
    
    $t->get_ok($url)
	->status_is(200)
	->header_is('Content-Type' => 'image/png');
    
  }
}

$t->app->mode('production');

$t->get_ok('/')
    ->status_is(200)
    ->text_is('h1' => 'Faces for your RPG Characters')
    # alex
    ->element_exists('li a[href="/view/alex/all"]')
    # but not debugging alex
    ->element_exists_not('li a[href="/debug/alex"]');

$t->app->mode('development');

$t->get_ok('/')
    # debugging alex
    ->element_exists('li a[href="/debug/alex"]');

$t->get_ok('/view')
    ->status_is(302)
    ->header_is(Location => '/view/alex/all');

 ARTIST:
    for my $artist (qw(alex)) {
      for my $type (qw(all man woman elf)) {
	
	$t->get_ok("/view/$artist/$type")
	    ->status_is(200)
	    ->text_is('h1' => "Random Face ($artist/$type)")
	    # Gallery
	    ->element_exists("a[href='/gallery/$artist/$type']")
	    # For demonstration purposes...
	    ->element_exists("a[href='/random/$artist/$type']")
	    # The image link itself
	    ->element_exists("a img[src^='/face/$artist/']");
	
	my $url = $t->tx->res->dom->at('img')->attr('src');
	
	$t->get_ok($url)
	    ->status_is(200)
	    ->header_is('Content-Type' => 'image/png');
	
	$t->get_ok("/gallery/$artist/$type")
	    ->status_is(200)
	    ->text_is('h1' => "Face Gallery ($artist/$type)");
	
	png_images_ok($t->tx->res->dom->find('img'));
	
	if ($ENV{QUICK_TEST}) {
	  diag "Skipping some tests because QUICK_TEST ist set";
	  last ARTIST;
	}
      }
}

$t->get_ok('/debug/alex')
    ->status_is(200);

for my $element (all_elements()) {
  $t->element_exists("li a[href='/debug/alex/$element']");
}

if ($ENV{QUICK_TEST}) {
  diag "Skipping some tests because QUICK_TEST ist set";
} else {
  for my $element (all_elements()) {
    
    $t->get_ok("/debug/alex/$element")
	->status_is(200);

    png_images_ok($t->tx->res->dom->find('img'));
  }
}

my $image = GD::Image->new(1, 30);
my $white = $image->colorAllocate(255,255,255);
my $black = $image->colorAllocate(  0,  0,  0);
$image->rectangle(0, 0, $image->getBounds(), $white);
$image->setPixel(0, 20, $black);

my $home = $ENV{MOJO_HOME}; # set at the top
my $file = "$home/elements/alex/test_all.png";
open(my $fh, '>:raw', $file);
print $fh $image->png();
close($fh);

$t->get_ok("/debug/alex/test");
my $url = $t->tx->res->dom->at('a.edit')->attr('href');
$t->get_ok($url)
    ->status_is(200)
    ->element_exists("area[alt='Move up']")
    ->element_exists("area[alt='Move down']");

my $up = $t->tx->res->dom->at("area[alt='Move up']")->attr('href');
my $down = $t->tx->res->dom->at("area[alt='Move down']")->attr('href');

png_images_ok($t->tx->res->dom->find('img'));

$t->get_ok($up)
    ->status_is(200);

my $y;

$image = GD::Image->new($file);

for ($y = 0;
     $image->getPixel(0, $y) eq $white
     && $y < $image->height - 1;
     $y++) {};

is($y, 10, "Black dot moved up");

$t->get_ok($down)
    ->status_is(200);

$image = GD::Image->new($file);

for ($y = 0;
     $image->getPixel(0, $y) eq $white
     && $y < $image->height - 1;
     $y++) {};

is($y, 20, "Black dot moved down");

unlink($file);

done_testing();
