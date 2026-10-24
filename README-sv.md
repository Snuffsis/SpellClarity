# SpellClarity

Ett fristÃƒÂ¥ende addon fÃƒÂ¶r World of Warcraft Classic beta / Forever-klienten
(Interface 16001). Version 0.1.0-beta. KrÃƒÂ¤ver inga andra addons och innehÃƒÂ¥ller
egna sprÃƒÂ¥kstrÃƒÂ¤ngar, spell-data och berÃƒÂ¤kningar.

- Korta, kÃƒÂ¤nda Equip-bonusar: exempelvis `+19 Fire spell dmg` och `+24 Ranged attack power`.
- Kombinerad spell damage/healing delas i tvÃƒÂ¥ rader, med respektive eget vÃƒÂ¤rde.
- JÃƒÂ¤mfÃƒÂ¶relser anvÃƒÂ¤nder samma korta spell-etiketter och behÃƒÂ¥ller tal, tecken och fÃƒÂ¤rgkoder.
- HÃƒÂ¥ll Shift ÃƒÂ¶ver en inlÃƒÂ¤rd spell/ability fÃƒÂ¶r grundvÃƒÂ¤rden, bonusbidrag och tillgÃƒÂ¤ngliga berÃƒÂ¤kningar.
- BehÃƒÂ¥ller spelets tooltipram, typsnitt och native fÃƒÂ¤rger. Inga skins, fÃƒÂ¶remÃƒÂ¥lsrÃƒÂ¤knare, musfÃƒÂ¶ljning eller nya instÃƒÂ¤llningspaneler.

## Installation

Packa upp `SpellClarity` direkt i klientens `Interface/AddOns`, sÃƒÂ¥ att
`Interface/AddOns/SpellClarity/SpellClarity.toc` finns. Starta om WoW helt nÃƒÂ¤r
den nya mappen har lagts till och aktivera SpellClarity i addonlistan.
Aevum behÃƒÂ¶ver inte vara installerat eller aktiverat.

Om Aevum Tooltips ÃƒÂ¤r laddat pausar SpellClarity sig sjÃƒÂ¤lvt fÃƒÂ¶r att undvika
dubbla tillÃƒÂ¤ggsrader. StÃƒÂ¤ng av **Aevum Tooltips** och ladda om fÃƒÂ¶r att
anvÃƒÂ¤nda SpellClarity. Ãƒâ€“vriga Aevum-paket kan vara aktiva.

Engelska etiketter ÃƒÂ¤r standard. `/spellclarity sv` vÃƒÂ¤ljer svenska,
`/spellclarity en` engelska. KÃƒÂ¶r `/reload` efter sprÃƒÂ¥kbyte.
SprÃƒÂ¥kvalet sparas i addonets egen `SpellClarityDB`.

## BerÃƒÂ¤kningar och stÃƒÂ¶d

Spell-underlaget innehÃƒÂ¥ller 6 372 poster fÃƒÂ¶r **1.60.1.70338**. En annan build
fÃƒÂ¥r meddelande om uppdaterade klientdata i stÃƒÂ¤llet fÃƒÂ¶r numeriska uppskattningar.
Utbyt inte bara buildnumret: formler och scalar-data behÃƒÂ¶ver verifieras.
`spell-data-sources.json` innehÃƒÂ¥ller ursprung och kontrollsummor fÃƒÂ¶r datakÃƒÂ¤llorna.

Skada, healing, periodiska effekter och absorption visas separat nÃƒÂ¤r formeln
stÃƒÂ¶ds. TickvÃƒÂ¤rden ÃƒÂ¤r per tick. VapenfÃƒÂ¶rmÃƒÂ¥gor visar kÃƒÂ¤nda komponenter.
BerÃƒÂ¤kningar ÃƒÂ¤r uppskattningar fÃƒÂ¶re talanger, crits och mÃƒÂ¥leffekter, inte en
exakt uppdelning av spellbeskrivningen eller en garanti fÃƒÂ¶r faktisk skada.
Pet-/saknade formler fÃƒÂ¥r en fÃƒÂ¶rklaring och anvÃƒÂ¤nder aldrig spelarens stats.

Equip-fÃƒÂ¶rkortningar kÃƒÂ¤nner igen hela engelska formuleringar. Andra sprÃƒÂ¥k,
okÃƒÂ¤nda/villkorade effekter, procs, inaktiva bonusar och skyddad information
lÃƒÂ¤mnas native. Svenska ÃƒÂ¤r ett val fÃƒÂ¶r addonets etiketter, ingen svensk WoW-klientparser.
Shift-detaljer lÃƒÂ¤ggs efter befintligt innehÃƒÂ¥ll och utelÃƒÂ¤mnas om den sammanlagda
tooltipen skulle ÃƒÂ¶verstiga 48 textrader.

## Utveckling och verifiering

SpellClarity underhÃƒÂ¥lls nu i ett eget repository. Aevum-kÃƒÂ¤llan frÃƒÂ¥n importen
finns dokumenterad i `UPSTREAM.md`; inga automatiska exporter skriver ÃƒÂ¶ver detta projekt.
Se `AGENTS.md`, `Docs/GitWorkflow.md` och `Docs/Releasing.md`.

```text
python -m pip install -r dev/requirements.txt
python dev/update_manifest.py
python dev/ci.py
```

Paketet skapas som `dist/release/SpellClarity-0.1.0-beta.zip`. Tester laddar
addonets faktiska TOC utan Aevum och verifierar ÃƒÂ¤ven det paketerade innehÃƒÂ¥llet.
Speltest, licensval och CurseForge-konfiguration ÃƒÂ¥terstÃƒÂ¥r fÃƒÂ¶re publicering.
