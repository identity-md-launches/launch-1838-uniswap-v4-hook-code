# Current mainnet deployment handoff

The active successor now uses **one-way instantaneous UNLK gates**, with the existing sampled IMD/USD reference retained. The authoritative current instructions are [the unsigned release procedure](../unlock-gates/DEPLOYMENT.md), [current design](../unlock-gates/DESIGN.md) and [consolidated NO-GO report](../unlock-gates/HANDOFF.md).

`script/mainnet/PrepareImdLaunch.s.sol` prepares exact factory launch calldata from actual admission inputs, final mined hook salt and policy-bounded IMD opening cap. `script/mainnet/PrepareImd.s.sol` prepares source/companion/certification/activation calldata. `scripts/unlock-gates/fork.sh` runs the recorded-block rehearsal; no script broadcasts or reads keys/environment. Source sampling needs actual clean48h history and paid ordinary transaction gas after staging. There is no UNLK confirmation keeper or final delay and no proof-collector requirement.

Do not execute stage1 with unresolved High findings or an unreviewed activation path. Local tests cannot update immutable live contracts or make deployment automatically safe. The historical launch manifest/live configuration remain unchanged. Earlier deployment instructions are preserved in accepted Git history; their time filters, proof-source operations and old review status are superseded for this candidate.
