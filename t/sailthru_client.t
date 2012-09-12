use strict;
use warnings;

use Test::More;

use lib 'lib';

use_ok('Sailthru::Client');

my ( $api_key, $secret ) = ( $ENV{SAILTHRU_KEY}, $ENV{SAILTHRU_SECRET} );

# create the Sailthru::Client object
my $fake_sc = Sailthru::Client->new( 'key', 'secret' );

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

done_testing;
