# 2.6

### Features
* **Mitarbeiter-Stammdaten:** Ausweisinformationen können nun hinzugefügt werden.
* **Buchungspositionen:** Einstellungen zu Ticket, Von-Bis-Zeiten und Bemerkungen können nicht mehr geändert werden, falls bereits Leistungen ohne diese Angaben erfasst wurden.
* **Buchungspositionen:** Auftrags-Cockpit mit neuen Informationen ergänzt.

### Improvements
* **Usability:** "Members" - "Zeiten" werden standardmässig nach Members der eigenen Organisationseinheit gefiltert, was die Bedienung und Ladegeschwindigkeit massiv steigert.
* **WebServer:** Mehr Threads für mehr Leistung.
* **Sicherheit:** Updates diverser rubygems aus Sicherheitsgründen.

### Bug fixes
* **Stundenübersicht:** Falsches Total berichtigt.
* **Buchungspositionen:** Automatische Budget-Berechnung beim Eintragen korrigiert.
* **Mitarbeiterliste:** Falsche Berechnung des Jubiläum (Dienstjahre) [\#61](https://github.com/puzzle/puzzletime/issues/61)


# 2.5

### Improvements
* **Layout:** Die Navigationsleiste ist nun sticky [\#29](https://github.com/puzzle/puzzletime/issues/29)
* **Wording:** Mitarbeiter heissen neu Members.
* **Absenzen:** Mit Management-Berechtigung können nun Absenzen der anderen Members gelöscht werden.
* **Zeitfreigabe:** Die Zeitfreigabe wird neu im Log des Members angezeigt.
* **Rechnungen:** Manuelle Rechnung, die im Rechnungsstellungtool editiert wurden, können in PuzzleTime nicht mehr versehentlich überschrieben werden.
* **Mitarbeiterblatt:** Die AHV-Nummer der Members wird nur noch mit Management-Berechtigung angezeigt [\#23](https://github.com/puzzle/puzzletime/issues/23)

* **Umsatzberechnung:** Fälschlicherweise verrechenbar gebuchte Stunden auf Puzzle werden nun nicht mehr mit einbezogen.
* **Umsatz:** Gibt es jetzt als CSV Export.
* **Feiertage:** Neu können alle Feiertage frei konfiguriert werden.
* **Sicherheit:** Updates diverser rubygems aus Sicherheitsgründen.

### Bug fixes
* **Login:** Bei fehlerhaftem Login wird die Meldung nun in der Warnfarbe dargestellt.
* **Wochenübersicht Stunden:** Sollstundenlinie verschiebt sich nicht mehr.
* **Zeitbuchung:** Es kann nun nur noch von 00:00-23:59 gebucht werden um Fehlern vorzubeugen.
* **Budget-Controlling:** Submenü wird nun wieder korrekt dargestellt.
* **Browsersupport:** Projektsuche funktioniert wieder auf IE11.


# 2.4

### Features
* **Spesen:** Neu können in PuzzleTime Spesen hochgeladen und freigegeben resp. abgelehnt werden.
* **API:** Ein neues json:api mit Lesezugriff, vorerst nur für /employees. Unter `/api/docs` ist ein Swagger UI mit der Dokumentation verfügbar.

### Improvements
* **Umsatz:** Auftragsverantwortliche haben nun auch Zugriff auf den Umsatz.

### Bug Fixes
* **Zeiterfassung:** Usability Fehler beim Duplizieren von Zeiteinträgen geflickt [\#28](https://github.com/puzzle/puzzletime/issues/28)
* **Zeiterfassung:** Beim Zeiterfassen mit Firefox kann mit Tab wieder von der Buchungsposition weitergesprungen werden [\#34](https://github.com/puzzle/puzzletime/issues/34)


# 2.3

### Improvements
* **Ruby/Rails:** Auf Ruby 2.5.3 und Rails 5.2.2 aktualisiert
* **Mitarbeiter-Stammdaten:** Neu können bei den Mitarbeitern Nationalitäten und der (Hochschul-)Abschluss erfasst werden.
* **Rechnungen:** Unter Aufträge - In einem einzelnen Auftrag - Rechnungen wurden die Summen verbessert um einen besseren Überblick über bezahlte und offene Stunden zu erhalten.
* **Mitarbeiterlog I:** Unter Verwalten - Mitarbeiter - Log können berechtigte Personen nun nebst den Änderungen am Mitarbeiter auch die Änderungen an den Anstellungen nachverfolgen.
* **Mitarbeiterlog II:** Sofern möglich werden Namen statt IDs der Änderungen angezeigt.
* **Konfigurierbarkeit:** ID der betreibenden Firma, MwST, Währung und Land können nun konfiguriert werden.

### Bug Fixes
* **Wirtschaftlichkeit:** Unter Aufträge - In einem einzelnen Auftrag - Positionen werden in der Berechnung der Wirtschaftlichkeit die stornierten Rechnungen nicht mehr mit einberechnet.

# 2.2

### Features
* **Budget-Controlling I:** Unter Aufträge - Controlling sieht man anhand eines Fortschrittsbalken, wie viele Stunden vom Gesamtbudget schon geleistet wurden. Ein Klick darauf führt ins neue Budget-Controlling Tab des entsprechenden Auftrages.
* **Budget-Controllig II:** Im Budget-Controlling Tab eines Auftrages sieht man anhand eines chicen Balkendiagramms, wann wie viele Stunden geleistet wurden und wie viele Stunden in der Zukunft provisorisch und definitiv geplant sind.
* **Zeitkontrolle:** Zeitfreigabe und -kontrolle ist nun auch für die Auftragsverantwortlichen (unter Aufträge - Meine Aufträge) ersichtlich
* **Mitarbeiterblatt:** Auf dem Mitarbeiterblatt (unter Mitarbeiter - Zeiten - Mitarbeiter auswählen) ist nun die Sollarbeitszeit im entsprechenden Zeitraum ersichtlich.
* **Fremde Arbeitszeiten löschen:** Mit Management-Berechtigung können die Arbeitszeiten anderen Mitarbeiter gelöscht werden. Diese werden per E-Mail darüber informiert, wer wann welchen Eintrag gelöscht hat.

### Bug Fixes
* **Planung:** Planungseinträge gehen nicht mehr verloren, wenn in einem Auftrag ohne Buchungspositionen nachträglich Buchungspositionen erstellt werden
* **Planungswiederholung:** Eine Planungswiederholung kann nun auch bis am 31.12.2018 erstellt werden, denn dieses Datum trifft ausnahmsweise auf die Kalenderwoche 1 des Folgejahres 2019.
* **Mitarbeiterblatt:** Das Mitarbeiterblatt (unter Mitarbeiter - Zeiten - Mitarbeiter auswählen) sieht nun auch gedruckt gut aus und passt auf eine Seite (querformat).
* **Zeiterfassung:** Die Arbeitszeiten können nun auch mit Microsoft Edge erfasst werden [\#3](https://github.com/puzzle/puzzletime/issues/3)

# 2.1

### Features

* **Risikomanagement:** Die Chancen/Risiken werden neu in einem eigenen Tab unter den Aufträgen verwaltet
* **Mehrere Highrise Aufträge:** Auf einem Auftrag können nun mehrere Highrise Aufträge verlinkt werden
* **Zeitkontrolle:** Die Zeitkontrolle kann nun im PuzzleTime unter "Auswertungen" - "Mitarbeit" - "Kontrolle" gemacht werden
* **Jubiläum:** In der Mitarbeiterliste werden nun die Anzahl Dienstjahre der Mitarbeiter angezeigt


### Bug Fixes

* **Volltextsuche:** Volltextsuche der Buchungspositionen geflickt
* **Auslastung:** Auswertung Detailierte Auslastung CSV berücksichtigt nun die korrekten internen Positionen
* **MWST:** PuzzleTime kann nun mit mehreren MWST-Sätzen korrekt rechnen
* **Absenzen:** Die Sichtbarkeit der Absenzen bereinigen


### Improvements

* **Ruby/Rails:** Auf Ruby 2.2.2 und Rails 5.1.2 aktualisiert
* **Performance:** Chrome Memory Leak in Plannings behoben
* **Usability:** Menüstruktur reorganisiert


