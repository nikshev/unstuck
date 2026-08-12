-- Top pools on Sonic by volume (last 7 days)
SELECT project,
       concat(least(token_bought_symbol, token_sold_symbol), ' / ',
              greatest(token_bought_symbol, token_sold_symbol)) AS pair,
       round(sum(amount_usd)) AS volume_usd,
       count(*)               AS trades
FROM dex.trades
WHERE blockchain = 'sonic' AND block_time > now() - interval '7' day
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 12
