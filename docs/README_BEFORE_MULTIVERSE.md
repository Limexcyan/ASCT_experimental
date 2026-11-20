# Flanker ASCT — pilot real-data multiverse (feature/multiverse_analysis)

Użyj tylko na checkout branchu `feature/multiverse_analysis` (nie na `main`).
Paczka to minimalny overlay, nie cały toolbox: pliki w niej zastępują lub dodają
odpowiadające pliki w katalogu głównym ASCT. Zachowaj własne poprawki w `fix/`.

## Przygotowanie na Macu

1. `git switch feature/multiverse_analysis`
2. Skopiuj pliki z overlay do odpowiednich lokalizacji repo.
3. `git diff --check && git diff` i po weryfikacji: `git add ... && git commit ... && git push`.
4. Na serwerze: `git switch feature/multiverse_analysis && git pull --ff-only`.

## Dane wejściowe

Wymagane: `/mnt/devv/Exp/LG/wprawki/flanker/ana1/7_SOURCEACT/DC{1,2}/lc/*_sigroi_lc.mat`.
Dane muszą odpowiadać tym samym uczestnikom dla DC1 (INCO) i DC2 (CONG).
`begId=1, endId=4` oznacza pierwsze CZTERY pliki w KAŻDYM DC, po sortowaniu,
a nie koniecznie czterech uczestników globalnie. Preflight sprawdza ID i ich
unikalność w parze porównań dla STEP11.

## Na serwerze, z katalogu repo

    matlab -batch "addpath(pwd); flanker_multiverse_setup"

W pliku `multiverse.dryRun=true` — tworzy manifest z planem, nie STEP10.
Po inspekcji manifestu: `.../ana1_mv_flanker_alpha_v1__multiverse/realdata_manifest.csv`
zmień tylko `multiverse.dryRun=false` i uruchom ponownie.
**Nie ustawiaj `allowOverwrite=true` przy pierwszych próbach.** Jeśli katalog
wariantu istnieje, użyj nowego `multiverse.outputName`.

Realne wyjścia:
- `ana1_mv_flanker_alpha_v1__mv_0001/8_CONN/FPN_300_600/lc/DC{1,2}/..._mltout.mat`
- `ana1_mv_flanker_alpha_v1__mv_0002/8_CONN/FPN_300_600/lc/DC{1,2}/..._mltout.mat`
- `ana1_mv_flanker_alpha_v1__multiverse/realdata_manifest.csv`
- `ana1_mv_flanker_alpha_v1__multiverse/realdata_results.mat`

Wariant 1: `con.varNorm=0`; wariant 2: `con.varNorm=1`.
STEP11 działa w tym samym katalogu wariantu po pomyślnym STEP10. STAT alpha
8–12Hz, `pThresh={0.05}` jest ustawieniem progowania do wizualizacji.
To pilotaż (n=4), a nie potwierdzenie odporności wyników.

## Testy

    matlab -batch "addpath(pwd); addpath('multiverse'); t=runtests({'tests/TestMultiverseRealData.m','tests/TestFlankerRealDataPreflight.m'}); assert(all([t.Passed]));"

W tej sesji nie uruchamiano MATLAB ani danych ze zdalnego serwera. Archiwa
zawierają kod, nie surowe BDF ani gotowe `ana1/7_SOURCEACT`.

## Różnice od konfiguracji użytkownika

- Poprawione uszkodzone formatowanie skopiowanego MATLAB-a (repo zawiera czystą wersję).
- `multiverse.outputName` izoluje nowe warianty.
- Pozostawiony `rc.load=0` i `rc.stop=11`: w trybie multi adapter sam
  ustawia STEP10 oraz osobne STEP11.
- Usunięta powtórzona instrukcja `pThresh`, pozostawione tylko `{0.05}`.
- Jawne `con.lc=1, con.unc=0`, wejściowy `con.varNorm=1`.
- Nowa kontrola identyfikatorów i faktycznych plików ROI przed startem.
- `sc_arstat.m` kieruje liczbę prób do katalogu źródłowego zamiast raportować NaN.
