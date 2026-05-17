# Skill: Betaalreconciliatie (Payment Reconciliation)

## Doel

Koppel bankbetalingen aan openstaande facturen in Octopus. Identificeer welke betalingen bij welke documenten horen, punt hoge-confidence matches automatisch af, en presenteer onzekere matches ter bevestiging aan de boekhouder.

## Achtergrond

In Octopus wordt een "afpunting" (balancing) gebruikt om een bankboeking (F-journal) te koppelen aan een factuur (A-journal voor aankopen, V-journal voor verkopen). Bankafschriften worden dagelijks automatisch via CODA geïmporteerd en verschijnen als financiële boekingen in de F-journals.

### Terminologie
- **F-journal**: Financieel dagboek (bank) — bijv. F1 = "BELFIUS - 4974"
- **A-journal**: Aankoopdagboek — bijv. A1 = "AANKOPEN"
- **V-journal**: Verkoopdagboek — bijv. V1 = "VERKOOP"
- **Afpunting / Balancing**: De koppeling tussen een bankboeking en een factuur
- **Gestructureerde mededeling**: Belgische betalingsreferentie in formaat +++xxx/xxxx/xxxxx+++

## Workflow

### Stap 1: Context ophalen

```
get_bookyears → Identificeer het huidige/actieve boekjaar (het meest recente niet-afgesloten boekjaar)
list_journals(bookyear_id) → Identificeer:
  - F-journals (bankdagboeken): F1, F2, F4, ...
  - A-journals (aankoop): A1, ...
  - V-journals (verkoop): V1, ...
```

### Stap 2: Bankbetalingen ophalen

```
list_financial_divers_bookings(bookyear_id, journal_key: "F1")
```

Dit geeft alle bankboekingen terug. Elke boeking bevat:
- `documentSequenceNr` — uniek nummer binnen het dagboek
- `documentDate` — transactiedatum
- `bookingLines[]` — boekingslijnen, elk met:
  - `type`: 'A' (rekening), 'C' (klant), 'S' (leverancier)
  - `amount`: bedrag (positief = debit, negatief = credit)
  - `accountKey` of `relationId` / `externalRelationId`
  - `reference`: mededeling van de bank (bevat mogelijk gestructureerde mededeling)

**Let op**: Herhaal dit voor ALLE F-journals als er meerdere bankrekeningen zijn.

### Stap 3: Openstaande facturen ophalen

```
report_open_clients(bookyear_id: 10) → Openstaande verkoopfacturen (klanten die nog moeten betalen)
report_open_suppliers(bookyear_id: 10) → Openstaande aankoopfacturen (leveranciers die betaald moeten worden)
```

**Belangrijk:** De parameter `bookyear_id` wordt als `fromBookyearKey` naar de API gestuurd. Optioneel kan `to_bookyear_id` meegegeven worden om een bereik van boekjaren op te vragen (bijv. alle openstaande posten van boekjaar 1 t/m 10).

Als het rapport geen data vindt (HTTP 404), betekent dit dat er geen openstaande posten zijn voor dat boekjaar — dat is geen fout.

Optioneel voor meer detail:
```
get_unbalanced_invoices → Lijst van nog niet (volledig) afgepunte facturen
list_buy_sell_bookings(bookyear_id: 10, journal_key: "A1") → Alle aankoopboekingen met detail
list_buy_sell_bookings(bookyear_id: 10, journal_key: "V1") → Alle verkoopboekingen met detail
```

### Stap 4: Matching

Vergelijk elke niet-afgepunte bankboeking met openstaande facturen.

#### Matching criteria (in volgorde van betrouwbaarheid):

1. **Gestructureerde mededeling** (HOOGSTE betrouwbaarheid)
   - Zoek in de `reference` van de bankboeking naar het patroon `+++xxx/xxxx/xxxxx+++`
   - Match met de `reference` van een openstaande factuur
   - Bij een match: **automatisch afpunten**

2. **Exact bedrag + zelfde relatie** (HOGE betrouwbaarheid)
   - Bankboeking heeft een `relationId` die overeenkomt met een factuur
   - Het bedrag komt exact overeen
   - Bij een match: **automatisch afpunten**

3. **Exact bedrag zonder relatie-match** (MEDIUM betrouwbaarheid)
   - Bedrag komt exact overeen maar relatie is niet dezelfde of onbekend
   - **Presenteer als voorstel** aan de boekhouder

4. **Relatie-match + benaderend bedrag** (LAGE betrouwbaarheid)
   - Zelfde relatie maar bedrag verschilt (< 5% of < €10 verschil)
   - Kan een deelbetaling zijn, of afrondingsverschil
   - **Presenteer als voorstel** met uitleg over het verschil

5. **Geen match gevonden**
   - Rapporteer als "handmatige verwerking nodig"
   - Geef zoveel mogelijk context (bedrag, datum, relatie indien bekend, mededeling)

### Stap 5: Uitvoering

#### Automatische afpunting (hoge confidence)

```
insert_balancing(
  amount: <matched bedrag>,
  balancing_date: "<bankboekingsdatum>",
  reference: "<factuurreferentie>",
  document_keys: [
    { bookyear_id: <id>, journal_key: "F1", document_sequence_nr: <bank_doc_nr> },
    { bookyear_id: <id>, journal_key: "A1", document_sequence_nr: <factuur_doc_nr> }
  ]
)
```

#### Voorstellen (lage confidence)

Presenteer de voorstellen in een overzichtelijke tabel:

```
| # | Bank | Bedrag | Factuur | Bedrag | Relatie | Confidence | Reden |
|---|------|--------|---------|--------|---------|------------|-------|
| 1 | F1/#42 | €1.250 | V1/#18 | €1.210 | Acme BV | 65% | Bedrag verschilt €40 |
| 2 | F1/#43 | €500 | A1/#95 | €500 | Onbekend | 55% | Geen relatie-match |
```

Vraag de boekhouder per voorstel of per batch: "Wil je deze afpunten?"

### Stap 6: Verificatie

Na de afpuntingen:

```
get_modified_balancings(modified_timestamp: "<start van deze sessie>")
→ Controleer dat alle afpuntingen correct zijn geregistreerd

get_unbalanced_invoices
→ Vergelijk met stap 3: er zouden minder openstaande facturen moeten zijn
```

### Stap 7: Rapportage

Geef een samenvatting:

```
Reconciliatie voltooid voor boekjaar 2026, dagboek F1:

✅ 45 betalingen automatisch afgepunt (totaal: €125.430,50)
   - 28 via gestructureerde mededeling
   - 17 via exact bedrag + relatie

⚠️  8 voorstellen ter bevestiging gepresenteerd
   - 5 bevestigd en afgepunt
   - 3 afgewezen

❌ 3 betalingen zonder match (handmatige verwerking nodig):
   - F1/#67: €2.500,00 op 05/05/2026 — geen matching factuur gevonden
   - F1/#71: €89,50 op 07/05/2026 — meerdere mogelijke matches
   - F1/#73: €15.000,00 op 08/05/2026 — onbekende relatie
```

## Foutafhandeling

### Verkeerde afpunting ongedaan maken

Als een afpunting fout blijkt:

```
delete_balancing(
  mode: "document",
  bookyear_id: <id>,
  journal_key: "A1",
  document_sequence_nr: <factuur_doc_nr>
)
```

Dit verwijdert alle afpuntingen voor dat document.

### Rate limits

- `insert_balancing`: max 400 calls/dag
- `delete_balancing`: max 400 calls/dag
- `list_financial_divers_bookings`: geen expliciete limiet, maar de /modified fallback wordt automatisch gebruikt
- `report_open_clients/suppliers`: geen expliciete limiet

Bij een groot aantal betalingen: werk in batches en houd het aantal API-calls bij.

## Belangrijke aandachtspunten

1. **Deelbetalingen**: Een klant kan een factuur in meerdere termijnen betalen. Vergelijk het openstaande bedrag (uit `report_open_clients`) met het bankbedrag, niet het originele factuurbedrag.

2. **Groepbetalingen**: Een leverancier kan meerdere facturen in één keer betalen. Als het bankbedrag overeenkomt met de som van meerdere openstaande facturen van dezelfde relatie, moeten meerdere afpuntingen worden aangemaakt.

3. **Creditnota's**: Creditnota's hebben negatieve bedragen. Deze kunnen ook afgepunt worden tegen bankboekingen (terugbetalingen).

4. **Meerdere bankrekeningen**: Controleer ALLE F-journals, niet alleen F1. Gebruik `list_journals` om alle bankdagboeken te identificeren.

5. **Cross-boekjaar**: In sommige gevallen kan een factuur uit boekjaar N-1 betaald worden in boekjaar N. De `report_open_*` rapporten tonen dit correct.

6. **Nooit blindelings afpunten**: Bij twijfel, vraag altijd bevestiging. Een verkeerde afpunting is lastiger te corrigeren dan geen afpunting.
