SELECT plpython3.create_virtual_env('venv') \gset

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
from pathlib import PurePath
from subprocess import check_output, STDOUT

try:
    lock_path = PurePath(sys.prefix) / "pip.lock"
    open(lock_path, "x")
    stdout = check_output([sys.executable, '-m', 'pip', 'install', name], stderr=STDOUT, text=True)
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
