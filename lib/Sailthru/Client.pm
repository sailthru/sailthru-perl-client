package Sailthru::Client;

use strict;
use warnings;

use Carp;
use JSON::XS;
use LWP::UserAgent;
use Digest::MD5 qw( md5_hex );
use Params::Validate qw( :all );
use Readonly;
use URI;

our $VERSION = '2.000';
Readonly my $API_URI => 'https://api.sailthru.com/';

#
# helpers
#

# Every request must also generate a signature hash called sig according to the
# following rules:
#
# * take the string values of every parameter, including api_key
# * sort the values alphabetically, case-sensitively (i.e. ordered by Unicode code point)
# * concatenate the sorted values, and prepend this string with your shared secret
# * generate an MD5 hash of this string and use this as sig
# * now generate your URL-encoded query string from your parameters plus sig

# args:
# * params - hashref
# * secret - scalar
sub get_signature_string {
    validate_pos( @_, { type => HASHREF }, { type => SCALAR } );
    my ( $params, $secret ) = @_;
    my @param_values = values %{$params};
    return join '', $secret, sort @param_values;
}

# args:
# * params - hashref
# * secret - scalar
sub get_signature_hash {
    validate_pos( @_, { type => HASHREF }, { type => SCALAR } );
    my ( $params, $secret ) = @_;
    # assumes utf8 encoded text, works fine because we use encode_json internally
    return md5_hex( get_signature_string( $params, $secret ) );
}

#
# public api
#

sub new {
    my ( $class, $key, $secret, $timeout ) = @_;
    my $self = {
        api_key => $key,
        secret  => $secret,
        ua      => LWP::UserAgent->new,
    };
    $self->{ua}->timeout($timeout) if $timeout;
    $self->{ua}->default_header( 'User-Agent' => "Sailthru API Perl Client $VERSION" );
    return bless $self, $class;
}

# args:
#
# * template - scalar
# * email - scalar
# * vars - hashref (optional)
# * options - hashref (optional)
# * schedule_time - scalar (optional)
sub send {
    my $self = shift;
    validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF, default => {} },
        { type => HASHREF, default => {} },
        { type => SCALAR, default => undef }
    );
    my ( $template, $email, $vars, $options, $schedule_time ) = @_;
    my $data = {};
    $data->{template}      = $template;
    $data->{email}         = $email;
    $data->{vars}          = $vars if keys %{$vars};
    $data->{options}       = $options if keys %{$options};
    $data->{schedule_time} = $schedule_time if $schedule_time;
    return $self->api_post( 'send', $data );
}

# args:
# * send_id - scalar
sub get_send {
    my $self = shift;
    validate_pos( @_, { type => SCALAR } );
    my ($send_id) = @_;
    return $self->api_get( 'send', { send_id => $send_id } );
}

# args:
# * email - scalar
sub get_email {
    my $self = shift;
    validate_pos( @_, { type => SCALAR } );
    my ($email) = @_;
    return $self->api_get( 'email', { email => $email } );
}

# args:
# * email - scalar
# * vars - hashref (optional)
# * lists - hashref (optional)
# * templates - hashref (optional)
sub set_email {
    my $self = shift;
    validate_pos(
        @_,
        { type => SCALAR },
        { type => HASHREF, default => {} },
        { type => HASHREF, default => {} },
        { type => HASHREF, default => {} }
    );
    my ( $email, $vars, $lists, $templates ) = @_;
    my $data = {};
    $data->{email}     = $email;
    $data->{vars}      = $vars if keys %{$vars};
    $data->{lists}     = $lists if keys %{$lists};
    $data->{templates} = $templates if keys %{$templates};
    return $self->api_post( 'email', $data );
}

# args:
# * name - scalar
# * list - scalar
# * schedule_time - scalar
# * from_name - scalar
# * from_email - scalar
# * subject - scalar
# * content_html - scalar
# * content_text - scalar
# * options - hashref (optional)
sub schedule_blast {
    my $self = shift;
    validate_pos(
        @_,
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

# args:
# * template - scalar
# * list - scalar
# * schedule_time - scalar
# * options - hashref (optional)
sub schedule_blast_from_template {
    my $self = shift;
    validate_pos( @_, { type => SCALAR }, { type => SCALAR }, { type => SCALAR }, { type => HASHREF, default => {} }, );
    my ( $template, $list, $schedule_time, $options ) = @_;
    my $data = $options;
    $data->{copy_template} = $template;
    $data->{list}          = $list;
    $data->{schedule_time} = $schedule_time;
    return $self->api_post( 'blast', $data );

}

# args:
# * blast_id - scalar
sub get_blast {
    my $self = shift;
    validate_pos( @_, { type => SCALAR } );
    my ($blast_id) = @_;
    return $self->api_get( 'blast', { blast_id => $blast_id } );
}

# args:
# * template_name - scalar
sub get_template {
    my $self = shift;
    validate_pos( @_, { type => SCALAR } );
    my ($template_name) = @_;
    return $self->api_get( 'template', { template => $template_name } );
}

# args:
# * action - scalar
# * data - hashref
sub api_get {
    my $self = shift;
    validate_pos( @_, { type => SCALAR }, { type => HASHREF } );
    my ( $action, $data ) = @_;
    return $self->_api_request( $action, $data, 'GET' );
}

# args:
# * action - scalar
# * data - hashref
# * TODO: optional binary_key arg
sub api_post {
    my $self = shift;
    validate_pos( @_, { type => SCALAR }, { type => HASHREF } );
    my ( $action, $data ) = @_;
    return $self->_api_request( $action, $data, 'POST' );
}

# args:
# * action - scalar
# * data - hashref
sub api_delete {
    my $self = shift;
    validate_pos( @_, { type => SCALAR }, { type => HASHREF } );
    my ( $action, $data ) = @_;
    return $self->_api_request( $action, $data, 'DELETE' );
}

# args:
# * action - scalar
# * data - hashref
# * request_type - scalar
sub _api_request {
    my $self = shift;
    validate_pos( @_, { type => SCALAR }, { type => HASHREF }, { type => SCALAR } );
    my ( $action, $data, $request_type ) = @_;
    my $payload    = $self->_prepare_json_payload($data);
    my $action_uri = $API_URI . $action;
    my $response   = $self->_http_request( $action_uri, $payload, $request_type );
    return decode_json( $response->content );
}

# args:
# * uri - scalar
# * data - hashref
# * method - scalar
sub _http_request {
    my $self = shift;
    validate_pos( @_, { type => SCALAR }, { type => HASHREF }, { type => SCALAR } );
    my ( $uri, $data, $method ) = @_;
    $uri = URI->new($uri);
    my $response;
    if ( $method eq 'GET' ) {
        $uri->query_form($data);
        $response = $self->{ua}->get($uri);
    }
    elsif ( $method eq 'POST' ) {
        $response = $self->{ua}->post( $uri, $data );
    }
    elsif ( $method eq 'DELETE' ) {
        $uri->query_form($data);
        $response = $self->{ua}->delete($uri);
    }
    else {
        croak "Invalid method: $method";
    }
    return $response;
}

# args:
# * data - hashref
sub _prepare_json_payload {
    my $self = shift;
    validate_pos( @_, { type => HASHREF } );
    my ($data) = @_;
    my $payload = {};
    $payload->{api_key} = $self->{api_key};
    $payload->{format}  = 'json';
    # this gives us nice clean utf8 encoded json text
    $payload->{json} = encode_json($data);
    $payload->{sig} = get_signature_hash( $payload, $self->{secret} );
    return $payload;
}

### XXX
### DEPRECATED METHODS
### XXX

# args:
# * email - scalar
sub getEmail {
    my $self = shift;
    warnings::warnif( 'deprecated', 'getEmail is deprecated, use get_email instead' );
    return $self->get_email(@_);
}

# args:
# * email - scalar
# * vars - hashref (optional)
# * lists - hashref (optional)
# * templates - hashref (optional)
sub setEmail {
    my $self = shift;
    warnings::warnif( 'deprecated', 'setEmail is deprecated, use set_email instead' );
    return $self->set_email(@_);
}

# args:
# * send_id - scalar
sub getSend {
    my $self = shift;
    warnings::warnif( 'deprecated', 'getSend is deprecated, use get_send instead' );
    return $self->get_send(@_);
}

# args:
# * name - scalar
# * list - scalar
# * schedule_time - scalar
# * from_name - scalar
# * from_email - scalar
# * subject - scalar
# * content_html - scalar
# * content_text - scalar
# * options - hashref (optional)
sub scheduleBlast {
    my $self = shift;
    warnings::warnif( 'deprecated', 'scheduleBlast is deprecated, use schedule_blast instead' );
    return $self->schedule_blast(@_);
}

# args:
# * blast_id - scalar
sub getBlast {
    my $self = shift;
    warnings::warnif( 'deprecated', 'getBlast is deprecated, use get_blast instead' );
    return $self->get_blast(@_);
}

sub copyTemplate {
    my $self = shift;
    validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF, default => {} }
    );
    my ( $template, $data_feed, $setup, $subject_line, $schedule_time, $list, $options ) = @_;
    warnings::warnif( 'deprecated', 'copyTemplate is deprecated, use schedule_blast_from_template instead' );
    my $data = $options;
    $data->{copy_template} = $template;
    $data->{data_feed_url} = $data_feed;
    $data->{setup}         = $setup;
    $data->{name}          = $subject_line;
    $data->{schedule_time} = $schedule_time;
    $data->{list}          = $list;
    return $self->api_post( 'blast', $data );
}

# args:
# * template_name - scalar
sub getTemplate {
    my $self = shift;
    warnings::warnif( 'deprecated', 'getTemplate is deprecated, use get_template instead' );
    return $self->get_template(@_);
}

# args:
# * email - scalar
# * password - scalar
# * include_names - scalar (optional)
sub importContacts {
    my $self = shift;
    validate_pos( @_, { type => SCALAR }, { type => SCALAR }, { type => SCALAR, default => 0 } );
    my ( $email, $password, $include_names ) = @_;
    warnings::warnif( 'deprecated',
        'importContacts is deprecated. The contacts API has been discontinued as of August 1st, 2011.' );
    my $data = {
        email         => $email,
        password      => $password,
        include_names => $include_names,
    };
    return $self->api_post( 'contacts', $data );
}

1;

# TODO update documentation

__END__

=head1 NAME

Sailthru::Client - Perl module for accessing Sailthru's API

=head1 SYNOPSIS

 use Sailthru::Client;

 # Optionally include timeout in seconds as the third parameter.
 $tm = Sailthru::Client->new('api_key', 'secret');

 %vars = (
    name => "Joe Example",
    from_email => "approved_email@your_domain.com",
    your_variable => "some_value"
 );
 %options = ( reply_to => "your reply_to header");

 $tm->send("template_name", 'example@example.com', \%vars, \%options);

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

Steve Miketa

Sam Gerstenzang

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 by Steve Miketa <steve@sailthru.com>

Adapted from the original SailthruClient & Triggermail modules created by
Sam Gerstenzang and Steve Miketa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
