Name: postgres@@PKGVER@@-alternatives
Version: 1.0
Release: 1%{?dist}
Summary: alternatives configuration for PostgreSQL @@PGSQL_VERSION@@
Group: Applications/Databases
License: PostgreSQL
Requires: chkconfig
Requires: postgresql@@PKGVER@@
Requires: postgresql@@PKGVER@@-server
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
alternatives configuration for PostgreSQL @@PGSQL_VERSION@@ provided by
PostgreSQL Global Development Group.
This package puts symbolic links from /usr/local/bin to /usr/pgsql-xx.

%post
if [ "$1" = 1 ]; then
  alternatives \
    --install /usr/local/bin/postgres postgres  \
              /usr/pgsql-@@PGSQL_VERSION@@/bin/postgres @@PRIORITY@@ \
    --slave /var/lib/pgdata pgdata \
            /var/lib/pgsql/@@PGSQL_VERSION@@/data \
    --slave /var/lib/pgbackups pgbackups \
            /var/lib/pgsql/@@PGSQL_VERSION@@/backups \
    --slave /usr/local/bin/initdb initdb \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/initdb \
    --slave /usr/local/bin/pg_ctl pg_ctl \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_ctl \
    --slave /usr/local/bin/postmaster postmaster \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/postmaster \
    --slave /usr/local/bin/pg_controldata pg_controldata \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_controldata \
    --slave /usr/local/bin/pg_resetxlog pg_resetxlog \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_resetxlog \
    --slave /usr/local/bin/psql psql \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/psql \
    --slave /usr/local/bin/clusterdb clusterdb \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/clusterdb \
    --slave /usr/local/bin/createdb createdb \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/createdb \
    --slave /usr/local/bin/createlang createlang \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/createlang \
    --slave /usr/local/bin/createuser createuser \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/createuser \
    --slave /usr/local/bin/dropdb dropdb \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/dropdb \
    --slave /usr/local/bin/droplang \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/droplang \
    --slave /usr/local/bin/dropuser dropuser \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/dropuser \
    --slave /usr/local/bin/pg_archivecleanup pg_archivecleanup \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_archivecleanup \
    --slave /usr/local/bin/pg_basebackup pg_basebackup \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_basebackup \
    --slave /usr/local/bin/pg_config pg_config \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_config \
    --slave /usr/local/bin/pg_dump pg_dump \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_dump \
    --slave /usr/local/bin/pg_dumpall pg_dumpall \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_dumpall \
    --slave /usr/local/bin/pg_isready pg_isready \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_isready \
    --slave /usr/local/bin/pg_receivexlog pg_receivexlog \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_receivexlog \
    --slave /usr/local/bin/pg_restore pg_restore \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_restore \
    --slave /usr/local/bin/pg_rewind pg_rewind \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_rewind \
    --slave /usr/local/bin/pg_test_fsync pg_test_fsync \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_test_fsync \
    --slave /usr/local/bin/pg_test_timing pg_test_timing \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_test_timing \
    --slave /usr/local/bin/pg_upgrade pg_upgrade \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_upgrade \
    --slave /usr/local/bin/pg_xlogdump \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_xlogdump \
    --slave /usr/local/bin/pgbench pgbench \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/pgbench \
    --slave /usr/local/bin/reindexdb reindexdb \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/reindexdb \
    --slave /usr/local/bin/vacuumdb vacuumdb \
            /usr/pgsql-@@PGSQL_VERSION@@/bin/vacuumdb
fi

%preun
if [ "$1" = 0 ]; then
#  alternatives --remove postgres /usr/pgsql-@@PGSQL_VERSION@@/bin/postgres
fi

%files
%defattr(-,root,root,-)

%changelog
* Sun Feb 25 2018 KaiGai Kohei <kaigai@heterodb.com> 1.0-1
- initial release
