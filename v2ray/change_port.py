import datetime
import os
from jinja2 import Environment, FileSystemLoader

current_date = datetime.date.today()
port = '1{:02d}{:02d}'.format(current_date.month, current_date.day)
environment = Environment(loader=FileSystemLoader('./'))
template = environment.get_template("template.txt")
content = template.render(port=port)
text_file = open("default.conf", "w")
text_file.write(content)
text_file.close()

