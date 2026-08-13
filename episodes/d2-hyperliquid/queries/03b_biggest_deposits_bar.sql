-- Hyperliquid: biggest single deposits — BAR-CHART variant (2 columns: label + value)
-- Same data as 03_biggest_deposits.sql, but shaped for a categorical bar chart on the
-- dashboard: a text X-axis label (the deposit timestamp) + one numeric Y value (USDC).
-- Dune's bar viz plots the first text column as X and the numeric column as Y, so a
-- 2-column (label, value) shape renders reliably; the 3-column version is best as a table.
SELECT format_datetime(block_time, 'MMM d HH:mm') AS deposit_time,
       amount                                     AS usdc
FROM tokens_arbitrum.transfers
WHERE contract_address = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
  AND "to" = 0x2Df1c51E09aECF9cacB7bc98cB1742757f163dF7
  AND block_time > now() - interval '30' day
ORDER BY amount DESC
LIMIT 12
