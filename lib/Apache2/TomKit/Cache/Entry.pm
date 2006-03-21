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

package Apache2::TomKit::Cache::Entry;

use strict;
use Apache2::RequestRec;
use Apache2::Request;
use Apache2::Const;
use Apache2::RequestIO;
use warnings;

sub new {
    my $class          = shift;
    my $logger         = shift;
    my $key            = shift;
    my $cache          = shift;
    my $processorChain = shift;

    bless {
            logger => $logger,
            key => $key,
            isCached => 0,
            content => undef,
            cache => $cache,
            processorChain => $processorChain,
            isNew => 1,
            dependencies => []
          };
}

sub handler {
    my $r = shift;

    my $entry = $r->pnotes( "AxCacheEntry" );

    if( defined $entry->{processorChain}->{chain} && scalar @{ $entry->{processorChain}->{chain} } > 0 ) {
        $entry->{logger}->debug(9,"Setting the content type to: " . $entry->{processorChain}->{chain}->[-1]->getContentType());
        $r->content_type($entry->{processorChain}->{chain}->[-1]->getContentType());
    }

    $entry->{logger}->debug(9,"Delivering cached content.");
    $r->print( $entry->{content} );

    $entry->{logger}->debug(9,"Chain: " . $entry->{processorChain}->{chain} . ": " . scalar @{ $entry->{processorChain}->{chain} } );

    return Apache2::Const::OK;
}

sub restore {
    my $this = shift;
    my $content = shift;

    $this->{content} = $content;
    $this->{cache}->restore($this);
}

sub addDependency {
    my $this = shift;
    my $dependency = shift;

    $this->{logger}->debug(8,"Adding dependency: " . $dependency );

    push @{ $this->{dependencies} }, $dependency;
}

sub getDependencies {
    my $this = shift;

    return @{ $this->{dependencies} }, $this->{processorChain}->getDependencies();
}

return 1;