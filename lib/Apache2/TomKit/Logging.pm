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

package Apache2::TomKit::Logging;

use Apache2::Request;
use Apache2::RequestRec;
use Apache2::Log;
use warnings;
use strict;

sub new {
    my $class  = shift;
    my $config = shift;

    bless {
        debugLevel => ($config->getDebugLevel() || 0),
        apr        => $config->{apr}
    }, $class;
}

sub debug {
    my $this    = shift;
    my $level   = shift;
    my $message = shift;

    if( $level <= $this->{debugLevel} ) {
    	my ($package, $filename, $line, $subroutine) = caller(1);
    	$subroutine =~ s/Apache2/A2/;
    	$subroutine =~ s/TomKit/T/;
        $this->{apr}->log_error( "$subroutine(Line: $line): " . $message );
    }
}

sub isLevelActive {
	return $_[1] <= $_[0]->{debugLevel};
}

1;
