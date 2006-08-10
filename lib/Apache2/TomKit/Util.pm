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

package Apache2::TomKit::Util;

use strict;
use warnings;
use Carp;

our %registeredProtocols;
our %loadedModules;


## -----------------------------------------------
## public static loadModule
## -----------------------------------------------
##
## Arguments:
##      String ... fully qualified module-name
## Description:
##      Sometimes we need to load a module at runtime using require. This method
##      does the job for us
## Return:
##      void
sub loadModule {
    my $module = shift;
	
	if( ! exists $loadedModules{$module} ) {
	    $module =~ s/::/\//g;
        $module .= ".pm";
        require( $module );
		$loadedModules{$module} = 1;
	}
}

## -----------------------------------------------
## public static setUpProcessor
## -----------------------------------------------
##
## Arguments:
## 		Apache2::TomKit::ProcessorChain .......... the processor-chain instance
##		Apache2::TomKit::Logging ................. the logging instance
##		Apache2::TomKit::Config::DefaultConfig ... the configuration instance
##		@string-array ............................ the processor definitions
## Description:
##   In different places of TomKit we have to set up a processor chain. This method
##   does the whole magic for us. The processor-definitions are passed as an String-Array.
##   One item of the String array matches the following pattern:
##
##   ${typeMape}=>${relative_path_from_document-root_2_definition|absolute-path in filesystem}
##
## Return:
##		void
sub setUpProcessor {
    my $chain   = shift;
    my $logging = shift;
    my $config  = shift;
    my @processorDefs = @_;

    $logging->debug(9,"Moving to another directory: " . $config->{apr}->document_root() );    
    $logging->debug(9,"We are going to add " . (scalar @processorDefs) . " processors.");

    my $type;
    my $defintion;

    foreach ( @processorDefs ) {
        ($type,$defintion) = split( "=>", $_ );

        if( $defintion !~ /^\// ) {
            $defintion = $config->{apr}->document_root() . "/" . $defintion;
        }

        $chain->add2chain( $type, $defintion );
    }
}

sub createDependency {
    my $logger             = shift;
    my $config             = shift;
    my $protocol           = shift;
    my $definitionLocation = shift;

    return $registeredProtocols{$protocol}->new($logger,$config,$definitionLocation);	
}

sub registerDefinitionProvider {
    my $protocol  = shift;
    my $className = shift;

    if( ! exists $registeredProtocols{$protocol} ) {
        $registeredProtocols{$protocol} = $className;
    } else {
        carp "There's already a provider registered for this protocol";
    }
}

sub isProtocolRegistered {
    my $protocol = shift;
    return exists $registeredProtocols{$protocol};
}


package Apache2::TomKit::Util::LibXML;

sub new {
    my $class = shift;

    bless { dependencyCollector => shift, logger => shift, config => shift }, $class;
}

sub match_cb {
    my $this = shift;
    my $uri  = shift;

    $this->{logger}->debug(9,"Matched callback: " . $uri);
	
	# Search for the protocol (We may have a custom one)
	$uri =~ /^((\w+:\/\/)|\/)/;
	my $protocol = $1;

        if( ! defined $protocol ) {
	    $protocol = "file://";
	    $uri = "file://" . $uri;
	}

        $this->{logger}->debug( 9, "Protocol: " . $protocol );

	if( ! $this->{config}->getNoCompilance() ) {
		if( $protocol eq "" ) {
    		    $this->{logger}->debug( 9, "Setting new Protocol to file because we are running in AxKit-Compilance mode" );
    	 	    $protocol = "file://";
    	 	    $uri = $this->{config}->{apr}->document_root() . "/" . $uri;
    	    	} elsif( $uri =~ /^file:\/\/\w/ ) {
    		    $uri =~ s/^file:\/\///;
    		    $uri = $this->{config}->{apr}->document_root() . "/" . $uri;
    	    	}
	}
    

	# Check if this protocol is handled by use
    if( &Apache2::TomKit::Util::isProtocolRegistered( $protocol ) ) {
    	my $dependency = Apache2::TomKit::Util::createDependency( $this->{logger}, $this->{config}, $protocol,$uri);
	
	# only add the dependency if there's a collector there are situations e.g.
	# when caching is turned of where dependencies don't have to be collected
	if( defined $this->{dependencyCollector} ) {
	   ## We need to add us self to the dependencies   
    	   $this->{dependencyCollector}->addDependency($dependency);
	}
	
    	if( $uri =~ /file:\/\/\/etc\/xml\/catalog/ ) {
    		## We don't handle Catalog requests
    		return 0;
    	} elsif( $protocol eq "file://" || $protocol eq "/" ) {
    		## We need to decide if file-request which can be handled by
    		## LibXML itself should really be handled
    		if( $this->{config}->getNoCompilance() ) {
    			return 0;
    		} else {
    			$this->{cached_dependency} = $dependency;
    			return 1;
    		}
    	} else {
    		## This is a custom protocol LibXML can not understand
    		$this->{cached_dependency} = $dependency;
    		return 1;
    	}
    	
    	# restore the dependency we need it in open_cb once more
    	$this->{cached_dependency} = $dependency;
    } else {
    	$this->{logger}->debug( 9, "Could not find the protocol: " . $protocol );
    	return 0;
    }
}

sub open_cb {
    my $this = shift;
    $this->{logger}->debug(9,"INSTRUCTIONS: " . $this->{cached_dependency} . " => " . $this->{cached_dependency}->getInstructions());
    #$this->{logger}->debug(9,"THE CONTENT LOADED: " . $this->{cached_dependency}->getContent() );

    my $rv = $this->{cached_dependency}->getContent();
    return \$rv;
}

sub read_cb {
#    $_[0]->{logger}->debug(9,"Reading chunk: " . substr(${$_[1]}, 0, $_[2], "") ); 
    return substr(${$_[1]}, 0, $_[2], "");
}

sub close_cb {
}


1;

__END__

=head1 NAME

TomKit - Perl Module used to Transform Content

=head1 SYNOPSIS

 Only used internally
  
=head1 DESCRIPTION

This module provides utility functions used by TomKit-Modules

=head1 API

=head2 loadModule

=head3 Arguments:

=over
  
=item String ... fully qualified module-name

=back

=head3 Description:

Sometimes we need to load a module at runtime using require. This method
does the job for us

=head2 setUpProcessor

=head3 Arguments:

=over

=item Apache2::TomKit::ProcessorChain .......... the processor-chain instance

=item Apache2::TomKit::Logging ................. the logging instance

=item Apache2::TomKit::Config::DefaultConfig ... the configuration instance

=item @string-array ............................ the processor definitions

=back

=head3 Description:

In different places of TomKit we have to set up a processor chain. THis method
does the whole magic for us. The processor-definitions are passed as an String-Array.
One item of the String array matches the following pattern:

  ${typeMape}=>${relative_path_from_document-root_2_definition}

=head1 SEE ALSO

Apache2, Apache2::TomKit, Apache2::TomKit::ProcessorChain, Apache2::TomKit::Logging, 
Apache2::TomKit::Config::DefaultConfig

=head1 AUTHOR

Tom Schindl, E<lt>tom.schindl@bestsolution.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Tom Schindl and BestSolution Systemhaus GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
