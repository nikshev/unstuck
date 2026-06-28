// Creates a throwaway DEVNET wallet (throwaway.json) and airdrops test SOL.
// Safe to re-run: it reuses the wallet if it already exists.
// This file is why the repo never ships a private key — you generate your own.
const { Connection, Keypair, LAMPORTS_PER_SOL } = require('@solana/web3.js');
const fs = require('fs');

const FILE = 'throwaway.json';
const conn = new Connection('https://api.devnet.solana.com', 'confirmed');

(async () => {
  let kp;
  if (fs.existsSync(FILE)) {
    kp = Keypair.fromSecretKey(new Uint8Array(JSON.parse(fs.readFileSync(FILE))));
    console.log('Using existing wallet:', kp.publicKey.toBase58());
  } else {
    kp = Keypair.generate();
    fs.writeFileSync(FILE, JSON.stringify(Array.from(kp.secretKey)));
    console.log('Created wallet:', kp.publicKey.toBase58());
  }

  const bal = await conn.getBalance(kp.publicKey);
  if (bal >= 0.5 * LAMPORTS_PER_SOL) {
    console.log('Balance OK:', bal / LAMPORTS_PER_SOL, 'SOL — you are set.');
    return;
  }

  console.log('Requesting devnet airdrop...');
  try {
    const sig = await conn.requestAirdrop(kp.publicKey, LAMPORTS_PER_SOL);
    await conn.confirmTransaction(sig, 'confirmed');
    console.log('Airdropped. Balance:',
      (await conn.getBalance(kp.publicKey)) / LAMPORTS_PER_SOL, 'SOL');
  } catch (e) {
    console.error('\nAirdrop failed — the public devnet faucet is often rate-limited.');
    console.error('Fund it manually with either:');
    console.error('  solana airdrop 1', kp.publicKey.toBase58(), '--url devnet');
    console.error('  or paste the address at https://faucet.solana.com');
  }
})();
