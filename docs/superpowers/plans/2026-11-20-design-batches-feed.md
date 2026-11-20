# Design step 7: Batches, feed, sales and the form standard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The More menu, the batches list and page, the feed page, Ventes and customers take the design. Every member form follows one standard: pond buttons, option buttons, bands under their field, the recorded number first, a pinned action named for what it does, Supprimer in ⋮, optional fields folded.

**Architecture:**
- **Shared form pieces** in `lib/features/common/`: `PinnedAction`, `PondChoice`, `ChoiceButtons`, `DetailsFold`, `FormMenu`, `confirmDelete`, `showDone`. Each form switches to them; nothing in `lib/theme/` changes.
- **New correction paths** for screens that lacked them, on repository methods that already exist: a delivery (`FeedRepository.correctDelivery`) and a sale (`HarvestRepository.correctSale`). No schema, sync or server change.
- **Pure pieces** in `lib/domain/`: `unsoldG` (Reste à vendre). The batch rows and the batch page read `farmFactsProvider`, `placementsProvider`, `alertsProvider` and `batchTrace`, as they exist.
- **Demo:** `seedDemoTrade` adds feed lots, a transfer, a harvest with a sale and a closed batch on top of `seedDemoFarm`, for the new goldens and phone screenshots. The existing demo goldens are untouched.

**Tech Stack:** Flutter 3.47.8, flutter_riverpod 3, go_router 18, Drift, ARB l10n, `flutter_test` goldens.

**Spec:** `docs/design.md` (principles, §Step 7), `docs/SPEC.md` F2, F11, F12, `docs/DOMAIN.md` §Feed stock.

## Decisions (Claude's calls)

1. **`PinnedAction`**: the `bottomNavigationBar` of a form or page. It pads by `MediaQuery.viewInsetsOf(context).bottom` so it rides above the keyboard (the daily log's fix), then a `SafeArea`, 12 dp padding and a 56 dp `FilledButton.icon`. `onPressed: null` disables it. The daily log keeps its own bar (worker screen, unchanged).
2. **`PondChoice`**: a `Wrap` (8 dp gaps) of 56 dp-tall `OutlinedButton`s, each showing `PondCode`, with an optional caption line under the code (`bodySmall`: the pond's status on the stock form, "≈ 900 poissons" on the harvest form). The picked one is filled `ink` with `PondCode(ink: paper)`. `allowNone: true` lets a second tap unpick (the visit's observation). With exactly one option and `allowNone == false`, it is picked on first build. A preset pond is not a `PondChoice`: forms show a header line `PondCode` plus a text.
3. **`ChoiceButtons<T>`**: a `Wrap` of 56 dp `OutlinedButton`s with labels; the picked one is filled `ink`. It replaces every `ChoiceChip`, `SegmentedButton` and short-list `DropdownButtonFormField` in the forms in scope: pond role, structure, water supply, status, colour (colour shows swatch plus name), product form, discard reason, feed phase, partial/final, monosex (Oui/Non/Inconnu), the observation category, the treatment's batch.
4. **`DetailsFold`**: a `FoldedSection`-style line titled `detailsFold` "Plus de détails", no summary, no animation. `initiallyOpen` is true when correcting a record with any folded field filled. Its children are always built, kept offstage while closed (`Offstage` + `TickerMode`), so `Form.validate` still sees them (`FormBody`'s reason).
5. **Fields per form.** The recorded number comes first after the pond and date; the rest are in "Plus de détails":

   | Form | Visible | Folded |
   |---|---|---|
   | Stock | pond, date, count, weight, density, acclimatisation, batch code | strain, hatchery, certificate, monosex, planned harvest |
   | Batch edit | code, planned harvest | strain, hatchery, certificate, monosex |
   | Transfer | from (header), to, date, count, band | average weight |
   | Delivery | date delivered, weight, phase, date made | label, supplier, protein, pellet |
   | Discard | lot (header), date, weight, reason | — |
   | Harvest | pond, date, weight, count with aim, partial/final, band | — |
   | Sale | harvest, date, weight, customer, form | note |
   | Customer | name, type | contact |
   | Water reading, sample | as today, bands for issues | — |
   | Treatment | product, dose, date | batch, advised by |
   | Signaler | as today, isolation as a 56 dp switch row | — |
   | Pond | code, colour, role, structure, length, width | depths, water supply, surface override, status |
   | Person | name, active | phone, note |

   Batch edit keeps the planned harvest visible: it drives the fasting alert.
6. **Pinned labels** (new keys unless noted). A correction's label is always `actionSaveCorrection`.

   | Form | New | Correction |
   |---|---|---|
   | Stock | `pondStock` "Empoissonner" (exists) | ✓ |
   | Transfer | `pondTransfer` "Transférer" (exists) | ✓ |
   | Batch edit | `actionSaveBatch` "Enregistrer le lot" | — |
   | Delivery | `actionSaveDelivery` "Enregistrer la livraison" | ✓ |
   | Discard | `actionDiscard` "Jeter" | — |
   | Harvest | `harvestAction` "Récolter" (exists) | ✓ |
   | Sale | `sellAction` "Vendre" (exists) | ✓ |
   | Customer | `actionAddCustomer` "Ajouter le client" / `actionSaveCustomer` "Enregistrer le client" | — |
   | Water reading | `actionSaveReading` "Enregistrer le relevé" | ✓ |
   | Sample | `actionSaveSample` "Enregistrer la pesée" | ✓ |
   | Treatment | `actionSaveTreatment` "Enregistrer le traitement" | — |
   | Signaler | `actionReport` "Signaler" | — |
   | Pond | `pondAdd` (exists) / `actionSavePond` "Enregistrer l'étang" | — |
   | Person | `actionAddPerson` "Ajouter la personne" / `save` | — |

   `actionSaveCorrection` "Enregistrer la correction". The correction title stays `correctionTitle`.
7. **`showDone(context, text)`**: a `SnackBar` with `Icons.check_circle` in `ok` and the text, shown by the screen that opened the form, after it pops. Texts: `doneStocked` "Empoissonné", `doneTransferred` "Transféré", `doneHarvested` "Récolté", `doneSold` "Vendu", `doneDiscarded` "Jeté", `doneDelivered` "Livraison enregistrée", `doneCorrected` "Correction enregistrée", `doneDeleted` "Supprimé". The visit's own forms keep returning to the visit with no snackbar (its finished check already shows the result).
8. **`FormMenu`**: an app-bar `PopupMenuButton` (⋮, 56 dp) built from `(label, icon, onTap)` entries; a form adds it only when correcting. **`confirmDelete(context, message)`** returns `Future<bool>`: an `AlertDialog` with the message, `cancel` and a `FilledButton` `delete` in `danger`. Messages (fr; plural forms where a count is shown):

   | Key | French |
   |---|---|
   | `deleteStockingConfirm` | "Supprimer l'empoissonnement du {date} ({count} poissons, {pond}) ? Le lot perd ces poissons." |
   | `deleteTransferConfirm` | "Supprimer le transfert du {date} ({count} poissons, {from} → {to}) ? Les poissons comptent de nouveau dans {from}." |
   | `deleteDeliveryConfirm` | "Supprimer la livraison du {date} ({kg}) ? Le stock baisse de {kg}." |
   | `deleteHarvestConfirm` | "Supprimer la récolte du {date} ({kg}, {pond}) ? Les poissons comptent de nouveau dans {pond}." |
   | `deleteSaleConfirm` | "Supprimer la vente du {date} ({kg}, {customer}) ? Ces kilos restent à vendre." |
   | `deleteReadingConfirm` | "Supprimer le relevé d'eau du {date} ?" |
   | `deleteSampleConfirm` | "Supprimer la pesée du {date} ({batch}) ?" |
   | `harvestHasSales` (new text) | "{count, plural, =1{Supprimez d'abord sa vente.} other{Supprimez d'abord ses {count} ventes.}}" |

   `deleteConfirm` goes if nothing uses it any more. A customer's ⋮ holds `customerArchive` (exists).
9. **More menu.** Group headings in `titleSmall` `inkMuted`, 16 dp side padding: `moreGroupFarm` "La ferme", `moreGroupSheets` "Fiches", `moreGroupPhone` "Ce téléphone", `moreGroupAdmin` "Administration". Rows keep their icons and routes. A summary sits in `trailing` before the chevron, `bodySmall` ink, wrapping:
   - **Lots:** `moreBatchesSummary` "{count, plural, =0{Aucun en cours} =1{1 en cours} other{{count} en cours}}", counting batches not closed.
   - **Aliment:** `EstimatedLabel` "≈ {days} jours" then ", {kg}" from `feedStockProvider`. With `daysLeft == null`, kg alone.
   - **Synchronisation:** `syncSummaryRejected` "{count} refusés" in `danger` when rejected > 0; otherwise `syncSummaryPending` "{count} en attente"; otherwise `syncSummaryNever` "Jamais synchronisé" when there is no last sync; otherwise `syncSummaryUpToDate` "À jour". `_lastSyncProvider` becomes the public `lastSyncProvider`. The `SyncBadge` stays on the icon.
   - **Compte:** the name of the member whose id is `session.userId`, if this phone has that row.
   - **Langue:** the current language's name.
   Order: La ferme (Lots, Aliment, Ventes if sales), Fiches (Saisie des fiches, Fiches papier, Exports), Ce téléphone (Synchronisation, Mode ouvrier, Compte, Langue), Administration (Administration, Personnes; admins only).
10. **Batch rows** (`batchRowsProvider`, `lib/features/batches/batch_rows.dart`):

    ```dart
    class BatchRow {
      final Batch batch;
      final List<BatchPlace> places;  // ponds holding it (live > 0 or inconsistent), by code
      final int liveCount;            // sum of places
      final int? avgWeightG;          // only with one place and a known weight
      final int? biomassG;            // null if any place lacks a weight
      final Phase? phase;             // only with one place and status active
      final PondAttention? attention; // isolated places, inconsistent places, then alerts with this batchId
    }
    class BatchPlace { final Pond pond; final Placement placement; final int? biomassG; }
    ```

    `attention` reuses `PondAttention` and `AttentionLead`: `LeadIsolated` for an isolated place, `LeadInconsistent` for an inconsistent one, then `LeadAlert` for each alert whose `batchId` is the batch, in `compareAlerts` order. Its band text is `leadText`.
11. **Batches list.**
    - **Row line 1:** the code (`titleMedium` Bold), then the phase if set, else `batchStatus`. `EstimatedLabel` with the count and `fishUnit` "poissons" under it, right-aligned in `titleMedium`.
    - **Row line 2:** each place's `PondCode` (8 dp apart), then the weight (`formatGrams`) and `≈` biomass, joined by ", ".
    - **Band:** an `AttentionBand` (no code slot: the ponds are on line 2) above line 1 when `attention != null`, opening `alertRoute` for an alert, or the pond page for isolated or inconsistent.
    - Rows are at least 56 dp, separated by 1 dp `line` rules, and tap to `/more/batches/:id`.
    - **Closed batches:** one `FoldedSection` `batchesClosed` "Lots terminés" with summary `batchesClosedCount` "{count, plural, =1{1 lot} other{{count} lots}}"; inside, one line per batch: code, `batchClosedOn`, chevron.
    - **Last row:** `Icons.add` + `batchesStockRow` "Empoissonner un étang", opening `/stock` with no pond.
    - **Empty:** `batchesEmpty` "Aucun lot. Empoissonnez un étang depuis sa page ou ci-dessous.", then the last row.
12. **Stock pond buttons.** `PondChoice` over active ponds without fish. Ready ones come first, by code, with no caption. The rest follow by code with `pondStatus` as caption. Ponds holding fish are left out, as today.
13. **Batch page** (`batch_detail_screen.dart`, rewritten).
    - **App bar:** `batch.code`, then the phase or status in `bodySmall` as the title's second line. ⋮ holds `batchEdit` and `traceTitle`.
    - **Bands:** every item of the batch's attention list as a `CodedBand` (pond code where it has one), each opening its fix.
    - **Places:** per place, a 56 dp row: `PondCode` in the 72 dp column, `EstimatedLabel` "≈ {count} poissons", chevron, opening `/ponds/:id`. A second line holds the weight and `≈` biomass. `inconsistent` adds nothing here (it's a band).
    - **Totals:** `survivalValue`. With two places or more, a first line "≈ {count} poissons, ≈ {kg}".
    - **Closed batch:** instead of places and totals, `batchHarvestedLine` "Récolté {count} poissons, {kg}", `batchCycleFcr` "IC du cycle {value}" (`fcrValue` formatting, no arrow), `survivalValue`, and `initialStock` (exists). Figures come from `batchTrace(facts, id, status: closed)`.
    - **Harvests:** `harvestsHeading`, then `HarvestRows` per harvest (Decision 14).
    - **History:** `history`, one 56 dp row per event: date, an icon (`Icons.add` stocking, `Icons.swap_horiz` transfer), "E2" or "E2 → E4", the count (and weight for a stocking), chevron. Each opens its correction route (exist).
    - **Origin:** a `FoldedSection` `batchOrigin` "Origine", summary of hatchery and certificate (or `notSpecified`). It opens to strain, hatchery, certificate, monosex and planned harvest.
    - **Pinned:** with the sales flag and live fish in any place, `PinnedAction(Icons.set_meal, harvestAction)` → `/more/batches/:id/harvest`. When closed, `PinnedAction(Icons.picture_as_pdf, traceTitle)` → `shareTrace`. Otherwise none.
14. **`HarvestRows`** (replaces `HarvestLines`, in `sales/harvest_rows.dart`):
    - **The harvest row:** "14/03 " `PondCode` " Partielle 300 poissons, 45 kg", chevron, 56 dp; it opens `/more/batches/:batch/harvests/:id/edit` with the sales flag, and is not tappable without it.
    - **Sale rows:** indented 24 dp: "{customer}, {form}" and the kg on the right, chevron, opening `/more/batches/:batch/sales/:saleId/edit` (new route, sales flag).
    - **Unsold:** when `unsoldG > 0`, `unsoldLine` "Reste à vendre : {kg}", then (sales flag) an outlined 56 dp `sellAction` button with `Icons.storefront` → `/more/batches/:batch/sell?harvestId=:id`.
15. **Pond page link.** In `_BatchBlock`, the code line becomes a 56 dp `InkWell` row: `batch.code` in `titleMedium`, a chevron, → `/more/batches/:id`. Peser and Transférer stay.
16. **Feed page.**
    - **Header:** `feedOnHand` "En stock" `titleMedium`, with `EstimatedLabel` "≈ {days} jours" (`feedDaysLeftShort`) right-aligned on the same line (or `feedNoUsage`). Under it, `formatKg(onHandG)` in `headlineSmall`.
    - **Bands:**
      - `expiredG > 0`: danger `AttentionBand` `feedExpiredBand` "{kg} périmés, à jeter", opening the discard of the oldest expired lot;
      - `overdrawnG > 0`: warning with `feedOverdrawn` (exists).
    - **Lots:** lots with balance > 0, grouped by `lot.phase` in phase order. A group line is the phase name and its kg subtotal (`titleMedium`). Each lot row is "{label} fait le {date}, {days} j" (`feedLotLine`; no label → `feedLotUnnamed` "Lot"), with an `Icons.warning_amber` in `warning` plus `feedLotOld`, or `Icons.error` in `danger` plus `feedLotExpired`, on a second line. The kg sit on the right, with a chevron → `/more/feed/:lotId` (new: the delivery form correcting).
    - **Empty:** `feedNoLots` "Aucun aliment en stock. Enregistrez une livraison."
    - **Pinned:** `PinnedAction(Icons.add, feedDeliver)` → `/more/feed/deliver`. The FAB goes.
    - **Delivery form correcting:** adds an outlined 56 dp `feedDiscardPart` "Jeter une partie" (→ `/more/feed/:lotId/discard`) above the folded details, and ⋮ Supprimer.
17. **Ventes.**
    - **First row:** `Icons.people`, `customersTitle`, `customersCount` "{count, plural, =0{Aucun} =1{1 client} other{{count} clients}}", chevron → `/more/sales/customers`.
    - **Batch groups:** harvests grouped by batch, groups ordered by their newest harvest date, newest first. A group heading row is the batch code (`titleMedium`) and `batchStatus`, chevron → batch page. Then `HarvestRows` newest first.
    - **Empty:** `salesNone` stays.
    - **Customers list:** rows in name order (case-insensitive), with type and contact on a `bodySmall` line, then a last row `Icons.person_add` `customerNew` → new customer. The FAB goes.
18. **Customer picker** (`sales/customer_picker.dart`): a page `customerPickTitle` "Client". Customers who bought most recently come first (latest sale date), then the rest by name. One 56 dp row each, with a tick on the current one. The last row is `customerNew`; it pushes the customer form and pops the picker with the new id. Tapping a row pops with its id.
19. **Harvest aim:** above the count, `EstimatedLabel` `harvestAim` "≈ {count} poissons dans {pond}" (replacing `harvestEstimate` on screen). `harvestMissing` becomes a warning band under the count.
20. **`unsoldG(int harvestG, Iterable<int> soldG) → int`**: harvest minus sold, never below 0. It lives in `lib/domain/sales.dart` and is used by `HarvestRows` and the sale form's over-harvest band.

## Global Constraints

- No schema, sync, server or report-format change; no new package.
- Every string from the ARB files, every key in both; mg drafts; regenerate `docs/mg-review.csv` with `dart run tool/mg_review.dart export`; check for an existing key before adding one; remove keys nothing uses any more. Edit ARB files line by line; never re-serialise a whole file.
- Colours from the theme (guard test); `Colors.*` only for pond tags.
- Touch targets ≥ 56 dp; no text below 14 sp on screen; long Malagasy text wraps.
- On screen an estimate starts with `≈` (`EstimatedLabel`).
- Append-only: corrections go through the existing `correct*` methods, deletions through the existing `delete*`/tombstones.
- `dart format` only touched files, by name; never commit `failures/`.
- At the end of each task: `flutter analyze` clean; `flutter test` and `TZ=UTC flutter test` pass.
- Commits: conventional prefix and the `Co-Authored-By` line. Branch: `design/batches-feed`.

## Review Focus

1. **A required field inside a closed "Plus de détails"** (the stock form's batch code is visible, but a correction could fail validation on a folded field): Save must still validate it and open the fold to show the error. Covered in Task 1 (`DetailsFold` opens when a child fails validation) and Task 2 (stock correction test).
2. **Keyboard open on a small screen:** the pinned action stays above the keyboard and the focused field stays visible (360 × 640 with insets). Covered in Task 1.
3. **A batch spread over ponds, one of them isolated, with a count to check elsewhere:** the batches list's band names the isolation first, with "+1"; the batch page shows both bands. Covered in Task 6.
4. **A harvest corrected to less than what was already sold:** "Reste à vendre" never goes negative (no line), and the sale form's band shows. Covered in Task 3 and Task 8.
5. **Deleting the only stocking of a batch** from its correction form returns to a batch page that may now be empty. The page must not throw; it shows no places and the history is empty. Covered in Task 2.

---

### Task 1: Shared form pieces

**Files:**
- Create: `lib/features/common/pinned_action.dart`, `pond_choice.dart`, `choice_buttons.dart`, `details_fold.dart`, `form_menu.dart` (with `confirmDelete` and `showDone`), `lib/domain/sales.dart`
- Modify: ARB files (`detailsFold`, `doneDeleted`), `docs/mg-review.csv`
- Test: `test/features/common/form_pieces_test.dart`, `test/domain/sales_test.dart`, golden `form_pieces.png`

**Interfaces:**
- Produces:

```dart
class PinnedAction extends StatelessWidget {
  const PinnedAction({super.key, required IconData icon, required String label, required VoidCallback? onPressed});
}
class PondChoice extends StatelessWidget {
  const PondChoice({super.key, required List<PondOption> options, required String? value,
      required ValueChanged<String?> onChanged, bool allowNone = false});
}
class PondOption { const PondOption({required Pond pond, String? caption}); }
class ChoiceButtons<T> extends StatelessWidget {
  const ChoiceButtons({super.key, required List<(T, String)> options, required T? value,
      required ValueChanged<T> onChanged, Widget Function(T)? leading});
}
class DetailsFold extends StatefulWidget {
  const DetailsFold({super.key, required List<Widget> children, bool initiallyOpen = false});
}
class FormMenu extends StatelessWidget {
  const FormMenu({super.key, required List<FormMenuEntry> entries});
}
class FormMenuEntry { const FormMenuEntry({required String label, required IconData icon, required VoidCallback onTap}); }
Future<bool> confirmDelete(BuildContext context, String message);
void showDone(BuildContext context, String text);
int unsoldG(int harvestG, Iterable<int> soldG);
```

- [ ] **Step 1: Write the failing tests:**
  - **`unsoldG`:** `(45000, [40000]) → 5000`; `(45000, []) → 45000`; `(30000, [40000]) → 0`.
  - **`PinnedAction`:** with `MediaQueryData(viewInsets: bottom 300)` at 360 × 640, the button's bottom edge is ≥ 300 dp above the screen's bottom, and its height is ≥ 56. `onPressed: null` disables it.
  - **`PondChoice`:**
    - three ponds give three buttons ≥ 56 dp tall with their codes;
    - a tap calls `onChanged(id)`, and the picked one has a filled background;
    - with `allowNone`, tapping the picked one calls `onChanged(null)`;
    - a single option with `allowNone == false` calls `onChanged(thatId)` after the first frame;
    - a caption shows under its code.
  - **`ChoiceButtons`:** a tap calls `onChanged`; the picked option is filled; five Malagasy labels at 130 % text wrap to rows with no overflow at 360 dp.
  - **`DetailsFold`:**
    - closed, its children are not visible; one tap shows them with no animation (`pump()` once);
    - `initiallyOpen` shows them;
    - a required `TextFormField` inside a closed fold fails `Form.validate()`, and the fold is then open.
  - **`confirmDelete`:** the message shows; Supprimer returns true; Annuler returns false.
  - **`showDone`:** shows a snackbar with the text and `Icons.check_circle`.
  - **Golden:** `form_pieces.png` (pond choice with one picked, choice buttons, closed fold, pinned action) at 360 × 640.
- [ ] **Step 2: Run** `flutter test test/features/common/form_pieces_test.dart test/domain/sales_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 1–4, 7, 8 and 20. For `DetailsFold`'s opening on a failed validation, wrap the children in a `FormField<void>` whose validator runs the children's state check; the simplest working approach is fine, as long as the test passes.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(common): pinned action, pond and option buttons, details fold, named delete`.

### Task 2: Batch and feed forms

**Files:**
- Modify:
  - `lib/features/batches/stock_screen.dart`, `transfer_screen.dart`, `batch_detail_screen.dart` (`BatchFormScreen` only), `batch_identity_fields.dart`
  - `lib/features/feed/feed_delivery_screen.dart` (`lotId` for a correction), `feed_discard_screen.dart`
  - `lib/router.dart` (`/more/feed/:lotId` → `FeedDeliveryScreen(lotId:)`)
  - ARB files, `docs/mg-review.csv`
  - tests: `test/features/batches/stock_screen_test.dart`, `transfer_screen_test.dart`, `test/features/feed/feed_stock_screen_test.dart`
- Test: `test/features/feed/feed_forms_test.dart`, goldens `stock_form_fr.png`, `transfer_form_mg.png`

**Interfaces:**
- Consumes: Task 1.
- Produces: `FeedDeliveryScreen({String? lotId})`; route `/more/feed/:lotId`; ARB keys `actionSaveCorrection`, `actionSaveBatch`, `actionSaveDelivery`, `actionDiscard`, `doneStocked`, `doneTransferred`, `doneDelivered`, `doneDiscarded`, `doneCorrected`, `deleteStockingConfirm`, `deleteTransferConfirm`, `deleteDeliveryConfirm`, `feedDiscardPart`.

- [ ] **Step 1: Write the failing tests:**
  - **Stock from the batches list:**
    - on the demo farm plus a pond P3 created with status ready, `PondChoice` lists P3 (no caption) before P1 and P2 (each with its `pondStatus` caption);
    - E1 (holding fish) isn't offered;
    - no `DropdownButtonFormField` and no `Notice` are on the screen.
  - **Stock from a pond:** the pond shows as a header with no `PondChoice`.
  - **Stock, optional fields:** strain, hatchery and certificate are not visible until "Plus de détails" is tapped.
  - **Stock, density:** an out-of-range count shows an `AttentionBand` directly under the count field (its top below the count field's bottom, above the next field). An in-range density is a plain text line.
  - **Stock, saving:** the pinned button reads "Empoissonner"; saving pops and the opener shows "Empoissonné".
  - **Stock correction:**
    - opened with hatchery set, the fold is open and the button reads "Enregistrer la correction";
    - ⋮ → Supprimer shows "Supprimer l'empoissonnement du 05/03/2026 (1 240 poissons, E1) ? Le lot perd ces poissons.";
    - confirming tombstones it and the batch page still builds (Review Focus 5).
  - **Transfer:** destination by `PondChoice`; the isolated destination band sits under the pond buttons; the pinned button reads "Transférer"; correction ⋮ shows the named transfer message.
  - **Delivery:**
    - new: phase is chosen with `ChoiceButtons`; label, supplier, protein and pellet are folded; the button reads "Enregistrer la livraison";
    - `/more/feed/:lotId` opens filled in with "Jeter une partie" and ⋮ Supprimer;
    - saving calls `correctDelivery` (the lot's weight changes on the feed page);
    - for a 120 kg delivery dated 01/03/2026, deleting shows "Supprimer la livraison du 01/03/2026 (120 kg) ? Le stock baisse de 120 kg."
  - **Discard:** the lot as a header, the reason by `ChoiceButtons`, the button "Jeter"; saving shows "Jeté".
  - **Large text:** each form in mg at 130 % at 360 × 780 has no overflow.
  - **Goldens:** the stock form in fr from the batches list, and the transfer form in mg with its band.
- [ ] **Step 2: Run** `flutter test test/features/batches/ test/features/feed/`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 5, 6, 8 and 12 for these forms. The acclimatisation reminder is an ink line with `Icons.thermostat`. Update the existing tests that found widgets by `DropdownButtonFormField`, `ChoiceChip` or "Enregistrer".
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(forms): batch and feed forms take the form standard`.

### Task 3: Sales forms

**Files:**
- Create: `lib/features/sales/customer_picker.dart`
- Modify:
  - `lib/features/sales/harvest_screen.dart`, `sale_screen.dart` (`saleId` to correct, `harvestId` to preset), `customers_screen.dart` (`CustomerFormScreen` only)
  - `lib/router.dart` (`sell?harvestId=`, `sales/:saleId/edit`, `/more/sales/customers/pick`)
  - ARB files, `docs/mg-review.csv`, `test/features/sales/harvest_screen_test.dart`, `sale_screen_test.dart`, `customers_screen_test.dart`
- Test: goldens `sale_form_fr.png`, `harvest_form_mg.png`

**Interfaces:**
- Consumes: Task 1 (`unsoldG` included).
- Produces:
  - `SaleScreen({required String batchId, String? harvestId, String? saleId})`;
  - `Future<String?> pickCustomer(BuildContext context, {String? current})`;
  - routes `/more/batches/:id/sell?harvestId=` and `/more/batches/:id/sales/:saleId/edit`;
  - ARB keys `harvestAim`, `customerPickTitle`, `doneHarvested`, `doneSold`, `deleteHarvestConfirm`, `deleteSaleConfirm`, `actionAddCustomer`, `actionSaveCustomer`, and the new `harvestHasSales` text.

- [ ] **Step 1: Write the failing tests** (on `sales_fixtures.dart`):
  - **Harvest, ponds:** a batch in E2 only has E2 preselected; a batch in E2 and E4 shows both buttons, none picked.
  - **Harvest, field order:** the weight field comes before the count field; "≈ 1 240 poissons dans E2" shows above the count.
  - **Harvest, missing fish:** final with a count below the estimate shows a warning `AttentionBand` with `harvestMissing` under the count.
  - **Harvest, saving:** partial and final use `ChoiceButtons`; the button reads "Récolter"; saving shows "Récolté".
  - **Harvest correction:**
    - ⋮ Supprimer on a harvest with 2 sales shows "Supprimez d'abord ses 2 ventes." and deletes nothing;
    - with none, the named message, then a tombstone.
  - **Sale preset:** `?harvestId=` shows that harvest as a header with "reste 5 kg".
  - **Sale customer:** the customer row opens the picker. The recent buyer is listed first; "Nouveau client" adds one and comes back with it picked.
  - **Sale form:** the product form uses `ChoiceButtons` with five options; the note is folded.
  - **Sale over the harvest:** 6 kg on a 5 kg remainder shows the `saleOverHarvest` band under the weight.
  - **Sale correction:** `sales/:saleId/edit` opens filled in; saving calls `correctSale`; ⋮ shows `deleteSaleConfirm` with the fixture sale's date, kilos and customer.
  - **Customer form:** type by `ChoiceButtons`, contact folded, button "Ajouter le client"; an existing customer has ⋮ "Retirer de la liste".
  - **Large text:** mg at 130 % has no overflow.
  - **Goldens:** the sale form in fr, preset; the harvest form in mg.
- [ ] **Step 2: Run** `flutter test test/features/sales/`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 5, 6, 8, 18 and 19. "Recent buyers" order: the latest `sales.recordedAt` per customer, in one query in `CustomerRepository` (`watchByRecentSale()`), tested in `test/db/` alongside the existing customer repository tests.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(forms): harvest, sale and customer forms take the form standard`.

### Task 4: Pond page forms, pond and person forms

**Files:**
- Modify:
  - `lib/features/readings/water_reading_screen.dart`, `sample_screen.dart`
  - `lib/features/health/treatment_screen.dart`, `report_problem_screen.dart`
  - `lib/features/ponds/pond_form_screen.dart`, `lib/features/people/person_form_screen.dart`
  - `lib/features/visit/visit_screen.dart` (`_ObservationDialog`: `PondChoice(allowNone: true)`, category by `ChoiceButtons`)
  - ARB files, `docs/mg-review.csv`
  - their tests: `test/features/readings/`, `health_test.dart`, `pond_form_test.dart`, `test/features/people/`, `test/features/visit/`
- Test: golden `pond_form_fr.png`

**Interfaces:**
- Consumes: Task 1.
- Produces: ARB keys `actionSaveReading`, `actionSaveSample`, `actionSaveTreatment`, `actionReport`, `actionSavePond`, `actionAddPerson`, `deleteReadingConfirm`, `deleteSampleConfirm`.

- [ ] **Step 1: Write the failing tests:**
  - **Water reading:** the pinned button reads "Enregistrer le relevé"; an out-of-range oxygen shows a danger band under the oxygen field (replacing the `Notice`); a correction has ⋮ Supprimer with "Supprimer le relevé d'eau du 15/03/2026 ?", which tombstones it.
  - **Sample:** the button reads "Enregistrer la pesée"; the small-sample notice is a warning band under the fish count; a correction has ⋮ Supprimer.
  - **Visit forms:** opened from the visit, saving still returns to the visit (existing visit tests pass).
  - **Treatment:** batch and advised-by are folded; the batch uses `ChoiceButtons`; the button reads "Enregistrer le traitement".
  - **Signaler:** the button reads "Signaler"; isolate is a 56 dp switch row.
  - **Pond form:**
    - no `DropdownButtonFormField`;
    - colour, role and structure by `ChoiceButtons` (colour buttons show a swatch);
    - depths, water supply, surface override and status are folded;
    - the design warning is a band under the dimensions;
    - the button reads "Ajouter un étang" (new) or "Enregistrer l'étang" (edit).
  - **Person form:** phone and note folded; "Ajouter la personne" / "Enregistrer".
  - **Observation dialog:** pond buttons with none picked means farm-wide, as before.
  - **Large text:** each form in mg at 130 % has no overflow.
  - **Golden:** the pond form in fr, new.
- [ ] **Step 2: Run** the tests listed. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 3, 5, 6 and 8 for these forms. A `SwitchListTile` keeps `minTileHeight: 56`.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(forms): pond page, pond and person forms take the form standard`.

### Task 5: The demo trade and the More menu

**Files:**
- Create: `test/features/more/more_design_test.dart`, goldens `more_fr.png`, `more_mg.png`
- Modify:
  - `test/demo_farm.dart` (`seedDemoTrade`)
  - `lib/features/more/more_screen.dart`
  - `lib/features/sync/sync_screen.dart` (`lastSyncProvider` public)
  - ARB files, `docs/mg-review.csv`

**Interfaces:**
- Produces:

```dart
/// On top of [seedDemoFarm] (plan design step 7):
/// - feed: grower lot "Lot A" made 70 days before demoNow (old), 60 kg; grower "Lot B" made 14 days ago, 120 kg;
///   fry lot made 20 days ago, 60 kg; grower lot made 100 days ago (expired), 25 kg; all delivered 2 days after made.
/// - transfer: 300 fish of L-E1 from E1 to P2, 5 days ago.
/// - harvest: L-E6 partial, 300 fish, 45 kg from E6, yesterday; sold 40 kg fresh to "Marché Anosy" (market).
/// - customers: "Marché Anosy" (market), "Restaurant Lova" (restaurant).
/// - closed batch: pond E7 (green), L-E7 stocked 1 520 fish at 2 g on 01/10/2025, final harvest 02/02/2026, 1 100 fish, 210 kg.
Future<void> seedDemoTrade(AppDatabase db, DemoFarm farm);
```

- ARB keys `moreGroupFarm`, `moreGroupSheets`, `moreGroupPhone`, `moreGroupAdmin`, `moreBatchesSummary`, `syncSummaryUpToDate`, `syncSummaryPending`, `syncSummaryRejected`, `syncSummaryNever`.

- [ ] **Step 1: Write the failing tests** (demo farm and trade, admin with the sales flag, clock at `demoNow`):
  - **Order:** headings in order La ferme, Fiches, Ce téléphone, Administration; Lots comes before Compte.
  - **Lots:** "6 en cours" (count the batches the demo actually has open, and pin that number).
  - **Aliment:** a `≈` label followed by "jours" and the kg.
  - **Synchronisation:** "Jamais synchronisé" on a fresh database; with a pending record, "1 en attente".
  - **Langue:** "Français".
  - **Roles:** a member without the admin or sales flags sees neither Administration nor Ventes.
  - **Large text:** mg at 130 % has no overflow.
  - **Goldens:** fr and mg at 360 × 780.
- [ ] **Step 2: Run** `flutter test test/features/more/`. Expected: FAIL.
- [ ] **Step 3: Implement** `seedDemoTrade` through the repositories (as `seedDemoFarm` does), then Decision 9.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. The earlier design goldens are unchanged. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(more): grouped by job, farm pages first, with their summaries`.

### Task 6: The batches list

**Files:**
- Create: `lib/features/batches/batch_rows.dart`, `test/features/batches/batch_rows_test.dart`, `test/features/batches/batches_design_test.dart`, goldens `batches_fr.png`, `batches_mg.png`
- Modify: `lib/features/batches/batches_screen.dart`, ARB files, `docs/mg-review.csv`

**Interfaces:**
- Consumes: Tasks 1, 5; `placementsProvider`, `batchSummariesProvider`, `allPondsByIdProvider`, `alertsProvider`, `pondAttention` types, `leadText`, `alertRoute`.
- Produces: `BatchRow`, `BatchPlace` (Decision 10); `final batchRowsProvider = Provider<AsyncValue<List<BatchRow>>>`; ARB keys `batchesClosed`, `batchesClosedCount`, `batchesStockRow`, `batchClosedOn`, `fishUnit`, new `batchesEmpty`.

- [ ] **Step 1: Write the failing tests:**
  - **`batchRowsProvider` places:** after the demo trade, L-E1 has places `[E1, P2]`, no `avgWeightG` and no phase, and a biomass that is the sum of its places.
  - **`batchRowsProvider` attention:**
    - L-E4 has `LeadIsolated`, and L-E5 has `LeadInconsistent`;
    - a batch in an isolated pond and an inconsistent one has `LeadIsolated` with `more == 1` (Review Focus 3).
  - **Screen, order:** rows in code order with L-E7 absent from the open rows; "Lots terminés" with summary "1 lot".
  - **Screen, L-E1:** E1 and P2 as `PondCode`s; "≈" before the count.
  - **Screen, taps:** L-E4's band opens E4's page; a row opens its batch page; the last row opens `/stock` with no pond.
  - **Screen, empty:** a farm without batches shows the new `batchesEmpty` text and the last row.
  - **Large text:** mg at 130 % has no overflow.
  - **Goldens:** fr and mg at 360 × 780.
- [ ] **Step 2: Run** `flutter test test/features/batches/`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 10 and 11.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(batches): the list for a glance: ponds, numbers, bands, closed folded`.

### Task 7: The batch page and the pond page's link

**Files:**
- Create: `lib/features/sales/harvest_rows.dart`, `test/features/batches/batch_design_test.dart`, goldens `batch_fr.png`, `batch_fr_bottom.png`, `batch_mg.png`, `batch_closed_fr.png`
- Modify:
  - `lib/features/batches/batch_detail_screen.dart` (the page)
  - `lib/features/ponds/pond_detail_screen.dart` (`_BatchBlock` code row)
  - `lib/features/sales/sales_screen.dart` (drop `HarvestLines`)
  - ARB files, `docs/mg-review.csv`, `test/features/batches/batch_detail_test.dart`, `test/features/ponds/pond_detail_test.dart`

**Interfaces:**
- Consumes: Tasks 1, 3 (routes), 6 (`batchRowsProvider`); `batchTrace`, `farmFactsProvider`, `shareTrace`, `unsoldG`.
- Produces: `class HarvestRows extends ConsumerWidget { const HarvestRows({required HarvestWithSales entry, required Map<String, Pond> ponds, required Map<String, Customer> customers}); }`; ARB keys `batchOrigin`, `batchHarvestedLine`, `batchCycleFcr`, `unsoldLine`.

- [ ] **Step 1: Write the failing tests** (demo farm and trade, sales flag):
  - **L-E1:**
    - E1 and P2 rows each with "≈ … poissons" and a chevron; tapping E1 opens `/ponds/<E1>`;
    - `survivalValue` and a totals line;
    - history rows "⇄ E1 → P2" and "+ E1", each opening its correction;
    - "Origine" is folded.
  - **L-E4:** the "Étang isolé" `CodedBand` at the top, opening E4.
  - **L-E6 harvest rows:**
    - "Reste à vendre : 5 kg" and a "Vendre" button opening `sell?harvestId=`;
    - the sale row opens `sales/<id>/edit`;
    - "Récolter" pinned in `bottomNavigationBar`.
  - **Without the sales flag:** no pinned button, no Vendre button, harvest rows not tappable.
  - **L-E7 (closed):** "Récolté 1 100 poissons, 210 kg", "IC du cycle", no place rows, "Fiche de traçabilité" pinned.
  - **⋮:** "Modifier le lot" and "Fiche de traçabilité".
  - **No cards:** no `Card` and no `TextButton` "Corriger" on the page.
  - **Pond page link:** on E1's page, tapping "L-E1" opens `/more/batches/<id>`; Peser and Transférer are still there.
  - **Large text:** mg at 130 % has no overflow.
  - **Goldens:** L-E1 in fr (top and bottom), mg (top), L-E7 in fr.
- [ ] **Step 2: Run** `flutter test test/features/batches/ test/features/ponds/pond_detail_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 13–15. The pond page goldens change by the chevron only; regenerate them and look.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(batches): the batch page: where the fish are, harvests, history, one pinned action`.

### Task 8: Feed page, Ventes and customers

**Files:**
- Create: `test/features/feed/feed_design_test.dart`, `test/features/sales/sales_design_test.dart`, goldens `feed_fr.png`, `feed_mg.png`, `sales_fr.png`, `customers_fr.png`
- Modify: `lib/features/feed/feed_stock_screen.dart`, `lib/features/sales/sales_screen.dart`, `customers_screen.dart` (list), ARB files, `docs/mg-review.csv`, `test/features/feed/feed_stock_screen_test.dart`, `test/features/sales/customers_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 1, 2 (`/more/feed/:lotId`), 3, 7 (`HarvestRows`).
- Produces: ARB keys `feedDaysLeftShort`, `feedExpiredBand`, `feedLotLine`, `feedLotUnnamed`, `customersCount`, and new text for `feedNoLots`.

- [ ] **Step 1: Write the failing tests** (demo farm and trade):
  - **Feed header:** "En stock" with "≈ … jours", and the kg in `headlineSmall`.
  - **Feed bands:** a danger band "25 kg périmés, à jeter" that opens the expired lot's discard.
  - **Feed groups:** "Croissance" before "Alevinage", each with its subtotal; within Croissance, Lot A (with "ancien") before Lot B.
  - **Feed lots:** a lot row opens `/more/feed/<lotId>`; no `Card` and no `FloatingActionButton`; "Livraison" pinned.
  - **Feed, empty:** the new `feedNoLots` text with Livraison pinned.
  - **Ventes:**
    - the first row is "Clients" with "2 clients";
    - the L-E6 group comes before L-E7, and its heading opens the L-E6 page;
    - "Reste à vendre : 5 kg" under L-E6;
    - L-E7's final harvest has no sales in the demo, so it shows "Reste à vendre : 210 kg".
  - **Customers:** rows in name order; a last row "Nouveau client"; no FAB.
  - **Large text:** mg at 130 % has no overflow on the three pages.
  - **Goldens:** feed fr/mg, Ventes fr, customers fr, at 360 × 780.
- [ ] **Step 2: Run** `flutter test test/features/feed/ test/features/sales/`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 16 and 17.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(feed,sales): stock by phase with bands; sales by batch with what's left to sell`.

### Task 9: On the phone

**Files:**
- Modify: `tool/design_demo.dart` (pages `more`, `batches`, `batch` = L-E1, `batch-closed` = L-E7, `feed`, `sales`, `transfer` = L-E1 from E1, `sale` = L-E6's harvest preset; each seeds `seedDemoTrade` and runs as an admin with the sales flag), `tool/design_screenshots.sh` (page names in its header)

- [ ] **Step 1:** Add the pages. Run `tool/design_screenshots.sh <device> more batches batch batch-closed feed sales transfer sale` with the phone unlocked. Look at every PNG in fr and mg for cut text, overlaps and anything that reads as an alarm when it isn't one.
- [ ] **Step 2: Commit:** `test: design screenshots of batches, feed and sales`.

Then a fresh whole-branch review, the fixes it calls for, the screenshots shown to the user, the step marked merged in `docs/design.md`, and the local merge.
