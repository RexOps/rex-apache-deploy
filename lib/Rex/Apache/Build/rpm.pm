#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Build::rpm;

use strict;
use warnings;
use attributes;

use Cwd qw(getcwd);
use Digest::MD5;
use Rex::Logger;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::File;
use Rex::Template;
use Data::Dumper;

use Rex::Apache::Build::Base;
use base qw(Rex::Apache::Build::Base);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   $self->{priority}   ||= "optional";
   $self->{license}    ||= "unknown";
   $self->{file_user}  ||= "root";
   $self->{file_group} ||= "root";

   return $self;
}

sub build {
   my ($self, $name) = @_;

   $name ||= $self->name;

   mkdir "temp-rpm-build";
   mkdir "temp-rpm-build/tree";

   my @dirs  = $self->find_dirs;
   my @files = $self->find_files;

   file "temp-rpm-build/$name.spec",
      content => template('@spec.template', pkg => $self, cur_dir => getcwd(), files => \@files, dirs => \@dirs);

   chdir "temp-rpm-build";

   run "/opt/local/bin/rpmbuild --buildroot=" . getcwd() . "/tree -bb $name.spec";

   chdir "..";

   my $arch = $self->arch;
   cp "temp-rpm-build/$arch/*.rpm", ".";

   return "$name-" . $self->version . "-" . $self->release . "." . $self->arch . ".rpm";
}

sub find_files {
   my ($self) = @_;

   my @ret;

   my @dirs = ($self->{path});
   for my $dir (@dirs) {
      opendir(my $dh, $dir) or die($!);
      while(my $entry = readdir($dh)) {
         next if($entry eq ".");
         next if($entry eq "..");

         if(-d "$dir/$entry") {
            push(@dirs, "$dir/$entry");
            next;
         }

         Rex::Logger::debug("Adding file: " . getcwd() . "/$dir/$entry => $dir/$entry");
         push(@ret, [getcwd() . "/$dir/$entry", "$dir/$entry"]);
      }
      closedir($dh);
   }

   # free conffiles
   for my $conf (@{ $self->config_files }) {
      @ret = grep { $_->[0] !~ m/$conf/ } @ret;
   }

   my $top = $self->path . "/";
   map { $_->[1] =~ s/^$top// } @ret;

   Rex::Logger::debug("==== files ====");
   Rex::Logger::debug(Dumper(\@ret));

   return @ret;
}

sub find_dirs {
   my ($self) = @_;

   my @ret;

   my @dirs = ($self->{path});
   for my $dir (@dirs) {
      opendir(my $dh, $dir) or die($!);
      while(my $entry = readdir($dh)) {
         next if($entry eq ".");
         next if($entry eq "..");

         if(-d "$dir/$entry") {
            push(@dirs, "$dir/$entry");

            Rex::Logger::debug("Adding directory: $dir/$entry");
            push(@ret, "$dir/$entry");
         }

      }
      closedir($dh);
   }

   my $top = $self->path;
   map { s/^$top//; $_ = $self->prefix . $_ } @ret;

   Rex::Logger::debug("==== directories ====");
   Rex::Logger::debug(Dumper(\@ret));

   return @ret;
}



1;

__DATA__

@spec.template
# bold copied from fpm

%define _rpmdir <%= $::cur_dir %>/temp-rpm-build

<% for (qw/prep build install clean/) { %>
%define __spec_<%= $_ %>_post true
%define __spec_<%= $_ %>_pre true
<% } %>
# Disable checking for unpackaged files ?
#%undefine __check_files

Name: <%= $::pkg->name %>
Version: <%= $::pkg->version %>
<% if($::pkg->epoch) { %>
Epoch: <%= $::pkg->epoch %>
<% } %>
Release: <%= $::pkg->release || 1 %>
Summary: <%= [ split(/\n/, $::pkg->description()) ]->[0] %>
BuildArch: <%= $::pkg->arch %>
AutoReqProv: no
# Seems specifying BuildRoot is required on older rpmbuild (like on CentOS 5)
BuildRoot: %buildroot
<% if($::pkg->prefix) { %>
Prefix: <%= $::pkg->prefix %>
<% } %>

Group: <%= $::pkg->section %>
License: <%= $::pkg->license %>
<% if($::pkg->vendor) { %>
Vendor: <%= $::pkg->vendor %>
<% } %>
<% if($::pkg->url) { %>
URL: <%= $::pkg->url %>
<% } else { %>
URL: http://example.tld/
<% } %>
Packager: <%= $::pkg->maintainer %>

<% for my $pkg (@{ $::pkg->depends }) { -%>
Requires: <%= $pkg %><% } -%>
<% for my $prov (@{ $::pkg->provides }) { -%>
Provides: <%= $prov %><% } -%>
<% for my $conf (@{ $::pkg->conflicts }) { -%>
Conflicts: <%= $conf %><% } %>

%description
<%= $::pkg->description %>

%prep
# noop

%build
# noop

%install
<% for my $dir (@{ $dirs }) { %>
mkdir -p %{buildroot}<%= $dir %><% } -%>

<% for my $file (@{ $files }) { %>
cp <%= $file->[0] %> %{buildroot}<%= $::pkg->prefix %>/<%= $file->[1] %><% } -%>

%clean
# noop

<% if($::pkg->post_install) { %>
%post
<%= $::pkg->post_install %>
<% } %>

<% if($::pkg->pre_install) { %>
%pre
<%= $::pkg->pre_install %>
<% } %>

<% if($::pkg->pre_uninstall) { %>
%preun
<%= $::pkg->pre_uninstall %>
<% } %>

<% if($::pkg->post_uninstall) { %>
%postun
<%= $::pkg->post_uninstall %>
<% } %>


%files
%defattr(-,<%= $::pkg->file_user %>,<%= $::pkg->file_group %>,-)
<% for my $cfg (@{ $::pkg->config_files }) { -%>
%config(noreplace) <%= $cfg %>
<% } -%>

<% for my $dir (@{ $dirs }) { %>
%dir <%= $dir %><% } -%>

<% for my $file (@{ $files }) { %>
<%= $::pkg->prefix %>/<%= $file->[1] %><% } -%>



@end
