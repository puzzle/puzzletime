### Auftrag

Ein Auftrag kann Buchungspositionen haben oder selbst eine Buchungsposition sein. Letzteres ermöglicht, dass neben dem Buchen von Zeiten auf der Buchunsposition aus fachlicher Sicht auch direkt auf Auftragsebene Zeiten gebucht werden könnten.

Beispiel:

* Kunde: NASA
* Auftragskategorie: APO (Appolo Programm)
* Auftrag: A11 (Apollo 11 Projekt)
* Buchungsposition: REA (Realisierung)

Die folgenden Strukturierungsmöglichkeiten sind möglich:

* Volle Struktur: _Kunde-Auftragskategorie-Auftrag-Buchungsposition_ (NASA-APO-A11-REA)
* Auftrag als Buchungsposition: _Kunde-Auftragskategorie-Auftrag_ (NASA-APO-A11)
* Ohne Auftragskategorie mit Auftragsebene als Buchungsposition: _Kunde-Auftrag_ (NASA-APO)

| Begriff | Beschreibung | Beispiel | Validierung |
| --- | --- | --- | --- |
| _Name_ | Textuelle Bezeichung des Auftrags. Der Auftragsname wird im Highrise abgefragt (Deals mit Status "won" von heute 1-3 Monate zurück) und kann bei Bedarf angepasst werden. | Apollo 11 | Muss |
| _Kurzname_ | 3-stellige Kurzbezeichnung des Auftrags. | A11 | _Muss_ </br> Eindeutigkeit innerhalb desselben Kunden prüfen |
| _Art_ | Auftragsarten gemäss Prozess P33. Es können in Zukunft weitere Auftragsarten dazukommen z.B. Stundenbudget oder bestehende umbenennt werden z.B. Kleinaufträge. Bei Umbenennung bestehender Arten werden sämtliche Aufträge auf die neue Bezeichnung aktualisiert. Ist dies nicht gewünscht muss eine neue Art erstellt werden. | Projekt, Mandat, Wartung, Service und Support, Schulung, Kleinauftrag, Intern | _Muss_ |
| _Auftragsverantwortlicher (AV)_ | Mitarbeiter welcher für den Auftrag verantwortlich ist. Für Projekte ist dies der Projektleiter. | John F. Kennedy | _Muss_ |
| _Status_ | Status in welchem sich der Auftrag befindet. Es können in Zukunft weitere Status dazukommen oder bestehende umbenennt werden. Bei Umbenennung werden bestehende auf die neue Bezeichnug umbenannt. <br />Es gibt folgende Flows: <br><br> <ul><li>Bearbeitung > Abschluss > Abgeschlossen</li><li>Bearbeitung > Abschluss > Garantie > Abgeschlossen</li></ul><br>Das Setzen des Status Garantie startet einen Timer welcher den Auftrag nach 2 Jahren automatisch in den Status Abgeschlossen setzt. Im Garantiefall muss noch mindestens eine Buchungsposition z.B. "Garantie" offen sein, damit entsprechende Stunden verbucht werden können. <br />_Hinweis:_ In Zukunft könnte ein Auftragsart abhängiger Status umgesetzt werden. | *Bearbeitung*, Abschluss, Garantie, Abgeschlossen | _Muss_<br>Garantie wenn Vertragsart = "Werk" |
| _Organisatinseinheit (OE)_ | Siehe [Organisationseinheit](department.md) <br />_Hinweis:_ Anstelle der OE könnten wir ergänzend oder in Zukunft anstelle, den Prozess verwenden welcher für den Auftrag verantwortlich ist. Dies hätte den Vorteil, dass sämtliche Aufträge, Kunden- und Interne Aufträge, abgedeckt werden könnten. Die Bezeichnung der Funktionsbereiche und der Prozessbezeichnungen weist bereits heute eine grosse Übereinstimmung auf. <br /> | | _Muss_ |
| _Chance/Risiko_ | Siehe [Chance/Risiko](order_uncertainty.md) | | _Optional_ |
| _Team_ | Aufzählung der in diesem Auftrag tätigen Mitarbeiter. Reihenfolge Vorname Name. (z.B. Mitarbeiter als Link auf Highrise Kontakt) | Neil Armstrong, Edwin Aldrin | _Optional_ |
| _Vertrag_ | Ein Auftrag kann mehrere Verträge umfassen. Die folgenden Fälle kommen vor: <br /> <br />  <ul><li>Jährliche Vertragserneuerung (z.B. bei Beratungsleistungen)</li><li>Grundvertrag und Vertragsnachträge (z.B. bei Budgeterweiterungen, Change Requests oder sonstigen Vertragsanpassungen wie z.B. Laufzeit)</li><li>Rahmenvertrag und Einzelverträge</li></ul> Der erste Fall kann gelöst werden, indem pro jährlichem Vertrag ein Auftrag eröffnet wird, z.B. NASA-APO-1969. Damit ergibt sich wieder ein 1:1 Bezug zwischen Auftrag und Vertrag. <br /> <br />Im zweiten Fall der Budgeterweiterungen kann grundsätzlich das Budget Basisauftrags erhöht werden. Die Nachvollziehbarkeit des Budget könnte durch Erfassung einer eigenen Buchungsposition für die Zusatzbudget sein. Zeiten könnten dann auf diese Budgetposition gebucht werden. Es müssten aber nicht zwingend Zeiten gebucht werden womit dann aber die Zahlen im Cockpit nur für den Gesamtauftrag stimmen würden. <br /> <br />Im Dritten Fall kann mit der Kategorie zwar nicht eine Aggregation mehrer Einzelverträge zu einem Rahmenvertrag erfolgen aber eine Zusammenfasssung mehrer Aufträge. Im Repporting könnte der Aggregation auf Stufe Kategorie bei Bedarf Rechnung getragen werden. <br /> <br />Attribute siehe [Vertrag](contract.md) | | _Optional_ |
| _Rechnungsadresse_ | Siehe [Rechnungsadresse](billing_address.md) | | _Optional_ |
| _Kunde_ | Siehe [Kunde](customer.md) | | _Muss_ |
| _Kontakte_ | Siehe [Kontakt](contact.md) | | _Optional_ |
| _Ziel_ | Siehe [Ziel](order_target.md) | | _Optional_ |
| _Journal_ | Mit dem Journal kann der Auftragsverantwortliche zu beliebigen Zeitpunkten, in der Regel z.B. im Rahmen des Monatsabschlusses den Stand/Abweichungen etc. festhalten. Die Kommentierung ist ein Log mit Datum, Ersteller und Kommentar. <br />Das Kommentarfeld soll auch dazu dienen weitere Highrise Deals in Form von URL zu referenzieren. z.B. um auf Change Request zu referenzieren welche in der Regel nicht zu einem neuen Auftrag führen sondern das Budget eines bestehenden Auftrags erweitern. | | _Optional_ |
| _Funktion_ | Funktion des Mitarbeiters im Zusammenhang mit dem betroffenen Auftrag | Architekt | _Optional_ |

Weitere Attribute als Idee: Startdatum, Enddatum, Anzahl durchgeführter Code-Reviews, Flag für Abnahmedokumente (muss gesetzt sein bevor Status auf Abgeschlossen gehen kann)
