#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy::Package::deb;

use strict;
use warnings;

use Rex::Apache::Deploy::Package::Base;
use base qw(Rex::Apache::Deploy::Package::Base);

use Rex::Commands;
use Rex::Commands::Fs;
use Rex::Commands::Run;
use Rex::Commands::Upload;
use Rex::Apache::Build;
use Data::Dumper;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   if($self->{arch} eq "x86_64") {
      $self->{arch} = "amd64";
   }

   return $self;
}

sub deploy {
   my ($self, $package_name, %option) = @_;

   $package_name = $self->name . "_" . $self->version . "_" . $self->arch . ".deb";

   LOCAL {
      if(! -f $package_name) {
         build($self->name, %option);
      }
   };

   upload $package_name, "/tmp";

   run "dpkg -i /tmp/$package_name";
   if($? != 0) {
      # try to install deps
      run "apt-get -y -f install";
      if($? != 0) {
         unlink "/tmp/$package_name";
         die("Error installing $package_name");
      }

      my $pkg = Rex::Pkg->get;
      if(! $pkg->is_installed($self->name)) {
         unlink "/tmp/$package_name";
         die("Error installing $package_name");
      }
   }

   Rex::Logger::info("Package $package_name installed.");

   unlink "/tmp/$package_name";
}

1;
