fx_version 'cerulean'
game 'gta5'

name 'ld_carwhitelist'
author 'LD Scripts'
version '2.0.0'
description 'Lock vehicles to jobs or permissions: blocked before entering, enforced by the server'
repository 'https://github.com/LucaNL/LD-CarWhitelist'

lua54 'yes'

shared_scripts {
    'config.lua',
    'locales.lua',
    'shared/rules.lua',
}

server_script 'server/main.lua'
client_script 'client/main.lua'
