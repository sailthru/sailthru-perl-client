use Test::More tests => 5;

use_ok('Sailthru::Api::Client');

my ( $api_key, $secret ) = ( $ENV{TRIGGERMAIL_KEY}, $ENV{TRIGGERMAIL_SECRET} );



##################################################
#
# create the Sailthru object
#
my $fake_tm = new Sailthru::Api::Client( 'api_key', 'secret' );

##################################################
#
# Signature hash generation invalid key response
#
my %vars = ( var1 => "var_content", );
my $signature = $fake_tm->_getSignatureHash( \%vars );
is( $signature, "27a0c810cdd561a69de9ca9bae1f3d82", "Testing signature hash generation" );

##################################################
#
# Testing invalid email
#
SKIP: {
	skip "requires an API key and secret.", 1
	  unless defined($api_key)
		  and defined($secret);
	my $tm = Client->new( $api_key, $secret );
	my %invalid_key = %{ $tm->getEmail('not_an_email') };
	is( $invalid_key{error}, 11, "Testing error code on invalid email" );
}

##################################################
#
# Testing invalid authorization
#
SKIP: {
	skip "requires an API key.", 1
	  unless defined($api_key);
	my $tm = Client->new( $api_key, 'invalid_secret' );
	%invalid_key = %{ $tm->getEmail('not_an_email') };
	is( $invalid_key{error}, 5, "Testing authentication failing error code" );
}

###################################################
##
## Testing invalid key response
##
%invalid_key = %{ $fake_tm->getEmail('not_an_email') };
is( $invalid_key{error}, 3, "Testing error code on invalid key" );
