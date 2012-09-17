use strict;
use warnings;

use Test::More;
use Readonly;

#
# test the client functions with the API/network mocked
#

use lib 'lib';
use_ok('Sailthru::Client');

# TODO mock out so network / http / api calls are not actually made (do this with fixtures?)

# TODO test new

# TODO test helper _prepare_json_payload

# TODO test send
# TODO test get_send
# TODO test get_email
# TODO test set_email
# TODO test schedule_blast
# TODO test schedule_blast_from_template
# TODO test get_blast
# TODO test get_template
# TODO test api_get
# TODO test api_post
# TODO test api_delete

# temporarily suppress deprecation warnings
{
    no warnings 'deprecated';
    # TODO test getEmail
    # TODO test setEmail
    # TODO test getSend
    # TODO test scheduleBlast
    # TODO test getBlast
    # TODO test copyTemplate
    # TODO test getTemplate
    # TODO test importContacts
}

done_testing;
