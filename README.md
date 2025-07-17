# StarGuard module

A module for the Sky Protocol that enables permissionless execution of Star Spells in a separate transaction after they were whitelisted by the core spell.

## Overview

The StarGuard module resolves multiple problems with direct inclusion of the Star spells into the Core spell, the main of which is the bottleneck caused by the size of the core spell "cast" transaction (limited by the max block size). This module removes the bottleneck by allowing permissionless execution of Star spells after they has been "approved" by the core spell. 

In other words, it replaces current flow:

```
1st transaction: Anyone ──► Core Spell ─┬─► SubProxy A ──executes──► Star Spell A1
                                        └─► SubProxy B ──executes──► Star Spell B1
```

with the updated flow:

```
1st transaction: Anyone ──► Core Spell ─┬─► StarGuard A ──approves──► Star Spell A1
                                        └─► StarGuard B ──approves──► Star Spell B1
2nd transaction: Anyone ──────────────────► StarGuard A ──executes──► Star Spell A1
3nd transaction: Anyone ──────────────────► StarGuard B ──executes──► Star Spell B1
```

## Features

- Codehash validation of the code, at the time of the execution
- Configurable Star spell expiration deadline, after which the spell no longer can be executed
- Validation that Star spell did not remove StarGuard from the authorized contracts

## Testing and linting

- To test, provide required env variables, then use `make test`
- To lint, use `make lint`
- To verify [solidity natspec](https://docs.soliditylang.org/en/latest/natspec-format.html), use `make spec`

