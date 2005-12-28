package Apache2::TomKit::Processor::DefinitionProvider::FileSystemProvider;

use base qw( Apache2::TomKit::Processor::DefinitionProvider::AbstractProvider );

use strict;
use warnings;

use Apache2::TomKit::Util;

&Apache2::TomKit::Util::registerDefinitionProvider( "file://", __PACKAGE__ );
&Apache2::TomKit::Util::registerDefinitionProvider( "/", __PACKAGE__ );

sub init {
    my $this     = shift;
    my $filename = shift;

    $filename =~ s|^file://||;

    $this->{definition} = $filename;
}

sub getProtocol {
    return "file://";
}

sub getMTime {
    return (stat($_[0]->{definition}))[9];
}

sub getInstructions {
    return $_[0]->{definition};
}

sub getKey {
    return $_[0]->{definition};
}

1;