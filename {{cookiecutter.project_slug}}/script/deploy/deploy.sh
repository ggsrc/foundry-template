#!/usr/bin/env bash
#
# Deploy a Foundry script with a keystore-signed transaction.
#
# Usage:
#   script/deploy/deploy.sh <forge-script-path> [flags]
#
# Examples:
#   script/deploy/deploy.sh script/deploy/Deploy.s.sol      --account my-deployer
#   script/deploy/deploy.sh script/deploy/MyScript.s.sol    --dry-run --account my-deployer
#   script/deploy/deploy.sh script/deploy/MyScript.s.sol    --ledger
#
# Configuration is read from a `.env` file in the repo root (gitignored).
#   RPC_URL                JSON-RPC endpoint of the target chain  (required)
#   ETHERSCAN_API_KEY      explorer API key; enables `--verify`   (optional)
#   VERIFIER               "etherscan" | "blockscout" | "sourcify" (optional)
#   VERIFIER_URL           verifier API URL (required for Blockscout) (optional)
#   DEPLOYER_PRIVATE_KEY   plaintext signing key. REJECTED on any chain
#                          other than 31337 (local anvil). For mainnet /
#                          testnet, sign via --account or --ledger so the
#                          key never lives on disk in plaintext.
#
# Signing (pick one for any real chain):
#   --account NAME         sign with a foundry keystore account (recommended).
#                          One-time setup: `cast wallet import NAME --interactive`.
#                          Forge prompts for the keystore password at sign time.
#   --ledger               sign with a connected Ledger hardware wallet.
#
# Flags:
#   --dry-run              simulate only; do not broadcast (default: broadcast)
#   --no-verify            skip contract verification even if a key is configured
#   --                     forward all subsequent args verbatim to `forge script`
#                          (useful for --sig, --target-contract, env-arg passthrough)
#   -h | --help            show this help and exit
#
# On a successful broadcast it prints the deployed contract addresses (parsed
# from broadcast/<script>/<chainId>/run-latest.json; needs `jq`) plus a short
# post-deploy checklist.
#
set -euo pipefail

# ----------------------------------------------------------------------------
# locate repo root, load .env
# ----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -f "$REPO_ROOT/.env" ]]; then
  # shellcheck disable=SC1091
  set -a; source "$REPO_ROOT/.env"; set +a
fi

die()  { echo "error: $*" >&2; exit 1; }
note() { echo ">>> $*" >&2; }
warn() { echo "warning: $*" >&2; }

usage() { sed -n '2,/^set -euo/{/^set -euo/!p}' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

# ----------------------------------------------------------------------------
# parse args
# ----------------------------------------------------------------------------
SCRIPT_PATH="${1:-}"
[[ -z "$SCRIPT_PATH" || "$SCRIPT_PATH" == "-h" || "$SCRIPT_PATH" == "--help" ]] && { usage; exit 0; }
shift

BROADCAST=1
DO_VERIFY=1
SIGNER_ARGS=()
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   BROADCAST=0; shift ;;
    --no-verify) DO_VERIFY=0; shift ;;
    --account)   [[ -n "${2:-}" ]] || die "--account needs a name"; SIGNER_ARGS=(--account "$2"); shift 2 ;;
    --ledger)    SIGNER_ARGS=(--ledger); shift ;;
    -h|--help)   usage; exit 0 ;;
    --)          shift; EXTRA_ARGS=("$@"); break ;;
    *)           die "unknown flag: $1 (see --help)" ;;
  esac
done

[[ -f "$SCRIPT_PATH" ]] || die "script not found: $SCRIPT_PATH"

# ----------------------------------------------------------------------------
# validate config
# ----------------------------------------------------------------------------
: "${RPC_URL:?set RPC_URL}"

CHAIN_ID="$(cast chain-id --rpc-url "$RPC_URL")"
note "target chain id: $CHAIN_ID"

# Plaintext DEPLOYER_PRIVATE_KEY is only accepted against a local anvil
# (chain id 31337). For any other chain (mainnet, testnet, sidechain, ...)
# require a foundry keystore account (`--account NAME`) or a hardware wallet
# (`--ledger`) so the signing key never lives on disk in plaintext.
if [[ ${#SIGNER_ARGS[@]} -eq 0 ]]; then
  if [[ "$CHAIN_ID" -ne 31337 ]]; then
    die "plaintext DEPLOYER_PRIVATE_KEY is not allowed on chain $CHAIN_ID.
       Import the key once into foundry's encrypted keystore:
         cast wallet import <name> --interactive
       then deploy with:
         script/deploy/deploy.sh $SCRIPT_PATH --account <name>
       (or sign with a hardware wallet via --ledger)."
  fi
  : "${DEPLOYER_PRIVATE_KEY:?set DEPLOYER_PRIVATE_KEY (anvil only) or pass --account / --ledger}"
  warn "using plaintext DEPLOYER_PRIVATE_KEY against chain $CHAIN_ID (anvil) -- only acceptable for local dev"
  SIGNER_ARGS=(--private-key "$DEPLOYER_PRIVATE_KEY")
fi

# ----------------------------------------------------------------------------
# build & run
# ----------------------------------------------------------------------------
note "forge build"
forge build >/dev/null

FORGE_ARGS=(script "$SCRIPT_PATH" --rpc-url "$RPC_URL" "${SIGNER_ARGS[@]}")

if [[ "$BROADCAST" -eq 1 ]]; then
  FORGE_ARGS+=(--broadcast)
else
  note "DRY RUN -- simulation only, nothing will be broadcast"
fi

if [[ "$BROADCAST" -eq 1 && "$DO_VERIFY" -eq 1 ]]; then
  if [[ -n "${VERIFIER:-}" ]]; then
    FORGE_ARGS+=(--verify --verifier "$VERIFIER")
    [[ -n "${VERIFIER_URL:-}" ]] && FORGE_ARGS+=(--verifier-url "$VERIFIER_URL")
    [[ -n "${ETHERSCAN_API_KEY:-}" ]] && FORGE_ARGS+=(--etherscan-api-key "$ETHERSCAN_API_KEY")
  elif [[ -n "${ETHERSCAN_API_KEY:-}" ]]; then
    FORGE_ARGS+=(--verify --etherscan-api-key "$ETHERSCAN_API_KEY")
  else
    warn "no ETHERSCAN_API_KEY / VERIFIER set -- skipping verification (pass --no-verify to silence)"
  fi
fi

if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  FORGE_ARGS+=("${EXTRA_ARGS[@]}")
fi

# Hand DEPLOYER_PRIVATE_KEY to `forge script` only on the raw-key path. On the
# --account / --ledger paths forge uses the CLI signer; a stray key left in
# `.env` (exported by `source .env` above) must not silently shadow it for any
# script that reads it via vm.env*.
if [[ "${SIGNER_ARGS[0]}" == "--private-key" ]]; then
  export DEPLOYER_PRIVATE_KEY
else
  unset DEPLOYER_PRIVATE_KEY
fi

note "running: forge ${FORGE_ARGS[*]}"
forge "${FORGE_ARGS[@]}"

# ----------------------------------------------------------------------------
# report -- list the contracts that were just deployed
# ----------------------------------------------------------------------------
if [[ "$BROADCAST" -eq 1 ]]; then
  RUN_JSON="broadcast/$(basename "$SCRIPT_PATH")/$CHAIN_ID/run-latest.json"
  if [[ -f "$RUN_JSON" ]]; then
    echo
    echo "=================================================================="
    echo " deployed (chain $CHAIN_ID) -- $RUN_JSON"
    if command -v jq >/dev/null 2>&1; then
      jq -r '.transactions[]?
               | select(.transactionType == "CREATE" or .transactionType == "CREATE2")
               | "   \(.contractName // "<unknown>")\t\(.contractAddress)"' "$RUN_JSON" || true
    else
      warn "install jq for a parsed address summary; raw broadcast log: $RUN_JSON"
    fi
    echo "=================================================================="
    echo
    echo "Post-deploy checklist:"
    echo "  1. Verify each address on the explorer if --verify was skipped."
    echo "  2. Record the addresses in your deployment registry / README."
    echo "  3. If ownership should move to a multisig, transfer it now and have"
    echo "     the multisig accept (e.g. transferOwnership + acceptOwnership)."
  else
    warn "broadcast log not found at $RUN_JSON -- check the forge output above"
  fi
fi
