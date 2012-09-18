use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Exception;
use Readonly;

use lib 'lib';
use Sailthru::Client;

Readonly my $API_KEY => 'abcdef1234567890abcdef1234567890';

my $module = Test::MockModule->new('Sailthru::Client');
# we'll use api_req_args to grab and hold on to the arguments passed in
my $api_req_args;
$module->mock(
    _api_request => sub {
        my $self = shift;
        $api_req_args = \@_;
    }
);
$module->mock(
    validate_pos => sub(\@@) {
        # do nothing
        # don't validate because we loop over methods with different argument signatures
        return;
    }
);

my $sc = Sailthru::Client->new( $API_KEY, '00001111222233334444555566667777' );
isa_ok( $sc, 'Sailthru::Client' );

my %deprecated_methods = (
    getEmail       => [ 'GET',  'email' ],
    setEmail       => [ 'POST', 'email' ],
    getSend        => [ 'GET',  'send' ],
    scheduleBlast  => [ 'POST', 'blast' ],
    getBlast       => [ 'GET',  'blast' ],
    copyTemplate   => [ 'POST', 'blast' ],
    getTemplate    => [ 'GET',  'template' ],
    importContacts => [ 'POST', 'contacts' ],
);
# suppress deprecation warnings
{
    no warnings 'deprecated';
    for my $method ( keys %deprecated_methods ) {
        my $req_type = $deprecated_methods{$method}->[0];
        my $action   = $deprecated_methods{$method}->[1];
        my %opts     = my %save_opts = ( test => 'arg' );
        # clear saved args from mock
        $api_req_args = undef;
        # is the method in the module?
        can_ok( $sc, $method );
        lives_ok( sub { $sc->$method( \%opts ) }, "$method lives" );
        # see if right API action was accessed
        is( $api_req_args->[0], $action, "$method: api '$action' was called" );
        # make sure the http request verb matches
        is( $api_req_args->[2], $req_type, "$method: request type $req_type was called" );
        # make sure the argument hash that was passed in wasn't munged
        is_deeply( \%opts, \%save_opts, "$method opts weren't overwritten" );
    }
}

done_testing;
