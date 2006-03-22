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

package TomKitTest::TestUtil;

use Exporter();
use Digest::MD5 qw( md5_hex );
use Apache::TestConfig;

@ISA = qw(Exporter);
@EXPORT = qw(&loadExpectedResult &loadCachedData &updateTimestamp &modifyCache &precalculateSimpleCacheKey );


sub loadExpectedResult {
	my $filename = shift;
	my $data_expected;
	
	open(EXPECTED,"<$filename") or die "Could not open file: $filename";
	local $/= undef;
	$data_expected = <EXPECTED>;
	close(EXPECTED);
	return $data_expected;
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

sub modifyCache {
	my $filename = shift;
	
	open( CACHED, ">>$filename" );
	print CACHED "<cached />";
	close( CACHED );
	
}

sub precalculateSimpleCacheKey {
	my $uri = shift;
	my $vars = Apache::Test::config()->{vars};

	return md5_hex( $vars->{servername} . $uri );
}

1;
