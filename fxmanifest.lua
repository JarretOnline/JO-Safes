fx_version 'cerulean'
game 'gta5'

author 'PlayerNo1'
description 'A placeable safe script'

shared_scripts {
    'config.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua'
}

client_script 'client.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

lua54 'yes'

escrow_ignore {
    'config.lua',
    'client.lua',
    'server.lua',
    'locales/*.lua'
}
dependency '/assetpacks'