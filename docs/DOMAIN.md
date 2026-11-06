# Domain reference — tilapia pond farming

The single source of truth for every farming number, formula and rule the app uses. Values come from the handbook `Dossier_Elevage_Tilapia_Etangs.docx` (section numbers in brackets). Values marked **[default]** are not in the handbook: they are Claude's planning defaults, kept configurable, to be confirmed with the user.

Every value the app computes with or compares against maps to one constant in `lib/domain/config.dart`; guidance shown only as text (inlet/outlet depths, clove dose, safety rules) lives in the l10n info cards. Change a number here and in config together.

## Species and fingerlings

- Species: Nile tilapia (*Oreochromis niloticus*); improved strains preferred (GIFT grows 20–30 % faster). [4.1]
- Prefer all-male (monosex) populations to avoid uncontrolled breeding. [9]
- Buy from a hatchery with a health certificate; record the certificate number. [4.2]
- Stocking weight 10–20 g, uniform size. [4.2]
- Acclimatisation: float the closed bag on the pond 15–20 min before release. [4.3]
- Quarantine every new batch 7–10 days in a separate pond before joining the rest of the farm. [7.1]

## Ponds

- Structure types and stocking density [4.4]:

| Structure | Density (fish/m²) |
|---|---|
| Earth pond (`earth`) | 2–6 |
| Ground tank (`tank`) | 50–100 |
| Floating cage (`cage`) | 150–200 |

- Pond roles [3]: `breeding`, `nursery` (frayère, fry), `pregrow`, `growout`, `holding` (live fish before sale), `quarantine`. A starting farm needs at least one pregrow and one growout pond.
- Water supply types [3]: `barrage` (dam), `derivation` (diversion canal, recommended), `marsh`.
- Design guidance, shown as soft warnings at pond setup, never blocking [2.2, 2.4]:
  - surface 200–1,000 m² per pond;
  - rectangular, length:width 2:1 to 3:1;
  - depth ≥ 1 m, checked on the mean of inlet and outlet depths when both are entered; 0.8–1 m at inlet, 1.2–1.5 m at outlet.

## Phases

Phase is derived from the batch's latest average weight; it is never entered by hand. [5]

| Phase | Avg weight | Protein | Pellet | Feedings/day | Typical duration |
|---|---|---|---|---|---|
| `fry` (alevinage) | < 5 g | 30–35 % | 0.5–1 mm | 4–6 | — |
| `pregrow` (prégrossissement) | 5–20 g | 25–30 % | 2 mm | 4–6 | — |
| `growout` (grossissement) | 20–250 g | 20–25 % | 3 mm | 3–4 | 4–5 months |
| `finishing` (finition) | > 250 g | adult feed | ≥ 3 mm | 2–3 | up to 6–7 months total |

Boundaries: a weight exactly on 5, 20 or 250 g belongs to the heavier phase.

## Feeding

- Daily ration = biomass × ration rate. Handbook range 3–5 % of biomass. [5.3]
  - **[default]** rate by phase: fry and pregrow 5 %, growout 4 %, finishing 3 %.
- Recalculate the ration after each sample (every 2 weeks). [5.3]
- Leftover rule [5.3]: if feed is still floating 15–20 min after feeding, reduce the next ration by 10–20 % (**[default]** 15 %). If everything is eaten immediately, a slight increase is allowed (**[default]** +5 %). The suggested ration never exceeds 5 % of biomass.
- Feed in the afternoon when oxygen is higher. Advise stopping feeding when fish swim at the surface or behave abnormally (stress or low oxygen). [5.3]
  - **[default]** the advice holds while surface or erratic swimming was logged today or yesterday (2 days), or the latest reading has oxygen below the minimum.
- Use floating pellets; spread feed over several points. [5.3]
- Stop feeding 24–48 h before harvest. [8.1]

## Feed stock

- Feed older than 2–3 months from manufacture loses nutritional value [5.2]: **[default]** warn at 60 days, "do not use" at 90 days.
- Discard sacks with mould, rancid smell or clumped pellets; record the discard. [5.2]
- **[default]** low-stock warning when stock covers fewer than 7 days at the current daily usage.
- **[default]** daily usage is the feed logged over the last 7 days (today included) ÷ 7.

## Sampling

- Every 14 days, weigh a random sample of 30–50 fish per batch per pond. [5.3, Annex B]
- Average weight = total sample weight ÷ number of fish weighed.
- A sample of fewer than 30 fish is accepted but flagged "small sample".

## Formulas

All weights in grams internally.

- **Live count** of a batch in a pond = stocked + transferred in − transferred out − recorded deaths − harvested.
  A final harvest ends the batch in that pond: the live count becomes 0, and what the estimate still counted is reported as "not found" (predation, theft, counting error), never as deaths.
  Predation and theft are invisible to this count, so it is an upper bound; reports say "estimated".
- **Biomass** = live count × latest average weight. If no sample exists yet, use the stocking average weight.
- **Survival rate** = (live count + fish harvested) ÷ total fish that entered the batch. Harvested fish survived; a final harvest's leftover estimate (fish not found) does not count as survived.
- **Density** = live count ÷ pond surface (m²); compare against the structure type's range.
- **Period FCR** between two samples = feed given in the period ÷ biomass gain in the period, where
  gain = (biomass now + weight of fish harvested or transferred out in the period) − (biomass at previous sample + weight transferred in).
  Deaths are not added back (economic FCR). If gain ≤ 0, FCR is undefined and the app raises "growth stalled".
- **Cycle FCR** (Annex C) = total feed given to the batch ÷ (total harvested weight − total stocked weight). [5.4, Annex C]
- FCR target: 1.5–1.8 with commercial feed. [5.1]
- **Pond prep doses** from pond surface (1 ha = 10,000 m²) [6]:
  - quicklime (CaO) 1–2 t/ha → 0.1–0.2 kg/m²;
  - composted manure 200–300 kg/ha → 0.02–0.03 kg/m².

## Water quality

Checked at least weekly per pond [7.7]:

| Parameter | Target | Note |
|---|---|---|
| Temperature | 27–32 °C | optimal growth range |
| pH | 6.5–8.5 | |
| Dissolved oxygen | ≥ 3 mg/L | user's choice; see note |
| Water renewal | 10–20 % per week | when water turns cloudy |
| Depth | ≥ 1 m | |

Oxygen note: the handbook says > 0.8 mg/L, which is close to lethal for tilapia. The user chose 3 mg/L, in line with common aquaculture guidance. Keep it configurable.

Water colour (worker pictograms) [6]: `clear`, `light_green` (good), `medium_green` (good), `dark_green`, `brown_turbid`. Dark green or brown/turbid suggests renewing water.

## Pond preparation

Ordered checklist before each stocking [6]:

1. Drain and remove sludge.
2. Dry the bottom in the sun 5–7 days, until surface cracks appear.
3. Treat residual water with quicklime or chlorine (dose from pond surface).
4. Fertilise with manure (dose from pond surface); adjust by water colour.
5. Fill slowly through a screened inlet.
6. Rest 2–3 days after filling, then the pond is ready to stock.

## Health

Warning signs, recorded as pictograms by workers and members [7.2]:
`no_appetite`, `surface_swimming`, `near_banks`, `erratic_or_circling`, `abnormal_colour`, `skin_lesions`, `pale_or_swollen_gills`, `grouped_deaths`, `rubbing`, `excess_mucus`, `white_spots`, `bulging_eyes`, `fin_bleeding`.

Common diseases, shown as information only and never as a diagnosis [7.2]:

| Disease | Signs |
|---|---|
| Streptococcosis | erratic swimming, bulging eyes, rapid mortality; favoured by high density and heat/water stress |
| Aeromonas | skin ulcers, fin bleeding; linked to poor water or handling injuries |
| External parasites (Trichodina, Ich) | rubbing on walls or bottom, excess mucus, white spots |

When disease is suspected, the response is [7.2]: isolate the pond, move no fish or water to other ponds, call a vet or aquaculture technician before treating. The app never suggests a drug or dose. Every treatment is recorded (product, dose, date, who advised).

Mortality handling [7.3]: remove dead fish daily, bury or burn away from water, record count and appearance.

## Biosecurity and safety

Shown as checklist items and info cards [7.1, 7.5, 7.8]: disinfect shared nets, buckets and dip nets between ponds (diluted chlorine, then rinse); one tool set per pond where possible; footbath or clean boots at the entrance; keep ducks and other animals out; predator nets and a low fence; gloves and boots for lime and chlorine; no working alone during draining or deep harvests.

## Harvest and delivery

- Stop feeding 24–48 h before harvest; harvest early morning with a seine net. [8.1, 8.2]
  - **[default]** a planned harvest starts at 06:00; the 48 h fast ends then.
- Live transport: aerated tanks; clove powder 0.5 g per 10 L as a sedative; avoid overloading. [8.3]
- Product forms [8.4]: `live`, `fresh`, `frozen`, `smoked`, `dried`. Fresh fish go on ice immediately; label with the batch number when possible.

## Alert rules

Computed on the device from local records; never synced. Each has a severity (`danger` or `warning`).

| Alert | Trigger | Severity |
|---|---|---|
| Water out of range | latest reading outside the temperature, pH or oxygen target, or water colour `dark_green` or `brown_turbid` (renew water) | danger for oxygen, warning otherwise |
| FCR worsening | period FCR increased at 2 consecutive samples [5.4] | danger |
| Growth stalled | biomass gain ≤ 0 between samples | danger |
| Mortality spike | **[default]** at least 5 deaths in the day, and either > 0.5 % of live count or ≥ 3× the trailing 7-day daily average; checked on each of the last 3 days **[default]** | danger |
| Warning sign seen | any warning sign recorded in the last 3 days **[default]**, or dated in the future (wrong phone clock) | danger |
| Sample due | ≥ 14 days since last sample of an active batch | warning |
| Water check due | ≥ 7 days since last water reading of a stocked pond | warning |
| Density out of range | density outside the structure's range | warning |
| Phase change | latest average weight crossed a phase boundary → change feed and feedings/day | warning |
| Quarantine ending | quarantine batch reaches 7 days (may move from day 7, recommended by day 10) | warning |
| Pre-harvest fast | planned harvest within the next 48 h: tells the worker to stop feeding, and notes if feeding was still recorded in that window | warning |
| Feed stock low | stock covers < 7 days | warning |
| Feed too old | feed lot past 60 days (warning) or 90 days (danger) | warning / danger |
| Pond prep step | a prep step's waiting time has elapsed (drying 5–7 d, rest 2–3 d) | warning |
