#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Apache::Build::deb;

use strict;
use warnings;
use attributes;

use Cwd qw(getcwd);
use Digest::MD5;
use Rex -base;
use Rex::Template;
use Data::Dumper;

$Rex::Template::DO_CHOMP = TRUE;

use Rex::Apache::Build::Base;
use base qw(Rex::Apache::Build::Base);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   $self->{priority} ||= "optional";
   $self->{arch}     ||= "all";

   return $self;
}

sub build {
   my ($self, $name) = @_;

   $name ||= $self->{name};
   my $version = $self->version;

   my $old_dir = getcwd;

   mkdir "temp-deb-build";
   mkdir "temp-deb-build/control";
   mkdir "temp-deb-build/tree";

   $self->copy_files_to_tmp;

   file "temp-deb-build/debian-binary",
      content => "2.0\n";


   file "temp-deb-build/control/control",
      content => template('@control.file', pkg => $self);

   file "temp-deb-build/control/md5sums",
      content => $self->get_md5sums;


   $self->package_data;
   $self->package_control;

   rmdir "temp-deb-build/tree";
   rmdir "temp-deb-build/control";

   chdir "temp-deb-build";

   my $arch = $self->{arch};
   run "ar -qc ../${name}_${version}_${arch}.deb debian-binary control.tar.gz data.tar.gz";
   chdir "..";

   rmdir "temp-deb-build";
}

sub package_data {
   my ($self) = @_;

   chdir "temp-deb-build/tree";
   run "tar czf ../data.tar.gz .";
   chdir "../../";
}

sub package_control {
   my ($self) = @_;

   chdir "temp-deb-build/control";
   run "tar czf ../control.tar.gz .";
   chdir "../../";
}

sub copy_files_to_tmp {
   my ($self) = @_;

   my $prefix = $self->prefix || ".";
   mkdir "temp-deb-build/tree/$prefix";
   cp $self->{path} . "/*", "temp-deb-build/tree/$prefix";
}

sub get_md5sums {
   my ($self) = @_;

   my @s = ();
   chdir "temp-deb-build/tree";

   my @dirs = (".");
   for my $dir (@dirs) {
      opendir(my $dh, $dir);
      while(my $entry = readdir($dh)) {
         next if($entry eq ".");
         next if($entry eq "..");

         my $file = "$dir/$entry";

         if(-d $file) {
            push(@dirs, $file);
            next;
         }

         my $md5 = Digest::MD5->new;
         open(my $fh, "<", $file) or die($!);
         $file =~ s/^\.\///;
         $md5->addfile($fh);
         push(@s, $md5->hexdigest . "  " . $file);
         close($fh);


      }
      closedir($dh);
   }

   chdir "../..";

   return join("\n", @s);

}

sub description {
   my ($self, $desc) = @_;

   if($desc) {
      $self->{description} = $desc;
   }

   my $s = "";

   my @lines = split(/\n/, $self->{description});
   $s = shift(@lines);

   for (@lines) {
      $s .= " $_";
   }

   return $s;
}

sub depends {
   my ($self, $dep) = @_;

   if($dep) {
      $self->{depends} = $dep;
   }

   my @s = ();

   for my $dep (@{ $self->{depends} }) {
      if(ref($dep)) {
         my ($pkg) = keys %{ $dep };
         my ($ver) = values %{ $dep };

         push(@s, $pkg . "($ver)");
      }
      else {
         push(@s, $dep);
      }
   }

   return join(", ", @s);
}

sub installed_size {
   my ($self) = @_;

   my $size = 0;

   chdir "temp-deb-build/tree";

   my @dirs = (".");
   for my $dir (@dirs) {
      opendir(my $dh, $dir);
      while(my $entry = readdir($dh)) {
         next if($entry eq ".");
         next if($entry eq "..");

         my $file = "$dir/$entry";

         if(-d $file) {
            push(@dirs, $file);
            next;
         }
         $size += -s $file;

      }
      closedir($dh);
   }

   chdir "../..";

   return $size;
}


1;

__DATA__

@control.file
Package: <%= $::pkg->name %>
Version: <% if($::pkg->epoch) { %><%= $::pkg->epoch %>:<% } %><%= $::pkg->version %><% if($::pkg->release) { %><%= $::pkg->release %><% } %>
License: <% if($::pkg->license) { %><%= $::pkg->license %><% } else { %>unknown<% } %>
Vendor: <% if($::pkg->vendor) { %><%= $::pkg->vendor %><% } else { %>unknown<% } %>
Architecture: <% if($::pkg->arch) { %><%= $::pkg->arch %><% } else { %>all<% } %>
Maintainer: <%= $::pkg->maintainer  %>
Installed-Size: <%= $::pkg->installed_size %>
<% if($::pkg->depends) { %>
Depends: <%= $::pkg->depends %>
<% } %>
<% if($::pkg->conflicts) { %>
Conflicts: <%= join(", ", @{ $::pkg->conflicts }) %>
<% } %>
<% if($::pkg->provides) { %>
Provides: <%= join(", ", @{ $::pkg->provides }) %>
<% } %>
Section: <%= $::pkg->section %>
Priority: <%= $::pkg->priority %>
Homepage: <%= $::pkg->url %>
Description: <%= $::pkg->description %>
@end
