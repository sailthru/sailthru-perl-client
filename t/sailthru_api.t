use strict;
use warnings;

use Test::More;
use Readonly;

#
# test the client functions with the api/network live
#

use lib 'lib';
use_ok('Sailthru::Client');

my ( $api_key, $secret ) = ( $ENV{SAILTHRU_KEY}, $ENV{SAILTHRU_SECRET} );

# resources to use for the test.  These will be automatically created/deleted on Sailthru
my $t = time;
Readonly my $LIST     => 'CPAN test list ' . $t;
Readonly my $EMAIL    => 'sc-cpan@example' . $t . '.com';
Readonly my $TEMPLATE => 'CPAN Test ' . $t;

# responses to api calls
my $response;

my $bad_sc = Sailthru::Client->new( 'key', 'secret' );
# testing invalid key response
$response = $bad_sc->get_email('not_an_email');
is( $response->{error}, 3, 'Testing error code on invalid key.' );

SKIP: {
    skip 'Requires an API key and secret.', 1 if not defined $api_key and not defined $secret;

    # test bad secret
    my $sc = Sailthru::Client->new( $api_key, 'invalid_secret' );
    $response = $sc->get_email('not_an_email');
    is( $response->{error}, 5, 'Testing authentication failing error code.' );

    # build a good client to use
    $sc = Sailthru::Client->new( $api_key, $secret );

    # test invalid email
    $response = $sc->get_email('not_an_email');
    is( $response->{error}, 11, 'Testing error code on invalid email.' );

    ############################################################
    # Grab template source/preview
    ############################################################

    # create template (or overwrite if already exists)
    my @lines = <DATA>;
    close DATA;
    $response = $sc->api_post( 'template', { template => $TEMPLATE, content_html => "@lines" } );
    is( $response->{error}, undef, 'no error creating template' );

    # valid source
    my $source = $sc->api_post( 'blast', { copy_template => $TEMPLATE } );
    like( $source->{content_html}, qr/Hey/,       'got right result' );
    like( $source->{content_html}, qr/\Q{email}/, 'has variable' );
    unlike( $source->{content_html}, qr/\Q@{[$EMAIL]}/, 'did not find email' );

    # valid preview
    my $preview = $sc->api_post(
        'preview',
        {
            template => $TEMPLATE,
            email    => $EMAIL,
        }
    );
    ok( not( $preview->{error} ), 'No error in preview' );
    like( $preview->{content_html}, qr/Hey/, 'found text' );
    unlike( $preview->{content_html}, qr/\Q{email}/, 'does not have variable' );
    like( $preview->{content_html}, qr/\Q@{[$EMAIL]}/, 'found email' );

    # delete template, rerun preview, look for error.
    $sc->api_delete( 'template', { template => $TEMPLATE } );

    my $no_template = $sc->api_post(
        'preview',
        {
            template => $TEMPLATE,
            email    => $EMAIL,
        }
    );

    ok( $no_template->{error}, 'got error from deleted template' );
    like( $no_template->{errormsg}, qr/template/, 'got expected error message from deleted template' );

    ############################################################
    # test email subscriptions
    ############################################################
    my $email;

    # try to create list, in case it doesn't exist (will delete at end, anyway) and verify it's there
    $email = $sc->api_post( 'list', { list => $LIST } );
    is( $email->{errormsg}, undef, 'No error creating list' );
    $email = $sc->api_get( 'list', { list => $LIST } );
    is( $email->{list},     $LIST, 'email list exists' );
    is( $email->{errormsg}, undef, 'No error getting list' );

    # add via api calls
    $sc->api_post( 'email', { email => $EMAIL, lists => { $LIST => 1 } } );
    $email = $sc->api_get( 'email', { email => $EMAIL } );
    is( $email->{lists}{$LIST}, 1, 'is on list' );

    # remove via api call
    $sc->api_post( 'email', { email => $EMAIL, lists => { $LIST => 0 } } );
    $email = $sc->api_get( 'email', { email => $EMAIL } );
    is( $email->{lists}{$LIST}, undef, 'is not on list' );

    # add via set_email/get_email
    $sc->set_email( $EMAIL, {}, { $LIST => 1 } );
    $email = $sc->get_email($EMAIL);
    is( $email->{lists}{$LIST}, 1, 'is on list' );

    # remove via set_email/get_email
    $sc->set_email( $EMAIL, {}, { $LIST => 0 } );
    $email = $sc->get_email($EMAIL);
    is( $email->{lists}{$LIST}, undef, 'is not on list' );

    $sc->api_delete( 'list', { list => $LIST } );
    $email = $sc->api_get( 'list', { list => $LIST } );
    is( $email->{name}, undef, 'email list does not exist' );

    ############################################################
    # TODO test all object methods
    ############################################################

    # TODO test send
    # TODO test get_send
    # TODO test schedule_blast
    # TODO test schedule_blast_from_template
    # TODO test get_blast
    # TODO test get_template

    ############################################################
    # test deprecated functions
    ############################################################

    # temporarily suppress deprecation warnings
    {
        no warnings 'deprecated';
        # test deprecation of 'contacts' API
        my $r = $sc->importContacts( 'foobarbaz@gmail.com', 'foobarbaz' );
        is( $r->{error}, 99, 'importContacts returns error 99 (other).' );
        like(
            $r->{errormsg},
            qr/The contacts API has been discontinued as of August 1st, 2011/,
            'importContacts returns errormsg describing deprecation of "contacts".'
        );
        # TODO test getEmail
        # TODO test setEmail
        # TODO test getSend
        # TODO test scheduleBlast
        # TODO test getBlast
        # TODO test copyTemplate
        # TODO test getTemplate
    }
}


done_testing;

__DATA__
<html>
<body>
<h1>Hey!!!</h1>

This is a big important message

Not really, we just use this template to test the CPAN module.

bye, {email}

<p><small>If you believe this has been sent to you in error, please safely <a href="{optout_confirm_url}">unsubscribe</a>.</small></p>
</body>
</html>
