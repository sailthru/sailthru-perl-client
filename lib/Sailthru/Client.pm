package Sailthru::Client;

# TODO compare old methods and new methods
# TODO deprecation warnings in old methods
# TODO new implementation of send

use strict;
use warnings;

our $VERSION = '2.000';
use constant API_URI => 'https://api.sailthru.com/';

use Carp;
use JSON::XS;
use LWP::UserAgent;
use Digest::MD5 'md5_hex';
use Params::Validate qw( :all );
use Encode qw( decode_utf8 encode_utf8 );

### helper methods

# args: params, secret
sub get_signature_hash {
    # TODO

    # XXX ruby implementation:
    # Digest::MD5.hexdigest(get_signature_string(params, secret)).to_s

    # XXX python implementation:
    # hashlib.md5(get_signature_string(params, secret)).hexdigest()

    return;
}

### class methods

sub new {
    my ( $class, $key, $secret, $timeout ) = @_;
    my %self = (
        api_key => $key,
        secret  => $secret,
        encoder => JSON::XS->new->ascii->allow_nonref,
        ua      => LWP::UserAgent->new,
    );
    $self{ua}->timeout($timeout) if $timeout;
    return bless \%self, $class;
}

# args: template, email, vars (optional), options (optional), schedule_time
# TODO are any of these args optional?
sub send_new {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR }, { type => SCALAR }, 0, 0, 0 );
    # TODO
}

# args: send_id
sub get_send {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR } );
    my $self = shift;
    my ($send_id) = @_;
    return $self->api_get( 'send', { send_id => $send_id } );
}

# args: email
sub get_email {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR } );
    my $self = shift;
    my ($email) = @_;
    return $self->api_get( 'email', { email => $email } );
}

# args: email, vars, lists, templates
sub set_email {
    validate_pos(
        @_,
        { type => OBJECT },
        { type => SCALAR },
        { type => HASHREF, default => {} },
        { type => HASHREF, default => {} },
        { type => HASHREF, default => {} }
    );
    my $self = shift;
    my ( $email, $vars, $lists, $templates ) = @_;
    my $data = {};
    $data->{email}     = $email;
    $data->{vars}      = $vars;
    $data->{lists}     = $lists;
    $data->{templates} = $templates;
    return $self->api_post( 'email', $data );
}

# args: name, list, schedule_time, from_name, from_email, subject, content_html, content_text, options
sub schedule_blast {
    validate_pos(
        @_,
        { type => OBJECT },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF, default => {} },
    );
    my $self = shift;
    my ( $name, $list, $schedule_time, $from_name, $from_email, $subject, $content_html, $content_text, $options ) = @_;
    my $data = $options;
    $data->{name}          = $name;
    $data->{list}          = $list;
    $data->{schedule_time} = $schedule_time;
    $data->{from_name}     = $from_name;
    $data->{from_email}    = $from_email;
    $data->{subject}       = $subject;
    $data->{content_html}  = $content_html;
    $data->{content_text}  = $content_text;
    return $self->api_post( 'blast', $data );
}

# args: template, list, schedule_time, options
sub schedule_blast_from_template {
    validate_pos(
        @_,
        { type => OBJECT },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF, default => {} },
    );
    my $self = shift;
    my ( $template, $list, $schedule_time, $options ) = @_;
    my $data = $options;
    $data->{copy_template} = $template;
    $data->{list}          = $list;
    $data->{schedule_time} = $schedule_time;
    return $self->api_post( 'blast', $data );

}

# args: blast_id
sub get_blast {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR } );
    my $self = shift;
    my ($blast_id) = @_;
    return $self->api_get( 'blast', { blast_id => $blast_id } );
}

# args: template_name
sub get_template {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR } );
    my $self = shift;
    my ($template_name) = @_;
    return $self->api_get( 'template', { template => $template_name } );
}

# args: action, data
sub api_get {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR }, { type => HASHREF } );
    my $self = shift;
    my ( $action, $data ) = @_;
    return $self->_api_request( $action, $data, 'GET' );
}

# args: action, data
# TODO: optional binary_key arg
sub api_post {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR }, { type => HASHREF } );
    my $self = shift;
    my ( $action, $data ) = @_;
    return $self->_api_request( $action, $data, 'POST' );
}

# args: action, data
sub api_delete {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR }, { type => HASHREF } );
    my $self = shift;
    my ( $action, $data ) = @_;
    return $self->_api_request( $action, $data, 'DELETE' );
}

# args: action, data, request_type
sub _api_request {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR }, { type => HASHREF }, { type => SCALAR } );
    my $self = shift;
    my ( $action, $data, $request_type ) = @_;
    $data = $self->_prepare_json_payload($data);
    my $action_uri = API_URI . $action;
    return $self->_http_request( $action_uri, $data, $request_type );
}

# args: uri, data, method
# TODO are any of these args optional?
sub _http_request {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR }, { type => HASHREF }, { type => SCALAR } );
    my $self = shift;
    my ( $uri, $data, $method ) = @_;
    # TODO the rest of this...
}

# args: data
sub _prepare_json_payload {
    validate_pos( @_, { type => OBJECT }, { type => HASHREF } );
    my $self    = shift;
    my ($data)  = @_;
    my $payload = {};
    $payload->{api_key} = $self->{api_key};
    $payload->{format}  = 'json';
    # TODO convert $data into json
    # XXX how are we doing this?
    $payload->{json} = 'XXX';
    $payload->{sig} = get_signature_hash( $payload, $self->{secret} );
    return $payload;
}

sub _generate_sig {
    my $self = shift;
    my $args = shift;
    # api_key should already be in args
    md5_hex( encode_utf8( decode_utf8( join( '', $self->{secret}, sort( values(%$args) ) ), Encode::FB_DEFAULT ) ) );
}

sub _call_api_raw {
    my ( $self, $method, $action, $json ) = @_;

    $json = $self->{encoder}->encode($json) if ref $json;
    my %data = ( api_key => $self->{api_key}, format => 'json', json => $json );
    $data{sig} = $self->_generate_sig( \%data );

    my $response;
    if ( $method eq 'GET' ) {
        my $url = URI->new( API_URI . $action );
        $url->query_form(%data);
        $response = $self->{ua}->get($url);
    }
    elsif ( $method eq 'POST' ) {
        $response = $self->{ua}->post( API_URI . $action, \%data );
    }
    else {
        croak "Invalid method: $method";
    }

    return $response;
}

sub call_api {
    my $self     = $_[0];
    my $response = &_call_api_raw;
    $self->{encoder}->decode( $response->content );
}

sub _call_api_with_arguments {
    my ( $self, $method, $action, $arg_names, $args ) = @_;
    my %data;

    if ( @$args > @$arg_names ) {
        my $opts = pop @$args;
        %data = %$opts;
    }

    croak "Extra arguments specified" if @$args > @$arg_names;

    foreach my $i ( 0 .. $#{$arg_names} ) {
        $data{ $arg_names->[$i] } = $args->[$i] if defined $args->[$i];
    }
    $self->_call_api( $method, $action, \%data );
}

sub getEmail {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR } );
    my ( $self, $email ) = @_;
    $self->_call_api( 'POST', 'email', { email => $email } );
}

sub setEmail {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR }, 0, 0, 0 );
    my $self   = shift;
    my @params = qw(email vars lists templates);
    $self->_call_api_with_arguments( 'POST', 'email', \@params, \@_ );
}

sub sendOld {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR }, { type => SCALAR }, 0, 0, 0 );
    my $self   = shift;
    my @params = qw(email vars lists options schedule_time);
    $self->_call_api_with_arguments( 'POST', 'send', \@params, \@_ );
}

sub getSend {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR } );
    my ( $self, $id ) = @_;
    $self->_call_api( 'GET', 'send', { send_id => $id } );
}

sub scheduleBlast {
    validate_pos(
        @_,
        { type => OBJECT },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        0
    );

    my $self   = shift;
    my @params = qw(name list schedule_time from_name from_email subject content_html content_text);
    $self->_call_api_with_arguments( 'POST', 'blast', \@params, \@_ );
}

sub getBlast {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR } );
    my ( $self, $id ) = @_;
    $self->_call_api( 'GET', 'blast', { blast_id => $id } );
}

sub copyTemplate {
    validate_pos(
        @_,
        { type => OBJECT },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        0
    );

    my $self   = shift;
    my @params = qw(copy_template data_feed_url setup name schedule_time list);
    $self->_call_api_with_arguments( 'POST', 'blast', \@params, \@_ );
}

sub getTemplate {
    validate_pos( @_, { type => OBJECT }, { type => SCALAR } );
    my ( $self, $t ) = @_;
    $self->call_api( 'GET', 'template', { template => $t } );
}

=head1 NAME

Sailthru::Client - Perl module for accessing Sailthru's API

=head1 SYNOPSIS

 use Sailthru::Client;

 # Optionally include timeout in seconds as the third parameter.
 $tm = Sailthru::Client->new('api_key','secret');

 %vars = (
    name => "Joe Example",
    from_email => "approved_email@your_domain.com",
    your_variable => "some_value"
 );
 %options = ( reply_to => "your reply_to header");

 $tm->send("template_name",'example@example.com',\%vars,\%options);

=head1 DESCRIPTION

Sailthru::Client is a Perl module for accessing the Sailthru API.

All methods return a hash with return values. Dump the hash or explore the
Sailthru API documentation page for what might be returned.

L<http://docs.sailthru.com/api>

Some options might change. Always consult the Sailthru API documentation for the best information.

=head2 METHODS

=over 4

=item B<call_api>( I<METHOD>, I<ACTION>, I<ARGUMENTS> )

This is the generic method to call the API; the specific methods are
implemented using this method, which can also be used to directly call APIs.

I<METHOD> is typically C<GET> or C<POST>.  I<ACTION> is the name of the API
to call.  I<ARGUMENTS> specifies the arguments to pass to the API; this
should be an expanded has that can be converted to JSON (although if a
scalar is passed in, it will be assumed to already be JSON).

For example, you could get information about an email with

 $sc->call_api('GET', 'email', {email=>'somebody@example.com'});

=item B<getEmail>( I<$email> )

=item B<setEmail>( $email, \%vars, \%lists, \%templates )

Takes email as string. vars, lists, templates as hash references.  The vars
hash you choose your own key/values for later substitution.  The lists hash
should be of format list_name => 1 for subscribed, 0 for unsubscribed.  The
templates hash is a list of templates user has opted out, use the key as the
template name to signal opt-out.

=item B<send>( $template, $email, \%vars, \%options, $schedule_time )

Send an email to a single address.
Takes template, email and schedule_time as strings. vars, options as hash references.

Options:

=over

=item I<replyto>

override Reply-To header

=item I<test>

send as test email (subject line will be marked, will not count towards stats)

=back

=item B<getSend>( $send_id )

Check if send worked, using send_id returned in the hash from send()

=item B<scheduleBlast>( $name, $list, $schedule_time, $from_name, $from_email, $subject, $content_html, $content_text, \%options )

Schedule an email blast. See the API documentation for more details on what should be passed.

L<http://docs.sailthru.com/api/blast>

=item B<getBlast>( I<$blast_id> )

Check if blast worked, using blast_id returned in the hash from scheduleBlast()
Takes I<blast_id>.

=item B<copyTemplate>( $template_name, $data_feed, $setup, $subject_line, $schedule_time, $list, \%options )

Allows you to use an existing template to send out a blast.

=item B<getTemplate>( $template_name )

Retrieves information about the specified template

=back

=head1 SEE ALSO

See the Sailthru API documentation for more details on their API.

L<http://docs.sailthru.com/api>

=head1 AUTHOR

Steve Sanbeg

Steve Miketa

Sam Gerstenzang

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 by Steve Sanbeg <stevesanbeg@buzzfeed.com>

Adapted from the original SailthruClient & Triggermail modules created by
Sam Gerstenzang and Steve Miketa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

1;
