-- Operational Performance KPI Analysis Pack (PostgreSQL)
-- Table: support_tickets

-- 1) KPI overview snapshot
WITH resolved AS (
  SELECT EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600.0 AS resolution_hours
  FROM support_tickets
  WHERE resolved_at IS NOT NULL
)
SELECT
  (SELECT ROUND(AVG(resolution_hours)::numeric, 2) FROM resolved) AS avg_resolution_hours,
  (SELECT ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours))::numeric, 2) FROM resolved) AS median_resolution_hours,
  ROUND(100.0 * AVG(sla_breach_flag), 2) AS sla_breach_pct,
  COUNT(*) FILTER (WHERE status <> 'Closed') AS backlog_size,
  ROUND(100.0 * AVG(reopened_flag), 2) AS reopen_rate_pct,
  ROUND(100.0 * AVG(repeat_ticket_flag), 2) AS repeat_ticket_rate_pct,
  ROUND(AVG(csat), 2) AS avg_csat
FROM support_tickets;

-- 2) Weekly ticket volume trend
SELECT
  DATE_TRUNC('week', created_at)::date AS week_start,
  COUNT(*) AS tickets_created
FROM support_tickets
GROUP BY 1
ORDER BY 1;

-- 3) Average vs median resolution by category
SELECT
  category,
  ROUND(AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600.0)::numeric, 2) AS avg_resolution_hours,
  ROUND(
    (PERCENTILE_CONT(0.5) WITHIN GROUP (
      ORDER BY EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600.0
    ))::numeric,
    2
  ) AS median_resolution_hours,
  COUNT(*) AS closed_tickets
FROM support_tickets
WHERE resolved_at IS NOT NULL
GROUP BY category
ORDER BY avg_resolution_hours DESC;

-- 4) SLA breach % by category and priority (heatmap query)
SELECT
  category,
  priority,
  COUNT(*) AS ticket_count,
  SUM(sla_breach_flag) AS breaches,
  ROUND(100.0 * AVG(sla_breach_flag), 2) AS sla_breach_pct
FROM support_tickets
GROUP BY category, priority
ORDER BY category, priority;

-- 5) Backlog aging (open > 72 hours)
SELECT
  ticket_id,
  category,
  priority,
  status,
  created_at,
  ROUND((EXTRACT(EPOCH FROM (NOW() - created_at)) / 3600.0)::numeric, 1) AS age_hours,
  assigned_agent
FROM support_tickets
WHERE status <> 'Closed'
  AND NOW() - created_at > INTERVAL '72 hours'
ORDER BY age_hours DESC;

-- 6) Reopen and repeat rate by category
SELECT
  category,
  COUNT(*) AS ticket_count,
  ROUND(100.0 * AVG(reopened_flag), 2) AS reopen_rate_pct,
  ROUND(100.0 * AVG(repeat_ticket_flag), 2) AS repeat_ticket_rate_pct
FROM support_tickets
GROUP BY category
ORDER BY reopen_rate_pct DESC, repeat_ticket_rate_pct DESC;

-- 7) Agent performance table
SELECT
  assigned_agent,
  COUNT(*) AS total_tickets,
  COUNT(*) FILTER (WHERE status = 'Closed') AS closed_tickets,
  ROUND((AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600.0) FILTER (WHERE resolved_at IS NOT NULL))::numeric, 2) AS avg_resolution_hours,
  ROUND(100.0 * AVG(sla_breach_flag), 2) AS sla_breach_pct,
  ROUND(AVG(csat), 2) AS avg_csat
FROM support_tickets
GROUP BY assigned_agent
ORDER BY total_tickets DESC;

-- 8a) CSAT by SLA breach
SELECT
  sla_breach_flag,
  COUNT(*) AS ticket_count,
  ROUND(AVG(csat), 2) AS avg_csat
FROM support_tickets
GROUP BY sla_breach_flag
ORDER BY sla_breach_flag;

-- 8b) CSAT by category
SELECT
  category,
  COUNT(*) AS ticket_count,
  ROUND(AVG(csat), 2) AS avg_csat
FROM support_tickets
GROUP BY category
ORDER BY avg_csat DESC;


