local Translations = {
    error = {
        to_far_from_door = 'ドアベルから離れすぎています',
        nobody_home = '家には誰もいません..',
        nobody_at_door = 'ドアの前には誰もいません...'
    },
    success = {
        receive_apart = 'アパートを借りました',
        changed_apart = 'アパートを引っ越しました',
    },
    info = {
        at_the_door = '誰かがドアの前にいます！',
    },
    text = {
        options = '[E] アパートオプション',
        enter = 'アパートに入る',
        ring_doorbell = 'ドアベルを鳴らす',
        logout = 'このキャラクターからログアウトする',
        change_outfit = '衣装を変更する',
        open_stash = '隠し倉庫を開ける',
        move_here = 'ここに移動する',
        open_door = 'ドアを開ける',
        leave = 'アパートを出る',
        close_menu = '⬅ メニューを閉じる',
        tennants = '部屋',
    },
}

if GetConvar('qb_locale', 'en') == 'ja' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang
    })
end
