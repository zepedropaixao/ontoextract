use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'OntoExtract' }
BEGIN { use_ok 'OntoExtract::Controller::Role' }

ok( request('/role')->is_success, 'Request should succeed' );
done_testing();
