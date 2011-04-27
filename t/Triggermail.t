use Test::More tests => 6;

my ( $api_key, $secret ) = ( $ENV{TRIGGERMAIL_KEY}, $ENV{TRIGGERMAIL_SECRET} );

use_ok('Triggermail');

##################################################
#
# create the Sailthru object
#
my $fake_tm = Triggermail->new( 'api_key', 'secret' );

##################################################
#
# Signature hash generation invalid key response
#
my %vars = ( var1 => "var_content", );
my $signature = $fake_tm->_getSignatureHash( \%vars );
is( $signature, "27a0c810cdd561a69de9ca9bae1f3d82", "Testing signature hash generation" );

SKIP: {
	skip "requires an API key and secret.", 2
	  unless defined($api_key)
		  and defined($secret);
##################################################
#
# Testing invalid email
#
	my $tm = Triggermail->new( $api_key, $secret );
	my %invalid_key = %{ $tm->getEmail('not_an_email') };
	is( $invalid_key{error}, 11, "Testing error code on invalid email" );
	is( $invalid_key{errormsg}, "Invalid email: not_an_email", "Testing error message on invalid email" );
}

SKIP: {
	skip "requires an API key.", 1
	  unless defined($api_key);
##################################################
#
# Testing invalid authorization
#
	my $tm = Triggermail->new( $api_key, 'invalid_secret' );
	%invalid_key = %{ $tm->getEmail('not_an_email') };
	is( $invalid_key{error}, 5, "Testing authentication failing error code" );
}

##################################################
#
# Testing invalid key response
#
%invalid_key = %{ $fake_tm->getEmail('not_an_email') };
is( $invalid_key{error}, 3, "Testing error code on invalid key" );
