# feat: CI fuzz/invariant profiles; deploy.sh summary and key hygiene

PR: #7 (after #6, `2026-11-04-deploy-wrapper.md`). Tracking:
alva-ai/mono-meta#1115 (ggsrc standing-PR sweep).

## 1. Current state

- The generated `test.yml` runs with `FOUNDRY_PROFILE` `ci`, `test` and
  `medium`, but `foundry.toml` defines none of them, so every job uses the
  default fuzz and invariant budget.
- `SimpleToken.s.sol` signs with `vm.envUint("DEPLOYER_PRIVATE_KEY")`, so
  it cannot run with `deploy.sh --account` / `--ledger`.
- `deploy.sh` prints nothing after a broadcast about what was deployed.
- #7 tried to keep a stray `DEPLOYER_PRIVATE_KEY` in `.env` away from
  scripts on the `--account` / `--ledger` paths with `unset`. Forge loads
  `.env` itself, so the script still read the key (seen in testing).
- Projects generated with Tenderly fail `forge fmt --check`:
  `src/SimpleToken.sol` is not formatted for forge 1.5. The template check
  generates only the variant without Tenderly.

## 2. Behavior after this change

- B1 `ci` and `test` inherit the default profile (fuzz 256, invariant
  256 × depth 500); `medium` runs fuzz 1000, invariant 512; `intense`
  fuzz 10000, invariant 1000 × depth 1000.
- B2 `SimpleToken.s.sol` broadcasts with the CLI signer and logs the
  signer's address and balance.
- B3 After a broadcast, `deploy.sh` lists the created contracts from
  `broadcast/<script>/<chainId>/run-latest.json` (with `jq`) and a short
  post-deploy checklist.
- B4 On the `--account` / `--ledger` paths, scripts see an empty
  `DEPLOYER_PRIVATE_KEY`: `vm.envOr` returns its default and `vm.envUint`
  reverts.
- B5 Generated projects with Tenderly pass `forge fmt --check`; the
  Tenderly quick start deploys through `deploy.sh`.

## 3. Decisions

- D1 Empty `ci` / `test` profiles instead of copies of the default (review
  on #7).
- D2 Set the key to empty instead of `unset`: Forge's `.env` loading does
  not override variables that are already set.

## 4. Changes

- `foundry.toml`: B1.
- `script/deploy/SimpleToken.s.sol`: B2.
- `script/deploy/deploy.sh`: B3, B4.
- `src/SimpleToken.sol`: `forge fmt`.
- Root and generated `README.md`: Tenderly quick start.

## 5. Verification

- `bash -n` and ShellCheck: clean.
- `cruft create` from this branch in `python:3.12` with Tenderly on and
  demo files kept, then in `ghcr.io/foundry-rs/foundry:stable` (forge
  1.5.1): `forge build`, `forge test` with the default and `medium`
  profiles, `forge fmt --check` with the default and `test` profiles pass.
  `forge config --json` per profile shows the budgets in B1 and
  `fmt.line_length` 120 in every profile.
- Against anvil (chain 1337), keystore account imported with
  `cast wallet import`, `DEPLOYER_WALLET_ADDRESS` set, the key also left in
  `.env`:
  - a probe script sees no key (`vm.envOr(...) != 0` is false); with the
    `unset` from the first version of #7 it was true;
  - `deploy.sh script/deploy/SimpleToken.s.sol --account …` deploys;
    `Deployer` = the keystore address, balance = total supply, matching
    `balanceOf` on chain; the summary lists `SimpleToken` at the deployed
    address.

## 6. Human decisions

- Yumin, 2026-11-04: "研究，处理，合并" for #6 and #7.

## 7. Outcome

- [x] Template check green (run 41753266934).
- [x] Squash-merged (#7).

## 8. Remaining work

- Optional: the template check could also generate the Tenderly variant,
  which would have caught the `forge fmt` failure.
