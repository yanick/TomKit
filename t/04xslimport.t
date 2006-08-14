use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Apache2::TomKit;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
use File::Path;
use TomKitTest::TestUtil;


plan tests => 2;


rmtree "t/tmp";

my $baseCacheKey = &precalculateSimpleCacheKey("/xsl-import/base.xml");

my $data_retrieved = GET_BODY "/xsl-import/base.xml";
$data_retrieved =~ s/\s//g;

my $data_expected = &loadExpectedResult("t/expected-results/xsl-import/base-test.txt");
$data_expected =~ s/\s//g;

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test",
);


# Check if cache is created and used appropriately
&modifyCache("t/tmp/axkittest/$baseCacheKey/content");

$data_retrieved = GET_BODY "/xsl-import/base.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xsl-import/base-cached-test.txt");
$data_expected =~ s/\s//g;

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test",
);
