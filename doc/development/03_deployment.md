## Deployment und Betrieb

PuzzleTime kann wie die meisten Ruby on Rails Applikationen auf verschiedene Arten
[deployt](http://rubyonrails.org/deploy/) werden.
Folgende Umsysteme müssen vorgängig eingerichtet werden:

* Ruby >= 2.2.2
* Apache HTTPD
* Phusion Passenger
* PostgreSQL
* Memcached
* SSL Zertifikat (optional)
* Airbrake/Errbit (optional)
* Highrise CRM (optional)
* Smallinvoice (optional)


### Konfiguration

Um PuzzleTime mit den Umsystemen zu verbinden und zu konfigurieren, können folgende Umgebungsvariablen
gesetzt werden. Werte ohne Default müssen in der Regel definiert werden.

| Umgebungsvariable | Beschreibung | Default |
| --- | --- | --- |
| RAILS_API_USER | Benutzername für API HTTP basic auth | |
| RAILS_API_PASSWORD | Passwort für API HTTP basic auth | |
| RAILS_DB_NAME | Name der Datenbank | `puzzletime_[environment]` |
| RAILS_DB_USERNAME | Benutzername, um auf die Datenbank zu verbinden. | - |
| RAILS_DB_PASSWORD | Passwort, um auf die Datenbank zu verbinden. | - |
| RAILS_DB_HOST | Hostname der Datenbank | 127.0.0.1 |
| RAILS_DB_PORT | Port der Datenbank | - |
| RAILS_DB_ADAPTER | Datenbank adapter | `postgresql` |
| RAILS_SECRET_TOKEN | Secret token für die Sessions (128 byte hex). Muss für jede laufende Instanz eindeutig sein. Generierbar mit `rake secret` | - |
| RAILS_MEMCACHED_HOST | Hostname des Memcache Dienstes | localhost |
| RAILS_MEMCACHED_PORT | Port des Memcache Dienstes  | 11211 |
| RAILS_SERVE_STATIC_FILES | Ob statische Dateien in der Produktivumgebung geserved werden sollen  | false |
| RAILS_AIRBRAKE_HOST | Hostname der Airbrake/Errbit Instanz, an welche Fehler gesendet werden sollen. Falls diese Variable nicht gesetzt ist, werden keine Fehlermeldungen verschickt. | - |
| RAILS_AIRBRAKE_PORT | Port der Airbrake/Errbit Instanz | 443 |
| RAILS_AIRBRAKE_API_KEY | Airbrake API Key der Applikation | - |
| RAILS_HIGHRISE_URL | Highrise App-URL: https://<Name der Firma/Organisation>.highrisehq.com | - |
| RAILS_HIGHRISE_TOKEN | Highrise API Key der Applikation (im Highrise: Account & Settings > My Info > API Token) | - |
| RAILS_SMALL_INVOICE_TOKEN | Smallinvoice API Key der Applikation | - |
| RAILS_SMALL_INVOICE_REQUEST_RATE | | 1 |
| RAILS_LDAP_HOST |  | - |
| RAILS_LDAP_PORT |  | 636 |
| RAILS_LDAP_USER_DN |  | - |
| RAILS_LDAP_ENCRYPTION |  | simple_tls |
| RAILS_LDAP_EXTERNAL_DN |  | - |
| RAILS_LDAP_GROUP_DN |  | - |

### OpenShift Deployment Example
Note: The following steps can be used to get an idea of how to deploy PuzzleTime on OpenShift.

Create a new project

    oc new-project puzzle-time

Create a database service

    oc new-app \
    -e POSTGRESQL_USER=username \
    -e POSTGRESQL_PASSWORD=password \
    -e POSTGRESQL_DATABASE=db_name \
    registry.access.redhat.com/rhscl/postgresql-95-rhel7  --name=pg-ptime

Note: For production you should add a persistent volume to the service

Create a memcached service

    oc new-app --docker-image=memcached

Create the frontend service

    oc new-app puzzle/ose3-rails~https://github.com/puzzle/puzzletime.git -e RAILS_DB_NAME=db_name -e RAILS_DB_USERNAME=username -e RAILS_DB_PASSWORD=password -e RAILS_DB_HOST=pg-ptime.puzzle-time.svc -e RAILS_MEMCACHED_HOST=memcached.puzzle-time.svc --name=puzzletime

Expose the frontend service

    oc expose svc/puzzletime --hostname=puzzletime.nubiq.ch

Get the pods

    oc get pods

Open a remote shell session to the frontend container

    oc rsh puzzletime-<id>

Populate the database

    bundle exec rake db:migrate
    bundle exec rake db:seed

Create the testusers

    bundle exec rake db:create_testuser
