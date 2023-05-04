/* src/pl/plpython/plpython3u--1.0.sql */

/*
 * Currently, all the interesting stuff is done by CREATE LANGUAGE.
 * Later we will probably "dumb down" that command and put more of the
 * knowledge into this script.
 */

CREATE LANGUAGE plpython3u;

COMMENT ON LANGUAGE plpython3u IS 'PL/Python3U untrusted procedural language';

CREATE SCHEMA plpython3;

CREATE OR REPLACE FUNCTION plpython3.create_virtual_env(
    creator text
) RETURNS text AS 'MODULE_PATHNAME', 'create_virtual_env'
LANGUAGE c;
