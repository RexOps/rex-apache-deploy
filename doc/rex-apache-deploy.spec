%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)

%define real_name Rex-Apache-Deploy

Summary: Rex-Apache-Deploy is a (R)?ex Module to deploy Websites.
Name: rex-apache-deploy
Version: 0.8.0
Release: 1
License: Artistic
Group: Utilities/System
Source: http://search.cpan.org/CPAN/authors/id/J/JF/JFRIED/Rex-Apache-Deploy-0.8.0.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

BuildRequires: perl >= 5.8.0
BuildRequires: perl(ExtUtils::MakeMaker)
Requires: rex >= 0.18.0
Requires: perl >= 5.8.0
Requires: perl-libwww-perl
Requires: perl-YAML
Requires: unzip
Requires: zip
Requires: bzip2
Requires: tar
AutoReqProv: no

%description
Rex::Apache::Deploy is a (R)?ex Module to deploy Web sites into Apache 
and WAR-files into Tomcat. It eases the deployment process of many servers.

%prep
%setup -n %{real_name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;


%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root, 0755)
%doc META.yml 
%doc %{_mandir}/*
%{perl_vendorlib}/*

%changelog

* Sun Sep 18 2011 Jan Gehring <jan.gehring at, gmail.com> 0.8.0-1
- added windows support

* Tue Sep 13 2011 Jan Gehring <jan.gehring at, gmail.com> 0.7.0-1
- added sprocketize command
- added coffeescript support
- added sass support

* Sun Aug 14 2011 Jan Gehring <jan.gehring at, gmail.com> 0.6.0-1
- added yui compressor support
- [Deploy::Symlink] added a default function for generate_deploy_directory the default awaits now files in the format: name-[0-9\._~]+.zip|tar\.gz|tar\.bz2|war
- Added support to build .tar.gz packages

* Tue Jul 05 2011 Jan Gehring <jan.gehring at, gmail.com> 0.5.2-1
- added tab as an allowed property seperator
- fixed another property parsing bug
- enable/disable tomcat instances in mod_jk

* Mon Jun 27 2011 Jan Gehring <jan.gehring at, gmail.com> 0.5.1-1
- fixed template parsing in property files
- strip windows lineending in property files

* Mon Jun 13 2011 Jan Gehring <jan.gehring at, gmail.com> 0.5.0-1
- set path to tomcat manager
- standardization for function calls
- allow = and : for seperator in templates file (Inject::Properties)
- run hooks on sub extracts, too
- first rpm

