const { Connection, Keypair, Transaction, SystemProgram } = require('@solana/web3.js');
const fs = require('fs');

const conn = new Connection('https://api.devnet.solana.com', 'confirmed');
const payer = Keypair.fromSecretKey(new Uint8Array(JSON.parse(fs.readFileSync('throwaway.json'))));

async function main() {
  // FIX: fetch the blockhash RIGHT BEFORE sending, and track lastValidBlockHeight
  const { blockhash, lastValidBlockHeight } = await conn.getLatestBlockhash();
  console.log('Fresh blockhash:', blockhash);

  const tx = new Transaction();
  tx.recentBlockhash = blockhash;
  tx.lastValidBlockHeight = lastValidBlockHeight;
  tx.feePayer = payer.publicKey;
  tx.add(SystemProgram.transfer({ fromPubkey: payer.publicKey, toPubkey: payer.publicKey, lamports: 1 }));
  tx.sign(payer);

  const sig = await conn.sendRawTransaction(tx.serialize());
  // confirm against the SAME blockhash window -> no 'Blockhash not found'
  await conn.confirmTransaction({ signature: sig, blockhash, lastValidBlockHeight }, 'confirmed');
  console.log('OK confirmed:', sig);
}
main().catch(e => console.error('FAILED:', e.message));
