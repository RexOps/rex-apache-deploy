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

use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands;
use File::Basename qw(dirname basename);

our $VERSION = '0.2';

require Exporter;
use base qw(Exporter);

use vars qw(@EXPORT $real_name_from_template $deploy_to $document_root $generate_deploy_directory $template_file $template_pattern);
@EXPORT = qw(inject deploy get_live_version
               generate_real_name deploy_to generate_deploy_directory document_root 
               template_file template_search_for list_versions switch_to_version);

############ deploy functions ################

sub inject {
   my ($to) = @_;

   my $cmd1 = sprintf (_get_extract_command($to), "../$to");
   my $cmd2 = sprintf (_get_pack_command($to), "../$to", ".");

   my $template_params = _get_template_params($template_file);

   mkdir("tmp");
   chdir("tmp");
   run $cmd1;

   for my $file (`find . -name $template_pattern`) {
      chomp $file;
      my $content = eval { local(@ARGV, $/) = ($file); $_=<>; $_; };
      for my $key (keys %$template_params) {
         my $val = $template_params->{$key};
         $content =~ s/\@$key\@/$val/g;
      }

      my $new_file_name = &$real_name_from_template($file);
      open(my $fh, ">", $new_file_name) or die($!);
      print $fh $content;
      close($fh);
   }

   run $cmd2;
   chdir("..");
   system("rm -rf tmp");
}

sub deploy {
   my ($file) = @_;

   no strict;
   no warnings;
   my $rnd_file = get_random(8, a..z, 0..9);
   use strict;
   use warnings;

   unless(is_writeable($deploy_to)) {
      die("No write permisson to $deploy_to\n");
   }

   unless(is_writeable(dirname($document_root))) {
      die("No write permission to " . dirname($document_root) . "\n");
   }

   upload ($file, "/tmp/$rnd_file" . _get_ext($file));

   my $deploy_dir = "$deploy_to/" . &$generate_deploy_directory($file);

   if(is_dir($deploy_dir)) {
      rmdir $deploy_dir;
   }

   mkdir $deploy_dir;

   run "cd $deploy_dir; " . sprintf(_get_extract_command($file), "/tmp/$rnd_file" . _get_ext($file));
   run "ln -snf $deploy_dir $document_root";

   unlink "/tmp/$rnd_file" . _get_ext($file);
}

sub list_versions {
   return grep { ! /^\./ } list_files($deploy_to);
}

sub switch_to_version {
   my ($new_version) = @_;

   my @versions = list_versions;
   if(! grep { /$new_version/ } @versions) { print "no version found!\n"; return; }

   run "ln -snf $deploy_to/$new_version $document_root";
}

sub get_live_version {
   my $link = readlink $document_root;
   return basename($link);
}


############ configuration functions #############

sub generate_real_name {
   $real_name_from_template = shift;
}

sub template_file {
   $template_file = shift;
}

sub template_search_for {
   $template_pattern = shift;
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

# read the template file and return a hashref.
sub _get_template_params {
   my ($template_file) = @_;
   my @lines = eval { local(@ARGV) = ($template_file); <>; };
   my $r = {};
   for my $line (@lines) {
      next if ($line =~ m/^#/);
      next if ($line =~ m/^\s*?$/);

      my ($key, $val) = ($line =~ m/^(.*?) ?= ?(.*)$/);
      $val =~ s/^["']//;
      $val =~ s/["']$//;

      $r->{$key} = $val;
   }

   $r;
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


1;
