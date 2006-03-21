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

package TomKitTest::CustomProvider;

use Apache2::Const;
use Apache2::RequestIO;

use base qw(Apache2::TomKit::Provider::FileSystemProvider);

sub thandler {
	my $this = shift;
	my $apr  = shift;
	
	$this->{logger}->debug( 10, "Handler is called" );
	
	my $content = ${ $this->getFileContent() };
	
	$content =~ s/A1/C1/;
	
	$apr->print( $content );
	
	return Apache2::Const::OK;
}

1;