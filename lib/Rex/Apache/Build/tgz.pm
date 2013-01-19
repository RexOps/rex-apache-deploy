#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Apache::Build::tgz;

use strict;
use warnings;

use Cwd qw(getcwd);
use Rex -base;

use Rex::Apache::Build::Base;
use base qw(Rex::Apache::Build::Base);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   return $self;
}

sub build {
   my ($self, $name) = @_;

   $name ||= $self->{name};

   my $old_dir = getcwd();

   my $excludes = "";
   if(exists $self->{exclude}) {
      $excludes = " --exclude " . join(" --exclude ", @{$self->{exclude}});
   }

   my $version = $self->version;

   my $dir = getcwd();

   if(exists $self->{source}) {
      $dir = $self->{source};
   }

   chdir($dir);

   my $package_name = "$name-$version.tar.gz";

   Rex::Logger::info("Building: $package_name");
   if($^O =~ m/^MSWin/i) {
      run "tar -c $excludes --exclude \"$name-*.tar.gz\" --exclude \".*.sw*\" --exclude \"*~\" --exclude Rexfile.lock --exclude Rexfile --exclude $package_name -z -f $old_dir/$package_name .";
   }
   else {
      run "tar -c $excludes --exclude '$name-*.tar.gz' --exclude '.*.sw*' --exclude '*~' --exclude Rexfile.lock --exclude Rexfile --exclude $package_name -z -f $old_dir/$package_name .";
   }
   Rex::Logger::info("Your build is now available: $name-$version.tar.gz");

   chdir($old_dir);

   return $package_name;
}

1;
