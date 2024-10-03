use strict;
use warnings;
use DBI;

# Настройки подключения к PostgreSQL
my $dbname = "maillog";
my $user = "postgres";
my $password = "postgres";
my $host = "localhost";

# Подключаемся к базе данных "postgres" для выполнения запросов по созданию базы данных
my $dsn = "DBI:Pg:dbname=postgres;host=$host;port=5432";
my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1 })
    or die $DBI::errstr;

eval {
    $dbh->do("CREATE DATABASE $dbname");
    print "Database $dbname created successfully.\n";
};
if ($@) {
    print "Database $dbname already exists or error: $@\n";
}

$dsn = "DBI:Pg:dbname=$dbname;host=$host";
$dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1 })
    or die $DBI::errstr;

eval {
    $dbh->do("
        CREATE TABLE IF NOT EXISTS message (
            created TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
            id VARCHAR NOT NULL,
            int_id CHAR(16) NOT NULL,
            str VARCHAR NOT NULL,
            status BOOL,
            CONSTRAINT message_id_pk PRIMARY KEY(id)
        );
    ");
    print "Table 'message' created successfully.\n";

    $dbh->do("CREATE INDEX IF NOT EXISTS message_created_idx ON message (created);");
    $dbh->do("CREATE INDEX IF NOT EXISTS message_int_id_idx ON message (int_id);");
};
if ($@) {
    die "Error creating table 'message': $@\n";
}

eval {
    $dbh->do("
        CREATE TABLE IF NOT EXISTS log (
            created TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
            int_id CHAR(16) NOT NULL,
            str VARCHAR,
            address VARCHAR
        );
    ");
    print "Table 'log' created successfully.\n";

    $dbh->do("CREATE INDEX IF NOT EXISTS log_address_idx ON log USING hash (address);");
};
if ($@) {
    die "Error creating table 'log': $@\n";
}

$dbh->disconnect;
print "Database setup completed.\n";
