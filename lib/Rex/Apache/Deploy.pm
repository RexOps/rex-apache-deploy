#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy;

=begin

=head2 SYNOPSIS

This is a (R)?ex module to ease the deployments of PHP, Perl or other languages.

=cut

use strict;
use warnings;

use Data::Dumper;

our $VERSION = '0.3.99';

sub import {

   die("Invalid input format") unless($_[1] =~ m/^[a-z0-9_]+$/i);

   eval "use $_[0]::$_[1];";

}

1;
