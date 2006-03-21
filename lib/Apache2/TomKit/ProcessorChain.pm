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

package Apache2::TomKit::ProcessorChain;

use strict;
use warnings;

sub new {
    my $class   = shift;
    my $logger = shift;
    my $config  = shift;

    my $this = { logger => $logger, config => $config, processorMap => {}, chain => [] };

    bless $this, $class;

    $this->init();

    return $this;
}

sub init {
    my $this = shift;

    my %map2module = ();
    my ($mapName,$module);

    foreach( $this->{config}->getProcessorsMap() ) {
        ($mapName,$module) = split( "=>", $_ );
        $map2module{$mapName} = $module;
        &Apache2::TomKit::Util::loadModule( $module );
    }

    $this->{processorMap} = \%map2module;

}

sub add2chain {
    my $this      = shift;
    my $mapName   = shift;
    my $processor = shift;

    my $modulereal;

    $this->{logger}->debug(9, "Added Processor: " . $mapName . " => " . $processor );

    if( ! defined $this->{processorMap}->{$mapName} ) {
        $this->{logger}->debug(0,"Could not find module map for: $mapName");
    } else {
        $this->{logger}->debug(9,"Found matching module for processor.");
        $modulereal = $this->{processorMap}->{$mapName};
        $modulereal->startUp( $this->{config} );
        &Apache2::TomKit::Util::loadModule( $modulereal );
        push @{ $this->{chain} }, $modulereal->new( $this->{logger}, $this->{config}, $processor, $mapName );
    }
}

sub clear {
    $_[0]->{chain} = [];
}

sub getDependencies {
    my @dependencies;

    foreach( @{ $_[0]->{chain} } ) {
        push @dependencies, @{ $_->{dependencies} };
    }

    return @dependencies;
}

1;