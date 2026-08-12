-- Daily DEX volume on Sonic (last 30 days)
SELECT date_trunc('day', block_time) AS day,
       round(sum(amount_usd))        AS volume_usd,
       count(*)                      AS trades
FROM dex.trades
WHERE blockchain = 'sonic'
  AND block_time > now() - interval '30' day
GROUP BY 1
ORDER BY 1
