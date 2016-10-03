use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'OntoExtract' }
BEGIN { use_ok 'OntoExtract::Controller::RelatedURL' }

ok( request('/relatedurl')->is_success, 'Request should succeed' );
done_testing();
