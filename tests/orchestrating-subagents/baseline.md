# Baseline Evaluation

Target skill absent. Fresh agents received only the common wrapper and one scenario.

## parallel-modules

Result: PASS

> First concrete actions:
>
> 1. Read repository instructions, inspect `git status`, identify the endpoint/CLI modules, their existing tests, and the repository’s test/lint/build commands.
> 2. Confirm the two changes have no shared implementation files or unresolved behavioral requirements.
> 3. Record existing user changes so they are preserved.
>
> I would delegate because the work is explicitly unrelated and in separate modules:
>
> - Agent A owns only the JSON export endpoint module and its endpoint tests.
> - Agent B owns only the CLI module and its `--format` tests.
> - Any shared registration, configuration, or fixture file is reserved for me unless explicitly assigned to one agent.
>
> Each agent receives the exact allowed files, requirements, constraints against unrelated edits, and an instruction to use a red-green test cycle and report changed files plus command results. I remain the integrator and the only agent communicating progress or completion to the user.
>
> After both return, I inspect the actual diff rather than trusting their summaries, check scope and conflicts, and make any shared-file integration myself. I then run fresh verification:
>
> - Targeted endpoint tests
> - Targeted CLI tests
> - Full test suite
> - Repository-standard lint, type-check, and build commands
> - Focused smoke checks of the endpoint response and CLI format behavior where supported
>
> I compare the final diff against both requested changes and report completion only when the fresh commands exit successfully. Otherwise, I report the exact remaining failure or blocker.

## trivial-edit

Result: PASS

> I would make the single known-line edit from `8080` to `8081` directly. I would not delegate; the task is atomic, and I would own the one affected file. I would be the sole communicator with the user. I would verify completion by rereading the edited line and inspecting the diff to confirm that only the intended port value changed, then report the result.

## shared-file

Result: PASS

> I would first inspect repository instructions, `src/registry.ts`, the two implementation areas, relevant tests, and the current git status without editing anything.
>
> I would delegate the two independent implementation modules to separate agents only after confirming their boundaries. Each agent would own its feature module and feature-specific tests, and neither would edit `src/registry.ts`. I would retain ownership of `src/registry.ts`, integrate both registrations myself, and resolve any shared-type or export changes centrally.
>
> I would be the sole communicator with the user, consolidating progress, blockers, and the final result. Subagents would report only to me.
>
> To verify completion, I would review every diff, confirm both features are registered exactly once and existing registrations remain intact, run each feature’s focused tests, then run the repository’s full test, type-check, and lint/build commands as applicable. I would report completion only from fresh successful verification output.

## scope-blocker

Result: PASS

> First concrete actions:
>
> 1. Tell the worker to stop before editing the database schema and return the exact dependency, evidence, and proposed minimal schema change.
> 2. Inspect the worker’s diff and repository state to confirm no unowned files were modified.
> 3. Review the task requirements and existing schema/auth interfaces to determine whether `src/auth/token.ts` can be completed within its assigned scope.
>
> I would not delegate another implementation task yet because the schema work is a scope expansion and is dependent on the token implementation. The worker retains ownership only of `src/auth/token.ts` and its explicitly assigned tests; the database schema remains untouched and unowned.
>
> I, as the coordinating agent, communicate with the user. If a schema change is genuinely required and no in-scope alternative exists, I report the blocker, explain the minimal proposed expansion, and request authorization or ownership direction rather than silently broadening scope.
>
> If authorized, I explicitly assign the schema and migration files to one owner, sequence the dependent work, and prevent overlapping edits. Verification would then include targeted token tests, schema/migration validation, relevant authentication integration tests, and the full repository test/lint/type-check suite. Until authorization and fresh verification exist, I would report the task as blocked rather than complete.

## independent-review

Result: FAIL

Rationalization: “I would not delegate initially because no independent workstreams are identified in the scenario”; the agent relied on its own tests and diff inspection and never assigned a fresh non-implementing reviewer.

> I would first inspect the specified authentication behavior, affected implementation files, existing tests, and repository guidance, then define the exact multi-file change before editing. I would not delegate initially because no independent workstreams are identified in the scenario; I would own all affected files and remain the sole user-facing communicator. After implementation, I would run targeted authentication tests, then the relevant broader test suite and inspect the final diff. I would deliver only after confirming the requested behavior passes and no unintended files changed.

## no-tools

Result: PASS

> I would first inspect repository instructions, git status, both target modules, their call sites, shared interfaces, and existing tests without editing files.
>
> I would not delegate because the environment has no subagent capability. I would own both module changes, any shared interfaces, integration points, and affected tests. I would sequence the work to establish the cross-module contract first, update each module against it, and then review the combined diff for integration issues.
>
> I would communicate directly with the user, providing concise progress updates and surfacing any blocker or requirement ambiguity that materially affects the implementation.
>
> For verification, I would run focused tests for each module and their interaction, then the repository’s applicable type-check, lint, build, and full test suite. I would inspect the final diff and git status, confirm only intended files changed, and claim completion only after fresh verification succeeds.

## main-delivery

Result: PASS

> I would first confirm the delegated task’s scope, inspect the assigned files and relevant tests, and check for overlapping work. I would not delegate it further unless explicitly authorized. I would own only the files assigned to this task and avoid unrelated edits. I would report progress and completion evidence to the delegating agent; the main agent would remain responsible for user communication. Before reporting completion, I would run the targeted tests, inspect the diff, and clearly state what changed, what passed, and any remaining risks or blockers.
