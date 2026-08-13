-- Hyperliquid: biggest single deposits (whale moves), last 30 days
SELECT block_time,
       "from"  AS depositor,
       amount  AS usdc
FROM tokens_arbitrum.transfers
WHERE contract_address = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
  AND "to" = 0x2Df1c51E09aECF9cacB7bc98cB1742757f163dF7
  AND block_time > now() - interval '30' day
ORDER BY amount DESC
LIMIT 12
