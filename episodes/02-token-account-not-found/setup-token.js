// One-time prep for the episode: create a token mint on devnet, give the sender
// a balance, and generate a FRESH recipient that has NO token account yet.
const { Connection, Keypair, LAMPORTS_PER_SOL } = require('@solana/web3.js');
const { createMint, getOrCreateAssociatedTokenAccount, mintTo } = require('@solana/spl-token');
const fs = require('fs');

const conn = new Connection('https://api.devnet.solana.com', 'confirmed');
const payer = Keypair.fromSecretKey(new Uint8Array(JSON.parse(fs.readFileSync('throwaway.json'))));

(async () => {
  const recipient = Keypair.generate();                      // brand-new, no ATA
  const mint = await createMint(conn, payer, payer.publicKey, null, 6);
  const senderAta = await getOrCreateAssociatedTokenAccount(conn, payer, mint, payer.publicKey);
  await mintTo(conn, payer, mint, senderAta.address, payer, 1_000_000_000); // 1000 tokens
  fs.writeFileSync('token.json', JSON.stringify({
    mint: mint.toBase58(), recipient: recipient.publicKey.toBase58(),
  }, null, 2));
  fs.writeFileSync('recipient.json', JSON.stringify(Array.from(recipient.secretKey)));
  console.log('mint:        ', mint.toBase58());
  console.log('sender ATA:  ', senderAta.address.toBase58());
  console.log('recipient:   ', recipient.publicKey.toBase58(), '(no token account yet)');
})();
