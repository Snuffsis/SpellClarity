# SpellClarity

Ett fristående addon för World of Warcraft Classic beta / Forever-klienten
(Interface 16001). Version 0.1.0-beta. Kräver inga andra addons och innehåller
egna språksträngar, spell-data och beräkningar.

- Korta, kända Equip-bonusar: exempelvis `+19 Fire spell dmg` och `+24 Ranged attack power`.
- Kombinerad spell damage/healing delas i två rader, med respektive eget värde.
- Jämförelser använder samma korta spell-etiketter och behåller tal, tecken och färgkoder.
- Håll Shift över en inlärd spell/ability för grundvärden, bonusbidrag och tillgängliga beräkningar.
- Behåller spelets tooltipram, typsnitt och native färger. Inga skins, föremålsräknare, musföljning eller nya inställningspaneler.

## Installation

Packa upp `SpellClarity` direkt i klientens `Interface/AddOns`, så att
`Interface/AddOns/SpellClarity/SpellClarity.toc` finns. Starta om WoW helt när
den nya mappen har lagts till och aktivera SpellClarity i addonlistan.
Aevum behöver inte vara installerat eller aktiverat.

Om Aevum Tooltips är laddat pausar SpellClarity sig självt för att undvika
dubbla tilläggsrader. Stäng av **Aevum Tooltips** och ladda om för att
använda SpellClarity. Övriga Aevum-paket kan vara aktiva.

Engelska etiketter är standard. `/spellclarity sv` väljer svenska,
`/spellclarity en` engelska. Kör `/reload` efter språkbyte.
Språkvalet sparas i addonets egen `SpellClarityDB`.

## Beräkningar och stöd

Spell-underlaget innehåller 6 372 poster för **1.60.1.70338**. En annan build
får meddelande om uppdaterade klientdata i stället för numeriska uppskattningar.
Utbyt inte bara buildnumret: formler och scalar-data behöver verifieras.
`spell-data-sources.json` innehåller ursprung och kontrollsummor för datakällorna.

Skada, healing, periodiska effekter och absorption visas separat när formeln
stöds. Tickvärden är per tick. Vapenförmågor visar kända komponenter.
Beräkningar är uppskattningar före talanger, crits och måleffekter, inte en
exakt uppdelning av spellbeskrivningen eller en garanti för faktisk skada.
Pet-/saknade formler får en förklaring och använder aldrig spelarens stats.

Equip-förkortningar känner igen hela engelska formuleringar. Andra språk,
okända/villkorade effekter, procs, inaktiva bonusar och skyddad information
lämnas native. Svenska är ett val för addonets etiketter, ingen svensk WoW-klientparser.
Shift-detaljer läggs efter befintligt innehåll och utelämnas om den sammanlagda
tooltipen skulle överstiga 48 textrader.

## Utveckling och verifiering

SpellClarity underhålls nu i ett eget repository. Aevum-källan från importen
finns dokumenterad i `UPSTREAM.md`; inga automatiska exporter skriver över detta projekt.
Se `AGENTS.md`, `Docs/GitWorkflow.md` och `Docs/Releasing.md`.

```text
python -m pip install -r dev/requirements.txt
python dev/update_manifest.py
python dev/ci.py
```

Paketet skapas som `dist/release/SpellClarity-0.1.0-beta.zip`. Tester laddar
addonets faktiska TOC utan Aevum och verifierar även det paketerade innehållet.
GitHub-basversionen är uppladdad och ägaren har bekräftat publiceringsnyckeln.
PR-granskning, speltest och uttryckligt releasegodkännande återstår före publicering.
Licensen är All Rights Reserved, samma som det befintliga CurseForge-projektet.
CurseForge-projektet är 1763928 (spellclarity).
