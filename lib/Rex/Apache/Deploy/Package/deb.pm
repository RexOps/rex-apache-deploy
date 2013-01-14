#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy::Package::deb;

use Rex::Apache::Deploy::Package::Base;
use base qw(Rex::Apache::Deploy::Package::Base);

use Rex::Commands::Fs;
use Rex::Commands::Run;
use Rex::Commands::Upload;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   return $self;
}

sub deploy {
   my ($package_name) = @_;

   if(! $package_name) {
      $package_name = $self->name . "_" . $self->version . "_" . $self->arch . ".deb";
   }

   upload $package_name, "/tmp";

   run "dpkg -i /tmp/$package_name";

   unlink "/tmp/$package_name";
}

1;
