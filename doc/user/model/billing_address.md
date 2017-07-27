### Rechnungsadresse

Die Rechnungsadresse könnte auch auf Stufe Vertrag angehängt werden. Da ein Vertrag im Fall Rahmenvertrag aber mehrere Aufträge umfassen kann, ist es sinnvoller diese an den Auftrag zu hängen. Weil neben Highrise als Kundenmaster auch andere Systeme angebunden werden könnten, ist der Master in Bezug auf die Rechnungsadresse PuzzleTime. Damit werden konfigurative Abhängigkeiten zu den Umsysteme auf ein Minimum reduziert. Die Inbetriebnahme der Gesamtlösung wird dadurch einfacher.

| Begriff | Beschreibung | Beispiel | Validierung |
| --- | --- | --- | --- |
| _Kunde_ | Siehe [Kunde](model/customer.md) (bei Anbindung des CRM kommt dies aus dem CRM) | NASA | _Muss_ |
| _Kontakt_ | Auswahl von einem unter Kontakte erfassten Kontakt. Der Rechnungskontakt entspicht nicht zwingend dem Kontakt (Auftraggeber). (bei Anbidung des CRM kommt dies aus dem CRM) | Buchhaltung oder z.H. Muster Hans | _Optional_ |
| _Zusatz_ | Mehrzeilig, wird in jedem Fall lokal gespeichert. | Abteilung (Finanzen & Controlling) | _Optional_ |
| _Strasse_ | Mehrzeilig für zusätzlich Angabe von Postfach. <br />Wird in jedem Fall lokal gespeichert. | Two Independence Square | _Muss_ |
| _PLZ_ | Postleitzahl Schweiz oder Europa (Deutschland) <br />Wird in jedem Fall lokal gespeichert. | 3000 | _Muss_ |
| _Ort_ | Wird in jedem Fall lokal gespeichert. | Bern | _Muss_ |
| _Landescode_ | Wird in jedem Fall lokal gespeichert. Die ausgeschrieben Bezeichnung wird im Smallinvoice ergänzt. | CH | _Muss_ |
