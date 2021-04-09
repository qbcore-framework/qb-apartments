fx_version 'cerulean'
game 'gta5'

description 'QB-Apartments'
version '1.0.0'

server_scripts {
	"server/main.lua",
	"config.lua",
}

client_scripts {
	"client/main.lua",
	"client/gui.lua",
	"config.lua",
}

dependencies {
	'qb-core',
	'qb-interior',
	'qb-clothing',
	'qb-weathersync'
}