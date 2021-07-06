# InfluxDB-Metriken

PuzzleTime kann folgende Metriken nach InfluxDB v2 exportieren:

## Umsatz

* InfluxDB-Bucket: `Revenue`

Metriken / Felder

* `revenue_ordertime` - Geleistet
  * `volume [CHF]` - geleistete verrechenbare Aufwände
* `revenue_planning` - Forecast
  * `volume [CHF]` - geplante verrechenbare Aufwände

Tags

* `time_delta` - Zeitraum der Auswertung, z.B "-2 months" für vorletzter Monat
* `month` - Monat, den die Auswertung betrifft, z.B. "2021-01"
* `department` - Bereich

## Auslastung

* InfluxDB-Bucket: `Workload`

Metriken

* `workload_last_week` - Auswertungen der letzten Woche
  * `employment_fte [Vollzeitäkquivalente]` - Kumulierter Anstellungsgrad (1 = 100%)
  * `must_hours [h]` - Soll-Zeit
  * `must_hours [h]` - Ist-Zeit
  * `paid_absence_hours [h]` - Absenzen
  * `worktime_balance [h]` - Über-/Unterzeit
  * `external_client_hours [h]` - Kundenprojekte
  * `billable_hours [h]` - Verrechenbare Zeit
  * `workload [%]` - Auslastung
  * `billability [%]` - Verrechenbarkeit
  * `absolute_billability [%]` - Absolute Verrechenbarkeit

Tags

* `department` (Bereich)

## Aufträge

* InfluxDB-Bucket: `Orders`

Metriken

* `order_report` - Auftrags-Controlling
  * `offered_amount [CHF/EUR]` - Budget
  * `supplied_amount [CHF/EUR]` - Geleistet
  * `billable_amount [CHF/EUR]` - Verrechenbar
  * `billed_amount [CHF/EUR]` - Verrechnet
  * `billabiltity [%]` - Verrechenbarkeit
  * `offered_rate [CHF/h]` - Offerierter Stundensatz
  * `billed_rate [CHF/h]` - Verrechneter Stundensatz
  * `average_rate [CHF/h]` - Durchschnittlicher Stundensatz
  * `target_budget ["green"|"orange"|"red"]` - Projekt-Ampel "Kosten"
  * `target_schedule ["green"|"orange"|"red"]` - Projekt-Ampel "Termin"
  * `target_quality ["green"|"orange"|"red"]` - Projekt-Ampel "Qualität"

Tags

* `client` - Kunde
* `name` - Auftragsname
* `status` - Bearbeitungsstatus
* `category` - Kategorie

## CRM (Highrise)

* InfluxDB-Bucket: `Highrise`

Metriken

* `highrise_deals_yesterday` - Deals
  * `count` - Anzahl der Deals, welche erstellt wurden oder in einen neuen Status gewechselt haben
* `highrise_volume_yesterday` - Deal-Volumen
  * `value [CHF/EUR]` - Gesamtvolumen der Deals (Fixpreise + Stundensätze * Angebotene Stunden), welche erstellt wurden oder in einen neuen Status gewechselt haben

Tags

* `status` - Bearbeitungsstatus
* `category` - Deal-Kategorie
