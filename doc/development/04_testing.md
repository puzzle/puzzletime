## Tests

Grundlagen zum Ausführen der Tests sind in der [Entwicklungsumgebung](01_setup.md#tests) beschrieben.
Dieses Dokument behandelt Probleme, die beim Ausführen der Integration Tests auftreten können.

### Verwaiste Browser-Prozesse

Für die Integration Tests startet Cuprite/Ferrum pro Testprozess eine eigene Headless-Chrome-Instanz.
Wird ein Testlauf nicht regulär beendet, bleiben diese Instanzen zurück. Sie belasten das System
weiter, und nachfolgende Läufe schlagen dann mit `Ferrum::DeadBrowserError` fehl oder hängen — ohne
dass am Code etwas falsch ist. Bei 16 parallelen Workern genügen wenige verwaiste Instanzen, um einen
kompletten Lauf unbrauchbar zu machen.

Zwei Details in Ferrum führen zusammen dazu, dass Chrome verwaisen kann (siehe
`ferrum/browser/process.rb`):

* Chrome wird mit `pgroup: true` in einer **eigenen Prozessgruppe** gestartet. Das Beenden der
  Prozessgruppe des Testprozesses erreicht Chrome deshalb nicht.
* Das Aufräumen erfolgt über `ObjectSpace.define_finalizer`. Finalizer laufen nur beim **regulären**
  Beenden des Ruby-Interpreters — nicht bei `SIGKILL`, nicht bei `SIGABRT` und nicht bei einem
  Segfault.

Jeder nicht reguläre Abbruch eines Testprozesses hinterlässt daher eine Chrome-Instanz: abgebrochene
Läufe (`timeout`, `pkill -9`, Ctrl-C) ebenso wie Abstürze des Testprozesses selbst.

### Verwaiste Prozesse finden und beenden

Vorhandene Instanzen auflisten:

    ps -eo pid,etime,args | awk '$3 ~ /chrome$/ && /--headles[s]/ { print $1, $2 }'

Die gefundenen PIDs anschliessend in einem **separaten** Schritt beenden, nie im selben Befehl wie ein
Testlauf:

    ps -eo pid,args | awk '$2 ~ /chrome$/ && /--headles[s]/ { print $1 }' | xargs -r kill -9

**_Wichtig_** `pgrep -f` und `pkill -f` vergleichen das Muster mit der gesamten Kommandozeile — und
das Muster steht in der Kommandozeile des ausführenden Befehls selbst. `pgrep -f 'chrome.*--headless'`
findet daher immer mindestens die eigene Shell, was jede Zählung verfälscht, und
`pkill -f 'chrome.*--headless'` beendet unter Umständen das ausführende Skript, das dann ohne
Fehlermeldung abbricht. Deshalb über ein Feld filtern (`$2 ~ /chrome$/`) und einen Buchstaben in
Klammern setzen (`--headles[s]`), damit das Muster sich nicht selbst findet.

Der eigene Browser ist dabei nicht in Gefahr: er läuft ohne `--headless` und wird von den Mustern oben
nicht getroffen. Ein verwaister Testbrowser ist zusätzlich an der kurzen Laufzeit und an
`--disable-background-timer-throttling` erkennbar. Ein beendeter Testbrowser bleibt oft kurz als
`[chrome] <defunct>` sichtbar; das ist ein bereits beendeter, noch nicht abgeräumter Prozess und
unproblematisch.

### Verwaisen dauerhaft verhindern

Zuverlässig verhindern lässt sich das Verwaisen nur durch den Kernel: mit `PR_SET_PDEATHSIG` beendet
er den Kindprozess, sobald der Elternprozess stirbt — unabhängig vom Signal, also auch bei `SIGKILL`
oder einem Segfault. `setpriv` (util-linux) stellt das als Option bereit, und Ferrum erlaubt es, den
Browser über `browser_path` zu überschreiben.

Wrapper-Skript, z.B. `bin/chrome-pdeathsig`:

    #!/bin/sh
    exec setpriv --pdeathsig KILL "$(command -v google-chrome-stable || command -v chromium)" "$@"

Registrierung in `test/test_helper.rb` beim `Capybara.register_driver :chrome`:

    browser_path: pdeathsig_wrapper,

**_Wichtig_** `setpriv` ist Teil von util-linux und existiert unter macOS nicht. Der Wrapper darf
deshalb nur gesetzt werden, wenn er tatsächlich verfügbar ist, sonst schlagen alle Browser-Tests auf
einem Mac fehl. Ist `browser_path` `nil`, sucht Ferrum den Browser selbst:

    wrapper = Rails.root.join('bin/chrome-pdeathsig')
    pdeathsig_wrapper = wrapper.to_s if RUBY_PLATFORM.include?('linux') &&
                                        File.executable?(wrapper) &&
                                        !`command -v setpriv`.empty?

Für CI ist der Wrapper nicht erforderlich, da dort pro Lauf ein frischer Container verwendet wird. Er
lohnt sich vor allem lokal, wenn Testläufe häufig abgebrochen werden.
