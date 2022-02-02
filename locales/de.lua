local Translations = {
    error = {
        to_far_from_door = 'Du bist zu weit von der Türklingel entfernt',
        nobody_home = 'Es ist niemand zu Hause..',
    },
    success = {
        receive_apart = 'Du hast ein Apartment bekommen',
        changed_apart = 'Du bist umgezogen',
    },
    info = {
        at_the_door = 'Jemand ist an der Tür!',
    },
    text = {
        enter = 'Apartment betreten',
        ring_doorbell = 'Klingeln',
        logout = 'Ausloggen',
        change_outfit = 'Outfit wechseln',
        open_stash = 'Lager öffnen',
        move_here = 'Hierher umziehen',
        open_door = 'Tür öffnen',
        leave = 'Apartment verlassen',
        close_menu = '⬅ Menü schließen',
        tennants = 'Tennants',
    },
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
