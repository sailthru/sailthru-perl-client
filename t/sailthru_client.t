use strict;
use warnings;

use Test::More tests => 5;

use lib 'lib';

use_ok('Sailthru::Client');

my ( $api_key, $secret ) = ( $ENV{SAILTHRU_KEY}, $ENV{SAILTHRU_SECRET} );

# create the Sailthru::Client object
my $fake_sc = Sailthru::Client->new( 'key', 'secret' );

# signature hash generation invalid key response
my %vars = ( var1 => 'var_content', );
my $signature = $fake_sc->_getSignatureHash( \%vars );
is( $signature, '27a0c810cdd561a69de9ca9bae1f3d82', 'Testing signature hash generation.' );

my $sc;
my %invalid_key;

# testing invalid email
SKIP: {
    skip 'Requires an API key and secret.', 1 if not defined $api_key and not defined $secret;
    $sc = Sailthru::Client->new( $api_key, $secret );
    %invalid_key = %{ $sc->getEmail('not_an_email') };
    is( $invalid_key{error}, 11, 'Testing error code on invalid email.' );
}

# testing invalid authorization
SKIP: {
    skip 'Requires an API key.', 1 if not defined $api_key;
    $sc = Sailthru::Client->new( $api_key, 'invalid_secret' );
    %invalid_key = %{ $sc->getEmail('not_an_email') };
    is( $invalid_key{error}, 5, 'Testing authentication failing error code.' );
}

# testing invalid key response
%invalid_key = %{ $fake_sc->getEmail('not_an_email') };
is( $invalid_key{error}, 3, 'Testing error code on invalid key.' );
