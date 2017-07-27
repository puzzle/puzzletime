### Vertrag

| Begriff | Beschreibung | Beispiel | Validierung |
| --- | --- | --- | --- |
| _Vertragsreferenz_ | Vertrags- oder Bestellnummer oder andere Referenz aus welcher die Freigabe des Auftrags hervorgeht (z.B. Mail vom Datum XY). <br /> <br />Die Vertragsnummer ist eine eindeutige durch den Kunden vergebene Bezeichnung des Vertrags oder der Bestellung. Diese Nummer wird in der Regel auf der Rechnung gewünscht. <br /> <br />Small-Invoice Feld: Invoice.Title | XY-12345678 oder 12345678 oder XY-12345678/XY-98765432 (bei mehreren Verträgen) | _Optional_ |
| _Referenzinformationen_ | Freitextfeld für die je nach Kunde unterschiedlichen Informationen zusätzlich zur Vertragsreferenz auf die Rechnung aufzubringen: <br />Beispiele: <br /> <br />Referenznummer: 12JPL0034 <br />Kontaktperson, Leistungsbezüger, PL, Ansprechsperson (fachlich): Neil Armstrong <br />Projekt: A11 <br />SAP-Konto: 1234 0 00000 <br />SAP-KST-Nr.: 1234 5678 <br />Dienstabteilung: Space Personell <br />Cluster: Rocket Services <br />Kostendach: CHF 500'000.- exkl. MWSt. <br /> <br />Small-Invoice Feld: Invoice.Introduction" | | _Optional_ |
| _Startdatum_ | Datum an welchem der Vertrag Gültigkeit erlangt. | 01.01.2014 | _Muss wenn Vertragsnummer_ |
| _Enddatum_ | Datum an welchen der Vertrag endet. | 31.12.2014 | _Muss wenn Vertragsnummer_ |
| _Zahlungsfrist_ | Vereinbarte Zahlungsfrist in Tagen für Debitoren. Ist Teil der Rechnungsdaten. <br /> <br />Small-Invoice Feld: Invoice.Conditions | 30, 45, 60 | _Muss_ |
| _SLA_ | Textfeld um das SLA festzuhalten. Dies sind Angaben wie: <br /> <br /> <ul><li>Bereitschaftszeit</li><li>Reaktionszeit</li><li>Support (E-Mail, Telefon)</li>Ticketsystem</li><li>Wiki Seite</li></ul> Wir könnten diese Informationen auch direkt dem Auftrag als eigenständige Attribute anhängen.  Bereitschaftszeit, Reaktionszeit und Kommunikationsmittel dann nur im Fall Auftragsart Support. <br /> | | _Optional_ |
| _Notizen<br>Weitere Vereinbarungen_ | Textfeld als Ersatz für den Zahlungsplan sowie um weitere vertragliche Vereinbarungen festzuhalten. Dieses Feld dient generell dazu "noch" nicht modelierte vertragliche Informationen festhalten zu können. | | _Optional_ |
