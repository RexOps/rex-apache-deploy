#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Apache::Deploy::Package;

use strict;
use warnings;

use Rex::Apache::Build;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(deploy);

sub deploy {
   my ($name, %option) = @_;

   my $version = $option{version};

   my $package_name;
   if(-f "$name-$version.tar.gz") {
      # file not here, build it
      $package_name = build($name, %option);
   }

   my $klass = "Rex::Apache::Deploy::Package::" . $option{type};
   eval "use $klass";
   if($@) {
      die("Error loading deploy class of thype $option{type}\n");
   }

   my $deploy = $klass->new(%option);
   $deploy->deploy($package_name);
}

1;
