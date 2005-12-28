use strict;
use warnings FATAL => 'all';

use Apache2::TomKit;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
use File::Path;

plan tests => 8;

sub modifyCache {
	my $filename = shift;
	
	open( CACHED, ">>$filename" );
	print CACHED "<cached />";
	close( CACHED );
	
}

sub loadCachedData {
	my $filename = shift;
	my $data_retrieved;
	
	open(EXPECTED,"<$filename") or die "Could not open file: $filename";
	
	local $/= undef;
	$data_retrieved = <EXPECTED>;
	close(EXPECTED);
	$data_retrieved =~ s/\s//g;
	
	return $data_retrieved;
}

sub updateTimestamp {
	my $filename = shift;
	my $amount   = shift || 1;
	
	my $time = time;
	utime $time+$amount, $time+$amount, "$filename";
}

sub loadExpectedResult {
	my $filename = shift;
	my $data_expected;
	
	open(EXPECTED,"<$filename") or die "Could not open file: $filename";
	local $/= undef;
	$data_expected = <EXPECTED>;
	close(EXPECTED);
	return $data_expected;
}

rmtree "t/tmp";

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

$data_retrieved = &loadCachedData( "t/tmp/axkittest/3a4b76c920aa5905537db36fe62a917f/content" );

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

$data_retrieved = &loadCachedData( "t/tmp/axkittest/fdd87d29fa5b59d8ccc5f76084907a93/content" );

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

&modifyCache("t/tmp/axkittest/3a4b76c920aa5905537db36fe62a917f/content");

$data_retrieved = GET_BODY "/xslt/base.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xslt/base-cached-test.txt");

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test cache",
);


&modifyCache("t/tmp/axkittest/fdd87d29fa5b59d8ccc5f76084907a93/content");

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

&modifyCache("t/tmp/axkittest/3a4b76c920aa5905537db36fe62a917f/content");
&updateTimestamp("t/htdocs/xslt/base.xml",1);

$data_retrieved = GET_BODY "/xslt/base.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xslt/base-test.txt");


ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test source xml modified",
);

&modifyCache("t/tmp/axkittest/3a4b76c920aa5905537db36fe62a917f/content");
&updateTimestamp("t/htdocs/xslt/base.xsl",1);

$data_retrieved = GET_BODY "/xslt/base.xml";
$data_retrieved =~ s/\s//g;

$data_expected = &loadExpectedResult("t/expected-results/xslt/base-test.txt");


ok t_cmp(
	$data_expected,
	$data_retrieved,
	"basic test source xml modified",
);

