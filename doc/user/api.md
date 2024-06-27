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
