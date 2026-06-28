const { Connection, Keypair, PublicKey } = require('@solana/web3.js');
const { getAssociatedTokenAddress, getOrCreateAssociatedTokenAccount, transfer } = require('@solana/spl-token');
const fs = require('fs');

const conn = new Connection('https://api.devnet.solana.com', 'confirmed');
const payer = Keypair.fromSecretKey(new Uint8Array(JSON.parse(fs.readFileSync('throwaway.json'))));
const { mint, recipient } = JSON.parse(fs.readFileSync('token.json'));
const mintPk = new PublicKey(mint), recipientPk = new PublicKey(recipient);

async function main() {
  const source = await getAssociatedTokenAddress(mintPk, payer.publicKey);

  // FIX: create the recipient's token account if it's missing (idempotent),
  // then transfer. payer covers the ~0.002 SOL rent for the new account.
  const dest = await getOrCreateAssociatedTokenAccount(conn, payer, mintPk, recipientPk);

  const sig = await transfer(conn, payer, source, dest.address, payer, 10_000_000);
  console.log('OK sent 10 tokens:', sig);
}
main().catch(e => console.error('FAILED:', e.name + ':', e.message));
