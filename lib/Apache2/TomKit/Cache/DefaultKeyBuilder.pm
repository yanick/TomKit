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

package Apache2::TomKit::Cache::DefaultKeyBuilder;

use strict;
use Digest::MD5 qw( md5_hex );
use Apache2::RequestRec;
use Apache2::Cookie;
use warnings;

sub new {
    my $class  = shift;
    my $logger = shift;
    my $config = shift;

    bless { logger => $logger, config => $config }, $class;
}

sub buildKey {
    my $this = shift;
    my $host = $this->{config}->{apr}->hostname();
    my $uri  = $this->{config}->{apr}->uri();

    my $keySourceString = $host . $uri;

    ## add the request params to the key for caching
    if( $this->{config}->getEnableCGICache() ) {
	    $this->{logger}->debug(9,"Using CGI-Parameters in Cache");
		
        my @keys = $this->{config}->getCGICacheKeys();

        $this->{logger}->debug(9,"Cache-Keys: " . scalar(@keys) . " => " . join(",",@keys) );

        if( scalar(@keys) == 0 ) {
			$this->{logger}->debug(9,"Use all parameters with the keys");
            @keys = $this->{config}->{apr}->param();
        }

        foreach( @keys ) {
            $keySourceString .= ";$_=>" . (join ",", $this->{config}->{apr}->param( $_ ) );
        }
    }

    ## add the cookie information to the caching key
    if( $this->{config}->getEnableCookieCache() ) {
        my @keys = $this->{config}->getCookieCacheKeys();
        my $j = Apache2::Cookie::Jar->new($this->{config}->{apr});

        if( scalar @keys == 0 ) {
            @keys = $j->cookies();
        }

        foreach( @keys ) {
            $keySourceString .= ";$_=>" . $j->cookies($_);
        }
    }

    ## TODO add the session information to the caching key
    my $md5 = md5_hex( $keySourceString );

    $this->{logger}->debug(9,"The key: " . $keySourceString . " => " . $md5 );

    return $md5;
}

sub createKeyValueFilter {
	my %filters;
	my $key;
	my $value;
	
	foreach( @_ ) {
	    ($key,$value) = split ( "=>", $_ );
	    $filters{$key} = $value;
	}
	
	return %filters;
}

1;
