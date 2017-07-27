### Buchungsposition

Auf eine Buchungsposition können Zeiten/Leistungen verbucht werden.  Dies entspricht heute der untersten "Subprojekt"-Stufe z.B. REA für Realisierung. Die Summe aller Buchungspositionen ergeben das Auftragsbudget. Pro Buchungspostition gibt es die nachfolgenden Attribute.


| Begriff | Beschreibung | Beispiel | Validierung |
| --- | --- | --- | --- |
| _Name_ | Vollständige Bezeichung der Buchungsposition. | Konzeption | _Muss_ |
| _Kurzname_ | 3-stelliges Kurzbezeichnung der Buchungsposition. <br />:warning: In Bezug auf sich jährlich wiederholende Aufträge wäre es von Vorteil wenn die Buchungsposition neu 4stellig wäre. z.B. NASA-APO-1969, NASA-APO-1970 als eigenständige Aufträge. | KON, 2014 | _Muss_ |
| _Beschreibung_ | Beschreibung der Position welche, sofern vorhanden, bei der Suche angezeigt wird. | | _Optional_ |
| _Status_ | Zeigt an ob die Position noch offen und damit Zeiten erfasst werden können. Der Status auf der Buchungsposition ermöglich, dass z.B. ein Budget wie Evaluation oder Konzeption geschlossen werden kann und damit bei der Suche in der Zeiterfassung auch nicht mehr angezeigt wird. z.B. wenn nur noch die Realisierung offen ist. | offen, geschlossen | _Muss_ |
| _Stunden (Soll[h])_ | Budget in Stunden für die betreffende Buchungsposition. 8 Stunden entsprechen einem Tag. Falls die Personentage eingegeben werden, wird dies automatisch berechnet. <br />:warning: Könnte auch in Anzahl umbenennt werden, womit auch Buchungspositionen mit Material verwaltet werden könnten. Für Dienstleistungen wäre diese dann Stunden bei Material Stück. | 80 | _Optional_ |
| _Personentage (Soll[PT])_ | Budget in Personentagen für die betreffende Buchungsposition. Ein Tag entspricht 8 Stunden. Falls die Stunden eingegeben werden, wird dies automatisch berechnet. <br />:warning: Kein DB-Feld | 10 | _Optional_ |
| _Stundensatz (Soll[CHF/h])_ | Zur Anwendung kommender Stundensatz exklusive Mehrwertsteuer in CHF für diese Buchungsposition. Eingabe eines individuellen Stundensatzes. <br />_Hinweis:_ In Zukunft könnte auch ein Modell Stundensatz pro Rolle umgesetzt werden. Oder es könnten beide Modelle unterstützt werden. Aktuell wird aber auf diese Komplexität verzichtet. <br />:warning: Könnte auch in Preis umbenennt werden. Damit würde sich für Dienstleistungen CHF/h und für Material CHF/Stk. ergeben. | 190.-- | _Optional_ |
| _Budget (Soll[CHF])_ | _Stunden x Stundensatz_ <br />Anstelle der Berechnung _Stunden x Stundensatz_ muss es möglich sein hier einen individuellen Betrag einzugeben. Damit können beliebige Budgets eingegeben und für die Verrechnung vorgesehen werden (z.B. Material, Spesen etc.). | 15'200.-- | _Muss_ |
| _Portfolio_ | Siehe [Portfolio](portfolio_item.md) | | _Muss_ |
| _Dienstleistung_ | Siehe [Dienstleistung](service.md) | | _Muss_ |
| _ZeitkommentarFlag_ | Gibt an, ob Zeiten die auf dieser Position erfasst werden zwingend eine Beschreibung benötigen oder nicht. | ja oder *nein* | _Muss_ |
| _TicketangabeFlag_ | Gibt an, ob für Zeiten die auf dieser Position erfasst werden zwingend ein Ticket angegeben werden muss. | ja oder *nein* | _Muss_ |
| _VonBisZeitFlag_ | Gibt an, ob die Arbeitszeit als von-bis Zeit erfasst werden muss. | ja oder *nein* | _Muss_ |
| _Geleistet_ | Die geleisteten Stunden entsprechen der erfassten Arbeitszeit. Sie sind unabhängig von der Verrechenbarkeit. | 8h, 1PT, CHF 1'520.-- | _Muss_ |
| _Verrechenbar_ | Leistungen die als verrechenbar geflagt sind. <br /> | *ja* oder nein | _Muss_ |
| _Verrechnet_ | Verrechnete Leistungen sind Leistungen die effektiv in Rechnung gestellt wurden. Verrechnet muss nicht zwingend mit "Geleistet" übereinstimmen. z.B. im Fall von Vor- oder Nachverrechnungen. <br />_Hinweis:_ Wird mehr als die geleisteten Stunden verrechnet so gilt die Differenz nicht als Arbeitszeit. Können geleistete Stunden aufgrund Budgetüberschreitung nicht mehr verrechnet werden so gilt die Differenz als Arbeitszeit. | 8h, 1PT, CHF 1'520.-- | _Optional_ |
| _Restaufwand (RA[h])_ | Geschätzter Aufwand pro Buchungsposition bis der Auftrag abgeschlossen werden kann. <br /> <br />-> Streichen. Prognostizierter Aufwand aufgrund Planung berechnen. | | _Optional_ |
