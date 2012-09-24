use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Exception;
use Readonly;
use HTTP::Response;
use URI;

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
		my $p = shift;
		if (@$p == 1) {
			#only one real arg = fake list for wrapper. pad with dummy args
			unshift @$p, {} for 1..$#_;
		}
    }
);

my $sc = Sailthru::Client->new( $API_KEY, '00001111222233334444555566667777' );
isa_ok( $sc, 'Sailthru::Client' );

my %api_methods = (
    send                         => [ 'POST', 'send' ],
    get_send                     => [ 'GET',  'send' ],
    get_email                    => [ 'GET',  'email' ],
    set_email                    => [ 'POST', 'email' ],
    schedule_blast               => [ 'POST', 'blast' ],
    schedule_blast_from_template => [ 'POST', 'blast' ],
    get_blast                    => [ 'GET',  'blast' ],
    get_template                 => [ 'GET',  'template' ],
);
for my $method ( keys %api_methods ) {
    my $req_type = $api_methods{$method}->[0];
    my $action   = $api_methods{$method}->[1];
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

	is($api_req_args->[1]{test}, 'arg', "$method option was used");

    # make sure the argument hash that was passed in wasn't munged
    is_deeply( \%opts, \%save_opts, "$method opts weren't overwritten" );
}

done_testing;
