## Entwicklungs Guidelines

### Code Conventions

Die Code Conventions werden mit Rubocop. Grundsätzlich folgen wir den Ruby on Rails
Standardkonventionen.

Vor jedem Commit soll Rubocop auf die geänderten Dateien losgelassen werden. Die gefundenen
Violations sind unmittelbar zu korrigieren.

    rubocop [files]

Das selbe gilt für Warnungen, welche im Jenkins auftreten (Brakeman, ...).


### Lizenzen

PuzzleTime ist ein Open Source Projekt. Entsprechen müssen in jedem (!) File Header
Lizenzinformationen eingefügt werden. Dies kann manuell geschehen oder über den folgenden Rake Task:

    rake license:insert

Der Hauplizenztext und weitere Konfigurationen sind unter `lib/tasks/license.rake`.
