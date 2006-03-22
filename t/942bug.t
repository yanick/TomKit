use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Apache2::TomKit;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET GET_BODY );
use Apache2::Const qw(HTTP_OK);
use File::Path;
use TomKitTest::TestUtil;


plan tests => 5;

rmtree "t/tmp";

my $baseCacheKey = &precalculateSimpleCacheKey("/bug942/test.xml");

## ----------------------------------------
## TEST 1
## ----------------------------------------
## + cache has to be created
## + check expected result

my $res = GET "/bug942/test.xml";
ok $res->code == HTTP_OK;

my $data_expected = &loadExpectedResult("t/expected-results/bug942/result.txt");
my $data_retrieved = $res->content;
$data_retrieved =~ s/\s//g;

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"dependencies in document base test",
);

$data_retrieved = &loadCachedData( "t/tmp/axkittest/$baseCacheKey/content" );
$data_retrieved =~ s/\s//g;

ok t_cmp (
	$data_expected,
	$data_retrieved,
	"dependencies in document base test",
);

## ----------------------------------------
## TEST 2
## ----------------------------------------
## content has to be retrieved from cache

&modifyCache("t/tmp/axkittest/$baseCacheKey/content");

$data_retrieved = GET_BODY "/bug942/test.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/bug942/result-cached.txt");

ok t_cmp (
	$data_retrieved,
	$data_expected,
	"dependencies in document test cache",
);

## ----------------------------------------
## TEST 2
## ----------------------------------------
## content has to be retrieved from cache because dependency document is modified

&updateTimestamp("t/htdocs/bug942/simple.xml",2);

$data_retrieved = GET_BODY "/bug942/test.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/bug942/result.txt");

ok t_cmp (
	$data_retrieved,
	$data_expected,
	"dependencies in document invalidated cache",
);
