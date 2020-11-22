Name:      heterodb-swdc
Version:   1.1
Release:   1%{?dist}
Summary:   HeteroDB Software Distribution Center - Yum Repository Configuration
Group:     System Environment/Base
License:   GPL v2
URL:       https://heterodb.github.io/swdc/
Source0:   RPM-GPG-KEY-HETERODB
Source2:   heterodb-swdc.repo
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%description
This package contains yum configuration of the HeteroDB Software Distribution
Center for RHEL/CentOS.

%prep
%setup -c -T

%build

%install
%{__rm} -rf %{buildroot}

%{__install} -Dpm 644 %{SOURCE0} \
    %{buildroot}%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-HETERODB
%{__install} -Dpm 644 %{SOURCE2} \
    %{buildroot}%{_sysconfdir}/yum.repos.d/heterodb-swdc.repo

%clean
%{__rm} -rf %{buildroot}

%post
/bin/rpm --import %{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-HETERODB

%files
%defattr(-,root,root,-)
%config %{_sysconfdir}/yum.repos.d/*
%dir %{_sysconfdir}/pki/rpm-gpg
%{_sysconfdir}/pki/rpm-gpg/*

%changelog
* Sun Nov 11 2020 KaiGai Kohei <kaigai@heterodb.com> - 1.1
- Both of RHEL7/8 refers correct repository based on $releasever and $basearch
* Sat Jan 20 2018 KaiGai Kohei <kaigai@heterodb.com> - 1.0
- Initial setup for the release of HeteroDB Software Distribution Center
