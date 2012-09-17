use strict;
use warnings;

use lib 'lib';

use Test::More;

use JSON::XS;
use Sailthru::Client;

#
# test the extraction / signature / hashing functions in Sailthru::Client
#

my $api_key = 'abcdef1234567890abcdef1234567890';
my $secret  = '00001111222233334444555566667777';
my $sc      = Sailthru::Client->new( $api_key, $secret );

my $sig;
my $args = {
    email         => 'test@example.com',
    format        => 'xml',
    'vars[myvar]' => 'TestValue',
    optout        => 0,
    api_key       => $api_key,
};

$sig = Sailthru::Client::get_signature_hash( $args, $secret );
is( $sig, 'b0c1ba5e661d155a940da08ed240cfb9', 'get_signature_hash with multiple arguments' );

$args = {
    api_key => $api_key,
    format  => 'json',
    json    => encode_json( { email => 'stevesanbeg@buzzfeed.com', lists => { Test => 1 } } ),
};

$sig = Sailthru::Client::get_signature_hash( $args, $secret );
is( $sig, '62c9f19c053146634d94d531e2492438', 'get_signature_hash with JSON' );

# data for testing extraction and signature hash functions
$secret = '123456';
my $simple_args = {
    'unix'    => [ 'Linux', 'Mac', 'Solaris' ],
    'windows' => 'None'
};
my @simple_values = sort 'Linux', 'Mac', 'Solaris', 'None';
my $nested_args = {
    'US' => [ { 'New York' => [ 'Queens', 'New York', 'Brooklyn' ] }, 'Virginia', 'Washington DC', 'Maryland' ],
    'Canada' => [ 'Ontario', 'Quebec', 'British Columbia' ]
};
my @nested_values = sort 'Queens', 'New York', 'Brooklyn', 'Virginia', 'Washington DC', 'Maryland', 'Ontario', 'Quebec',
  'British Columbia';
my @extracted_values;

# test extract_params with simple hash
@extracted_values = sort @{ Sailthru::Client::extract_param_values($simple_args) };
is_deeply( \@extracted_values, \@simple_values, 'test extract_param_values with simple hash' );

# test extract_params with nested hash
@extracted_values = sort @{ Sailthru::Client::extract_param_values($nested_args) };
is_deeply( \@extracted_values, \@nested_values, 'test extract_param_values with nested hash' );

# test signature_string
my $expected = $secret . join '', @simple_values;
my $signature_string = Sailthru::Client::get_signature_string( $simple_args, $secret );
is( $signature_string, $expected, 'get_signature_string from simple hash' );

done_testing;
