# PuzzleTime API

Das API basiert auf dem [json:api] Format.
Es bietet Lesezugriff auf einige ausgewählte Resourcen.

## Authentifizierung

Alle implementierten Endpunkte sind mit [HTTP Basic Authentication][basic_auth] geschützt.

Die Credentials sind in der aktuellen Implementierung global definiert und werden von allen API clients geteilt.
Sie müssen auf dem Server über Umgebungsvariablen konfiguriert werden (siehe [/doc/development/02_deployment.md])

## Pagination

Die Pagination wird mithilfe von Kaminari über DryCrud realisisert.
Somit unterstützt die API folgende Query Parameter:

|Parameter|Beispiel|Funktion|
| ------- | ------ | ------ |
| ```page``` | ```/api/v1/employees?page=2``` | Wählt die gewünschte Seite aus |
| ```per_page``` | ```/api/v1/employees?per_page=100``` | Wählt die gewünschte Anzahl Resultate aus |

Zusätzlich gibt es folgende Header um sich zu orientieren:

| Header | Beispielwert | Funktion |
| ------ | ------------ | -------- |
| PaginationTotalCount | 186 | Enthält die Gesamte Anzahl der gewünschten Resource |
| PagionationPerPage | 10 | Enthält die zurückgegebene Anzahl von Elementen |
| PaginationCurrentPage | 2 | Enthält die zurückgegebene Seite |
| PaginationTotalPages | 19 | Enthält die gesamte Anzahl der Seiten |


## API Dokumentation

Die Dokumentation wird automatisch generiert und ist unter [/api/docs] erreichbar.
Auf dem Puzzletime Server ist sie im Swagger Webinterface unter [/api/docs] einsehbar.

Die Swagger Spezifikation liegt unter [/api/docs/v1], diese kann in [Postman] und ähnliche tools importiert werden.

[json:api]: https://jsonapi.org/
[basic_auth]: https://tools.ietf.org/html/rfc2617
[Postman]: https://www.getpostman.com/
[/doc/development/02_deployment.md]: /doc/development/02_deployment.md
[/api/docs]: /api/docs
[/api/docs/v1]: /api/docs/v1

## API v2

Reines JSON-API (kein json:api) für die meisten Stammdaten, erreichbar unter `/api/v2`. Die Swagger-Spezifikation liegt unter [/api/v2/swagger_doc].

* **Authentifizierung:** HTTP Basic mit den geteilten API-Credentials (nur Leserechte gemäss `Ability`) oder die Session eines angemeldeten Mitarbeiters. Die Berechtigungen entsprechen denen der Weboberfläche.
* **Schreibzugriffe** (`POST`, `PATCH`) müssen den Header `Content-Type: application/json` senden, sonst `415`.
* **Fehler:** `401`, `403`, `404`, `422` mit `{ "errors": { "attribut": ["Meldung"] } }`.
* **Pagination:** `page`, `per_page` (max. 100) und die oben beschriebenen Header.
* **Beziehungen:** z.B. `GET /api/v2/departments/1/employees`.

Ressourcen werden in `app/api/api/v2/root.rb` mit einer Zeile registriert, siehe `Api::V2::Crud`.

### Ressourcen mit eigenen Regeln

Diese Ressourcen sind pro Benutzer eingeschränkt (`scope`) und bilden die Regeln der Weboberfläche nach:

* **Zeiterfassung** (`/ordertimes`, `/absencetimes`): Management sieht alle, alle anderen nur eigene Einträge. `employee_id` darf nur das Management setzen. `hours` und Zeiten akzeptieren Formate wie `8:45`. Zusätzlich `POST /ordertimes/repeat`, `POST /absencetimes/multi` (alles oder nichts) sowie `PATCH /employees/:id/worktimes_commit` und `/worktimes_review`. Der Split-Workflow ist nicht verfügbar.
* **Spesen** (`/expenses`): eigene bzw. (Management) alle. Genehmigte Spesen sind für Nicht-Management gesperrt. Beleg als Base64 via `PUT /expenses/:id/receipt`, Beurteilung via `PATCH /expenses/:id/review` (nur Management).
* **Anstellungen und Überzeit-Vorbezüge** (`/employments`, `/overtime_vacations`): Schreibzugriff nur Management; Funktionsanteile werden verschachtelt in `employment_roles_employments_attributes` geschrieben.
* **Aufträge** (`/orders`, inkl. verschachteltem Work-Item, Team, Kontakten; `PATCH /orders/:id/completed|committed`; `GET`/`PATCH /orders/:id/targets`; `GET`/`PUT /orders/:id/contract`) sowie `/order_comments`, `/order_risks`, `/order_chances` und Kunden (`/clients`).
* **Buchungspositionen** (`/accounting_posts`, Schreibzugriff über `attach_work_item` wie in der Weboberfläche). **Rechnungen** (`/invoices`) und **Planungen** (`/plannings`) sind nur lesbar.

[/api/v2/swagger_doc]: /api/v2/swagger_doc
