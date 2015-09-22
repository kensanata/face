#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::ByteStream;
use Mojo::Home;
use GD;

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
  $self->render(template => 'view',
		components => join(',', random_components()));
};

get '/random' => sub {
  my $self = shift;
  $self->render(data => render_components(random_components()), format => 'png');
};

get '/face/#files' => sub {
  my $self = shift;
  $self->render(data => render_components(split(',', $self->param('files'))));
} => 'face';

app->start;

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

sub random_components {
  my @elements = qw(eyes nose ears mouth chin hair);
  my @files;
  opendir(my $dh, "$home/elements") || die "Can't open elements: $!";
  @files = grep { /\.png$/ } readdir($dh);
  closedir $dh;
  my @components = map {
    my $re = qr/$_/;
    one(grep(/$re/, @files));
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
% title 'Faces';
<h1>Random Face</h1>
<p><%= link_to 'Reload' => 'view' %> the page to get a different face.
<p>
<% my $components = $self->stash('components');
   my $url = $self->url_for(face => { files => $components }); %>
<a href="<%= $url %>" download="random.png">
<img class="face" src="<%= $url %>">
</a>
<p>
For demonstration purposes, you can also use this link to a
<%= link_to random => begin %>random face<% end %>.

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet '/korero.css'
%= stylesheet begin
body {
  padding: 1em;
  font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif;
}
.face {
  height: 300px;
}
#logo {
  position: absolute;
  top: 0;
  right: 2em;
}
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
