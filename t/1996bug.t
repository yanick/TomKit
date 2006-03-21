use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Apache2::TomKit;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET GET_BODY );
use Apache2::Const qw(HTTP_INTERNAL_SERVER_ERROR);
use File::Path;
use TomKitTest::TestUtil;

plan tests => 1;

my $res = GET "/bug1996/test.xml";
ok $res->code == HTTP_INTERNAL_SERVER_ERROR;