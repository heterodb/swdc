Name: postgresql-alternatives
Version: 1.1
Release: 1%{?dist}
Summary: alternatives configuration for PostgreSQL
Group: Applications/Databases
License: PostgreSQL
Requires: chkconfig
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%define localbindir             /usr/local/bin
%define __localbindir           %{buildroot}%{localbindir}

%description
alternatives configuration for PostgreSQL packages provides by
PostgreSQL Global Development Group.
This package puts symbolic links from /usr/local/bin to /usr/pgsql-xx.

%install
rm -rf %{buildroot}
mkdir -p %{__localbindir}
# postgresqlXX packages
ln -sf /usr/pgsql-current/bin/clusterdb         %{__localbindir}/clusterdb
ln -sf /usr/pgsql-current/bin/createdb          %{__localbindir}/createdb
ln -sf /usr/pgsql-current/bin/createuser        %{__localbindir}/createuser
ln -sf /usr/pgsql-current/bin/dropdb            %{__localbindir}/dropdb
ln -sf /usr/pgsql-current/bin/dropuser          %{__localbindir}/dropuser
ln -sf /usr/pgsql-current/bin/pg_archivecleanup %{__localbindir}/pg_archivecleanup
ln -sf /usr/pgsql-current/bin/pg_basebackup     %{__localbindir}/pg_basebackup
ln -sf /usr/pgsql-current/bin/pg_config         %{__localbindir}/pg_config
ln -sf /usr/pgsql-current/bin/pg_dump           %{__localbindir}/pg_dump
ln -sf /usr/pgsql-current/bin/pg_dumpall        %{__localbindir}/pg_dumpall
ln -sf /usr/pgsql-current/bin/pg_isready        %{__localbindir}/pg_isready
ln -sf /usr/pgsql-current/bin/pg_receivewal     %{__localbindir}/pg_receivewal
ln -sf /usr/pgsql-current/bin/pg_restore        %{__localbindir}/pg_restore
ln -sf /usr/pgsql-current/bin/pg_rewind         %{__localbindir}/pg_rewind
ln -sf /usr/pgsql-current/bin/pg_test_fsync     %{__localbindir}/pg_test_fsync
ln -sf /usr/pgsql-current/bin/pg_test_timing    %{__localbindir}/pg_test_timing
ln -sf /usr/pgsql-current/bin/pg_upgrade        %{__localbindir}/pg_upgrade
ln -sf /usr/pgsql-current/bin/pg_waldump        %{__localbindir}/pg_waldump
ln -sf /usr/pgsql-current/bin/pgbench           %{__localbindir}/pgbench
ln -sf /usr/pgsql-current/bin/psql              %{__localbindir}/psql
ln -sf /usr/pgsql-current/bin/reindexdb         %{__localbindir}/reindexdb
ln -sf /usr/pgsql-current/bin/vacuumdb          %{__localbindir}/vacuumdb

# postgresqlXX-server packages
ln -sf /usr/pgsql-current/bin/initdb            %{__localbindir}/initdb
ln -sf /usr/pgsql-current/bin/pg_controldata    %{__localbindir}/pg_controldata
ln -sf /usr/pgsql-current/bin/pg_ctl            %{__localbindir}/pg_ctl
ln -sf /usr/pgsql-current/bin/pg_resetwal       %{__localbindir}/pg_resetwal
ln -sf /usr/pgsql-current/bin/postgres          %{__localbindir}/postgres
ln -sf /usr/pgsql-current/bin/postmaster        %{__localbindir}/postmaster

# pg_strom-PGXX packages
ln -sf /usr/pgsql-current/bin/gpuinfo		%{__localbindir}/gpuinfo
ln -sf /usr/pgsql-current/bin/pg2arrow		%{__localbindir}/pg2arrow
ln -sf /usr/pgsql-current/bin/dbgen-ssbm	%{__localbindir}/dbgen-ssbm

%postun
if [ $1 = 0 ]; then
  for d in `alternatives --display pgsql | grep ^/usr/pgsql- | awk '{print $1}'`;
  do
    alternatives --remove pgsql $d
  done
fi

%triggerin -- postgresql96
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-96 96 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/96/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/96/backups || exit 0
fi

%triggerpostun -- postgresql96
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-9.6 || exit 0
fi

%triggerin -- postgresql10
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-10 100 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/10/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/10/backups || exit 0
fi

%triggerpostun -- postgresql10
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-10 || exit 0
fi

%triggerin -- postgresql11
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-11 110 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/11/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/11/backups || exit 0
fi

%triggerpostun -- postgresql11
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-11 || exit 0
fi

%triggerin -- postgresql12
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-12 120 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/12/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/12/backups || exit 0
fi

%triggerpostun -- postgresql12
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-12 || exit 0
fi

%triggerin -- postgresql13
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-13 130 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/13/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/13/backups || exit 0
fi

%triggerpostun -- postgresql13
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-13 || exit 0
fi

%triggerin -- postgresql14
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-14 140 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/14/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/14/backups || exit 0
fi

%triggerpostun -- postgresql14
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-14 || exit 0
fi

%triggerin -- postgresql15
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-15 150 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/15/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/15/backups || exit 0
fi

%triggerpostun -- postgresql15
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-15 || exit 0
fi

%triggerin -- postgresql16
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-16 160 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/16/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/16/backups || exit 0
fi

%triggerpostun -- postgresql16
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-16 || exit 0
fi

%triggerin -- postgresql17
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-17 170 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/17/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/17/backups || exit 0
fi

%triggerpostun -- postgresql17
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-17 || exit 0
fi

%triggerin -- postgresql18
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-18 180 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/18/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/18/backups || exit 0
fi

%triggerpostun -- postgresql18
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-18 || exit 0
fi

%triggerin -- postgresql19
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-19 190 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/19/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/19/backups || exit 0
fi

%triggerpostun -- postgresql19
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-19 || exit 0
fi

%triggerin -- postgresql20
if [ $2 -gt 0 ]; then
  alternatives --install /usr/pgsql-current pgsql /usr/pgsql-20 200 \
               --slave   /var/lib/pgdata pgdata /var/lib/pgsql/20/data \
               --slave   /var/lib/pgbackups pgbackups /var/lib/pgsql/20/backups || exit 0
fi

%triggerpostun -- postgresql20
if [ $2 -eq 0 ]; then
  alternatives --remove pgsql /usr/pgsql-20 || exit 0
fi

%files
%defattr(-,root,root,-)
# postgresqlXX packages
%{localbindir}/clusterdb
%{localbindir}/createdb
%{localbindir}/createuser
%{localbindir}/dropdb
%{localbindir}/dropuser
%{localbindir}/pg_archivecleanup
%{localbindir}/pg_basebackup
%{localbindir}/pg_config
%{localbindir}/pg_dump
%{localbindir}/pg_dumpall
%{localbindir}/pg_isready
%{localbindir}/pg_receivewal
%{localbindir}/pg_restore
%{localbindir}/pg_rewind
%{localbindir}/pg_test_fsync
%{localbindir}/pg_test_timing
%{localbindir}/pg_upgrade
%{localbindir}/pg_waldump
%{localbindir}/pgbench
%{localbindir}/psql
%{localbindir}/reindexdb
%{localbindir}/vacuumdb

# postgresqlXX-server packages
%{localbindir}/initdb
%{localbindir}/pg_controldata
%{localbindir}/pg_ctl
%{localbindir}/pg_resetwal
%{localbindir}/postgres
%{localbindir}/postmaster

# pg_strom-PGXX packages
%{localbindir}/gpuinfo
%{localbindir}/pg2arrow
%{localbindir}/dbgen-ssbm

%changelog
* Tue Sep  3 2019 KaiGai Kohei <kaigai@heterodb.com> 1.1-1
- add PG-Strom related commands

* Sun Feb 25 2018 KaiGai Kohei <kaigai@heterodb.com> 1.0-1
- initial release
