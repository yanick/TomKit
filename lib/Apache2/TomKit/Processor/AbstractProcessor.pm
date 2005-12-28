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

sub startUp {
    my $class = shift;
    my $config = shift;
}

sub shutDown {
    my $class = shift;
    my $config = shift;
}

sub addDependency {
    my $this       = shift;
    my $dependency = shift;

    $this->{logger}->debug(8,"Adding dependeny: " . $dependency );

    push @{ $this->{dependencies} }, $dependency;
}

1;