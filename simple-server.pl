#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Status;
use IO::Socket;
use CGI;

# Создаем HTTP-сервер
my $d = HTTP::Daemon->new(
    LocalAddr => 'localhost',
    LocalPort => 8080,
    Reuse     => 1,
) || die;

print "Server run on ", $d->url, "\n";

while (my $c = $d->accept) {
    while (my $r = $c->get_request) {
        if ($r->method eq 'POST') {
            my $cgi = CGI->new($r->content);
            my $email = $cgi->param('email');

            # Запускаем search.pl с переданным параметром email
            my $output = `perl search.pl email=$email`;

            # Проверка на ошибки выполнения
            if ($? != 0) {
                $c->send_error(RC_INTERNAL_SERVER_ERROR, "Error while proccess script");
                next;
            }

            # Отправляем ответ
            print $c "HTTP/1.0 200 OK\r\n";
            print $c "Content-Type: text/html; charset=UTF-8\r\n\r\n";
            print $c $output;
        } else {
            $c->send_error(RC_METHOD_NOT_ALLOWED);
        }
    }
    $c->close;
    undef($c);
}
