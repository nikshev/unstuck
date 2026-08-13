-- Hyperliquid: daily bridge NET inflow (Arbitrum USDC), last 30 days
SELECT date_trunc('day', block_time) AS day,
       sum(CASE WHEN "to" = 0x2Df1c51E09aECF9cacB7bc98cB1742757f163dF7 THEN amount ELSE -amount END) AS net_flow_usdc
FROM tokens_arbitrum.transfers
WHERE contract_address = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
  AND ("to" = 0x2Df1c51E09aECF9cacB7bc98cB1742757f163dF7 OR "from" = 0x2Df1c51E09aECF9cacB7bc98cB1742757f163dF7)
  AND block_time > now() - interval '30' day
GROUP BY 1 ORDER BY 1
