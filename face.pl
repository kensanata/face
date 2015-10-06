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
use Mojo::Home;
use GD;

# Directories to look for dictionaries.
# Earlier directories have precedence.
my $home = Mojo::Home->new;
$home->detect;

plugin 'Config' => {default => {users => {}}};

plugin 'authentication', {
    autoload_user => 1,
    load_user => sub {
        my ($self, $username) = @_;
        return {
	  'username' => $username,
	} if app->config('users')->{$username};
        return undef;
    },
    validate_user => sub {
        my ($self, $username, $password) = @_;
	if (app->config('users')->{$username}
	    && $password eq app->config('users')->{$username}) {
	  return $username;
	}
        return undef;
    },
};

get '/' => sub {
  my $self = shift;
  $self->render(template => 'index',
		artists => all_artists());
} => 'main';

get '/view' => sub {
  my $self = shift;
  $self->redirect_to(view => {artist => 'alex', type => 'woman'});
};

get '/view/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  $self->render(template => 'view',
		type => $type,
		artists => all_artists(),
		components => [random_components($type, $artist)]);
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
		artists => all_artists(),
		type => $type,
		components => [map {
		  [random_components($type, $artist, $self->param('debug'))];
			       } 1..10]);
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

get '/redirect/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  $self->redirect_to(render => {
    artist => $artist,
    files  => join(',', random_components($type, $artist)), });
} => 'redirect';

get '/render/#files' => sub {
  my $self = shift;
  my $files = $self->param('files');
  $self->redirect_to(face => {
    artist => 'alex',
    files => $files}, );
};

get '/render/:artist/#files' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $files = $self->param('files');
  $self->render(format => 'png',
		data => render_components(
		  $artist,
		  split(',', $files)));
} => 'render';

get '/debug' => sub {
  my $self = shift;
  $self->render(template => 'debug',
		elements => [all_elements()]);
} => 'debug';

get '/debug/:artist' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  $self->render(template => 'debug',
		artist => $artist,
		elements => [all_elements()]);
} => 'debug_artist';

get '/debug/:artist/:element' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $element = $self->param('element');
  $self->render(template => 'debugelement',
		artist => $artist,
		element => $element,
		components => [all_components($artist, $element)]);
} => 'debug_element';

get '/edit/:artist/#component' => sub {
  my $self = shift;
  my $component = $self->param('component');
  $self->render(template => 'edit',
		components => ['empty.png', 'edit.png', $component]);
} => 'edit';

get '/move/:artist/#component/:dir' => sub {
  my $self = shift;
  if (not $self->is_user_authenticated()) {
    return $self->redirect_to('login');
  }
  my $artist = $self->param('artist');
  my $component = $self->param('component');
  my $dir = $self->param('dir');
  my $step = $self->param('step') || 10;
  move($artist, $component, $dir, $step);
  $self->render(template => 'edit',
		components => ['empty.png', 'edit.png', $component]);
} => 'move';

any "/login" => sub {
  my $self = shift;
  my $username = $self->param('username');
  my $password = $self->param('password');
  if ($username) {
    $self->authenticate($username, $password);
    if ($self->is_user_authenticated()) {
      return $self->redirect_to('main');
    } else {
      $self->stash(login => 'wrong');
    }
  }
} => 'login';

get "/logout" => sub {
  my $self = shift;
  $self->logout();
  $self->redirect_to('main');
} => 'logout';

sub member {
  my $element = shift;
  foreach (@_) {
    return 1 if $element eq $_;
  }
}

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

my %artists;

sub all_artists {
  return \%artists if %artists;
  opendir(my $dh, "$home/elements") || die "Can't open elements: $!";
  my @dirs = grep {
    !/\.png$/ # ignore images
	&& substr($_, 0, 1) ne '.' # ignore "." and ".." and other "hidden files"
	&& -d "$home/elements/$_"
  } readdir($dh);
  closedir $dh;
  for my $dir (@dirs) {
    $artists{$dir} = $dir; # default
    open(my $fh, '<:utf8', "$home/elements/$dir/README.md") or next;
    local $/ = undef;
    my $text = <$fh>;
    if ($text =~ /\[([^]]*)\]\((https?:.*)\)/) {
      $artists{$dir} = {};
      $artists{$dir}{name} = $1;
      $artists{$dir}{url}  = $2;
    }
    close($fh);
  }
  return \%artists;
}

sub all_components {
  my ($artist, $element) = @_;
  opendir(my $dh, "$home/elements/$artist") || die "Can't open $home/elements/$artist: $!";
  my @files = grep { /$element.*\.png$/ } readdir($dh);
  closedir $dh;
  my @components = map { ['empty.png', $_] } @files;
  return @components;
}

sub all_elements {
  # chin after mouth (mustache hides mouth)
  # nose after chin (mustache!)
  # hair after ears
  # ears after chin (if you're fat)
  # chin after ears (for your beard) – damn!
  return qw(eyes mouth chin ears nose extra hair);
}

sub random_components {
  my ($type, $artist, $debug) = @_;
  $type ||= 'all';
  my @elements = all_elements();
  @elements = grep(!/extra/, @elements) if rand(1) >= 0.1; # 10% chance
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
  unshift(@elements, 'empty.png') if $debug;
  return @components;
}

sub render_components {
  my ($artist, @components) = @_;
  my $image = GD::Image->new(450, 600);
  my $white = $image->colorAllocate(255,255,255); # find white
  $image->rectangle(0, 0, $image->getBounds(), $white);
  for my $component (@components) {
    next unless $component;
    my $layer;
    if ($component eq 'empty.png' or $component eq 'edit.png') {
      $layer = GD::Image->new("$home/elements/$component");
    } else {
      $layer = GD::Image->new("$home/elements/$artist/$component");
    }
    $white = $layer->colorClosest(255,255,255); # find white
    $layer->transparent($white);
    $image->copyMerge($layer, 0, 0, 0, 0, $layer->getBounds(), 100);
  }
  return $image->png();
}

sub move {
  my ($artist, $element, $dir, $step) = @_;
  my $file = "$home/elements/$artist/$element";
  my $original = GD::Image->new($file);
  my $image = GD::Image->new(450, 600);
  my $white = $image->colorAllocate(255,255,255); # find white
  $image->rectangle(0, 0, $image->getBounds(), $white);
  if ($dir eq 'up') {
    $image->copy($original, 0, 0, 0, $step, $image->width, $image->height - $step);
  } elsif ($dir eq 'down') {
    $image->copy($original, 0, $step, 0, 0, $image->width, $image->height - $step);
  } elsif ($dir eq 'left') {
    $image->copy($original, 0, 0, $step, 0, $image->width - $step, $image->height);
  } elsif ($dir eq 'right') {
    $image->copy($original, $step, 0, 0, 0, $image->width - $step, $image->height);
  } else {
    die "Unknown direction: $dir\n";
  }
  open(my $fh, '>:raw', $file) or die "Cannot write $file: $!";
  print $fh $image->png();
  close($fh);
}

app->secrets([app->config('secret')]) if app->config('secret');

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Faces';
<h1>Faces for your RPG Characters</h1>
<p>Pick the artist:
<ul>
<% for my $artist (sort keys %$artists) { %>\
<li><%= link_to url_for(view => {artist => $artist, type => 'woman'}) => begin %><%= $artists->{$artist}{name} %><% end %>
<% } %>\
</ul>
<% if ($self->is_user_authenticated()) { %>
<p>
Debugging:
<ul>
<li><%= link_to url_for(debug_artist => {artist => $self->current_user()->{username}}) => begin %>\
<%= $artists->{$self->current_user()->{username}}{name} %>\
<% end %>
</ul>
<% } %>\

@@ view.html.ep
% layout 'default';
% title 'Random Face';
<h1>Random Face</h1>
<p>
<%= link_to url_for(view => {type => "$type"}) => begin %>Reload<% end %> the page to get a different face.<br>
Or take a look at the <%= link_to url_for(gallery => {artist => $artist, type => $type}) => begin %>Gallery<% end %>.<br>
Or switch type:
<% for my $t (qw(man woman elf all)) {
     $self->stash('t', $t);
     if ($type eq $t) { %>\
<b><%= $t %></b>
<%   } else { %>
<%= link_to url_for(view => {artist => "$artist", type => "$t"})   => begin %><%= $t %><% end %>
<%   }
   } %>
<p>
<% my $url = $self->url_for(render => { artist=> $artist, files => join(',', @$components)}); %>\
<a href="<%= $url %>" download="random.png">
<img class="face" src="<%= $url %>">
</a>
<p>
Images by <a href="<%= $artists->{$artist}{url} %>"><%= $artists->{$artist}{name} %></a>.
<p class="text">
For demonstration purposes, you can also use this link to a
<%= link_to url_for(random => {artist => $artist, type => $type}) => begin %>random face<% end %>.
You'll get a new random face every time you reload.
If you're writing an application that needs the <i>URL</i> to a random face, you're better using this
<%= link_to url_for(redirect => {artist => $artist, type => $type}) => begin %>redirecting<% end %>
link which gives you a URL to use.

@@ gallery.html.ep
% layout 'default';
% title 'Face Gallery';
<h1>Face Gallery</h1>
<p><%= link_to url_for(gallery => {type => "$type"}) => begin %>Reload<% end %> the page to get a different gallery.<br>
Or switch type:
<% for my $t (qw(man woman elf all)) {
     $self->stash('t', $t);
     if ($type eq $t) { %>\
<b><%= $t %></b>
<%   } else { %>
<%= link_to url_for(gallery => {artist => "$artist", type => "$t"})   => begin %><%= $t %><% end %>
<%   }
   } %>
<p>
<% for my $files (@$components) {
   my $url = $self->url_for(render => { files => join(',', @$files)}); %>
<a href="<%= $url %>" class="download" download="random.png">
<img class="face" src="<%= $url %>">
</a>
<% } %>
<p>
Images by <a href="<%= $artists->{$artist}{url} %>"><%= $artists->{$artist}{name} %></a>.

@@ debug.html.ep
% layout 'default';
% title 'Face Debugging';
<h1>Face Debugging (<%= $artist %>)</h1>
<p>
Pick an element:
<ul>
<% for my $element (@$elements) {
   my $url  = $self->url_for(debug_element => { artist => $artist, element => $element }); %>
<li><a href="<%= $url %>"><%= $element %></a></li>
<% } %>
</ul>

@@ debugelement.html.ep
% layout 'default';
% title 'Face Debugging';
<h1>Face Debugging (<%= $artist %>/<%= $element %>)</h1>
<p>
<% for my $files (@$components) {
   my $url  = $self->url_for(render => { artist => $artist, files => join(',', @$files) });
   my $edit = $self->url_for(edit => { artist => $artist, component => $files->[-1] }); %>
<a href="<%= $edit %>" class="edit">
<img class="face" src="<%= $url %>">
</a>
<% } %>

@@ edit.html.ep
% layout 'default';
% title 'Element Edit';
<h1>Element Edit</h1>
<p class="text">
Here's where you can make small edits to an element. The image below has eight
zones. Clicking the zone moves the element in its respective direction. The
outer zones move the element by ten pixels, the inner zones move the element by
five pixels.
<p>
<% my $i = 0;
   my $url        = $self->url_for(render => { files => join(',', @$components) });
   my $up         = $self->url_for(move => { component => $components->[-1], dir => 'up'});
   my $down       = $self->url_for(move => { component => $components->[-1], dir => 'down'});
   my $left       = $self->url_for(move => { component => $components->[-1], dir => 'left'});
   my $right      = $self->url_for(move => { component => $components->[-1], dir => 'right'});
   my $half_up    = $self->url_for(move => { component => $components->[-1], dir => 'up'})->query(step => 5);
   my $half_down  = $self->url_for(move => { component => $components->[-1], dir => 'down'})->query(step => 5);
   my $half_left  = $self->url_for(move => { component => $components->[-1], dir => 'left'})->query(step => 5);
   my $half_right = $self->url_for(move => { component => $components->[-1], dir => 'right'})->query(step => 5);
   $i++; %>

<img class="debug face" usemap="#map" src="<%= $url %>">
<map name="map">
  <area shape=poly coords="0,0,56,56,168,56,224,0" href="<%= $up %>" alt="Move up">
  <area shape=poly coords="0,299,56,243,168,243,224,299" href="<%= $down %>" alt="Move down">
  <area shape=poly coords="0,0,56,56,56,243,0,299" href="<%= $left %>" alt="Move left">
  <area shape=poly coords="224,0,168,56,168,243,224,299" href="<%= $right %>" alt="Move right">
  <area shape=poly coords="56,56,112,112,168,56" href="<%= $half_up %>" alt="Move half up">
  <area shape=poly coords="56,243,112,188,168,243" href="<%= $half_down %>" alt="Move half down">
  <area shape=poly coords="56,56,112,112,112,188,56,243" href="<%= $half_left %>" alt="Move half left">
  <area shape=poly coords="168,56,112,112,112,188,168,243" href="<%= $half_right %>" alt="Move half right">
</map>

@@ login.html.ep
% layout 'default';
% title 'Login';
<h1>Login</h1>
<% if ($self->stash('login') eq 'wrong') { %>
<p>
<span class="alert">Login failed. Username unknown or password wrong.</span>
<% } %>
%= form_for login => (enctype => 'multipart/form-data') => (method => 'POST') => begin
%= label_for username => 'Username'
%= text_field 'username'
<p>
%= label_for password => 'Password'
%= password_field 'password'
<p>
%= submit_button 'Login'
% end

@@ logout.html.ep
% layout 'default';
% title 'Logout';
<h1>Logout</h1>
<p>
You have been logged out.
<p>
Go back to the <%= link_to 'main menu' => 'main' %>.

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet '/face.css'
%= stylesheet begin
body { padding: 1em; font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif }
a.download, a.edit { text-decoration: none }
.face { height: 300px }
.text { width: 80ex }
.alert { padding: 1ex; background: #ffc0cb; color: #d02090; border: 2px solid #d02090 }
.author { font-size: 80% }
label { display: inline-block; width: 10ex }
% end
<meta name="viewport" content="width=device-width">
</head>
<body>
<%= content %>
<hr>
<p>
All the images generated are <a href="http://creativecommons.org/publicdomain/zero/1.0/">dedicated to the public domain</a>.<br>
<%= link_to 'Faces' => 'main' %> &nbsp;
<a href="https://alexschroeder.ch/wiki/Contact">Alex Schroeder</a> &nbsp; <a href="https://github.com/kensanata/face">Source on GitHub</a> &nbsp;
<% if ($self->is_user_authenticated()) { %>
<%= link_to 'Logout' => 'logout' %>
<% } else { %>
<%= link_to 'Login' => 'login' %>
<% } %>
</body>
</html>
