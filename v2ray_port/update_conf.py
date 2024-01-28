import datetime
import os
import sys
import shutil
from jinja2 import Environment, FileSystemLoader
import sqlite3

ID = 'b16dde59-7c20-43b7-a557-8c6bb55f935c'
PATH = '3b71'
SETTINGS = {
    'nginx_nginx.conf': {
        'name': 'nginx.conf',
        'directory': '/etc/nginx/conf.d',
        'template': 'nginx_nginx.conf.template',
        'params': {
            'id': ID,
            'path': PATH
        }
    },
    'nginx_default.conf': {
        'name': 'default.conf',
        'directory': '/etc/nginx/conf.d',
        'template': 'nginx_default.conf.template',
        'params': {
            'id': ID,
            'path': PATH
        }
    },
    'v2ray_server_config.json': {
        'name': 'config.json',
        'directory': '/usr/local/etc/v2ray',
        'template': 'v2ray_server_config.json.template',
        'params': {
            'id': ID,
            'path': PATH
        }
    },
    'v2ray_client_ubuntu_config.json': {
        'name': 'config.json',
        'directory': '/usr/local/etc/v2ray',
        'template': 'v2ray_client_config.json.template',
        'params': {
            'id': ID,
            'path': PATH
        }
    },
    'v2ray_client_windows_guiNDB.db': {
        'name': 'guiNDB.db',
        'directory': 'd:/tools/v2rayN-Core',
        'params': {
            'id': ID,
            'path': PATH
        }
    }
}


def get_setting(argv):
    today = datetime.date.today()
    port = '1{:02d}{:02d}'.format(today.month, today.day)
    target = argv[1]
    setting = SETTINGS[target]
    setting['directory'] = argv[2]
    params = {}
    params['domain'] = argv[3]
    params['port'] = port
    params['id'] = ID
    params['path'] = PATH

    return target, setting, params


def update_sqlite_db(setting, params):
    name = setting['name']
    directory = setting['directory']
    shutil.copy(directory + '/' + name, './')
    conn = sqlite3.connect(name)

    port = params['port']
    sql = f'UPDATE ProfileItem set port = {port} where remarks = "ladder"'
    conn.execute(sql)
    conn.commit()
    conn.close()
    shutil.copy(name, directory)


def update_config_file(setting, params):
    name = setting['name']
    environment = Environment(loader=FileSystemLoader('./'))
    template = environment.get_template(setting['template'])
    content = template.render(params)
    file = open(name, "w")
    file.write(content)
    file.close()
    shutil.copy(name, setting['directory'])


if __name__ == '__main__':
    target, setting, params = get_setting(sys.argv)
    if target == 'nginx_nginx.conf':
        update_config_file(setting, params)
    elif target == 'nginx_default.conf':
        update_config_file(setting, params)
    elif target == 'v2ray_server_config.json':
        update_config_file(setting, params)
    elif target == 'v2ray_client_ubuntu_config.json':
        update_config_file(setting, params)
    elif target == 'v2ray_client_windows_guiNDB.db':
        update_sqlite_db(setting, params)
    else:
        print('Unknown')
