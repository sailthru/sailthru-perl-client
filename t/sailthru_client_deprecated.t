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

# mock so we don't actually make a call out to the network
# we'll use api_req_args to grab and hold on to the arguments passed in to compare
my $api_req_args;
$module->mock(
    _api_request => sub {
        my $self = shift;
        $api_req_args = \@_;
    }
);

my $sc = Sailthru::Client->new( $API_KEY, '00001111222233334444555566667777' );
isa_ok( $sc, 'Sailthru::Client' );

# supress deprecation warnings since we're testing deprecated methods
no warnings 'deprecated';

# helper method to verify object methods
sub verify_object_method {
    my ( $object_method, $args, $req_type, $api_action ) = @_;
    # clear saved args from mock
    $api_req_args = undef;
    # is the method in the module?
    can_ok( $sc, $object_method );
    lives_ok( sub { $sc->$object_method( @{$args} ) }, "$object_method: lives when called" );
    # see if right API action was accessed
    is( $api_req_args->[0], $api_action, "$object_method: api action '$api_action' was called" );
    # make sure the http request verb matches
    is( $api_req_args->[2], $req_type, "$object_method: request type was $req_type" );
}

my $object_method;
my $expected_req_type;
my $expected_api_action;
my @args;

# test getSend
$object_method       = 'getSend';
@args                = ('my-send-id-alskdjfals');
$expected_req_type   = 'GET';
$expected_api_action = 'send';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

# test get_email
$object_method       = 'getEmail';
@args                = ('anemail@email.com');
$expected_req_type   = 'GET';
$expected_api_action = 'email';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

# test set_email
$object_method = 'setEmail';
my %vars  = my %save_vars  = ( var1  => 'foo', var2  => 'bar', var3  => 'baz' );
my %lists = my %save_lists = ( list1 => 1,     list2 => 0,     list3 => 1 );
my %templates = my %save_templates = ( template1 => 0, template2 => 1 );
@args                = ( 'atestemail@email.com', \%vars, \%lists, \%templates );
$expected_req_type   = 'POST';
$expected_api_action = 'email';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# make sure hashes weren't munged
is_deeply( \%vars,      \%save_vars,      "$object_method: vars hash wasn't changed" );
is_deeply( \%lists,     \%save_lists,     "$object_method: lists hash wasn't changed" );
is_deeply( \%templates, \%save_templates, "$object_method: templates hash wasn't changed" );

# test schedule_blast
$object_method = 'scheduleBlast';
my %options = my %save_options = ( replyto => 'someotheremail@email.com' );
@args = (
    'blast name', 'list to send to',
    '+3 hours', 'From Name', 'fromemail@email.com',
    'Blast Subject Line',
    '<p><b>Some</b> html content!</p>',
    'Some text content', \%options
);
$expected_req_type   = 'POST';
$expected_api_action = 'blast';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# make sure hash wasn't munged
is_deeply( \%options, \%save_options, "$object_method: options hash wasn't changed" );

# test getBlast
$object_method       = 'getBlast';
@args                = ('blast-id-sldkjfsdk');
$expected_req_type   = 'GET';
$expected_api_action = 'blast';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

# test getTemplate
$object_method       = 'getTemplate';
@args                = ('template name');
$expected_req_type   = 'GET';
$expected_api_action = 'template';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

# test copyTemplate
$object_method = 'copyTemplate';
%options       = %save_options = ();
@args          = (
    'template name',
    'my-template',
    'http://example.com/datafeed.json',
    '{content = horizon_select(content, 5)}',
    'blast-test-1', '+3 hours', \%options
);
$expected_req_type   = 'POST';
$expected_api_action = 'blast';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# make sure hash wasn't munged
is_deeply( \%options, \%save_options, "$object_method: options hash wasn't changed" );

# test importContacts
$object_method       = 'importContacts';
@args                = ( 'anemail@email.com', 'password12345', 1 );
$expected_req_type   = 'POST';
$expected_api_action = 'contacts';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

done_testing;
