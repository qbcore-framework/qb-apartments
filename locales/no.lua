local Translations = {
    error = {
        to_far_from_door = 'Du er for langt unna ringeklokken',
        nobody_home = 'Det er ingen hjemme..',
        nobody_at_door = 'Det er ingen ved døren...'
    },
    success = {
        receive_apart = 'Du fikk en leilighet',
        changed_apart = 'Du flyttet leiligheten',
    },
    info = {
        at_the_door = 'Noen står ved døren!',
    },
    text = {
        options = '[E] Leilighetsalternativer',
        enter = 'Gå inn i leiligheten',
        ring_doorbell = 'Ring på døren',
        logout = 'Logg ut karakter',
        change_outfit = 'Bytt antrekk',
        open_stash = 'Åpne lagring',
        move_here = 'Flytt her',
        open_door = 'Åpen dør',
        leave = 'Forlate leiligheten',
        close_menu = '⬅ Lukk menyen',
        tennants = 'Leietakere',
    },
}

if GetConvar('qb_locale', 'en') == 'no' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
