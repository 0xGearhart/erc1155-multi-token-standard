## ERC-1155 Staged Delivery Plan (Strict Gates + Review Cycles)

### Standards and Required References
- OpenZeppelin ERC-1155: https://docs.openzeppelin.com/contracts/5.x/erc1155
- Solidity NatSpec format: https://docs.soliditylang.org/en/latest/natspec-format.html#natspec
- Solidity style guide: https://docs.soliditylang.org/en/latest/style-guide.html
- Rule: prefer OpenZeppelin audited contracts and extensions over custom implementations when equivalent behavior exists.

### Global Stage-Gate Policy (Applies to Every Stage)
1. Stage order is strict. No work begins on Stage `N+1` until Stage `N` is accepted.
2. Every stage is split into small chunks with review/defense before merge.
3. Required defense packet per chunk:
- What changed and why.
- Security and trust assumptions.
- Alternatives considered and why rejected.
- Test evidence and coverage evidence.
4. Coverage gate: 100% line/function/branch coverage target for in-scope contracts before stage sign-off, excluding only unreachable items documented in stage review.
5. Completion gate for each stage:
- `forge build` passes.
- `forge test` passes.
- `forge coverage` for stage scope meets 100% lines/functions/branches for `src/` and `script/` only, except documented unreachable items.
- `slither .` passes (or findings are documented and explicitly accepted in the stage review).
- NatSpec complete for touched source contracts.
- Style-guide checks pass for touched files.
- No unresolved `TODO`/`QUESTION` markers remain in touched files at stage sign-off.

### Decision Lock (Pre-Implementation)
1. Burn access is role-gated with `BURNER_ROLE`; arbitrary holder burns are disabled.
2. Burn implementation uses explicit custom `burn`/`burnBatch` with `onlyRole(BURNER_ROLE)` (no `ERC1155Burnable` inheritance).
3. Role assignment default: deployer (`HelperConfig.NetworkConfig.account`) gets all roles initially.
4. Coverage gate scope: `src/` and `script/` only.
5. Placeholder/mock URI is used in early stages; production metadata/IPFS is finalized in Stage 6.
6. URI strategy is folder-CID based (`ipfs://<CID>/{id}.json`), not per-token URI storage.
7. Slither is part of every stage gate, with accepted findings documented if present.

### Stage 0 - Baseline and Tooling Lock
Objective: establish measurable baseline and guardrails before feature work.

Small chunks:
1. Define coverage measurement policy for this repo.
- Confirm stage-scope coverage command/report format.
- Lock scope to `src/` and `script/` for stage coverage gates.
- Lock metrics to lines/functions/branches and define unreachable-item documentation format for review sign-off.
- Lock the report artifact path to compare stage-over-stage progress in reviews.
 - Standard stage coverage command: `FOUNDRY_PROFILE=coverage forge coverage`.
 - Standard artifact capture command: `FOUNDRY_PROFILE=coverage forge coverage | tee reports/stage-<N>-coverage.txt`.
 - Unreachable-item exception format (required in stage review): file path, function, line(s), why unreachable, and proof (test/trace/static analysis).
 - Acceptable unreachable examples: compiler-eliminated defensive paths, impossible branches from strict preconditions, and dead paths introduced only by inherited library internals.
 - Non-acceptable unreachable examples: untested happy/negative paths that can be exercised with deterministic tests.
2. Add/standardize make targets for stage checks.
- Build, test, coverage, and report output paths.
3. Create stage checklist template in this file for repeated review cycles.

Sign-off artifacts:
- Baseline report with current build/test/coverage status.
- Stage checklist template ready.

### Stage Review Checklist Template
Use this template at the end of each stage before approval to advance.

Stage: `Stage <N> - <Name>`
Date: `YYYY-MM-DD`
Reviewer(s): `<name>`

1. Scope and decisions
- Planned chunks for this stage are complete.
- Any scope changes are documented and approved.
- No unresolved `TODO`/`QUESTION` markers in touched files.

2. Defense packet (required)
- What changed and why.
- Security/trust assumptions.
- Alternatives considered and rejected.
- Test evidence and coverage evidence.

3. Stage gate checks
- `forge build` passes.
- `forge test` passes.
- `FOUNDRY_PROFILE=coverage forge coverage` meets 100% lines/functions/branches for stage scope (`src/`, `script/`) except approved unreachable items.
- `slither .` run complete; findings resolved or accepted with explicit rationale.
- NatSpec complete for touched source contracts.
- Solidity style-guide conformance validated for touched files.

4. Coverage and unreachable exceptions
- Coverage report artifact linked: `reports/stage-<N>-coverage.txt`.
- Any unreachable exceptions documented with:
  - file path
  - function
  - line(s)
  - rationale
  - proof (test/trace/static analysis)

5. Outcome
- Stage status: `Approved` or `Rejected`.
- If rejected: required fixes listed and assigned.

### Stage 1 - Core ERC-1155 Contract Hardening
Objective: finalize a secure, documented core token contract.

Small chunks:
1. Access model hardening.
- Move to delayed admin model (`AccessControlDefaultAdminRules`).
- Keep granular roles for minter and URI setter.
- Add dedicated `BURNER_ROLE`.
- Default role assignment for now: deployer (`HelperConfig.NetworkConfig.account`) receives admin/minter/uri/burner roles.
2. Contract API finalization.
- Finalize constructor inputs for admin/minter/uri/base URI/admin delay.
- Confirm event/error surface and invariants.
- Drop `ERC1155Burnable` extension and implement explicit role-gated burn functions (`burn`, `burnBatch`) using `onlyRole(BURNER_ROLE)`.
- Optional future toggle (not in v1 default): allow self-burn only for explicitly marked consumable IDs.
3. Role administration matrix.
- Document which role administers each role and deployment-time grant policy.
- Default policy: grant required roles directly to intended addresses/contracts during deployment; no revoke step required in current plan.
- Matrix (current):
  - `DEFAULT_ADMIN_ROLE` admin of `MINTER_ROLE`
  - `DEFAULT_ADMIN_ROLE` admin of `URI_SETTER_ROLE`
  - `DEFAULT_ADMIN_ROLE` admin of `BURNER_ROLE`
  - `DEFAULT_ADMIN_ROLE` is managed only by `AccessControlDefaultAdminRules` delayed transfer flow (begin/cancel/accept), not by `grantRole(DEFAULT_ADMIN_ROLE, ...)`.
- Deployment-time role grant policy (current):
  - `defaultAdmin` is constructor input.
  - `minter` is constructor input.
  - `uriSetter` is constructor input.
  - `burner` is constructor input.
  - `initialDelay` is constructor input, sourced from `CodeConstants` in scripts.
  - For current deployments, scripts pass deployer for all role addresses until dedicated contracts are introduced.
4. NatSpec + style conformance.
- Add full NatSpec to all public/external methods and key internals.
- Align layout/order/naming/visibility with Solidity style guide.
5. Unit tests for all core behaviors.
- Positive and negative cases for roles, mint/mintBatch, burn, URI update, supply tracking, interface support.
- Explicitly test that EOAs without `BURNER_ROLE` cannot burn, including token holders.

Sign-off artifacts:
- Defended API and role model.
- 100% stage-scope coverage on core contract.

### Stage 2 - Deployment and Network Config Reliability
Objective: make deployment deterministic, inspectable, and testable.

Small chunks:
1. Expand helper config model.
- Add admin/minter/uri setter/base URI/admin delay per network.
- For current stages, set all role assignees to deployer; shop/crafting reassignment is deferred.
 - Define deployment inputs so future contract addresses can be granted roles at deploy time when those contracts exist.
2. Deploy script output contract.
- Return or persist deployed address in a test-consumable way.
3. Integration tests for script behavior.
- Validate deployed initialization values and role wiring.
- Validate burn role assignment and that unauthorized burner paths revert.
- Validate deployer starts with all configured roles.

Sign-off artifacts:
- Reproducible deployment flow for local + configured remote profile.
- 100% stage-scope coverage for deployment/config logic.

### Stage 3 - Invariant and Security-Focused Test Layer
Objective: validate protocol properties beyond unit behavior.

Status:
- Chunk 1 complete: handler actions implemented for authorized/unauthorized actors.
- Chunk 2 complete: invariants added for supply conservation and role safety boundaries, including burner-only successful burn accounting.
- Chunk 3 complete: fuzz targets added for batch burn edge cases and admin delay transition behavior.

Small chunks:
1. Build handler actions for authorized/unauthorized actors.
2. Add invariants for supply conservation and role safety boundaries.
 - Include invariant that only addresses with `BURNER_ROLE` can reduce supply.
3. Add fuzz targets for batch edge cases and URI/admin transitions.
 - Add fuzz scenarios for unauthorized user burn attempts across random IDs/amounts.

Sign-off artifacts:
- Invariant suite with documented properties.
- 100% stage-scope coverage target maintained.

### Stage 4 - Docs and Operational Readiness
Objective: finish project documentation for repeatable operation.

Status:
- Chunk 1 complete: README template replaced with project-specific documentation while preserving template layout.

Small chunks:
1. Replace README template with project-specific docs.

Sign-off artifacts:
- Concise README with core setup, deployment, and security notes.
- 100% stage-scope coverage target maintained.

### Stage 5 - Metadata Build Pipeline + IPFS URI Flow
Objective: produce deterministic metadata and publishable IPFS-backed URIs before advanced mechanics are selected.

Status:
- Chunk 1 complete: placeholder URI policy remains in effect for early stages.
- Chunk 2 complete: metadata schema and source input structure added.
- Chunk 3 complete: deterministic metadata generation script added.
- Chunk 4 complete: IPFS pin helper script and Makefile commands added.
- Chunk 5 complete: deployment script URI input wired and integration assertions added for URI template expectations.
- Chunk 6 complete: concise metadata/IPFS update and redeploy workflow added to README.

Small chunks:
1. Placeholder URI policy in earlier stages.
- Use a mock URI during Stages 1-5.
2. Metadata schema definition.
- Define required JSON fields for each item type.
- Add validation rules for deterministic generation.
3. Metadata generation scripts.
- Generate metadata files from structured source input.
- Ensure stable ordering and reproducible output hashes.
4. IPFS folder workflow scripts.
- Add script path for preparing upload folder and capturing CID.
- Use folder-based URI strategy (`ipfs://<CID>/{id}.json`) rather than per-token URI storage.
 - Enforce ERC-1155 ID filename convention for `{id}` substitution (lowercase, 64-hex-character token ID filenames).
5. Contract/deploy integration.
- Wire final base URI input to deployment flow.
- Add tests/assertions for URI construction expectations.
6. Documentation.
- Add metadata generation, pinning, CID update, and redeploy/update process to README.md.

Sign-off artifacts:
- Reproducible metadata output and CID workflow.
- 100% stage-scope coverage for URI/metadata-related contract logic and scripts.

### Stage 6 - Advanced Mechanics Discovery (Deferred, No Build Yet)
Objective: evaluate and select mechanics only after metadata/IPFS workflow is complete.

Status:
- Chunk 1 complete: threat model rubric added for all candidate mechanics.
- Chunk 2 complete: complexity vs game-value scoring matrix added.
- Chunk 3 complete: shortlist finalized and implementation sequence defined.
- Chunk 4 complete: crafting-only implementation spec defined and locked.

Backlog ideas to evaluate:
1. Crafting recipes (burn specific IDs for upgraded IDs).
2. Seasonal item epochs and rollover mechanics.
3. Soulbound achievement IDs (non-transferable subset).
4. Dynamic metadata state progression.
5. Lootbox mechanics with fairness guarantees (commit-reveal/VRF path).
6. Item staking for XP/material progression.
7. Set bonuses based on ownership combinations.
8. Dynamic shop pricing and sink/buyback mechanics.
9. Gasless UX via relayed/meta transactions.
10. Rental/borrow mechanics with time-bound rights.

Selection process for this stage:
1. Threat model and exploit surface review per candidate.
2. Complexity vs game value scoring.
3. Testing burden estimate and coverage feasibility.
4. Final mechanic shortlist and implementation stage plan.

Threat model rubric (apply to each candidate):
1. Asset risk:
- Can this mechanic mint, burn, lock, or transfer value-bearing items?
2. Privilege risk:
- Does it require elevated roles, and can those privileges be abused?
3. Economic risk:
- Can users extract unfair value through loops, timing, or price manipulation?
4. Liveness risk:
- Can the mechanic be griefed/DoS'd or permanently blocked?
5. Randomness/fairness risk:
- If chance is involved, can outcomes be predicted or manipulated?
6. Integration risk:
- Does it depend on external systems (oracles/bridges/VRF) that add failure modes?

Complexity vs value matrix (1-5 scale, higher is more):
| Mechanic | Game Value | Security Risk | Implementation Complexity | Test Burden | Notes |
| --- | --- | --- | --- | --- | --- |
| Crafting recipes | 5 | 3 | 3 | 4 | Strong fit with current burn model and shop/crafting direction. |
| Seasonal item epochs | 3 | 2 | 2 | 3 | Useful content cadence, moderate user impact. |
| Soulbound achievement IDs | 3 | 2 | 2 | 2 | Straightforward transfer restrictions, low economic risk. |
| Dynamic metadata progression | 4 | 3 | 4 | 4 | Valuable UX, but state-transition logic expands attack surface. |
| Lootbox with fairness guarantees | 4 | 5 | 5 | 5 | High value but highest risk/complexity due to randomness integrity. |
| Item staking for XP/materials | 4 | 4 | 4 | 5 | Broad gameplay depth; reward accounting and lock logic are sensitive. |
| Set bonuses | 3 | 3 | 3 | 3 | Moderate impact, manageable complexity if read-only bonuses. |
| Dynamic shop pricing/sinks | 4 | 4 | 4 | 4 | Valuable economy control; requires careful anti-manipulation design. |
| Gasless meta-transactions | 3 | 4 | 4 | 4 | UX improvement with replay/signature complexity. |
| Rental/borrow rights | 4 | 5 | 5 | 5 | Powerful but complex ownership/rights model and abuse cases. |

Current recommendation (pre-shortlist):
1. Start with `Crafting recipes` as first advanced mechanic.
2. Consider `Soulbound achievement IDs` as low-risk secondary mechanic.
3. Defer high-risk systems (`Lootbox`, `Rental/borrow`) until later iterations.

Approved shortlist and order (locked):
1. `Crafting recipes (burn -> upgraded item)` - first implementation target.
2. `Set bonuses from ownership combinations` - read-only bonus computation preferred.
3. `Soulbound achievement IDs` - non-transferable achievement subset.
4. `Item staking / progression resources` - staged after first three due to accounting complexity.

Active focus now (locked):
1. Only `Crafting recipes (burn -> upgraded item)` is in active implementation scope.
2. All other mechanics are paused until crafting stage is fully completed and signed off.

Crafting implementation progress:
1. Chunk 1 complete: `CraftingShop` scaffold added with admin-gated recipe storage/events and unit tests.
2. Chunk 2 complete: `craft(recipeId, times)` added with atomic transfer->burn->mint flow and unit tests.
3. Chunk 3 complete: deployment wiring added to deploy `CraftingShop` and grant it `MINTER_ROLE` + `BURNER_ROLE`.
4. Chunk 4 complete: integration/invariant coverage added for crafting safety properties.

Crafting implementation spec (execution order):
1. Contract boundary and trust model.
- Add a dedicated `CraftingShop` contract for recipe logic.
- `GameItems` remains token/role primitive; recipe rules stay outside token contract.
- `CraftingShop` receives `MINTER_ROLE` and `BURNER_ROLE` on `GameItems`.

2. Recipe model.
- Each recipe defines:
  - input token IDs and required amounts
  - output token ID and output amount
  - enabled/disabled flag
- Add recipe management functions gated to admin role in `CraftingShop`.

3. Craft execution flow (single transaction).
- User calls `craft(recipeId, times)` on `CraftingShop`.
- `CraftingShop` pulls required inputs from user using ERC-1155 transfer approval.
- `CraftingShop` calls `GameItems.burnBatch(...)` from its own balance.
- `CraftingShop` mints output to user via `GameItems.mint(...)`.
- Enforce atomicity: any failure reverts full flow.

4. Security controls.
- Validate recipe existence, enabled flag, and non-zero amounts.
- Validate `times` bounds and overflow-safe multiplication for required inputs.
- Reject malformed recipes (length mismatch, duplicate IDs policy decision explicit).
- Emit events for recipe creation/update/toggle and successful crafts.

5. Tests and gate criteria.
- Unit tests:
  - recipe CRUD/toggle access control
  - successful craft path
  - insufficient balance / missing approval reverts
  - disabled/unknown recipe reverts
  - multi-craft (`times > 1`) correctness
- Integration tests:
  - deployment wiring grants shop required roles
  - end-to-end craft from player account
- Invariants:
  - crafting cannot reduce total supply except through burner-owned burn path
  - crafting output supply tracks expected recipe conversions
- Stage gate remains 100% lines/functions/branches for `src/` and `script/` (unreachable exceptions documented if any).

Deferred for later consideration:
1. `Gasless UX via relayed/meta transactions`.
2. `Lootbox mechanics with fairness guarantees (VRF)`.
3. Remaining backlog mechanics not in shortlist.

Sign-off artifacts:
- Ranked shortlist and explicit inclusion/exclusion rationale.
- Crafting-only implementation spec approved.

### Working Defaults (Current)
- Scope now: core token + deployment + testing + docs, with metadata/IPFS finalized last.
- Advanced mechanics: intentionally deferred to Stage 6 selection.
- No transition between stages without completed review cycle and gate pass.
- Burn policy default: burns are role-gated with explicit custom functions, not arbitrary holder burn.
- Role assignment default: deployer receives all roles initially; reassignment to external contracts is a later controlled step.
- URI strategy default: folder CID + `{id}.json` template, not per-token URI storage.
