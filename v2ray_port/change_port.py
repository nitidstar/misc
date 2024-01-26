import datetime
import os
import sys
import shutil
from jinja2 import Environment, FileSystemLoader
import sqlite3

SETTINGS = {
    'nginx': {
        'name': 'default.conf',
        'directory': '/etc/nginx/conf.d',
        'template': 'default.conf.template',
    },
    'ubuntu': {
        'name': 'config.json',
        'directory': '/usr/local/etc/v2ray',
        'template': 'config.json.template'
    },
    'windows': {
        'name': 'guiNDB.db',
        'directory': 'd:/tools/v2rayN-Core'
    }
}


def get_setting(argv):
    today = datetime.date.today()
    port = '1{:02d}{:02d}'.format(today.month, today.day)
    setting = SETTINGS[argv[1]]
    if len(argv) > 2:
        setting['directory'] = argv[2]
    return argv[1], setting, port


def update_sqlite_db(setting, port):
    name = setting['name']
    directory = setting['directory']
    shutil.copy(directory + '/' + name, './')
    conn = sqlite3.connect(name)
    sql = f'UPDATE ProfileItem set port = {port} where remarks = "ladder"'
    conn.execute(sql)
    conn.commit()
    conn.close()
    shutil.copy(name, directory)


def update_config_file(setting, port):
    name = setting['name']
    environment = Environment(loader=FileSystemLoader('./'))
    template = environment.get_template(setting['template'])
    content = template.render(port=port)
    file = open(name, "w")
    file.write(content)
    file.close()
    shutil.copy(name, setting['directory'])


if __name__ == '__main__':
    target, setting, port = get_setting(sys.argv)
    if target == 'nginx':
        update_config_file(setting, port)
    elif target == 'ubuntu':
        update_config_file(setting, port)
    elif target == 'windows':
        update_sqlite_db(setting, port)
    else:
        print('Unknown')
