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

package Apache2::TomKit::Provider::FileSystemProvider;

use Apache2::RequestIO;
use Apache2::RequestRec;
use Apache2::Const;
use strict;

use base qw( Apache2::TomKit::IProvider );

sub new {
	my $class  = shift;
	my $logger = shift;
	my $config = shift;
	
	$logger->debug(10, "New File Provider created");
	
	bless {
		logger => $logger,
		config => $config
	}, $class;
}

sub thandler {
	my $this = shift;
	my $apr  = shift;
    $apr->sendfile($apr->filename);
    
    return Apache2::Const::OK;
}

sub getFileContent {
	my $logger = $_[0]->{logger};
	my $contentRef = $_[0]->{config}->{apr}->slurp_filename;
	
	if( $logger->isLevelActive(10) ) {
		$logger->debug(10, "Loaded content: " . ${ $contentRef } );
	}
	
	return $contentRef;
}

sub getMTime {
    return $_[0]->{config}->{apr}->finfo()->mtime;
}

sub createsDom {
    return 0;
}

1;