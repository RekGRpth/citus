--
-- failure_connection_establishment.sql tests some behaviour of connection management when
-- it fails to connect.
--
-- Failure cases covered:
--  - timeout
--

SELECT citus.mitmproxy('conn.allow()');

CREATE SCHEMA fail_connect;
SET search_path TO 'fail_connect';

SET citus.shard_count TO 4;
ALTER SEQUENCE pg_catalog.pg_dist_shardid_seq RESTART 1450000;
ALTER SEQUENCE pg_catalog.pg_dist_placement_placementid_seq RESTART 1450000;

CREATE TABLE products (
    product_no integer,
    name text,
    price numeric
);
SELECT create_distributed_table('products', 'product_no');

-- Can only add primary key constraint on distribution column (or group of columns
-- including distribution column)
-- Command below should error out since 'name' is not a distribution column
ALTER TABLE products ADD CONSTRAINT p_key PRIMARY KEY(name);


-- we will insert a connection delay here as this query was the cause for an investigation
-- into connection establishment problems
SET citus.node_connection_timeout TO 400;
SELECT citus.mitmproxy('conn.delay(500)');

ALTER TABLE products ADD CONSTRAINT p_key PRIMARY KEY(product_no);

SELECT citus.mitmproxy('conn.allow()');

DROP SCHEMA fail_connect CASCADE;
SET search_path TO default;