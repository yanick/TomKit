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

package Apache2::TomKit::Processor::DefinitionProvider::AbstractProvider;

use strict;
use Carp;
 
sub new {
    my $class  = shift;
    my $logger = shift;
    my $config = shift;


    my $this = bless { logger => $logger, config => $config }, $class;

    $this->init(@_);

    return $this;
}

sub init {
}

sub getProtocol {
    carp "Subclasses have to implement this method";
}

sub getMTime {
    carp "Subclasses have to implement this method";
}

sub getInstructions {
    carp "Subclasses have to implement this method";
}


sub isFile {
    return 1;
}

sub getKey {
    carp "Subclasses have to implement this method";
}

1;