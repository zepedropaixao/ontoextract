use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'OntoExtract' }
BEGIN { use_ok 'OntoExtract::Controller::Organization' }

ok( request('/organization')->is_success, 'Request should succeed' );
done_testing();
