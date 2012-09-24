use strict;
use warnings;

use Test::More;
use Readonly;

#
# test the client functions with the api/network live
#

use lib 'lib';
use_ok('Sailthru::Client');

my ( $api_key, $secret, $verified_email ) =
  ( $ENV{SAILTHRU_KEY}, $ENV{SAILTHRU_SECRET}, $ENV{SAILTHRU_VERIFIED_EMAIL} );

# resources to use for the test.  These will be automatically created/deleted on Sailthru
Readonly my $TIMESTAMP => time;
Readonly my $LIST      => 'CPAN test list ' . $TIMESTAMP;
Readonly my $EMAIL     => 'sc-cpan@example' . $TIMESTAMP . '.com';
Readonly my $TEMPLATE  => 'CPAN Test ' . $TIMESTAMP;

# responses to api calls
my $response;

my $bad_sc = Sailthru::Client->new( 'key', 'secret' );
# testing invalid key response
$response = $bad_sc->get_email('not_an_email');
is( $response->{error}, 3, 'testing error code on invalid key' );

my $sc;

SKIP: {
    skip 'requires an API key and secret', 1 if not defined $api_key or not defined $secret;

    # test bad secret
    $sc = Sailthru::Client->new( $api_key, 'invalid_secret' );
    $response = $sc->get_email('not_an_email');
    is( $response->{error}, 5, 'testing authentication failing error code' );

    # build a good client to use
    $sc = Sailthru::Client->new( $api_key, $secret );

    # test invalid email
    $response = $sc->get_email('not_an_email');
    is( $response->{error}, 11, 'testing error code on invalid email' );

    ############################################################
    # Grab template source/preview
    ############################################################

    # create template (or overwrite if already exists)
    my @lines = <DATA>;
    close DATA;
    $response = $sc->api_post( 'template', { template => $TEMPLATE, content_html => "@lines" } );
    is( $response->{error}, undef,     'no error creating template' );
    is( $response->{name},  $TEMPLATE, 'created template name matches' );

    # check retrieving template
    $response = $sc->get_template($TEMPLATE);
    is( $response->{name},         $TEMPLATE, 'retrieved template name matches' );
    is( $response->{content_html}, "@lines",  'retrieved template matches' );

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
    ok( not( $preview->{error} ), 'no error in preview' );
    like( $preview->{content_html}, qr/Hey/, 'found text' );
    unlike( $preview->{content_html}, qr/\Q{email}/, 'does not have variable' );
    like( $preview->{content_html}, qr/\Q@{[$EMAIL]}/, 'found email' );

    # schedule send, check that the send exists, delete send
    # test send
    my $schedule_time = "+12 hours";
    $response = $sc->send( $TEMPLATE, $EMAIL, {}, {}, $schedule_time );
    my $send_id = $response->{send_id};
    isnt( $send_id, undef, 'send created successfully' );
    is( $response->{status}, 'scheduled', 'send scheduled succesfully' );
    # test get_send
    $response = $sc->get_send($send_id);
    is( $response->{send_id}, $send_id, 'send retrieved succesfully' );
    # delete the send
    $response = $sc->api_delete( 'send', { send_id => $send_id } );
    is( $response->{ok}, 1, 'send deleted successfully' );

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
    is( $email->{errormsg}, undef, 'no error creating list' );
    $email = $sc->api_get( 'list', { list => $LIST } );
    is( $email->{list},     $LIST, 'email list exists' );
    is( $email->{errormsg}, undef, 'no error getting list' );

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
        # TODO test deprecated getEmail
        # TODO test deprecated setEmail
        # TODO test deprecated getSend
        # TODO test deprecated scheduleBlast
        # TODO test deprecated getBlast
        # TODO test deprecated copyTemplate
        # TODO test deprecated getTemplate
    }
}

SKIP: {
    skip 'requires an API key, a secret, and a Sailthru verified email', 1
      if not defined $api_key
      or not defined $secret
      or not defined $verified_email;

    my $blast_name    = "My new blast $TIMESTAMP";
    my $schedule_time = "+12 hours";
    my $blast_subject = "Hello! $TIMESTAMP";
    my $content_html  = "<p><b>Hello there.</b> $TIMESTAMP</p>";
    my $content_text  = "Hello there. $TIMESTAMP";
    $response = $sc->schedule_blast(
        $blast_name,     $LIST,          $schedule_time, 'FROM TEST',
        $verified_email, $blast_subject, $content_html,  $content_text
    );
    my $blast_id = $response->{blast_id};
    isnt( $blast_id, undef, 'blast created successfully' );
    #is( $response->{status}, 'scheduled', 'blast scheduled succesfully' );
    $response = $sc->get_blast($blast_id);
    is( $response->{blast_id}, $blast_id, 'blast retrieved succesfully' );
    $response = $sc->api_delete( 'blast', { blast_id => $blast_id } );
    is( $response->{ok}, 1, 'blast deleted successfully' );

    # TODO test schedule_blast_from_template
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
