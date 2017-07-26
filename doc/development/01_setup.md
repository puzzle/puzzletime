## Setup der Entwicklungsumgebung

Die Applikation läuft unter Ruby >= 2.2.2, Rails 5 und PostgreSQL (development, test und production).


### System

Grundsätzlich muss für PuzzleTime eine Ruby Version grösser gleich 2.2.2 sowie Bundler vorhanden sein.
Siehe dazu https://www.ruby-lang.org/en/documentation/installation/.

Die Befehle gehen von einem Ubuntu Linux als Entwicklungssystem aus.
Bei einem anderen System müssen die Befehle entsprechend angepasst werden.

    sudo apt-get install postgresql postgresql-server-dev-all

Folgende Dritt-Packete sind für die verschiedenen Features von PuzzleTime zusätzlich erforderlich.

    sudo apt-get install memcached


### Datenbank

 PuzzleTime verwendet PostgreSQL. Da auch DB-spezifische Features (Array Columns) verwendet werden, muss für Development und Test immer PostgreSQL eingesetzt werden.

Da auf DB-Ebene Foreign Keys verwendet werden, muss die Verbindung auf die Test DB mit einem Superuser erfolgen, damit die referenzielle Integrität beim Laden der Fixtures deaktiviert werden kann:

    sudo su postgres
    createuser -W -s -P puzzletime

Als Passwort für dev und test wird `timepuzzle` verwendet.

Alternativ: Laden eines Dumps:

    rake db:dump:load FILE=dump.sql

### Source

PuzzleTime aus dem Git Repository klonen, dazu muss Git installiert sein:

    sudo apt-get install git

    cd your-code-directory

    git clone https://github.com/puzzle/puzzletime.git


### Setup

Ruby Gem Dependencies installieren (alle folgenden Befehle im PuzzleTime Verzeichnis ausführen):

    bundle

Datenbank erstellen

    rake db:create

Initialisieren der Datenbank, laden der Seeds:

    rake db:setup

Starten des Entwicklungsservers:

    rails server

oder gleich aller wichtigen Prozesse:

    gem install foreman
    foreman start


### Seeds

Über die Development-Seeds werden unter anderem folgende Benutzer geladen:

| Name | Benutzername | Rolle | Passwort |
| --- | --- | --- | --- |
| Mark Waber | mw | manager | a |
| Andreas Rava | ar | manager | a |
| Pascal Zumkehr | pz | user | a |
| Daniel Illi | di | user | a |

Weitere Employees können in `db/seeds/development/employees.rb` hinzugefügt werden.


### Tests

Ausführen der Tests:

    rake

Dies führt aus Performancegründen keine JavaScript/Integration Tests aus. Diese können explizit
gestartet werden. Dazu muss XVFB installiert sein.

    sudo apt-get install xvfb
    rake test test/integration

Standartmässig wird der Browser beim Ausführen nicht angezeigt, dies ist aber möglich:

    HEADLESS=false rake test test/integration

Es ist möglich eine bestimmte Firefox Version zu verwenden:

    FIREFOX_PATH=/path/to/firefox rake test test/integration


### Request Profiling

Um einen einzelnen Request zu Profilen, kann der Parameter `?profile_request=true` in der URL
angehängt werden. Der Output wird nach `tmp/performance` geschrieben.


### Delayed Job

Um die Background Jobs abzuarbeiten (z.B. für die Synchronisation mit den CRM/Invoicing Diensten),
muss Delayed Job gestartet werden:

    rake jobs:work


### Spezifische Rake Tasks

| Task | Beschreibung |
| --- | --- |
| `rake annotate` | Spalten Informationen als Kommentar zu ActiveRecord Modellen hinzufügen. |
| `rake brakeman` | Führt `brakeman` aus. |
| `rake ci` | Führt die Tasks für einen Commit Build aus. |
| `rake ci:nightly` | Führt die Tasks für einen Nightly Build aus. |
| `rake db:dump` | Lädt einen Datenbankdump von `FILE`. |
| `rake db:create_testuser` | Erstellt die Testbenutzer `MB1` und `MB2` mit Passwort `member` |
| `rake erd` | Erstellt ein Entitiy Relationship Diagram in `doc/models.png` |
| `rake gemsurance` | Ruby Gems nach Vulnerabilities überprüfen |
| `rake license:insert` | Fügt die Lizenz in alle Dateien ein. |
| `rake license:remove` | Entfernt die Lizenz aus allen Dateien. |
| `rake license:update` | Aktualisiert die Lizenz in allen Dateien oder fügt sie neu ein. |
| `rake rubocop:changed` | Führt die Rubocop Standard Checks (`.rubocop.yml`) auf den geänderten files aus. |
| `rake rubocop:report` | Führt die Rubocop Standard Checks (`.rubocop.yml`) aus und generiert einen Report für Jenkins. |
