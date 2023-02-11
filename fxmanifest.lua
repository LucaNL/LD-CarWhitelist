fx_version 'bodacious'
game 'gta5'

name 'CarWhitelist-FiveM'
author 'LucaNL#2230'
description 'A script that allows you to create vehicles for only one or several jobs, so you can make sure people dont steal emergency vehicles. Like police, ambulance and so on. This script causes no performance loss.'
version 'v1.2.0'
url 'https://github.com/LucaNL/CarWhitelist-FiveM'

server_script {
    'version.lua'
}

client_scripts {
    'config.lua',
    'client/client.lua'
}