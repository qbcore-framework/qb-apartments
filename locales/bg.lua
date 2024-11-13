local Translations = {
    error = {
        to_far_from_door = 'Твърде далеч сте от звънеца',
        nobody_home = 'Няма никой вкъщи..',
        nobody_at_door = 'Няма никой на вратата...'
    },
    success = {
        receive_apart = 'Получихте апартамент',
        changed_apart = 'Преместихте се да живеете тук',
    },
    info = {
        at_the_door = 'Някой е на вратата!',
    },
    text = {
        options = '[E] Опции на апартамента',
        enter = 'Влезте в апартамента',
        ring_doorbell = 'Позвънете на звънеца',
        logout = 'Отписване на героя',
        change_outfit = 'Промяна на облеклото',
        open_stash = 'Отворете скривалището',
        move_here = 'Преместете се тук',
        open_door = 'Отворете вратата',
        leave = 'Излезте от апартамента',
        close_menu = '⬅ Затваряне на менюто',
        tennants = 'Наематели',
    },
}

if GetConvar('qb_locale', 'en') == 'bg' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end