#!/usr/bin/env perl
use Mojolicious::Lite;
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

get '/random' => sub {
  my $self = shift;
  my @elements = qw(eyes nose mouth hair);
  my @files;
  opendir(my $dh, "$home/elements") || die "Can't open elements: $!";
  @files = grep { /\.png$/ } readdir($dh);
  closedir $dh;
  my @components = map {
    my $re = qr/$_/;
    one(grep(/$re/, @files));
  } @elements;
  my $image = GD::Image->new(370, 470);
  my $white = $image->colorAllocate(255,255,255); # find white
  $image->rectangle(0,0, $image->getBounds(), $white);
  for my $component (@components) {
    open(my $fh, '<', "$home/elements/$component")
	|| die "Can't open $component: $!";
    my $layer = GD::Image->newFromPng($fh);
    $white = $layer->colorClosest(255,255,255); # find white
    $layer->transparent($white);
    $image->copyMerge($layer, 0, 0, 0, 0, $layer->getBounds(), 100);
  }
  my $bytes = $image->png();
  $self->render(data => $bytes, format => 'png');
};

app->start;

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Faces';
<h1>Faces for your RPG Characters</h1>
<p>Here's what the app can do:
<ul>
<li><%= link_to 'Random Face' => 'random' %></li>
</ul>


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
