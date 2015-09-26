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

use Mojolicious::Lite;
use Mojo::ByteStream;
use Mojo::Home;
use GD;

app->config(hypnotoad => {listen => ['http://*:8082'],});

# Directories to look for dictionaries.
# Earlier directories have precedence.
my $home = Mojo::Home->new;
$home->detect;

get '/' => sub {
  my $self = shift;
  $self->render(template => 'index',
		artists => all_artists());
} => 'main';

get '/view' => sub {
  my $self = shift;
  $self->redirect_to(view => {artist => 'alex', type => 'all'});
};

get '/view/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  $self->render(template => 'view',
		type => $type,
		components => join(',', random_components($type, $artist)));
} => 'view';

get '/gallery' => sub {
  my $self = shift;
  $self->redirect_to(gallery => {artist => 'alex', type => 'man'});
};

get '/gallery/:type' => sub {
  my $self = shift;
  my $type = $self->param('type');
  $self->redirect_to(gallery => {artist => 'alex', type => $type});
};

get '/gallery/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  $self->render(template => 'gallery',
		type => $type,
		components => join(';', map {
		  join(',', random_components($type, $artist, $self->param('debug')));
				   } 1..10));
} => 'gallery';

get '/random' => sub {
  my $self = shift;
  $self->redirect_to(random => {artist => 'alex', type => 'woman'});
};

get '/random/:type' => sub {
  my $self = shift;
  my $type = $self->param('type');
  $self->redirect_to(random => {artist => 'alex', type => $type});
};

get '/random/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  $self->render(format => 'png',
		data => render_components(
		  $artist,
		  random_components(
		    $type, $artist)));
} => 'random';

get '/face/#files' => sub {
  my $self = shift;
  my $files = $self->param('files');
  $self->redirect_to(face => {artist => 'alex', files => $files});
};

get '/face/:artist/#files' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $files = $self->param('files');
  $self->render(format => 'png',
		data => render_components(
		  $artist,
		  split(',', $files)));
} => 'face';

get '/debug' => sub {
  my $self = shift;
  $self->render(template => 'debug',
		elements => join(',', all_elements()));
};

get '/debug/:artist' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  $self->render(template => 'debug',
		artist => $artist,
		elements => join(',', all_elements()));
};

get '/debug/:artist/:element' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $element = $self->param('element');
  $self->render(template => 'debugelement',
		artist => $artist,
		element => $element,
		components => join(';', all_components($artist, $element)));
};

get '/edit/:artist/#component' => sub {
  my $self = shift;
  my $component = $self->param('component');
  $self->render(template => 'edit',
		components => "empty_all.png,$component");
} => 'edit';

get '/move/:artist/#component/:dir' => sub {
  my $self = shift;
  die unless $self->app->mode eq 'development';
  my $artist = $self->param('artist');
  my $component = $self->param('component');
  my $dir = $self->param('dir');
  move($artist, $component, $dir);
  $self->render(template => 'edit',
		components => "empty_all.png,$component");
} => 'move';

app->mode('production') if $ENV{GATEWAY_INTERFACE};

app->start;

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

sub all_artists {
  opendir(my $dh, "$home/elements") || die "Can't open elements: $!";
  my @dirs = grep {
    !/\.png$/ # ignore images
	&& substr($_, 0, 1) ne '.' # ignore "." and ".." and other "hidden files"
	&& -d "$home/elements/$_"
  } readdir($dh);
  closedir $dh;
  return @dirs;
}

sub all_components {
  my ($artist, $element) = @_;
  opendir(my $dh, "$home/elements/$artist") || die "Can't open $home/elements/$artist: $!";
  my @files = grep { /$element.*\.png$/ } readdir($dh);
  closedir $dh;
  my @components = map { "empty_all.png,$_" } @files;
  return @components;
}

sub all_elements {
  return qw(eyes mouth chin ears nose hair);
}

sub random_components {
  my ($type, $artist, $debug) = @_;
  $type ||= 'all';
  # chin after mouth (mustache hides mouth)
  # nose after chin (mustache!)
  # hair after ears
  # ears after chin
  my @elements = all_elements();
  unshift(@elements, 'empty') if $debug;
  push(@elements, 'extra') if rand(1) < 0.1; # 10% chance
  opendir(my $dh, "$home/elements/$artist") || die "Can't open elements: $!";
  my @files = grep { /\.png$/ } readdir($dh);
  closedir $dh;
  my @components = map {
    my $element = $_; # inside grep $_ points to a file
    my @candidates1 = grep(/^${element}_/, @files);
    my @candidates2 = grep(/_${type}/, @candidates1) if $type;
    @candidates2 = grep(/_all/, @candidates1) unless @candidates2;
    one(@candidates2) || '';
  } @elements;
  return @components;
}

sub render_components {
  my ($artist, @components) = @_;
  my $image = GD::Image->new(450, 600);
  my $white = $image->colorAllocate(255,255,255); # find white
  $image->rectangle(0, 0, $image->getBounds(), $white);
  for my $component (@components) {
    next unless $component;
    my $layer = GD::Image->new("$home/elements/$artist/$component");
    $white = $layer->colorClosest(255,255,255); # find white
    $layer->transparent($white);
    $image->copyMerge($layer, 0, 0, 0, 0, $layer->getBounds(), 100);
  }
  return $image->png();
}

sub move {
  my ($artist, $element, $dir) = @_;
  my $file = "$home/elements/$artist/$element";
  my $original = GD::Image->new($file);
  my $image = GD::Image->new(450, 600);
  my $white = $image->colorAllocate(255,255,255); # find white
  $image->rectangle(0, 0, $image->getBounds(), $white);
  if ($dir eq 'up') {
    $image->copy($original, 0, 0, 0, 10, $image->width, $image->height - 10);
  } elsif ($dir eq 'down') {
    $image->copy($original, 0, 10, 0, 0, $image->width, $image->height - 10);
  } else {
    die "Unknown direction: $dir\n";
  }
  open(my $fh, '>:raw', $file) or die "Cannot write $file: $!";
  print $fh $image->png();
  close($fh);
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Faces';
<h1>Faces for your RPG Characters</h1>
<p>Pick the artist:
<ul>
<% for my $artist (split(/,/, $self->stash('artists'))) { %>\
<li><%= link_to url_for(view => {artist => $artist, type => 'all'}) => begin %><%= $artist %><% end %>
<% } %>\
</ul>
<% if ($self->app->mode eq 'development') { %>
<p>
Debugging:
<ul>
<% for my $artist (split(/,/, $self->stash('artists'))) { %>\
<li><%= link_to url_for(debugartist => {artist => $artist}) => begin %><%= $artist %><% end %>
<% } %>\
</ul>
<% } %>\

@@ view.html.ep
% layout 'default';
% title 'Random Face';
<h1>Random Face (<%= $artist %>/<%= $type %>)</h1>
<p><%= link_to url_for(view => {type => "$type"}) => begin %>Reload<% end %> the page to get a different face.
Or take a look at the <%= link_to url_for(gallery => {artist => $artist, type => $type}) => begin %>Gallery<% end %>.
Or switch type:
<% for my $t (qw(all man woman elf)) {
     next if $type eq $t;
     $self->stash('t', $t); %>\
<%= link_to url_for(view => {artist => "$artist", type => "$t"})   => begin %><%= $t %><% end %>
<% } %>
<p>
<% my $components = $self->stash('components');
   my $url = $self->url_for(face => { artist=> $artist, files => $components }); %>\
<a href="<%= $url %>" download="random.png">
<img class="face" src="<%= $url %>">
</a>
<p>
For demonstration purposes, you can also use this link to a
<%= link_to url_for(random => {artist => $artist, type => $type}) => begin %>random face<% end %>.

@@ gallery.html.ep
% layout 'default';
% title 'Face Gallery';
<h1>Face Gallery (<%= $artist %>/<%= $type %>)</h1>
<p><%= link_to url_for(gallerytype => {type => "$type"}) => begin %>Reload<% end %> the page to get a different gallery.
<p>
<% for my $components (split(/;/, $self->stash('components'))) {
   my $url = $self->url_for(face => { files => $components }); %>
<a href="<%= $url %>" class="download" download="random.png">
<img class="face" src="<%= $url %>">
</a>
<% } %>

@@ debug.html.ep
% layout 'default';
% title 'Face Debugging';
<h1>Face Debugging (<%= $artist %>)</h1>
<p>
Pick an element:
<ul>
<% for my $element (split(/,/, $self->stash('elements'))) {
   my $url  = $self->url_for(debugartistelement => { artist => $artist, element => $element }); %>
<li><a href="<%= $url %>"><%= $element %></a></li>
<% } %>
</ul>

@@ debugelement.html.ep
% layout 'default';
% title 'Face Debugging';
<h1>Face Debugging (<%= $artist %>/<%= $element %>)</h1>
<p>
<% for my $components (split(/;/, $self->stash('components'))) {
   my @components = split(/,/, $components);
   my $url  = $self->url_for(face => { artist => $artist, files => $components });
   my $edit = $self->url_for(edit => { artist => $artist, component => $components[$#components] }); %>
<a href="<%= $edit %>" class="edit">
<img class="face" src="<%= $url %>">
</a>
<% } %>

@@ edit.html.ep
% layout 'default';
% title 'Element Edit';
<h1>Element Edit</h1>
<p>
<% my $i = 0;
   my $components = $self->stash('components');
   my @components = split(/,/, $components);
   my $url  = $self->url_for(face => { files => $components });
   my $up   = $self->url_for(move => { component => $components[$#components], dir => 'up'});
   my $down = $self->url_for(move => { component => $components[$#components], dir => 'down'});
   $i++; %>
<img class="debug face" usemap="#map" src="<%= $url %>">
<map name="map">
  <area shape=rect coords="0,0,225,150" href="<%= $up %>" alt="Move up">
  <area shape=rect coords="0,150,225,300" href="<%= $down %>" alt="Move down">
</map>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet '/face.css'
%= stylesheet begin
body { padding: 1em; font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif; }
a.download, a.edit { text-decoration: none }
.face { height: 300px; }
#logo { position: absolute; top: 0; right: 2em; }
% end
<meta name="viewport" content="width=device-width">
</head>
<body>
<p id="logo"><%= link_to 'Faces' => 'main' %></p>
<%= content %>
<hr>
<p>
All the images generated are <a href="http://creativecommons.org/publicdomain/zero/1.0/">dedicated to the public domain</a>.<br>
<a href="https://alexschroeder.ch/wiki/Contact">Alex Schroeder</a>&#x2003;<a href="https://github.com/kensanata/face">Source on GitHub</a>
</body>
</html>
