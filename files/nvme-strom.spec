Name: nvme-strom
Version: %{nvme_version}
Release: %{nvme_release}%{!?dist}
Summary: Linux kernel module for SSD-to-GPU Direct SQL Execution
Group: Applications/Databases
License: TBD
URL: https://github.com/heterodb/pg-strom
Source0: %{name}-%{nvme_tarball}.tar.gz
Source1: dkms.conf
Requires: dkms
Requires: kernel-devel >= 3.10.0-514
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%description
nvme-strom is a kernel module to intermediates SSD-to-GPU peer-to-peer DMA
under PG-Strom.

%prep
%setup -q -n %{name}-%{nvme_tarball}

%build
%{__rm} -rf %{buildroot}
%{__make} -C utils
%{__make} -C kmod modules

%install
%{__rm} -rf %{buildroot}
%{__install} -Dpm 755 utils/nvme_stat %{buildroot}/%{_bindir}/nvme_stat
%{__install} -Dpm 755 utils/ssd2gpu_test %{buildroot}/%{_bindir}/ssd2gpu_test
%{__install} -Dpm 755 utils/ssd2ram_test %{buildroot}/%{_bindir}/ssd2ram_test

%{__make} -C kmod install-dkms \
    DKMS_DEST=%{buildroot}/%{_usrsrc}/%{name}-%{version}
%{__install} -Dpm 644 %{SOURCE1} %{buildroot}/%{_usrsrc}/%{name}-%{version}/dkms.conf
%{__install} -Dpm 644 kmod/nvme_strom.modload.conf \
    %{buildroot}/%{_sysconfdir}/modules-load.d/nvme_strom.conf
%{__install} -Dpm 644 kmod/nvme_strom.modprobe.conf \
    %{buildroot}/%{_sysconfdir}/modprobe.d/nvme_strom.conf
ls -l %{buildroot}/%{_usrsrc}/%{name}-%{version}/

%clean
rm -rf %{buildroot}

%post
count=`/usr/sbin/dkms status '%{name}/%{version}' | wc -l`
if [ count > 0 ];
then
    /usr/sbin/dkms remove -m %{name} -v %{version} --all
fi
/usr/sbin/dkms add -m %{name} -v %{version}
/usr/sbin/dkms build -m %{name} -v %{version}
/usr/sbin/dkms install -m %{name} -v %{version}

%preun
/usr/sbin/dkms remove -m %{name} -v %{version} --all

%files
%defattr(-,root,root,-)
%{_bindir}/nvme_stat
%{_bindir}/ssd2gpu_test
%{_bindir}/ssd2ram_test
%{_usrsrc}/%{name}-%{version}/*
%config %{_sysconfdir}/modules-load.d/nvme_strom.conf
%config %{_sysconfdir}/modprobe.d/nvme_strom.conf

%changelog
* Sat Jan 20 2018 KaiGai Kohei <kaigai@heterodb.com>
- initial RPM specfile
