use Test::More;
use Test::MockModule;
use Test::Exception;

use lib 'lib';
use Sailthru::Client;
use Data::Dumper;
use constant API_KEY => 'abcdef1234567890abcdef1234567890';

my $module = Test::MockModule->new('Sailthru::Client');
my $mock_args;
$module->mock(call_api => sub {
				  my $self = shift; 
				  $mock_args = \@_;
		  });
$module->mock(validate_pos => sub(\@@) {
					my $p = shift;
					my $self = shift @$p;
					unshift @$p, {} for 1..$#_;
					unshift @$p, $self;
				});


my $sc = Sailthru::Client->new(API_KEY,	'00001111222233334444555566667777');
isa_ok($sc, 'Sailthru::Client');

my @wrap = qw[
getEmail
setEmail
send
getSend
scheduleBlast
getBlast
getTemplate
importContacts
copyTemplate
];

foreach my $method (@wrap) {
	my %opts = %save_opts = (test=>'arg');
	lives_ok { $sc->$method(\%opts) } "$method lives";

	#warn Dumper(${mock_args});

	my $action = $method;
	$action =~ s/^[a-z]+// if $method =~ m/[A-Z]/;
	$action = 'blast' if $method eq 'copyTemplate'; #one special case

	is($mock_args->[1], lc($action), "$method was called");
	is_deeply(\%opts, \%save_opts, "$method opts weren't overwritten");
	is($mock_args->[2]{test}, 'arg', "$method option was used");
}

done_testing;

