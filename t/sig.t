use Test::More;
use lib 'lib';
use Sailthru::Client;

use constant API_KEY => 'abcdef1234567890abcdef1234567890';

my $sc = Sailthru::Client->new( API_KEY, '00001111222233334444555566667777' );

my $sig = $sc->_generate_sig(
    {
        email         => 'test@example.com',
        format        => 'xml',
        'vars[myvar]' => TestValue,
        'optout'      => 0,
        api_key       => API_KEY,

    }
);
is( $sig, 'b0c1ba5e661d155a940da08ed240cfb9', 'multiple args example' );

$sig = $sc->_generate_sig(
    {
        api_key => API_KEY,
        format  => 'json',
        json    => $sc->{encoder}->encode( { email => 'stevesanbeg@buzzfeed.com', lists => { Test => 1 } } ),
    }
);
is( $sig, '62c9f19c053146634d94d531e2492438', 'json example' );

done_testing;
