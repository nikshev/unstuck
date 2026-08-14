-- Hyperliquid biggest single deposits — PARAMETERIZED (timeframe + min deposit size), bar-chart shape
SELECT format_datetime(block_time, 'MMM d HH:mm') AS deposit_time, amount AS usdc
FROM tokens_arbitrum.transfers
WHERE contract_address = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
  AND "to" = 0x2Df1c51E09aECF9cacB7bc98cB1742757f163dF7
  AND block_time > now() - interval '{{days}}' day
  AND amount >= {{min_usdc}}
ORDER BY amount DESC LIMIT 12
