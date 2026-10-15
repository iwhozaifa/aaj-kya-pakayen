# Git workflow

## Branches

| Branch | Purpose | Protected |
| --- | --- | --- |
| `main` | Production. Holds tagged releases only. | yes |
| `develop` | Integration branch and the GitHub default branch. | yes |
| `feature/<scope>-<short-desc>` | New capability | — |
| `fix/<scope>-<short-desc>` | Bug fix | — |
| `chore/<short-desc>` / `docs/<short-desc>` | Tooling, docs | — |
| `release/x.y.z` | Release stabilization | — |

```
feature/* ──squash──▶ develop ──(release/x.y.z)──merge commit──▶ main ──tag vX.Y.Z
                         ▲                                         │
                         └──────────── back-merge ─────────────────┘
```

## Commits

[Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`.

- Types: `feat`, `fix`, `test`, `docs`, `chore`, `refactor`, `perf`, `ci`, `build`.
- Scopes: `engine`, `db`, `seed`, `pantry`, `today`, `history`, `dishes`, `settings`, `theme`, `l10n`, `ci`.
- The subject is imperative, lower-case and ≤ 72 characters, with no trailing period.

## Test-driven development

All behaviour is built test-first (red → green → refactor):

1. **Red.** Write the smallest test that describes the next behaviour. Run it and watch it fail
   for the expected reason. Commit it as `test(<scope>): ...`.
2. **Green.** Write the minimum production code that makes it pass. Commit it as
   `feat(<scope>): ...` or `fix(<scope>): ...`.
3. **Refactor.** Clean up with all tests green. Commit it as `refactor(<scope>): ...`.

Because PRs are squash-merged, the red → green commit sequence stays visible in the PR's
commit list for review. The test pyramid looks like this:

- **Domain/engine:** pure unit tests and property-style tests (most of the suite)
- **Data:** DAO and repository tests against an in-memory Drift database
- **Features:** widget tests with fake repositories (mocktail), plus golden tests for key screens

## Pull requests

1. Every branch has a GitHub issue. The PR body says `Closes #n`.
2. Open the PR with `gh pr create --base develop` and fill in the template.
   The PR title is a Conventional Commit, because it becomes the squash commit.
3. Keep each PR to one feature, ideally under 500 changed lines excluding generated code.
4. The `ci` check must be green. The reviewer (@iwhozaifa) confirms before anything is merged.
5. The next branch starts only after the previous PR is merged.

## Merge strategy

- **feature/fix/chore/docs → develop:** squash merge. The branch is deleted automatically.
- **release/x.y.z → main:** merge commit (no squash). Then:
  ```bash
  git checkout main && git pull
  git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z
  git checkout develop && git pull && git merge --no-ff main && git push   # admin back-merge, see D-003
  ```

## Repository settings (applied)

```bash
gh repo edit iwhozaifa/aaj-kya-pakayen \
  --default-branch develop \
  --enable-squash-merge --enable-merge-commit --enable-rebase-merge=false \
  --delete-branch-on-merge
```

## Branch protection

Applied once the `ci` check has run at least once (after the bootstrap PR):

```bash
# develop: PR + green CI, linear history, no force pushes/deletions
gh api -X PUT repos/iwhozaifa/aaj-kya-pakayen/branches/develop/protection --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "checks": [{ "context": "ci" }] },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0, "dismiss_stale_reviews": true },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON

# main: same, but merge commits are allowed (release merges)
gh api -X PUT repos/iwhozaifa/aaj-kya-pakayen/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "checks": [{ "context": "ci" }] },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0, "dismiss_stale_reviews": true },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
```

Approvals are set to 0 because PRs are opened from the owner's account, and GitHub does not let an
author approve their own PR. The owner still reviews and confirms every merge (see D-002).

## Local checks before pushing

```bash
dart run build_runner build -d
dart format lib test
flutter analyze
flutter test --coverage && scripts/check_domain_coverage.sh 80
```
