fx_version 'cerulean'
name 'Group Script'
author 'erzn'
game 'gta5'
lua54 'yes'

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}
