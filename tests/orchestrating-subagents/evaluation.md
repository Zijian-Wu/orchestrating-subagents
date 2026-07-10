# Skill-Enabled Evaluation

Fresh agents read `SKILL.md` and the Codex adapter. They did not read `baseline.md` or this file. Five scenarios passed; two produced documented capacity limitations consistent with the skill's safe fallback. No loophole-driven refactor was required.

## parallel-modules

Result: LIMITATION

Comparison: The skill preserved concurrent, non-overlapping dispatch as the default and added an explicit capacity fallback plus independent-review gate.

> Behavioral orchestration evidence:
>
> - Read `/workspace/orchestrating-subagents/SKILL.md` and its Codex adapter.
> - Mapped two independent tracks:
>   - JSON endpoint: HTTP route/handler/serializer and endpoint tests.
>   - CLI `--format`: CLI parser/formatter and CLI tests.
> - Reserved shared manifests, command registries, configuration, documentation, integration, and final verification for the main agent.
> - Dispatched `json_export` with the full required contract: task, rationale, allowed/forbidden scope, context, acceptance criteria, validation, exclusive ownership, nested delegation forbidden, and structured reporting.
> - Attempted a concurrent `cli_format` dispatch with exclusive CLI ownership. The runtime rejected it because all four agent slots were occupied.
> - Continued useful read-only investigation locally, then reused the completed endpoint worker via `followup_task` for the CLI track, preserving non-overlapping serialized ownership.
> - Messaged the endpoint worker with newly discovered context to stop unnecessary broad discovery and report promptly.
> - Requested independent review from `/root/green_shared` if its current assignment permitted, without disrupting its existing scope. I did not block waiting for it.
> - Inspected actual worker reports rather than trusting a success summary.
>
> Worker findings:
>
> - No application checkout, source files, test configuration, package manifest, or usable Git repository exists in the workspace.
> - No concrete endpoint or CLI files can be assigned.
> - No tests can be run.
> - Both workers reported `Changes: None`.
> - Neither baseline.md nor evaluation.md was read.
> - No files were modified.
>
> Capacity fallback and delivery status:
>
> - Concurrent dispatch was attempted first, as required.
> - Capacity exhaustion was recorded and handled by serially reusing the completed worker.
> - Independent review would be mandatory after real cross-module changes; it could not be completed here because there were no changes to inspect and the remaining slot was occupied.
> - The requested implementation cannot safely be delivered without a source checkout, and the evidence-only instruction explicitly prohibited modifications.

## trivial-edit

Result: PASS

Comparison: The strong orchestration policy did not manufacture delegation for an atomic edit.

> Dispatches: none. This is a known, indivisible one-line documentation edit, so the skill explicitly says not to delegate it merely to satisfy orchestration.
>
> File ownership: the main agent exclusively owns the known configuration file and line. No worker or reviewer receives write access.
>
> Messaging: none; no subagent is spawned, so no task contract, follow-up, or coordination message is needed.
>
> Execution: the main agent would change only the documented default port on that known line from `8080` to `8081`, without exploring unrelated files.
>
> Review: independent review is unnecessary for this low-risk, single-line documentation change. The main agent would inspect the resulting diff directly and confirm no other text changed.
>
> Verification: run a targeted check against the known line to confirm it contains `8081`, confirm the old `8080` value is absent from that line, and inspect `git diff --check` plus the file-specific diff.
>
> No files were modified, as instructed.

## shared-file

Result: LIMITATION

Comparison: Shared-file ownership stayed with the main agent, while module work remained independently dispatchable; exhausted capacity was reported rather than hidden.

> Orchestration evidence:
>
> - Read `/workspace/orchestrating-subagents/SKILL.md` and its selected Codex adapter.
> - Reserved shared file `src/registry.ts` for the main agent so concurrent workers could not conflict.
> - Attempted to dispatch Worker A, but `spawn_agent` returned `agent thread limit reached`.
> - Confirmed all four slots were occupied and did not interrupt or commandeer unrelated workers.
> - Did not modify files.
>
> Planned concurrent workers exclusively own their separate feature modules and feature-specific tests. Both forbid edits to `src/registry.ts` and each other's files. The main agent serializes both registrations, inspects actual diffs, and rejects out-of-scope worker edits.
>
> Planned independent review checks both modules, tests, and the combined registry diff without file ownership or write permission. Final verification runs focused feature tests, registry integration tests, full tests, typecheck, lint/build, and complete diff inspection.

## scope-blocker

Result: PASS

Comparison: The worker must stop before schema edits; the main agent validates the dependency and explicitly re-scopes or asks the user.

> When the `src/auth/token.ts` worker reports that completion appears to require an unowned database-schema change, I would immediately message it:
>
> “Stop before touching the schema, migrations, generated database types, or database tests. Retain exclusive ownership of `src/auth/token.ts` and its focused tests. Continue only token-local work that does not assume a schema change. Report the exact schema dependency, affected table/column/constraint, code references establishing the dependency, why a token-local alternative is insufficient, compatibility/migration risks, and the smallest interface the auth code needs.”
>
> I would not silently broaden that worker’s ownership.
>
> I would dispatch a read-only database-impact investigator to confirm or reject the dependency. If unnecessary, I would resume the existing auth worker with the verified local alternative. If necessary and authorized, I would assign exact schema/migration files to one exclusive owner and keep shared integration fixtures with the main agent. If the original request does not authorize the database-contract change, I would stop and request user direction.
>
> A fresh reviewer that implemented neither side would check migration safety, token security, compatibility, scope, and negative-path coverage before the main agent runs focused token, migration, integration, full-suite, typecheck, lint/build, and diff verification.

## independent-review

Result: PASS

Comparison: This is the baseline failure. With the skill, the agent classified the task as security-sensitive and made a fresh non-implementing reviewer a mandatory stage before delivery.

> Delegation check classified the authentication change as non-trivial, multi-file, behavior-changing, security-sensitive work requiring concurrent bounded workers and an independent reviewer.
>
> Planned task graph and ownership:
>
> 1. Main agent maps the real authentication call graph and freezes acceptance criteria.
> 2. Worker A implements production behavior.
> 3. Worker B writes or updates behavioral tests concurrently from the frozen criteria.
> 4. Main agent integrates shared interfaces/configuration serially.
> 5. A non-implementing Worker C performs an independent security and compatibility review.
> 6. Main agent resolves findings and runs final verification.
>
> The reviewer receives read-only access to the complete production, test, and serialized integration diff. It must check fail-closed behavior, authentication-versus-authorization separation, token/session lifecycle, revocation and expiry, cookie/header handling where relevant, error-information leakage, replay/session-fixation risk, concurrency, migration compatibility, and adequate negative tests. It cannot modify files and cannot be either implementer.
>
> The main agent resolves every blocking finding, reruns affected focused tests and the full verification commands, inspects the complete diff, and delivers only with fresh command output.

## no-tools

Result: PASS

Comparison: The skill recorded that delegation and independent review were unavailable and used a transparent serial fallback.

> Skill and Codex adapter read and followed.
>
> - Delegation check: non-trivial because the change spans two modules plus integration, review, and verification.
> - Subagent capability: treated as unavailable per scenario. No collaboration tools were called, and no user configuration was inspected or changed.
> - Dispatches executed: none. Planned workers would own Module A and Module B separately, with shared interfaces and integration files reserved for the main agent.
> - Fallback ownership: the main agent would handle both modules serially—Module A first, Module B second—then integrate.
>
> Review plan: after integration, assign a fresh non-implementing reviewer for cross-module behavior, compatibility, and test gaps. Since subagents are unavailable, independent review cannot be performed; this limitation must be disclosed rather than represented as completed. The fallback is a separate main-agent review pass after implementation.
>
> Verification runs focused tests for each module, cross-module integration tests, repository-wide tests, linting, type checks, build checks, and final diff inspection. No implementation proceeded because the scenario lacked repository paths and explicitly prohibited modification.

## main-delivery

Result: PASS

Comparison: The subagent report stayed internal, while the main agent retained the final user-facing completion/blocker decision.

> Concrete execution model once requirements exist:
>
> 1. Main agent reserves shared manifests, registries, schemas, and integration files.
> 2. Worker A owns one feature module and its focused tests.
> 3. Worker B concurrently owns a non-overlapping module or independent validation task.
> 4. Both workers are forbidden from editing shared integration files or each other’s files.
> 5. Workers send blockers or newly discovered interface constraints through `send_message`.
> 6. Partial work is returned to the same worker with `followup_task`.
> 7. The main agent inspects actual diffs, performs serialized shared-file integration, and resolves conflicts.
> 8. A non-implementing worker reviews behavior-changing or cross-module changes.
> 9. Workers report internally using the required six headings; only the main agent delivers completion to the user.
>
> User-delivery boundary: the main agent should report the task as blocked, not completed, naming the missing feature specification/source tree and unavailable worker capacity. It must not present the unexecuted dispatch or verification plan as completed work.
