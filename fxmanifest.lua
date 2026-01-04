fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'NexusDevelopment'
description 'NexusHud'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_script 'client.lua'

dependencies {
    'es_extended',
    'esx_status'
}