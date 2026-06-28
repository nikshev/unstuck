const { Connection, Keypair, PublicKey } = require('@solana/web3.js');
const { getAssociatedTokenAddress, getAccount, transfer } = require('@solana/spl-token');
const fs = require('fs');

const conn = new Connection('https://api.devnet.solana.com', 'confirmed');
const payer = Keypair.fromSecretKey(new Uint8Array(JSON.parse(fs.readFileSync('throwaway.json'))));
const { mint, recipient } = JSON.parse(fs.readFileSync('token.json'));
const mintPk = new PublicKey(mint), recipientPk = new PublicKey(recipient);

async function main() {
  // Derive the recipient's associated token account (ATA) address
  const dest = await getAssociatedTokenAddress(mintPk, recipientPk);
  console.log('Recipient token account (derived):', dest.toBase58());

  // BUG: assume it already exists — look it up, then send 10 tokens
  const acc = await getAccount(conn, dest);          // <-- throws here
  console.log('Recipient balance:', acc.amount);

  const source = await getAssociatedTokenAddress(mintPk, payer.publicKey);
  const sig = await transfer(conn, payer, source, dest, payer, 10_000_000);
  console.log('Sent (unexpected):', sig);
}
main().catch(e => {
  console.error('FAILED:', e.name);
  console.error('-> The recipient has never held this token, so their associated token account does not exist.');
});
