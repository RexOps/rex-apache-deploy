#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Inject::Template;

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

use vars qw(@EXPORT $real_name_from_template $template_file $template_pattern);
@EXPORT = qw(inject
               generate_real_name
               template_file template_search_for);

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
         if($content =~ m/\@$key\@/gm) {
            Rex::Logger::info("Replacing \@$key\@ with $val ($file)");
            $content =~ s/\@$key\@/$val/g;
         }
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

####### import function #######

sub import {

   no strict 'refs';
   for my $func (@EXPORT) {
      Rex::Logger::debug("Registering main::$func");
      *{"main::$func"} = \&$func;
   }

}



1;
