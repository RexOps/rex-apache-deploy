#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Apache::Deploy::Package;

use strict;
use warnings;

use Rex::Apache::Build;

use vars qw(@EXPORT);

@EXPORT = qw(deploy);

sub deploy {
   my ($name, %option) = @_;

   my $klass = "Rex::Apache::Deploy::Package::" . $option{type};
   eval "use $klass";
   if($@) {
      die("Error loading deploy class of thype $option{type}\n");
   }

   $option{name} = $name;

   my $deploy = $klass->new(%option);
   $deploy->deploy($name, %option);
}


sub import {

   no strict 'refs';
   for my $func (@EXPORT) {
      Rex::Logger::debug("Registering main::$func");
      *{"$_[1]::$func"} = \&$func;
   }

}
1;
