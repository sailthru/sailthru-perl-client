use strict;
use warnings;
use Test::More;
use lib 'lib';

use_ok('Sailthru::Client');


my ( $api_key, $secret ) = ( $ENV{SAILTHRU_KEY}, $ENV{SAILTHRU_SECRET} );

use constant LIST     => 'CPAN test list';
use constant EMAIL    => 'sc-cpan@example.com';
use constant TEMPLATE => 'CPAN Test';

# testing invalid email
SKIP: {
    skip 'Requires an API key and secret.', 1 if not defined $api_key and not defined $secret;
    my $sc = Sailthru::Client->new( $api_key, $secret );

	############################################################
	# Grab template source/preview
	############################################################

	#valid source
	my $source = $sc->call_api('POST', 'blast', {copy_template=>TEMPLATE});
	like($source->{content_html}, qr/Hey/, "got right result");
	like($source->{content_html}, qr/\Q{email}/, "has variable");
	unlike ($source->{content_html}, qr/\Q@{[EMAIL]}/, "didn't found email");
	#valid preview
	my $preview =  $sc->call_api('POST', 'preview', {
		template=>TEMPLATE,
		email=>EMAIL,
	});
	ok (not $preview->{error});
	like ($preview->{content_html}, qr/Hey/, "found text");
	unlike($preview->{content_html}, qr/\Q{email}/, "doesn't have variable");
	like ($preview->{content_html}, qr/\Q@{[EMAIL]}/, "found email");
	my $no_template = $sc->call_api('POST', 'preview', {
		template=>'No such template',
		email=>EMAIL(),
	});

	ok($no_template->{error});
	like($no_template->{errormsg}, qr/template/);

	############################################################
	#test email subscriptions
	############################################################
	my $email;

	# add via call_api
	$sc->call_api( 'POST', 'email', {email=>EMAIL(), lists=>{LIST()=>1}} );
	$email = $sc->call_api( 'GET', 'email', {email=>EMAIL()} );
	is ($email->{lists}{LIST()}, 1, 'is on list');

	#rm via call_api
	$sc->call_api('POST', 'email', {email=>EMAIL(), lists=>{LIST()=>0}});
	$email = $sc->call_api( 'GET', 'email', {email=>EMAIL()});
	is ($email->{lists}{LIST()}, undef, 'is not on list');

	#add via setEmail/getEmail
	$sc->setEmail(EMAIL(), {}, {LIST()=>1});
	$email = $sc->getEmail( EMAIL );
	is ($email->{lists}{LIST()}, 1, 'is on list');

	#rm via setEmail/getEmail
	$sc->setEmail(EMAIL(), {}, {LIST()=>0});
	$email = $sc->getEmail( EMAIL );
	is ($email->{lists}{LIST()}, undef, 'is not on list');
	############################################################
}

done_testing;
