![Perl](https://img.shields.io/badge/Perl-39457E?style=flat&logo=perl&logoColor=white)

# perl-task

## Установка

Установите нужные библиотеки:
```bash
cpan DBI DBD::Pg CGI HTTP::Daemon
```

## Настройка

Создайте конфигурацию для подключения к PostgreSQL

## Выполнение скриптов

Сначала выполните следующие скрипты для инициализации базы данных и парсинга логов
```bash
perl create_db.pl
perl parse_maillog.pl
```

## Запуск сервера

Запустите веб-сервер
```bash
perl simple-server.pl
```

## Использование

Откройте файл 'search.html' в вашем браузере и введите адрес электронной почты для поиска

## Лицензия

[MIT](https://choosealicense.com/licenses/mit/)
