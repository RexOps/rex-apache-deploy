#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy::Package::rpm;

use Rex::Apache::Deploy::Package::Base;
use base qw(Rex::Apache::Deploy::Package::Base);

use strict;
use warnings;

use Rex::Commands;
use Rex::Commands::Fs;
use Rex::Commands::Run;
use Rex::Commands::Upload;
use Rex::Apache::Build;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   $self->{release}    ||= 1;

   return $self;
}

sub deploy {
   my ($self, $package_name, %option) = @_;

   $package_name = $self->name . "-" . $self->version . "-". $self->release . "." . $self->arch . ".rpm";

   LOCAL {
      if(! -f $package_name) {
         build($self->name, %option);
      }
   };

   upload $package_name, "/tmp";

   run "rpm -U /tmp/$package_name";
   if($? != 0) {
      die("Error installing $package_name");
   }

   Rex::Logger::info("Package $package_name installed.");

   unlink "/tmp/$package_name";
}

1;
