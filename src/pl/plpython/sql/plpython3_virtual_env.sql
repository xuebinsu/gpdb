CREATE OR REPLACE FUNCTION create_virtual_env(
    prefix text, 
    manager text, 
    current_ts timestamp
) RETURNS text AS $$
from pathlib import Path
from subprocess import check_output, STDOUT

env_name = f'{manager}_{current_ts}'
prefix_dir = Path(prefix)
prefix_dir.mkdir(parents=True, exist_ok=True)
lock_path = prefix_dir / f"{manager}.lock"
try:
    open(lock_path, "x")
    stdout = check_output(
        [sys.executable, '-m', manager, env_name], stderr=STDOUT, text=True)
    close(lock_path)
    os.remove(lock_path)
    plpy.notice(stdout)
    return env_name
except FileExistsError as e:
    plpy.notice(e)
    return None
$$ LANGUAGE plpython3u;

SELECT create_virtual_env('/tmp/plpython3', 'venv', now())
UNION ALL
SELECT create_virtual_env('/tmp/plpython3', 'venv', now())
FROM gp_dist_random('gp_id')
LIMIT 1 /gset

\connect

SET plpython3.virtual_env = :'create_virtual_env';

CREATE OR REPLACE FUNCTION test_path_added(virtual_env_name text) 
RETURNS TEXT AS $$
import sys

plpy.notice('PYTHON VIRTUAL ENV sys.prefix=' + str(sys.prefix))
plpy.notice('PYTHON VIRTUAL ENV sys.exec_prefix=' + str(sys.exec_prefix))
plpy.notice('PYTHON VIRTUAL ENV sys.executable=' + str(sys.executable))
plpy.notice('PYTHON VIRTUAL ENV sys.base_prefix=' + str(sys.base_prefix))
plpy.notice('PYTHON VIRTUAL ENV sys.base_exec_prefix=' + str(sys.base_exec_prefix))
plpy.notice('PYTHON VIRTUAL ENV sys.base_executable=' + str(sys._base_executable))
plpy.notice('PYTHON VIRTUAL ENV sys.home=' + str(sys._home))

assert sys.prefix == f"/tmp/plpython3/{virtual_env_name}"
assert sys.exec_prefix == f"/tmp/plpython3/{virtual_env_name}"
assert sys.executable == f"/tmp/plpython3/{virtual_env_name}/bin/python"
assert sys.base_prefix == f"/tmp/plpython3/{virtual_env_name}"
assert sys.base_exec_prefix == f"/tmp/plpython3/{virtual_env_name}"
assert sys._base_executable == f"/tmp/plpython3/{virtual_env_name}/bin/python"

return "SUCCESS"
$$ language plpython3u;

SELECT DISTINCT * FROM (
    SELECT test_path_added(:'create_virtual_env')
    UNION ALL
    SELECT test_path_added(:'create_virtual_env') FROM gp_dist_random('gp_id')
) t;

SET plpython3.virtual_env = :'create_virtual_env';

CREATE OR REPLACE FUNCTION test_import(name TEXT) 
RETURNS text AS $$
import importlib
return importlib.import_module(name)
$$ language plpython3u;

SELECT DISTINCT * FROM
(
    SELECT test_import('numpy')
    UNION ALL
    SELECT test_import('numpy') from gp_dist_random('gp_id')
) t;

CREATE OR REPLACE FUNCTION pip_install(name TEXT) 
RETURNS text AS $$
import os
import sys
from pathlib import Path
from subprocess import check_output, STDOUT

lock_path = Path(sys.prefix) / "pip.lock"
try:
    open(lock_path, "x")
    stdout = check_output([sys.executable, '-m', 'pip', 'install', name], stderr=STDOUT, text=True)
    close(lock_path)
    os.remove(lock_path)
    return stdout
except FileExistsError as e:
    plpy.notice(e)
    return None
$$ language plpython3u;

WITH pip_install AS (
    SELECT pip_install('numpy') AS stdout
    UNION ALL
    SELECT pip_install('numpy') AS stdout
    FROM gp_dist_random('gp_id')
), install_error AS (
    SELECT * FROM pip_install
    WHERE NOT (
        (stdout IS NULL) OR 
        (stdout LIKE '%Successfully installed numpy%') OR
        (stdout LIKE 'Requirement already satisfied: numpy%')
    )
)
SELECT NOT EXISTS (SELECT * FROM install_error);

SELECT DISTINCT * FROM
(
    SELECT test_import('numpy')
    UNION ALL
    SELECT test_import('numpy') from gp_dist_random('gp_id')
) t;
