Name: nvme_strom
Version: @@NVME_VERSION@@
Release: @@NVME_RELEASE@@%{?dist}
Summary: Linux kernel module for SSD-to-GPU Direct SQL Execution
Group: Applications/Databases
License: BSD
URL: https://github.com/heterodb/pg-strom
Source0: %{name}-@@NVME_TARBALL@@.tar.gz
Source1: strom.dkms.conf
Source2: rdmax.dkms.conf
Requires: dkms
Requires: kernel-devel >= 3.10.0-693.17
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%description
nvme-strom is a kernel module to intermediates SSD-to-GPU peer-to-peer DMA
under PG-Strom.

%prep
%setup -q -n %{name}-@@NVME_TARBALL@@

%build
%{__rm} -rf %{buildroot}
%{__make} -C kmod build-dkms \
    NVME_STROM_VERSION=%{version}-%{release} \
    DKMS_DEST=%{buildroot}/%{_usrsrc}/%{name}-%{version}
%{__make} -C utils

%install
%{__rm} -rf %{buildroot}
%{__install} -Dpm 0755 utils/nvme_stat %{buildroot}/%{_bindir}/nvme_stat
%{__install} -Dpm 0755 utils/ssd2gpu_test %{buildroot}/%{_bindir}/ssd2gpu_test
%{__install} -Dpm 4755 utils/nvme_strom-modprobe %{buildroot}/%{_bindir}/nvme_strom-modprobe

%{__make} -C kmod install-dkms \
    NVME_STROM_VERSION=%{version}-%{release} \
    DKMS_DEST=%{buildroot}/%{_usrsrc}/%{name}-%{version}
%{__make} -C rdmax install-dkms \
    NVME_STROM_VERSION=%{version}-%{release} \
    DKMS_DEST=%{buildroot}/%{_usrsrc}/rdmax-%{version}
%{__install} -Dpm 644 %{SOURCE1} %{buildroot}/%{_usrsrc}/%{name}-%{version}/dkms.conf
%{__install} -Dpm 644 %{SOURCE2} %{buildroot}/%{_usrsrc}/rdmax-%{version}/dkms.conf
%{__install} -Dpm 644 kmod/nvme_strom.modload.conf \
    %{buildroot}/%{_sysconfdir}/modules-load.d/nvme_strom.conf
%{__install} -Dpm 644 kmod/nvme_strom.modprobe.conf \
    %{buildroot}/%{_sysconfdir}/modprobe.d/nvme_strom.conf

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
/usr/sbin/dkms remove -m %{name} -v %{version} --all || \
	echo "notice: %{name} -v %{version} might be manually removed."
/usr/sbin/dkms remove -m rdmax -v %{version} --all || \
	echo "notice: %{name} -v %{version} might be manually removed."

%files
%defattr(-,root,root,-)
%{_bindir}/nvme_stat
%{_bindir}/ssd2gpu_test
%{_bindir}/nvme_strom-modprobe
%dir %{_usrsrc}/%{name}-%{version}
%{_usrsrc}/%{name}-%{version}/*
%{_usrsrc}/rdmax-%{version}/*
%config %{_sysconfdir}/modules-load.d/nvme_strom.conf
%config %{_sysconfdir}/modprobe.d/nvme_strom.conf

%changelog
