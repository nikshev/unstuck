const { Connection, Keypair, Transaction, SystemProgram, PublicKey } = require('@solana/web3.js');
const fs = require('fs');

const RPC = 'https://api.devnet.solana.com';
const conn = new Connection(RPC, 'confirmed');
const payer = Keypair.fromSecretKey(new Uint8Array(JSON.parse(fs.readFileSync('throwaway.json'))));

async function main() {
  // 1) Grab a blockhash NOW
  const { blockhash } = await conn.getLatestBlockhash();
  console.log('Got blockhash:', blockhash);

  // 2) Build a tiny self-transfer tx and pin it to that blockhash
  const tx = new Transaction();
  tx.recentBlockhash = blockhash;
  tx.feePayer = payer.publicKey;
  tx.add(SystemProgram.transfer({ fromPubkey: payer.publicKey, toPubkey: payer.publicKey, lamports: 1 }));
  tx.sign(payer);

  // 3) Wait long enough for the blockhash to EXPIRE (~90s)
  console.log('Waiting 95s so the blockhash expires...');
  await new Promise(r => setTimeout(r, 95000));

  // 4) Try to send -> this is where it blows up
  try {
    const sig = await conn.sendRawTransaction(tx.serialize());
    console.log('Sent (unexpected):', sig);
  } catch (e) {
    console.error('FAILED:', e.message);
  }
}
main();
