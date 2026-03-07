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

Small chunks:
1. Replace README template with project-specific docs.
2. Add role/governance operations guide (including delayed admin lifecycle).
3. Add deployment + verification playbooks.
4. Add testing/coverage troubleshooting guide.

Sign-off artifacts:
- Operator-ready docs for local/testnet/mainnet workflows.
- 100% stage-scope coverage target maintained.

### Stage 5 - Advanced Mechanics Discovery (Deferred, No Build Yet)
Objective: evaluate and select mechanics without implementation commitment yet.

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

Sign-off artifacts:
- Ranked shortlist and explicit inclusion/exclusion rationale.
- Next-stage implementation spec drafted from selected mechanics.

### Stage 6 - Metadata Build Pipeline + IPFS URI Flow (Finalized Later)
Objective: produce deterministic metadata and publishable IPFS-backed URIs after core mechanics direction is settled.

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
- Add runbook for metadata generation, pinning, CID update, and redeploy/update process.

Sign-off artifacts:
- Reproducible metadata output and CID workflow.
- 100% stage-scope coverage for URI/metadata-related contract logic and scripts.

### Working Defaults (Current)
- Scope now: core token + deployment + testing + docs, with metadata/IPFS finalized last.
- Advanced mechanics: intentionally deferred to Stage 5 selection.
- No transition between stages without completed review cycle and gate pass.
- Burn policy default: burns are role-gated with explicit custom functions, not arbitrary holder burn.
- Role assignment default: deployer receives all roles initially; reassignment to external contracts is a later controlled step.
- URI strategy default: folder CID + `{id}.json` template, not per-token URI storage.
