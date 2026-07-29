# Web export

Проект содержит готовый пресет `Web` в `export_presets.cfg` и HTML-оболочку
`web/custom_index_template.html`. Потоки, GDExtension и нативные плагины не используются.

## Экспорт

1. Установить Export Templates для используемой версии Godot 4.7.
2. Открыть `Project -> Export -> Web`.
3. Проверить путь `build/web/index.html`.
4. Нажать `Export Project`.
5. Упаковать содержимое `build/web`, чтобы `index.html` лежал в корне ZIP.

Папка `output` исключена через `.gdignore` и фильтр экспортного пресета.

## Локальная проверка

Web-сборку нельзя открывать двойным щелчком по `index.html`. Запустите HTTP-сервер
в каталоге экспорта, например `python -m http.server 8060`, и откройте
`http://localhost:8060`.

## Яндекс Игры

HTML-оболочка подключает SDK v2 до запуска Godot. Мост хранит ранние события
Game Ready и Gameplay Start до завершения `YaGames.init()`. Локально и в редакторе
все вызовы безопасно переходят на локальное сохранение.

Перед публикацией проверьте архив в черновике Яндекс Игр и в SDK debug panel:

- LoadingAPI.ready после появления главного меню;
- GameplayAPI.start при начале и продолжении;
- GameplayAPI.stop в меню, финале и перед рекламой;
- восстановление GameplayAPI.start после закрытия рекламы;
- локальное сохранение при недоступном SDK.
