#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use DBI;


# Настройки для подключения к БД
my $dsn = "DBI:Pg:dbname=maillog;host=localhost";
my $user = "postgres";
my $password = "postgres";

my $cgi = CGI->new;

# Получаем адрес электронной почты из параметров запроса
my $email;
if (defined($ARGV[0]) && $ARGV[0] =~ /email=(.*)/) {
    $email = $1;
}

# Подключение к БД
my $dbh = DBI->connect($dsn, $user, $password, {
    RaiseError => 1,
    AutoCommit => 1,
    pg_enable_utf8 => 1,
}) or die "Не удалось подключиться к базе данных: $DBI::errstr";

# Подсчет общего количества записей
my $count_sql = "
    SELECT COUNT(*) 
    FROM (
        SELECT created, str, int_id 
        FROM log 
        WHERE address = ? 
        UNION ALL
        SELECT created, str, int_id 
        FROM message 
        WHERE id IN (
            SELECT DISTINCT id 
            FROM log 
            WHERE address = ?
        )
    ) AS combined
";
my $count_sth = $dbh->prepare($count_sql);
$count_sth->execute($email, $email);
my ($total_count) = $count_sth->fetchrow_array;

# SQL-запрос для получения первых 100 записей
my $sql = "
    SELECT created, str 
    FROM (
        SELECT created, str, int_id 
        FROM log 
        WHERE address = ? 
        UNION ALL
        SELECT created, str, int_id 
        FROM message 
        WHERE id IN (
            SELECT DISTINCT id 
            FROM log 
            WHERE address = ?
        )
    ) AS combined
    ORDER BY int_id, created 
    LIMIT 100;
";

# Выполнение запроса
my $sth = $dbh->prepare($sql);
$sth->execute($email, $email);

# Начало HTML-ответа
print $cgi->header('text/html; charset=UTF-8');
print $cgi->start_html('Результаты поиска');
print $cgi->h1('Результаты поиска');

if ($total_count == 0) {
    print $cgi->p("Ничего не найдено для адреса: $email.");
} else {
    if ($total_count > 100) {
        print $cgi->p("Найдено более 100 записей. Пожалуйста, уточните запрос.");
    }
    print $cgi->h2("Найденные записи ($total_count):");
    print $cgi->start_table;

    while (my @row = $sth->fetchrow_array) {
        my ($created, $log_str) = @row;
        print $cgi->Tr($cgi->td("$created $log_str"));
    }

    print $cgi->end_table;
}

# Завершение HTML-ответа
$count_sth->finish;
$sth->finish;
$dbh->disconnect;
print $cgi->end_html;
