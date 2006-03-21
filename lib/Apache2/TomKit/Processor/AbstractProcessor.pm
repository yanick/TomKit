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

package Apache2::TomKit::Processor::AbstractProcessor;

use strict;
use warnings;
use Carp;

sub new {
    my $class  = shift;
    my $logger = shift;
    my $config = shift;

    my $this = bless { logger => $logger, config => $config, dependencies => [] }, $class;

    $this->init();

    return $this;
}

sub init {
    carp "Sub classes must implement this method";
}

sub process {
	carp "Sub classes must implement this method";
}

sub getMTime {
	carp "Sub classes must implement this method";
}

sub createsXML {
    carp "Sub classes must implement this method";
}

sub createsDom {
    carp "Sub classes must implement this method";
}

sub getContentType {
    carp "Sub classes must implement this method";
}

sub getMappingType {
	carp "Sub classes must implement this method";
}

sub getProcessorDefinition {
	carp "Sub classes must implement this method";
}



sub setUp {
}


sub addDependency {
    my $this       = shift;
    my $dependency = shift;

    $this->{logger}->debug(8,"Adding dependeny: " . $dependency );

    push @{ $this->{dependencies} }, $dependency;
}


sub startUp {
    my $class = shift;
    my $config = shift;
}

sub shutDown {
    my $class = shift;
    my $config = shift;
}



1;