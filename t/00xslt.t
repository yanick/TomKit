use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Apache2::TomKit;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
use File::Path;
use TomKitTest::TestUtil;


plan tests => 8;


rmtree "t/tmp";

my $baseCacheKey = &precalculateSimpleCacheKey("/xslt/base.xml"); 
my $chainCacheKey = &precalculateSimpleCacheKey("/xslt/chain.xml"); 


## ----------------------------------------
## TEST 1
## ----------------------------------------
## + cache has to be created
## + check expected result

my $data_retrieved = GET_BODY "/xslt/base.xml";
$data_retrieved =~ s/\s//g;

my $data_expected = &loadExpectedResult("t/expected-results/xslt/base-test.txt");

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test",
);

$data_retrieved = &loadCachedData( "t/tmp/axkittest/$baseCacheKey/content" );

ok t_cmp (
	$data_expected,
	$data_retrieved,
	"basic test cache created",
);



## ----------------------------------------
## TEST 2
## ----------------------------------------
## + cache has to be created
## + check expected result

$data_retrieved = GET_BODY "/xslt/chain.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xslt/chain-test.txt");

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"chain test",
);

$data_retrieved = &loadCachedData( "t/tmp/axkittest/$chainCacheKey/content" );

ok t_cmp (
	$data_expected,
	$data_retrieved,
	"basic test cache created",
);




## ----------------------------------------
## TEST 3
## ----------------------------------------
## + nochain: content has to be retrieved from cache
## + with chain: content has to be retrieved from cache

&modifyCache("t/tmp/axkittest/$baseCacheKey/content");

$data_retrieved = GET_BODY "/xslt/base.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xslt/base-cached-test.txt");

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test cache",
);


&modifyCache("t/tmp/axkittest/$chainCacheKey/content");

$data_retrieved = GET_BODY "/xslt/chain.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xslt/chain-cached-test.txt");

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"chain test cache",
);



## ----------------------------------------
## TEST 4
## ----------------------------------------
## + nochain: cache invalidated by modified source
## + nochain: cache invalidated by modified xslt

&modifyCache("t/tmp/axkittest/$baseCacheKey/content");
&updateTimestamp("t/htdocs/xslt/base.xml",1);

$data_retrieved = GET_BODY "/xslt/base.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xslt/base-test.txt");


ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test source xml modified",
);

&modifyCache("t/tmp/axkittest/$baseCacheKey/content");
&updateTimestamp("t/htdocs/xslt/base.xsl",1);

$data_retrieved = GET_BODY "/xslt/base.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xslt/base-test.txt");


ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test source xml modified",
);

