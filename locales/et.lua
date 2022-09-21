local Translations = {
    error = {
        to_far_from_door = 'Sa oled liiga kaugel uksekellast',
        nobody_home = 'Kedagi ei ole kodus..',
        nobody_at_door = 'Kedagi pole ukse taga...'
    },
    success = {
        receive_apart = 'Sa said korteri',
        changed_apart = 'Sa kolisid uude korterisse',
    },
    info = {
        at_the_door = 'Keegi on ukse peal!',
    },
    text = {
        options = '[E] Korteri valikud ',
        enter = 'Sisene korterisse',
        ring_doorbell = 'Helista uksekella',
        logout = 'Vaheta karakterit',
        change_outfit = 'Vaheta riideid',
        open_stash = 'Ava stash',
        move_here = 'Koli siia',
        open_door = 'Ava uks',
        leave = 'Lahku korterist',
        close_menu = '⬅ Sulge menüü',
        tennants = 'Üürnikud',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})