## -----------------------------------------------------------------
## Copyright (c) 2005-2006 BestSolution.at EDV Systemhaus GmbH
## All Rights Reserved.
##
## BestSolution.at GmbH MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE
## SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING
## BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
## BestSolution.at GmbH SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY
## LICENSEE AS A RESULT OF USING, MODIFYING OR DISTRIBUTING THIS
## SOFTWARE OR ITS DERIVATIVES.
## ----------------------------------------------------------------
##
## This library is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself, either Perl version 5.8.6 or,
## at your option, any later version of Perl 5 you may have available.
##

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
use File::Path;
use TomKitTest::TestUtil;

plan tests => 1;

rmtree "t/tmp";

## ----------------------------------------
## TEST 1
## ----------------------------------------
## + cache has to be created
## + check expected result

my $data_retrieved = GET_BODY "/processorinxml/base.xml";
$data_retrieved =~ s/\s//g;

my $data_expected = &loadExpectedResult("t/expected-results/processorinxml/base-test.txt");

open( OUT, ">/tmp/req" );
print OUT $data_retrieved . "\n";
print OUT $data_expected;
close( OUT );

ok t_cmp(
	$data_expected,
	$data_retrieved,
	"provider def in XML provider",
);

#$data_retrieved = &loadCachedData( "t/tmp/axkittest/a65d3eef3a0483b2f6a43ef81596f3af/content" );

#ok t_cmp (
#	$data_expected,
#	$data_retrieved,
#	"custom provider cache created",
#);
