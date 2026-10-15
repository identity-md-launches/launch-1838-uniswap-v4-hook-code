import { useEffect, useState } from "react";
import { formatEther, parseEther } from "viem";
import { CANDIDATE_DEPLOYMENT, NEXT_THRESHOLDS, NEXT_RATES, NFT_BENEFICIARY, fee75, buyPoolInput } from "./candidate";
import { client } from "./config";
import { useWallet } from "./wallet";
import { readCandidate, type CandidateSnapshot } from "./candidateReader";
import { NftGallery } from "./NftGallery";

export function NextRelease() {
  const wallet = useWallet();
  const [snapshot,setSnapshot]=useState<CandidateSnapshot | null>(null);
  const [readError,setReadError]=useState("");
  useEffect(()=>{
    setSnapshot(null);setReadError("");
    if(!CANDIDATE_DEPLOYMENT)return;
    let active=true;
    const refresh=()=>readCandidate(CANDIDATE_DEPLOYMENT,client,wallet.address).then(value=>{if(active)setSnapshot(value);}).catch(e=>{if(active){setSnapshot(null);setReadError(e instanceof Error?e.message:"Candidate read failed");}});
    void refresh();const timer=setInterval(refresh,30000);
    return()=>{active=false;clearInterval(timer);};
  },[wallet.address,wallet.receiptVersion]);
  const personal=snapshot?.wallet?.address.toLowerCase()===wallet.address?.toLowerCase()?snapshot?.wallet:null;
  const [eth, setEth] = useState("1");
  const [buy, setBuy] = useState(true);
  let summary: {base:bigint; fee:bigint; net:bigint} | undefined;
  let error = "";
  try {
    if (!/^\d+(?:\.\d{0,18})?$/.test(eth) || eth.length > 40) throw new Error();
    const amount = parseEther(eth); const base = buy ? buyPoolInput(amount) : amount;
    summary = {base,fee:fee75(base),net:buy ? base+fee75(base) : base-fee75(base)};
  } catch { error="Enter a non-negative ETH amount with at most 18 decimals."; }
  return <div className="next-release">
    <div className="page-intro"><p className="small muted">Source preview · undeployed</p><h1>Next release & NFT treasury</h1><p>The 0.75% treasury fee and expanded unlock ladder are candidate code. Standard-router attribution is unresolved; independent review is pending. Candidate swaps are unavailable.</p></div>
    <div className="notice">The Trade, My Unlock and Milestones tabs still show the existing live Sepolia rules: 25% initially, seven rates and no NFT hook fee. New rules require a separately reviewed release.</div>
    <section className="panel candidate-vault"><div className="panel-heading"><h2>Candidate fee vault</h2><span className="small muted">Not deployed</span></div>
      {readError && <p role="alert">{readError}</p>}
      <dl className="wallet-ledger">{[
        ["Accrued treasury ETH",snapshot?.vault.accrued],["Withdrawn treasury ETH",snapshot?.vault.withdrawn],
        ["Claimable ETH in vault",snapshot?.vault.claimable],["Unredeemed PoolManager claims",snapshot?.vault.pendingClaims],
        ["ETH donations",snapshot?.vault.donations]
      ].map(([label,value])=><div key={String(label)}><dt>{String(label)}</dt><dd>{typeof value==="bigint"?formatEther(value):"Unavailable"}</dd></div>)}</dl>
      {snapshot && <p className="small muted">Sepolia block {snapshot.block.toString()} · read {new Date(snapshot.readAt).toLocaleTimeString()}</p>}
      <p>These are unavailable readings, not zero balances. Once deployed, accrual, pending claims, redeemed funds and donations are separate amounts. Only <a href={`https://sepolia.etherscan.io/address/${NFT_BENEFICIARY}`} target="_blank" rel="noreferrer">the beneficiary ↗</a> can withdraw to itself.</p>
      <p>No marketplace integration, automatic purchase, buyback, burn, floor-price or yield promise.</p>
    </section>
    <section className="panel"><div className="panel-heading"><h2>Candidate wallet ledger</h2><span className="small muted">Sepolia · undeployed</span></div>
      <dl className="wallet-ledger">{[["Wallet balance",personal?.balance],["Eligible acquisitions · E",personal?.E],["Executed sales · S",personal?.S],["Sellable now",personal?.sellable]].map(([label,value])=><div key={String(label)}><dt>{String(label)}</dt><dd>{typeof value==="bigint"?formatEther(value):"Unavailable"}</dd></div>)}</dl>
      <p>Verified FDV: {snapshot?.fdv !== null && snapshot?.fdv !== undefined ? `$${formatEther(snapshot.fdv)}` : "Unavailable"}. {snapshot?.oracleError ?? "Candidate chain readings begin only after a reviewed deployment is configured."}</p>
      <p>Existing live wallet balances, claims and sync are available under <a href="#/unlock">My Unlock</a>. Their rights belong to the existing contracts.</p>
    </section>
    <section className="panel candidate-fees"><div className="panel-heading"><h2>Fee calculator</h2><span className="small muted">Illustration, not a swap quote</span></div>
      <div className="nft-toolbar"><label>Direction <select value={buy?"buy":"sell"} onChange={e=>setBuy(e.target.value==="buy")}><option value="buy">Buy · gross ETH budget</option><option value="sell">Sell · executed ETH pool output</option></select></label><label>ETH <input inputMode="decimal" value={eth} onChange={e=>setEth(e.target.value)} aria-invalid={!!error}/></label></div>
      {error ? <p role="alert">{error}</p> : summary && <dl className="wallet-ledger"><div><dt>Executed ETH pool leg</dt><dd>{formatEther(summary.base)}</dd></div><div><dt>75 bps hook fee · floor to wei</dt><dd>{formatEther(summary.fee)}</dd></div><div><dt>{buy?"Gross spent":"Net received"}</dt><dd>{formatEther(summary.net)}</dd></div></dl>}
      <p>The pool fee remains 1.25% (1% payer / 0.25% IMD). The additional fee is 0.75% of the executed ETH pool leg and persists after full unlock. Nominal 2% is not an exact effective cost. Partial fills pay only on execution; refunds retain no fee.</p>
      <p>Generic quotes do not prove wallet sell capacity. A reviewed transaction must also verify the actual wallet balance, eligible acquisitions E, executed sales S and Q = max(0, floor(E × p / 10000) − S).</p>
    </section>
    <section className="panel"><div className="panel-heading"><h2>Candidate unlock ladder</h2><span className="small muted">20% initially</span></div><ol className="candidate-tiers">{NEXT_THRESHOLDS.map((target,index)=><li key={target}><strong>${target.toLocaleString("en-US")}</strong><span>{NEXT_RATES[index+1]/100}%</span><small>{index===15?"24h · permanent bypass for everyone":"6h confirmation"}</small></li>)}</ol><p>Sequential confirmations; 2h TWAP warm-up, Chainlink freshness and locked seed depth, 4m cadence and 10m maximum gap. Invalid data cannot advance or revoke rights. Transfers create no eligibility. Other pools can bypass this hook’s quota.</p></section>
    <NftGallery/>
  </div>;
}
