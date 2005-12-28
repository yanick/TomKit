package Apache2::TomKit::IProvider;

use strict;
use Carp;
use warnings;

sub instanceHandler {
    carp "Subclasses have to implement this method";
}

sub getMTime {
    carp "Subclasses have to implement this method";
}

sub createsDom {
    carp "Subclasses have to implement this method";
}

1;