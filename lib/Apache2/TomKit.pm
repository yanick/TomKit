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

package Apache2::TomKit;

use 5.008006;
use strict;
use warnings;

our $VERSION = '0.01_3';

use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Request;
use Apache2::Filter;
use Apache2::Const;

use Apache2::TomKit::TomKitEngine;
use Apache2::TomKit::Config::DefaultConfig;
use Apache2::TomKit::Cache::DefaultKeyBuilder;
use Apache2::TomKit::Logging;
use Apache2::TomKit::Cache::FileSystem;
use Apache2::TomKit::Util;
use Apache2::TomKit::ProcessorChain;
use Apache2::TomKit::Cache::AbstractCache;


## -----------------------------------------------
## public static handler
## -----------------------------------------------
##
## Arguments:
## 		Apache2::Request ... the request object
## Description:
##   This is main handler called in the Fixup-Phase of a request. Its
##   main purpose is to decided if the content in the cache can be delivered
##   or the content has be recreated and retransformed.
## Return:
##		int ... one of the Apache2::Const
sub handler {
    my $r = shift;
    my $apr = new Apache2::Request($r);

    ## read the configuration and configure the looging
    my $config = new Apache2::TomKit::Config::DefaultConfig( $apr );
    my $logging = new Apache2::TomKit::Logging( $config );

    $logging->debug(9, "======= Request is started =======");
    $logging->debug(9,"We are handling the source.");

    ## set up the processor chain and restore it in a pnote
    ## so we can retrieve it in the output-filter-phase
    my $chain = new Apache2::TomKit::ProcessorChain( $logging, $config );
    $config->{apr}->pnotes( "AxProcessorChain" => $chain );

    ## if caching is disabled we don't need to check anything
    if( $config->getNoCache() == 1 ) {
        &startUpAxKit($logging,$config);
    } else {
        ## we set up the cache check and try to create a cache entry
        my $cache      = new Apache2::TomKit::Cache::FileSystem($logging, $config);
        my $cacheEntry = $cache->deliverFromCache( $chain );

        ## restore those values so we can access them in later phases
        $config->{apr}->pnotes( "AxCacheEntry" => $cacheEntry );
        $config->{apr}->pnotes( "AxCache"      => $cache      );

        ## let's now check if we can deliver from cache
        if( ! defined $cacheEntry || ! $cacheEntry->{isCached} ) {
            $logging->debug(9,"Well delivering from cache was not possible. We need to start AxKit");
            &startUpAxKit( $logging, $config );
        } else {
            $logging->debug(9,"We can deliver the content from the cache.");
            ## TODO maybe we could refactor this to use the object it self as the handler so we would not need to use pnotes
            $apr->handler('perl-script');
            $apr->set_handlers( "PerlResponseHandler" => \&Apache2::TomKit::Cache::Entry::handler );
        }
    }

    return Apache2::Const::OK;
}

## -----------------------------------------------
## public static startUpAxKit
## -----------------------------------------------
##
## Arguments:
##      Apache2::TomKit::Logging ......... the logger used
##      Apache2::TomKit::DefaultConfig ... the configuration
## Description:
##      Sets up Apache2::TomKit::TomKitEngine as the output-filter for this request
## Return:
##      void
sub startUpAxKit {
    my $logging = shift;
    my $config  = shift;

    $logging->debug(9,"We are about to set up full axkit-power");

    my $apr = $config->{apr};

    ## TODO maybe we could use the object directly as the output filter => so there would be no need to pass things using pnotes
    ## TODO maybe we should make the Engine configurable?
    $apr->add_output_filter( \&Apache2::TomKit::TomKitEngine::handler );
    $apr->pnotes( "AxKitConfig"  => $config  );
    $apr->pnotes( "AxKitLogging" => $logging );

    $logging->debug(9,"We added the Output-Filter");
}

1;

__END__

=head1 NAME

TomKit - Perl Module used to Transform Content

=head1 SYNOPSIS

  <Files *\.xml>
    PerlFixupHandler Apache2::TomKit

    PerlSetVar AxAddProcessorDef "text/xsl=>base.xsl"
    PerlSetVar AxAddProcessorDef "text/xsl=>html.xsl"

    PerlSetVar AxAddProcessorMap "text/xsl=>Apache2::TomKit::Processor::LibXSLT"

    PerlSetVar AxContentProvider My::Content::Provider
  </Files>

=head1 DESCRIPTION

TomKit is a perl handler which is working similar as the famous AxKit for mod_perl 1.x.
It is designed as an PerlFixupHandler which inserts an OutputFilter if needed to transform
XML-Content.

Although designed primarily to transform XML-Content it can be used to create any arbitary
output like e.g. PNG, ... . The big advantage is the easy to configure caching behaviour.

=head1 TOMKIT DIRECTIVES

TomKit is configured by setting configuration variables using PerlSetVar like shown in the synopsis.

=head2 AxAddProcessorDef

Configure the processor definition file used by the processor. The format of the looks
like the following:

  ${typeMape}=>${relative_path_from_document-root_2_definition}

You can use add more than one processor. They are restored in a processor chain and
run next to each other. 

You don't necessarily have to set the processor definition 
in the configuration. TomKit has the possibility to read the processor definitions directly
from the processed file. This looks like the following:

  <?xml version="1.0" ?>
  <?xml-stylesheet href="base.xsl" type="text/xsl"?>
  <?xml-stylesheet href="html.xsl" type="text/xsl"?>
  <!-- THE START OF THE XML-FILE -->

  <!-- .... -->

  <!-- THE END OF THE XML-FILE -->

Please note all relative paths are prefixed with the document-root if AxNoCompilance is set
to 0. If AxNoCompilance is set to 1 all paths are relative to the root path!

=head2 AxAddProcessorMap

Configure the processor used to transform the input-source. The format looks like the
following:

  ${typeMape}=>${Name::Of::The::Processor}

=head2 AxContentProvider

Configure the content provider which provides the content to the transformer chain as its
name indicates. If you don't configure a AxContentProvider there are 2 possibilities:

=over

=item * default response handler 

the default response handler of apache is used. This means caching is avaiable out of the box and done
automatically by TomKit for you

=item * another apache-module 

a content handler is another apache-module e.g. PerlResponseHandler. Although very cool it has 
the disadvantage that caching is not available out-of-the-box. To use caching possibilities TomKit
provides to you your ResponseHandler has 2 possibilities:

=over

=item * use a notes-slot to pass information

setting the AxMTime to the value the content has modified last time

=item * headers flag

setting AxMTime in the HTTP-Header

=back

=back

=head2 AxNoCompilance 0|1

This turns off AxKit-Compilance which is not given out-of-the box. C<Chdir> to 
document-root is possible automagically because of threading issues. Please note
that running with no AxKit-Compilance may be faster and can be achieved by
evaluating the special parameter "_TOMKIT_DocumentRoot" which is passed to 
XSLT-Processors.

=head1 SEE ALSO

Apache2, Apache2::TomKit::IProvider

=head1 AUTHOR

Tom Schindl, E<lt>tom.schindl@bestsolution.atE<gt>

=head1 SUVERSION AND BUG-TRACKING

The latest version of the application can be found on my
companies publicsvn-Server:
   http://publicsvn.bestsolution.at/repos

Bugtracking is done using mantisbt which can be found at here:
   http://phpot.bestsolution.at/mantis/main_page.php

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Tom Schindl and BestSolution Systemhaus GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
