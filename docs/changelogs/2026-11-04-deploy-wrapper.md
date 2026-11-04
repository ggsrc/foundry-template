# feat: deploy.sh wrapper that enforces keystore signing

PR: #6 (follow-up: #7). Tracking: alva-ai/mono-meta#1115 (ggsrc
standing-PR sweep).

## 1. Current state

- Generated projects deploy with `forge script ... --private-key <hex>`,
  so a plaintext key in `.env` is the documented path for every chain.
- #6 adds `script/deploy/deploy.sh`, ported from `Galxe/g-token-vault`,
  which refuses a plaintext key on any chain other than 31337 (anvil).
- #6's template check failed: Cookiecutter renders every file with Jinja,
  and Bash's `${#SIGNER_ARGS[@]}` in `deploy.sh` opens a Jinja comment
  (`{#`), so `cruft create` stopped with `Missing end of comment tag`.
- Review on #6 (not yet addressed): the wrapper printed the full command,
  including the anvil key and `ETHERSCAN_API_KEY`; `-- --rpc-url ...`
  sent the transaction to an RPC other than the one whose chain id was
  checked.

## 2. Behavior after this change

- B1 Generated projects get `script/deploy/deploy.sh` byte for byte; it
  is copied without rendering.
- B2 A plaintext `DEPLOYER_PRIVATE_KEY` is used only when `RPC_URL`
  reports chain id 31337; elsewhere the wrapper exits with the
  `cast wallet import` instructions.
- B3 The printed command shows `<RPC_URL>`, `<DEPLOYER_PRIVATE_KEY>` and
  `<ETHERSCAN_API_KEY>` instead of their values.
- B4 After `--`, the wrapper refuses `--rpc-url` / `--fork-url` / `-f`,
  raw-key signers (`--private-key(s)`, `--mnemonic*`, `--interactive*`,
  `-i`) and `--broadcast`.
- B5 `forge build` output is shown.

## 3. Decisions

- D1 `_copy_without_render` for `deploy.sh` instead of `{% raw %}`: the
  script uses no template variables, and the file stays a valid script in
  the template repository.
- D2 Refuse the unsafe passthrough flags rather than re-checking the
  chain id of an overridden RPC: one RPC, one check.
- D3 Secrets stay on the `forge` command line (as in g-token-vault); only
  the printed copy is masked.

## 4. Changes

- `cookiecutter.json`: `script/deploy/deploy.sh` in `_copy_without_render`.
- `script/deploy/deploy.sh`: B3, B4, B5; `.env` sourcing split so the
  ShellCheck directive applies to `source`.
- `script/deploy/Deploy.s.sol`, root `README.md`: usage points to
  `deploy.sh`.

## 5. Verification

See section 7.

## 6. Human decisions

- Yumin, 2026-11-04: "研究，处理，合并" for #6 and #7.

## 7. Outcome

- [ ] Template check green.
- [ ] Merged.
