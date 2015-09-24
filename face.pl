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
  $self->render('index');
} => 'main';

get '/view' => sub {
  my $self = shift;
  $self->redirect_to(viewtype => {type => 'all'});
} => 'view';

get '/view/:type' => sub {
  my $self = shift;
  my $type = $self->param('type');
  $self->render(template => 'view',
		type => $type,
		components => join(',', random_components($type)));
} => 'viewtype';

get '/gallery/:type' => sub {
  my $self = shift;
  my $type = $self->param('type');
  $self->render(template => 'gallery',
		type => $type,
		components => join(';', map { join(',', random_components($type)) } 1..10));
} => 'gallerytype';

get '/random' => sub {
  my $self = shift;
  $self->render(data => render_components(random_components()), format => 'png');
} => 'random';

get '/random/:type' => sub {
  my $self = shift;
  $self->render(data => render_components(random_components($self->param('type'))), format => 'png');
} => 'randomtype';

get '/face/#files' => sub {
  my $self = shift;
  $self->render(data => render_components(split(',', $self->param('files'))), format => 'png');
} => 'face';

app->start;

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

sub random_components {
  my $type = shift||'all';
  my @elements = qw(eyes nose ears mouth chin hair);
  push(@elements, 'extra') if rand(1) < 0.1; # 10% chance
  my @files;
  opendir(my $dh, "$home/elements") || die "Can't open elements: $!";
  @files = grep { /\.png$/ } readdir($dh);
  closedir $dh;
  my @components = map {
    my $element = $_; # inside grep $_ points to a file
    my @candidates1 = grep(/^${element}_/, @files);
    my @candidates2 = grep(/_${type}/, @candidates1) if $type;
    @candidates2 = grep(/_all/, @candidates1) unless @candidates2;
    one(@candidates2);
  } @elements;
  return @components;
}

sub render_components {
  my @components = @_;
  my $image = GD::Image->new(450, 600);
  my $white = $image->colorAllocate(255,255,255); # find white
  $image->rectangle(0,0, $image->getBounds(), $white);
  for my $component (@components) {
    next unless $component;
    open(my $fh, '<', "$home/elements/$component")
	|| die "Can't open $component: $!";
    my $layer = GD::Image->newFromPng($fh);
    $white = $layer->colorClosest(255,255,255); # find white
    $layer->transparent($white);
    $image->copyMerge($layer, 0, 0, 0, 0, $layer->getBounds(), 100);
  }
  return $image->png();
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Faces';
<h1>Faces for your RPG Characters</h1>
<p>Here's what the app can do:
<ul>
<li><%= link_to 'Random Face' => 'view' %></li>
</ul>

@@ view.html.ep
% layout 'default';
% title 'Random Face';
<h1>Random Face (<%= $type %>)</h1>
<p><%= link_to url_for(viewtype => {type => "$type"}) => begin %>Reload<% end %> the page to get a different face.
Or take a look at the <%= link_to url_for(gallerytype => {type => "$type"}) => begin %>Gallery<% end %>.
<p>
<% my $components = $self->stash('components');
   my $url = $self->url_for(face => { files => $components }); %>
<a href="<%= $url %>" download="random.png">
<img class="face" src="<%= $url %>">
</a>
<p>
Or switch type:
<% for my $t (qw(all man woman elf)) {
     next if $type eq $t;
     $self->stash('t', $t); %>
<%= link_to url_for(viewtype => {type => "$t"})   => begin %><%= $t %><% end %>
<% } %>
<p>
For demonstration purposes, you can also use this link to a
<%= link_to url_for(randomtype => {type => "$type"}) => begin %>random face<% end %>.

@@ gallery.html.ep
% layout 'default';
% title 'Face Gallery';
<h1>Face Gallery (<%= $type %>)</h1>
<p><%= link_to url_for(gallerytype => {type => "$type"}) => begin %>Reload<% end %> the page to get a different gallery.
<p>
<% for my $components (split(/;/, $self->stash('components'))) {
   warn $components;
   my $url = $self->url_for(face => { files => $components }); %>
<a href="<%= $url %>" class="download" download="random.png">
<img class="face" src="<%= $url %>">
</a>
<% } %>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet '/face.css'
%= stylesheet begin
body { padding: 1em; font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif; }
.download { text-decoration: none }
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
<a href="https://alexschroeder.ch/wiki/Contact">Alex Schroeder</a>&#x2003;<a href="https://github.com/kensanata/face">Source on GitHub</a>
</body>
</html>
