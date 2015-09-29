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

  ok($images, "images provided by " . $t->tx->req->url);
  
  for my $image (@$images) {
    
    my $url = $image->attr('src');
    
    $t->get_ok($url)
	->status_is(200)
	->header_is('Content-Type' => 'image/png');
  }
}

$t->get_ok('/')
    ->status_is(302)
    ->header_is(Location => '/face');

$t->get_ok('/face')
    ->status_is(200)
    ->text_is('h1' => 'Faces for your RPG Characters')
    # alex
    ->element_exists('li a[href="/face/view/alex/woman"]')
    # but not debugging alex
    ->element_exists_not('li a[href="/face/debug/alex"]');

# set up an account in the config file
$t->app->config('users')->{alex} = '*secret*';

# failed login to access debug mode
$t->post_ok('/face/login' => form =>  {
  username => 'alex',
  password => 'fnork' })
    ->status_is(200)
    ->content_like(qr/login failed/i)
    ->element_exists_not('li a[href="/face/debug/alex"]');

# successful login redirects to the main page
$t->post_ok('/face/login' => form =>  {
  username => 'alex',
  password => '*secret*' })
    ->status_is(302)
    ->header_is(Location => '/face');

# debugging alex works, now
$t->get_ok('/face/')
    ->element_exists('li a[href="/face/debug/alex"]');

$t->get_ok('/face/view')
    ->status_is(302)
    ->header_is(Location => '/face/view/alex/woman');

$t->get_ok('/face/gallery')
    ->status_is(302)
    ->header_is(Location => '/face/gallery/alex/man');

$t->get_ok('/face/gallery/man')
    ->status_is(302)
    ->header_is(Location => '/face/gallery/alex/man');

$t->get_ok('/face/random')
    ->status_is(302)
    ->header_is(Location => '/face/random/alex/woman');

$t->get_ok('/face/random/woman')
    ->status_is(302)
    ->header_is(Location => '/face/random/alex/woman');

$t->get_ok('/face/random/alex/woman')
    ->status_is(200)
    ->header_is('Content-Type' => 'image/png');

 ARTIST:
    for my $artist (qw(alex)) {
      for my $type (qw(all man woman elf)) {
	
	$t->get_ok("/face/view/$artist/$type")
	    ->status_is(200)
	    ->text_is('h1' => "Random Face ($artist/$type)")
	    # Gallery
	    ->element_exists("a[href='/face/gallery/$artist/$type']")
	    # For demonstration purposes...
	    ->element_exists("a[href='/face/random/$artist/$type']")
	    # The image link itself
	    ->element_exists("a img[src^='/face/face/$artist/']");
	
	my $url = $t->tx->res->dom->at('img')->attr('src');
	
	$t->get_ok($url)
	    ->status_is(200)
	    ->header_is('Content-Type' => 'image/png');
	
	$t->get_ok("/face/gallery/$artist/$type")
	    ->status_is(200)
	    ->text_is('h1' => "Face Gallery ($artist/$type)");
	
	png_images_ok($t->tx->res->dom->find('img'));
	
	if ($ENV{QUICK_TEST}) {
	  diag "Skipping some tests because QUICK_TEST ist set";
	  last ARTIST;
	}
      }
}

$t->get_ok('/face/debug/alex')
    ->status_is(200);

for my $element (all_elements()) {
  $t->element_exists("li a[href='/face/debug/alex/$element']");
}

if ($ENV{QUICK_TEST}) {
  diag "Skipping some tests because QUICK_TEST ist set";
} else {
  for my $element (all_elements()) {
    
    $t->get_ok("/face/debug/alex/$element")
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

$t->get_ok("/face/debug/alex/test");
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
