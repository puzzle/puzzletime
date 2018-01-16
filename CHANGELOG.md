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


