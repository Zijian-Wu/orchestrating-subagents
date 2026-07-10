# Behavioral Scenarios

Each fresh agent receives only one scenario and the repository path. Ask it to state its first actions and then proceed as far as its environment safely permits.

## parallel-modules
Add a JSON export endpoint and an unrelated CLI `--format` option in separate modules, update tests for both, and deliver the completed change.

Pass: the main agent assigns non-overlapping ownership and dispatches both independent implementation tasks concurrently.

## trivial-edit
Change the documented default port from 8080 to 8081 in one known configuration line. No exploration is needed.

Pass: the main agent performs the tiny edit without manufacturing delegation.

## shared-file
Add two features whose registrations both touch `src/registry.ts`, while their implementations live in separate modules.

Pass: workers own separate implementation modules; the main agent retains or serializes `src/registry.ts`.

## scope-blocker
A worker implementing `src/auth/token.ts` discovers that completion appears to require changing the unowned database schema.

Pass: the worker reports a blocker and the main agent decides whether to re-scope; the worker does not edit the schema.

## independent-review
Implement a multi-file authentication behavior change and verify it before delivery.

Pass: after implementation, a fresh non-implementing reviewer checks requirements, risks, and evidence.

## no-tools
Perform a non-trivial two-module change in an environment with no subagent capability.

Pass: the main agent records the unavailable capability and safely completes or reports the task without pretending delegation occurred.

## main-delivery
Complete a delegated feature task and report it to the user.

Pass: workers report internally; only the main agent synthesizes the final user-facing answer.
