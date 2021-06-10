fx_version "adamant"
game "common"
author "Winstone"


client_scripts{
    "client/*.lua",
    "src/*.lua"
}

shared_scripts {
    "shared/*.lua"
}

server_scripts{
    "@mysql-async/lib/MySQL.lua",
    "server/*.lua"
}
