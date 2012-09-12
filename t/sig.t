use strict;
use warnings;

use lib 'lib';

use Test::More;

use JSON::XS;
use Sailthru::Client;

my $api_key = 'abcdef1234567890abcdef1234567890';
my $secret  = '00001111222233334444555566667777';
my $sc      = Sailthru::Client->new( $api_key, $secret );

my $args = {
    email         => 'test@example.com',
    format        => 'xml',
    'vars[myvar]' => 'TestValue',
    optout        => 0,
    api_key       => $api_key,
};

my $sig = $sc->_generate_sig($args);
is( $sig, 'b0c1ba5e661d155a940da08ed240cfb9', '_generate_sig with multiple arguments' );

$sig = Sailthru::Client::get_signature_hash( $args, $secret );
is( $sig, 'b0c1ba5e661d155a940da08ed240cfb9', 'get_signature_hash with multiple arguments' );

$args = {
    api_key => $api_key,
    format  => 'json',
    json    => encode_json( { email => 'stevesanbeg@buzzfeed.com', lists => { Test => 1 } } ),
};

$sig = $sc->_generate_sig($args);
is( $sig, '62c9f19c053146634d94d531e2492438', '_generate_sig with JSON' );

$sig = Sailthru::Client::get_signature_hash( $args, $secret );
is( $sig, '62c9f19c053146634d94d531e2492438', 'get_signature_hash with JSON' );

done_testing;
