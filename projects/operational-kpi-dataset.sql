-- Synthetic dataset generator for Operational Performance KPI Analysis (PostgreSQL)

DROP TABLE IF EXISTS support_tickets;

CREATE TABLE support_tickets (
  ticket_id INT PRIMARY KEY,
  customer_id INT,
  created_at TIMESTAMP,
  first_response_at TIMESTAMP,
  resolved_at TIMESTAMP,
  status TEXT,
  priority TEXT,
  category TEXT,
  channel TEXT,
  assigned_agent TEXT,
  reopened_flag INT,
  repeat_ticket_flag INT,
  sla_hours INT,
  sla_breach_flag INT,
  csat NUMERIC(3,1)
);

INSERT INTO support_tickets (
  ticket_id,
  customer_id,
  created_at,
  first_response_at,
  resolved_at,
  status,
  priority,
  category,
  channel,
  assigned_agent,
  reopened_flag,
  repeat_ticket_flag,
  sla_hours,
  sla_breach_flag,
  csat
)
WITH base AS (
  SELECT
    gs AS ticket_id,
    10000 + FLOOR(random() * 260)::INT AS customer_id,
    TIMESTAMP '2025-10-01 00:00:00'
      + (random() * INTERVAL '140 days') AS created_at,
    CASE
      WHEN random() < 0.08 THEN 'Urgent'
      WHEN random() < 0.30 THEN 'High'
      WHEN random() < 0.72 THEN 'Medium'
      ELSE 'Low'
    END AS priority,
    CASE
      WHEN random() < 0.30 THEN 'Provisioning'
      WHEN random() < 0.52 THEN 'Technical'
      WHEN random() < 0.70 THEN 'Billing'
      WHEN random() < 0.88 THEN 'Account'
      ELSE 'Other'
    END AS category,
    CASE
      WHEN random() < 0.32 THEN 'Email'
      WHEN random() < 0.58 THEN 'Chat'
      WHEN random() < 0.82 THEN 'Phone'
      ELSE 'Web'
    END AS channel,
    (ARRAY[
      'Agent A. Diallo',
      'Agent B. Mensah',
      'Agent C. Smith',
      'Agent D. Johnson',
      'Agent E. Patel',
      'Agent F. Okafor',
      'Agent G. Kim',
      'Agent H. Torres',
      'Agent I. Brown'
    ])[1 + FLOOR(random() * 9)::INT] AS assigned_agent
  FROM generate_series(1, 800) AS gs
),
slas AS (
  SELECT
    b.*,
    CASE b.priority
      WHEN 'Urgent' THEN 4
      WHEN 'High' THEN 24
      WHEN 'Medium' THEN 48
      ELSE 72
    END AS sla_hours,
    CASE b.priority
      WHEN 'Urgent' THEN 0.33
      WHEN 'High' THEN 0.21
      WHEN 'Medium' THEN 0.13
      ELSE 0.08
    END AS base_breach_prob
  FROM base b
),
metrics AS (
  SELECT
    s.*,
    GREATEST(
      0.15,
      CASE
        WHEN random() < (s.base_breach_prob
                          + CASE WHEN s.category IN ('Provisioning', 'Technical') THEN 0.02 ELSE 0 END)
          THEN s.sla_hours + (1.0 + random() * 1.6) * s.sla_hours
        ELSE s.sla_hours * (0.22 + random() * 0.62)
      END
    ) AS resolution_hours_raw
  FROM slas s
),
resolved_calc AS (
  SELECT
    m.*,
    m.resolution_hours_raw
    * CASE
        WHEN m.category = 'Provisioning' THEN 1.12
        WHEN m.category = 'Technical' THEN 1.10
        WHEN m.category = 'Billing' THEN 0.96
        WHEN m.category = 'Account' THEN 0.92
        ELSE 0.90
      END AS resolution_hours
  FROM metrics m
),
with_flags AS (
  SELECT
    r.*,
    CASE
      WHEN r.resolution_hours > r.sla_hours * 1.05 THEN 1
      WHEN r.resolution_hours > r.sla_hours * 0.85 AND random() < 0.18 THEN 1
      ELSE 0
    END AS sla_breach_flag,
    CASE
      WHEN r.resolution_hours > r.sla_hours * 1.10 AND random() < 0.40 THEN 1
      WHEN r.resolution_hours > r.sla_hours * 0.75 AND random() < 0.16 THEN 1
      ELSE 0
    END AS reopened_flag
  FROM resolved_calc r
),
with_repeat AS (
  SELECT
    wf.*,
    CASE
      WHEN wf.reopened_flag = 1 AND random() < 0.52 THEN 1
      WHEN wf.category IN ('Technical', 'Provisioning') AND wf.resolution_hours > wf.sla_hours * 0.90 AND random() < 0.28 THEN 1
      WHEN random() < 0.06 THEN 1
      ELSE 0
    END AS repeat_ticket_flag
  FROM with_flags wf
),
with_timestamps AS (
  SELECT
    wr.*,
    wr.created_at
      + (
          GREATEST(0.05, LEAST(wr.resolution_hours * (0.06 + random() * 0.34), wr.resolution_hours - 0.03))
          * INTERVAL '1 hour'
        ) AS first_response_at,
    wr.created_at + (wr.resolution_hours * INTERVAL '1 hour') AS resolved_at_candidate,
    CASE
      WHEN wr.created_at > NOW() - INTERVAL '2 days' AND random() < 0.52 THEN 'Open'
      WHEN wr.created_at > NOW() - INTERVAL '9 days' AND random() < 0.33 THEN 'In Progress'
      ELSE 'Closed'
    END AS status
  FROM with_repeat wr
),
final_rows AS (
  SELECT
    wt.ticket_id,
    wt.customer_id,
    wt.created_at,
    wt.first_response_at,
    CASE WHEN wt.status = 'Closed' THEN wt.resolved_at_candidate ELSE NULL END AS resolved_at,
    wt.status,
    wt.priority,
    wt.category,
    wt.channel,
    wt.assigned_agent,
    wt.reopened_flag,
    wt.repeat_ticket_flag,
    wt.sla_hours,
    CASE
      WHEN wt.status <> 'Closed' THEN
        CASE WHEN NOW() - wt.created_at > (wt.sla_hours || ' hours')::INTERVAL THEN 1 ELSE 0 END
      ELSE wt.sla_breach_flag
    END AS sla_breach_flag,
    ROUND(LEAST(
        5.0,
        GREATEST(
          1.0,
          4.9
          - (CASE WHEN wt.status <> 'Closed' THEN 0.5 ELSE 0 END)
          - (CASE WHEN wt.sla_breach_flag = 1 THEN 1.0 ELSE 0 END)
          - (0.55 * wt.reopened_flag)
          - (0.45 * wt.repeat_ticket_flag)
          - LEAST(1.2, wt.resolution_hours / 84.0)
          + ((random() - 0.5) * 0.6)
        )
      )::numeric, 1)::NUMERIC(3,1) AS csat
  FROM with_timestamps wt
)
SELECT
  ticket_id,
  customer_id,
  created_at,
  first_response_at,
  resolved_at,
  status,
  priority,
  category,
  channel,
  assigned_agent,
  reopened_flag,
  repeat_ticket_flag,
  sla_hours,
  sla_breach_flag,
  csat
FROM final_rows
ORDER BY ticket_id;
