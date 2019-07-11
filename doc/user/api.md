# PuzzleTime API

Das API basiert auf dem [json:api] Format.
Es bietet Lesezugriff auf einige ausgewählte Resourcen.

## Authentifizierung

Alle implementierten Endpunkte sind mit [HTTP Basic Authentication][basic_auth] geschützt.

Die Credentials sind in der aktuellen Implementierung global definiert und werden von allen API clients geteilt.
Sie müssen auf dem Server über Umgebungsvariablen konfiguriert werden (siehe [/doc/development/03_deployment.md])



## API Dokumentation

Die Dokumentation wird automatisch generiert.e Dokumentation ist unter [/api/docs] erreichbar.
Auf dem Puzzletime Server ist sie im Swagger Webinterface unter [/api/docs] einsehbar.

Die Swagger Spezifikation liegt unter [/api/docs/v1], diese kann in [Postman] und ähnliche tools importiert werden.

[json:api]: https://jsonapi.org/
[basic_auth]: https://tools.ietf.org/html/rfc2617
[Postman]: https://www.getpostman.com/
[/doc/development/03_deployment.md]: /doc/development/03_deployment.md
[/api/docs]: /api/docs
[/api/docs/v1]: /api/docs/v1
