use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'OntoExtract' }
BEGIN { use_ok 'OntoExtract::Controller::News' }

ok( request('/news')->is_success, 'Request should succeed' );
done_testing();
