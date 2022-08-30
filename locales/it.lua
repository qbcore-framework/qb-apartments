local Translations = {
    error = {
        to_far_from_door = 'Sei troppo distante dal campanello',
        nobody_home = 'Non c\'è nessuno in casa..',
        nobody_at_door = 'Non c\'è nessuno alla porta...'
    },
    success = {
        receive_apart = 'Hai ottenuto un appartamento',
        changed_apart = 'Hai cambiato appartamento',
    },
    info = {
        at_the_door = 'Qualcuno è alla porta!',
    },
    text = {
        options = '[E] Gestione appartamento',
        enter = 'Entra nell\'appartamento',
        ring_doorbell = 'Suona il campanello',
        logout = 'Logout',
        change_outfit = 'Cambia outfit',
        open_stash = 'Apri inventario',
        move_here = 'Sposta qui',
        open_door = 'Apri la porta',
        leave = 'Esci dall\'appartamento',
        close_menu = '⬅ Chiudi Menù',
        tennants = 'Inquilini',
    },
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
