set -u
R=andrew-quintana/gha-queue-probe
disp(){ gh workflow run probe.yml -R $R -f tag=$1 -f sleep=$2 -f fail=$3 >/dev/null; sleep 5; gh run list -R $R -w probe.yml -L 20 --json databaseId,displayTitle -q ".[] | select(.displayTitle==\"probe $1\") | .databaseId" | head -1; }
snap(){ echo "== $1 $(date -u +%T)"; gh run list -R $R -w probe.yml -L 20 --json databaseId,displayTitle,status,conclusion,attempt -q '.[] | [.displayTitle,.databaseId,.attempt,.status,.conclusion]|@tsv'; }
sleep 8
F=$(disp failer 5 true); echo F=$F
gh run watch $F -R $R >/dev/null 2>&1; snap after-failer
A=$(disp A 150 false); B=$(disp B 10 false); C=$(disp C 10 false); O=$(disp other 10 false)
sleep 25; snap pending-check
gh run rerun $F -R $R --failed; sleep 20; snap after-rerun-failed
for id in $A $B $C $O $F; do gh run watch $id -R $R >/dev/null 2>&1; done
snap final
for id in $A $B $C $O $F; do echo "-- $id"; gh api "/repos/$R/actions/runs/$id/attempts/$(gh api /repos/$R/actions/runs/$id -q .run_attempt)/jobs" -q '.jobs[]|[.name,.started_at,.completed_at,.conclusion]|@tsv'; done
