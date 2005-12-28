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