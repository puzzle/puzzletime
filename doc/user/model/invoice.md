### Rechnung

| Begriff | Beschreibung | Beispiel | Validierung |
| --- | --- | --- | --- |
| _Datum_ | Rechnungsdatum <br /> <br />Small-Invoice Feld: Invoice.Date | 15.05.2014 | _Muss_ |
| _Betrag_ | Rechnungsbetrag in CHF exkl. MWSt. <br /> <br />Small-Invoice Feld: Invoice.Totalamount | | _Muss_ |
| _Referenz_ | Eindeutige Referenz der Rechnung die sich wie folgt zusammensetzt: </br> <br /> _PrefixKunde.KurznameKategorie.KurznameAuftrag.KurznameOrganisationseinheit.KurznameLaufnummerProKunde_ <br /> <br /><ul><li>Die Laufnummer gewährleistet die Eindeutigkeit (4-stellig)</li><li>Der Kurzname des Kunden, der Kategorie und des Auftrags dient der leichteren Orientierung bei der Ablage der physischen Unterlagen sowie der Unterscheidung der Rechnungen innerhalb des Kunden wenn mehrere identisch bezeichnete Aufträge vorliegen.</li><li>Die Bereichsangabe wird für den externen Abschluss benötigt</li><li>Mit oder ohne Delimiter?</li></ul> Small-Invoice Feld: Invoice.Number | NASAAPOA11JPL0001 oder NASA-APO-A11-JPL-0001 | _Muss_ |
| _Leistungsperiode_ | Die Leistungsperiode bezeichnet den Zeitraum in welchem die auf der Rechnung enthaltenen Leistungen erbracht wurden oder werden. Die Leistungsperiode wird für Abgrenzungen im externen Abschluss benötigt. Die Angabe erfolgt in Monaten und kann einen oder maximal 12 Monate umfassen und wird zur Gewährleistung der Eindeutigkeit mit dem Jahr ergänzt. <br /> <br />Small-Invoice Feld: Invoice.Period | Januar 2014 </br> Januar - Dezember 2014 | _Muss_ |
| _Status_ | Status der Rechnung <br /> <br />Small-Invoice Feld: Invoice.Status | Siehe http://www.smallinvoice.ch/api/objects/invoice#status | _Muss_ |
