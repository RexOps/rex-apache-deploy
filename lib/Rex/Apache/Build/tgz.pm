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

   if(exists $self->{path}) {
      $dir = $self->{path};
   }

   chdir($dir);

   Rex::Logger::info("Building: $name-$version.tar.gz");
   if($^O =~ m/^MSWin/i) {
      run "tar -c $excludes --exclude \"$name-*.tar.gz\" --exclude \".*.sw*\" --exclude \"*~\" --exclude Rexfile.lock --exclude Rexfile --exclude $name$version.tar.gz -z -f $old_dir/$name-$version.tar.gz .";
   }
   else {
      run "tar -c $excludes --exclude '$name-*.tar.gz' --exclude '.*.sw*' --exclude '*~' --exclude Rexfile.lock --exclude Rexfile --exclude $name$version.tar.gz -z -f $old_dir/$name-$version.tar.gz .";
   }
   Rex::Logger::info("Your build is now available: $name-$version.tar.gz");

   chdir($old_dir);
}

1;
