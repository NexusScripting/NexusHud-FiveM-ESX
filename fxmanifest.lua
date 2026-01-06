fx_version 'cerulean'
game 'gta5'
author 'NexusDevelopment'
description 'NexusHud - Optimized HUD'
version '1.6'

ui_page 'html/index.html'
shared_script 'config.lua'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'es_extended',
    'oxmysql'
}