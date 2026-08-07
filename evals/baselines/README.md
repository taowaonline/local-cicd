# Baselines

A baseline is a frozen eval report used as a regression reference. Promote
a report deliberately:

```bash
./harness eval full --offline
./harness baseline compare evals/baselines/latest.json "$(ls -t evals/reports/full-*.json | head -1)"
cp "$(ls -t evals/reports/full-*.json | head -1)" evals/baselines/latest.json
git add evals/baselines/latest.json && git commit -m "baseline: bump"
```

Baseline updates are an explicit, reviewable operation — they never
happen automatically inside an eval run. See
`docs/adr/0006-reports-vs-baselines.md` in the source repo for rationale.
