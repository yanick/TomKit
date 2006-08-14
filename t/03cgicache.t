use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Apache2::TomKit;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
use File::Path;
use TomKitTest::TestUtil;


plan tests => 3;


rmtree "t/tmp";

my $time = time;
my $baseCacheKey = &precalculateSimpleCacheKey("/cgicache/base.xml;checkIt=>$time");

my $data_retrieved = GET_BODY "/cgicache/base.xml?checkIt=" . $time;
$data_retrieved =~ s/\s//g;

my $data_expected = &loadExpectedResult("t/expected-results/cgicache/base-test.txt");

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test",
);


# Check if cache is created and used appropriately
&modifyCache("t/tmp/axkittest/$baseCacheKey/content");

$data_retrieved = GET_BODY "/cgicache/base.xml?checkIt=" . $time;
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/cgicache/base-cached-test.txt");

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test",
);


# Check if the cache is invalidated when a new key is used
$data_retrieved = GET_BODY "/cgicache/base.xml?checkIt=" . ($time+1);
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/cgicache/base-test.txt");

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test",
);
