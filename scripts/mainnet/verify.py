#!/usr/bin/env python3
"""Read-only offline verification of recorded Ethereum runtime and source evidence."""
import hashlib, json, pathlib, re, subprocess
root=pathlib.Path(__file__).resolve().parents[2]
folder=root/'docs/mainnet/network'
record=json.loads((folder/'mainnet.json').read_text())
source=(root/'test/mainnet/MainnetRuntime.sol').read_text()
for name in ['factory','manager','router','quoter','permit2','imd','ethUsd','fees','registry']:
    match=re.search(r'function\s+'+name+r'\(\).*?return hex"([0-9a-fA-F]+)";',source,re.S)
    assert match, name+' recorded runtime missing'
    runtime='0x'+match.group(1)
    digest=subprocess.check_output(['cast','keccak',runtime],text=True).strip()
    assert digest==record['contracts'][name]['codehash'], name+' runtime hash'
    assert len(match.group(1))//2==record['contracts'][name]['bytes'], name+' length'
    if name in ('factory','imd'):
        verified=json.loads((folder/(name+'.verified.json')).read_text())
        assert verified['runtimeMatch'] in ('match','exact_match') and verified['creationMatch'] in ('match','exact_match')
        assert verified['runtimeBytecode']['onchainBytecode'].lower()==runtime.lower()
        assert verified['stdJsonInput']['sources'], name+' exact compiler sources absent'
    print(name,record['contracts'][name]['address'],digest,'OK')
standard=json.loads((folder/'standard-source-verification.json').read_text())
for name in ['router','quoter','permit2','manager']:
    assert standard[name]['sourceRuntimeMatchesRpc'] is True
    assert standard[name]['recordedRuntimeKeccak']==record['contracts'][name]['codehash']
    assert standard[name]['runtimeMatch'] in ('match','exact_match')
print('Standard router/Quoter/Permit2/Manager source records match recorded RPC runtimes.')
policy=json.loads((folder/'policies.json').read_text())
matching=[p for p in policy['policies'] if p['kind']=='univ4_hook'
          and p['params'].get('chainId')==1
          and record['contracts']['imd']['address'].lower() in p['params'].get('pairedCurrencyAllowlist',[])]
latest=max(matching,key=lambda p:p['version'])
assert 12500 in latest['params']['feeTiers']
assert latest['params']['initialMarketCaps'][record['contracts']['imd']['address'].lower()]=='2500000000000000000000'
print('Recorded mainnet IMD hook policy',latest['version'],'fee12500, default2500IMD OK')
print('Sourcify match records checked, not an independent recompilation or audit. No usable oracle safety certification.')
