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

package Apache2::TomKit::Config::DefaultConfig;

use strict;
use warnings;

our $AUTOLOAD;

our %Config = (
    AxNoCache    => 0,
    XSLTEnhancedDynamicTagLibLoading => 0,
);

sub new {
    my $class = shift;
    my $apr   = shift;

    my $this = { apr => $apr, config => $apr->dir_config() };

    bless $this, $class;
}

sub getProcessorDefs {
    my $this = shift;
    my @processors = $this->{config}->get("AxAddProcessorDef");

    return @processors;
}

sub getProcessorsMap {
    my $this = shift;
    my @processorsMap = $this->{config}->get("AxAddProcessorMap");

    return @processorsMap;
}

sub getTagLibs {
    my $this = shift;
    my @taglibs = $this->{config}->get("AxAddXSPTaglib");

    return @taglibs;
}

sub AUTOLOAD {
    ## todo insert method for next time
    my $this = shift;
    my ($methodName) = $AUTOLOAD =~ /get(\w+)$/;

    if( defined  $methodName) {
        $methodName = "Ax$methodName";
        my $configValue = $this->{config}->{$methodName};

        if( ! defined $configValue ) {
            $configValue = $Config{$methodName};
        }

        return $configValue;
    }
}

1;
