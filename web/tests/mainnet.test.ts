import test from "node:test";
import assert from "node:assert/strict";
import { decodeAbiParameters, decodeFunctionData, parseAbi, parseAbiParameters, type Address } from "viem";
import { encodeImdSwap, requireMainnetRelease } from "../src/mainnetSwap";
import { IMD, UNIVERSAL_ROUTER, CANDIDATE_DEPLOYMENT, successorFee, verifiedMatureQuota } from "../src/mainnet";
test("mainnet writes remain blocked; no Sepolia route or native funding in unsigned plans",()=>{
  assert.equal(CANDIDATE_DEPLOYMENT,null);assert.throws(requireMainnetRelease,/disabled/);
  const hook="0x1111111111111111111111111111111111111111" as Address;
  for(const token of ["0x2222222222222222222222222222222222222222","0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"] as Address[]) {
    for(const mode of ["buyExactIn","buyExactOut","sellExactIn","sellExactOut"] as const) {
      const plan=encodeImdSwap(token,hook,mode,100n,1n,999n);
      assert.equal(plan.to,UNIVERSAL_ROUTER);assert.equal(plan.value,0n);
      const decoded=decodeFunctionData({abi:parseAbi(["function execute(bytes commands,bytes[] inputs,uint256 deadline) payable"]),data:plan.data});
      assert.equal(decoded.args[0],"0x10");
      const [actions,params]=decodeAbiParameters(parseAbiParameters("bytes,bytes[]"),decoded.args[1][0]);
      assert.equal(actions,mode.endsWith("ExactIn")?"0x060c0f":"0x080c0f");
      const [input]=decodeAbiParameters(parseAbiParameters("address,uint256"),params[1]);
      const [output]=decodeAbiParameters(parseAbiParameters("address,uint256"),params[2]);
      assert.equal(input.toLowerCase(),(mode.startsWith("buy")?IMD:token).toLowerCase());
      assert.equal(output.toLowerCase(),(mode.startsWith("buy")?token:IMD).toLowerCase());
    }
  }
  assert.throws(()=>encodeImdSwap(IMD,hook,"buyExactIn",1n,1n,999n));
});
test("IMD treasury budgets preserve raw-unit conservation and conservative rounding",()=>{
  for(let amount=0n;amount<20000n;amount++) {
    const b=successorFee("buyExactIn",amount);assert.equal(b.poolLeg+b.fee,amount);
    const s=successorFee("sellExactOut",amount);assert.equal(s.poolLeg-s.fee,amount);
  }
});

test("mature quota never counts this block's buys and final bypass remains permanent",()=>{
  assert.equal(verifiedMatureQuota(200n,100n,10n,2000n,false),10n);
  assert.equal(verifiedMatureQuota(200n,200n,10n,2000n,false),30n);
  assert.equal(verifiedMatureQuota(200n,0n,10n,2000n,false),0n);
  assert.equal(verifiedMatureQuota(0n,0n,100n,10000n,true),(1n<<256n)-1n);
  assert.throws(()=>verifiedMatureQuota(100n,101n,0n,2000n,false),/ledger/);
});
