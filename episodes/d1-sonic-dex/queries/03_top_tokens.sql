-- Top tokens traded on Sonic (last 7 days)
SELECT token_bought_symbol       AS token,
       round(sum(amount_usd))    AS volume_usd
FROM dex.trades
WHERE blockchain = 'sonic' AND block_time > now() - interval '7' day
  AND token_bought_symbol IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10
