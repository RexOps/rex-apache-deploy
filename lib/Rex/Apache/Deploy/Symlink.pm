#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy::Symlink;

=begin

=head2 SYNOPSIS

This is a (R)?ex module to ease the deployments of PHP, Perl or other languages.

=cut

use strict;
use warnings;

use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands;
use File::Basename qw(dirname basename);

#require Exporter;
#use base qw(Exporter);

use vars qw(@EXPORT $deploy_to $document_root $generate_deploy_directory);
@EXPORT = qw(deploy get_live_version get_deploy_directory_for
               deploy_to generate_deploy_directory document_root 
               list_versions switch_to_version);

############ deploy functions ################

sub deploy {
   my ($file) = @_;

   no strict;
   no warnings;
   my $rnd_file = get_random(8, a..z, 0..9);
   use strict;
   use warnings;

   unless(is_writeable($deploy_to)) {
      Rex::Logger::info("No write permission to $deploy_to");
      exit 1;
   }

   unless(is_writeable(dirname($document_root))) {
      Rex::Logger::info("No write permission to $document_root");
      exit 1;
   }

   my $deploy_dir = get_deploy_directory_for($file);
   Rex::Logger::debug("deploy_dir: $deploy_dir");

   if(get_live_version() && get_live_version() eq basename($deploy_dir)) {
      Rex::Logger::info("Sorry, you try to deploy to a version that is currently live.");
      exit 1;
   }

   Rex::Logger::debug("Uploadling $file to /tmp/$rnd_file" . _get_ext($file));
   upload ($file, "/tmp/$rnd_file" . _get_ext($file));

   if(is_dir($deploy_dir)) {
      Rex::Logger::debug("rmdir $deploy_dir");
      rmdir $deploy_dir;
   }

   mkdir $deploy_dir;

   run "cd $deploy_dir; " . sprintf(_get_extract_command($file), "/tmp/$rnd_file" . _get_ext($file));
   run "ln -snf $deploy_dir $document_root";

   Rex::Logger::debug("Unlinking /tmp/$rnd_file" . _get_ext($file));
   unlink "/tmp/$rnd_file" . _get_ext($file);
}

sub list_versions {
   return grep { ! /^\./ } list_files($deploy_to);
}

sub switch_to_version {
   my ($new_version) = @_;

   my @versions = list_versions;
   if(! grep { /$new_version/ } @versions) { Rex::Logger::info("no version found!"); return; }

   run "ln -snf $deploy_to/$new_version $document_root";
}

sub get_live_version {
   my $link = eval {
      return readlink $document_root;
   };

   return basename($link) if($link);
}


############ configuration functions #############

sub get_deploy_directory_for {
   my ($file) = @_;

   my $gen_dir_name = &$generate_deploy_directory($file);
   my $deploy_dir = "$deploy_to/$gen_dir_name";
   
   return $deploy_dir;
}

sub deploy_to {
   $deploy_to = shift;
}

sub document_root {
   $document_root = shift;
}

sub generate_deploy_directory {
   $generate_deploy_directory = shift;
}


############ helper functions #############

sub _get_extract_command {
   my ($file) = @_;

   if($file =~ m/\.tar\.gz$/) {
      return "tar xzf %s";
   } elsif($file =~ m/\.zip$/) {
      return "unzip %s";
   } elsif($file =~ m/\.tar\.bz2$/) {
      return "tar xjf %s";
   }

   die("Unknown Archive Format.");
}

sub _get_pack_command {
   my ($file) = @_;

   if($file =~ m/\.tar\.gz$/) {
      return "tar czf %s %s";
   } elsif($file =~ m/\.zip$/) {
      return "zip -r %s %s";
   } elsif($file =~ m/\.tar\.bz2$/) {
      return "tar cjf %s %s";
   }

   die("Unknown Archive Format.");
}

sub _get_ext {
   my ($file) = @_;

   if($file =~ m/\.tar\.gz$/) {
      return ".tar.gz";
   } elsif($file =~ m/\.zip$/) {
      return ".zip";
   } elsif($file =~ m/\.tar\.bz2$/) {
      return ".tar.bz2";
   }

   die("Unknown Archive Format.");

}


####### import function #######

sub import {

   no strict 'refs';
   for my $func (@EXPORT) {
      Rex::Logger::debug("Registering main::$func");
      *{"$_[1]::$func"} = \&$func;
   }

}

1;
