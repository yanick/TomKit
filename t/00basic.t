use strict;
use warnings FATAL => 'all';

use Apache2::TomKit;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 2;

ok 1; # simple load test

my $data_retrieved = GET_BODY "/index.xml";
my $data_expected;

{
open(EXPECTED,"<t/expected-results/index.xml") or die "Could not open file";
local $/= undef;
$data_expected = <EXPECTED>;
close(EXPECTED);
}

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test",
);