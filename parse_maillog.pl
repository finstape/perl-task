use strict;
use warnings;
use DBI;

# Настройки для подключения к БД
my $dsn = "DBI:Pg:dbname=maillog;host=localhost";
my $user = "postgres";
my $password = "postgres";

my $dbh = DBI->connect($dsn, $user, $password, {
    RaiseError => 1,
    AutoCommit => 1,
    pg_enable_utf8 => 1,
}) or die "Could not connect to the database: $DBI::errstr";

open my $log_file, '<', 'out' or die "Cannot open log file: $!";

# Проход по строкам файла лога
while (my $line = <$log_file>) {
    chomp $line;

    # Разбор строки лога
    my ($date, $time, $int_id, $flag, @rest) = split /\s+/, $line, 5;

    my $created = "$date $time";  # Форматируем timestamp
    my $log_str = join(' ', $flag, @rest);  # Собираем остальную часть строки, включая флаг

    my $address;

    if ($flag eq '<=') {
        # Обрабатываем строки с прибытием сообщений
        my ($id) = $log_str =~ /id=(\S+)/;  # Извлекаем id

        if (defined $id) {
            # Вставка в таблицу message
            my $insert_message = "INSERT INTO message (created, id, int_id, str, status) VALUES (?, ?, ?, ?, ?)";
            eval {
                $dbh->do($insert_message, undef, $created, $id, $int_id, $log_str, 1);
            };
            if ($@) {
                warn "Failed to insert into message table: $@";
            }
        } else {
            warn "Skipping message with undefined id for line: $line";
        }
    } elsif ($flag eq '=>' || $flag eq '->' || $flag eq '**' || $flag eq '==') {
        # Обрабатываем нормальную доставку, дополнительные адреса и ошибки/задержки
        if ($flag eq '=>') {
            # Для флага => извлекаем адрес
            if ($log_str =~ /<([^>]+)>/) {
                ($address) = $log_str =~ /<([^>]+)>/;  # Извлекаем адрес в формате <адрес>
            } elsif ($log_str =~ /(\S+@\S+)/) {
                ($address) = $log_str =~ /(\S+@\S+)/;  # Извлекаем адрес в формате почты
            }
        } elsif ($flag eq '->') {
            # Для флага -> сразу извлекаем адрес
            if ($log_str =~ /(\S+@\S+)/) {
                ($address) = $log_str =~ /(\S+@\S+)/;  # Извлекаем адрес в формате почты
            }
        } elsif ($flag eq '**' || $flag eq '==') {
            # Для ошибок и задержек извлекаем адрес
            if ($log_str =~ /<([^>]+)>/) {
                ($address) = $log_str =~ /<([^>]+)>/;  # Извлекаем адрес в формате <адрес>
            } elsif ($log_str =~ /(\S+@\S+)/) {
                ($address) = $log_str =~ /(\S+@\S+)/;  # Извлекаем адрес в формате почты
            }
        }
        
        # Вставка в таблицу log
        my $insert_log = "INSERT INTO log (created, int_id, str, address) VALUES (?, ?, ?, ?)";
        eval {
            $dbh->do($insert_log, undef, $created, $int_id, $log_str, $address);
        };
        if ($@) {
            warn "Failed to insert into log table: $@";
        }
    } else {
        # Если флаг не соответствует ни одному из перечисленных значений, добавляем как обычное сообщение
        my $insert_log = "INSERT INTO log (created, int_id, str, address) VALUES (?, ?, ?, ?)";
        eval {
            $dbh->do($insert_log, undef, $created, $int_id, $log_str, undef);  # Адреса нет
        };
        if ($@) {
            warn "Failed to insert into log table: $@";
        }
    }
}

close $log_file;
$dbh->disconnect;
