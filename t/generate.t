use Mojo::Base -strict;
use Mojo::File 'path';
use Test::Mojo;
use Test::More;

$ENV{MOJO_WEBPACK_ARGS} = '';

my $base = path(path(__FILE__)->dirname, 'generate');
mkdir $base;
plan skip_all => "$base does not exist" unless -d $base;

use Mojolicious::Lite;
plugin Webpack => {assets_dir => $base};

my $t     = Test::Mojo->new;
my $asset = $t->app->asset;

diag 'package.json';
is $asset->_generate($t->app, 'package.json', $base->child('package.json')), 'generated', 'generated package.json';
is $asset->_generate($t->app, 'package.json', $base->child('package.json')), 'custom',    'custom package.json';

diag 'webpack.config.js';
is $asset->_generate($t->app, 'webpack.config.js', $base->child('webpack.config.js')), 'generated',
  'generated webpack.config.js';
is $asset->_generate($t->app, 'webpack.config.js', $base->child('webpack.config.js')), 'current',
  'current webpack.config.js';

my $config = $base->child('webpack.config.js')->slurp;
$config =~ s!(Autogenerated.*)\s(\d+\.\d+)!$1 0!;
$base->child('webpack.config.js')->spurt($config);
is $asset->_generate($t->app, 'webpack.config.js', $base->child('webpack.config.js')), 'generated',
  'regenerated webpack.config.js';

$config =~ s!(Autogenerated.*)!Custom!;
$base->child('webpack.config.js')->spurt($config);
is $asset->_generate($t->app, 'webpack.config.js', $base->child('webpack.config.js')), 'custom',
  'custom webpack.config.js';

diag 'webpack.custom.js';
$asset->_generate($t->app, 'webpack.custom.js', $base->child('webpack.custom.js'));
my $custom = $base->child('webpack.custom.js')->slurp;
like $custom, qr{module\.exports.*function\(config\)}, 'webpack.custom.js';

$custom =~ s!(assetsDir.*)!Do not overwrite!;
$base->child('webpack.custom.js')->spurt($custom);
$asset->_generate($t->app, 'webpack.custom.js', $base->child('webpack.custom.js'));
$custom = $base->child('webpack.custom.js')->slurp;
like $custom, qr{Do not overwrite}, 'webpack.custom.js is generated once';

done_testing;

END {
  $base->list->each(sub {unlink}) if $base;
}
