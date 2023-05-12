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

WITH env AS (
  SELECT :'create_virtual_env' AS virtual_env_name
),
result AS (
  SELECT test_path_added(virtual_env_name) FROM env
  UNION ALL
  SELECT test_path_added(virtual_env_name) FROM gp_dist_random('gp_id'), env
)
SELECT DISTINCT * FROM result;

SET plpython3.virtual_env = :'create_virtual_env';

CREATE OR REPLACE FUNCTION test_import(name TEXT) 
RETURNS text AS $$
    import importlib
    ret = importlib.import_module(name)
    import re
    match = re.search(r"<module 'numpy' from '/tmp/plpython3/venv_", str(ret))
    if match:
        sub_string = match.group()
        return sub_string
    return ret

$$ language plpython3u;
SELECT DISTINCT * FROM
(
    SELECT test_import('numpy')
    UNION ALL
    SELECT test_import('numpy') from gp_dist_random('gp_id')
) t;

CREATE OR REPLACE FUNCTION test_pip_install(name TEXT) 
RETURNS int AS $$
    import pip
    ret = pip.main(['install', name])

    import importlib
    importlib.invalidate_caches()
    return ret
$$ language plpython3u;

SELECT DISTINCT * FROM
(
    SELECT test_pip_install('numpy')
    UNION ALL
    SELECT test_pip_install('numpy') from gp_dist_random('gp_id')
) t;

SELECT DISTINCT * FROM
(
    SELECT test_import('numpy')
    UNION ALL
    SELECT test_import('numpy') from gp_dist_random('gp_id')
) t;
