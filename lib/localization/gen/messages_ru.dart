// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ru';

  static m0(count) => "${Intl.plural(count, zero: 'Альбомов', one: 'Альбом', two: 'Альбома', few: 'Альбома', many: 'Альбомов', other: 'Альбома')}";

  static m1(remainingClicks) => "осталось всего ${remainingClicks} клика...";

  static m2(count) => "${Intl.plural(count, zero: 'Треков', one: 'Трек', two: 'Трека', few: 'Трека', many: 'Треков', other: 'Трека')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "actions" : MessageLookupByLibrary.simpleMessage("Действия"),
    "addToQueue" : MessageLookupByLibrary.simpleMessage("Добавить в очередь"),
    "albums" : MessageLookupByLibrary.simpleMessage("Альбомы"),
    "albumsPlural" : m0,
    "allTracks" : MessageLookupByLibrary.simpleMessage("Все треки"),
    "allowAccessToExternalStorage" : MessageLookupByLibrary.simpleMessage("Пожалуйста, предоставьте доступ к хранилищу"),
    "allowAccessToExternalStorageManually" : MessageLookupByLibrary.simpleMessage("Предоставьте доступ к хранилищу вручную"),
    "almostThere" : MessageLookupByLibrary.simpleMessage("Вы почти у цели"),
    "arbitraryQueue" : MessageLookupByLibrary.simpleMessage("Произвольная очередь"),
    "areYouSure" : MessageLookupByLibrary.simpleMessage("Вы уверены?"),
    "artist" : MessageLookupByLibrary.simpleMessage("Исполнитель"),
    "artistUnknown" : MessageLookupByLibrary.simpleMessage("Неизвестный исполнитель"),
    "byQuery" : MessageLookupByLibrary.simpleMessage("По запросу"),
    "dateAdded" : MessageLookupByLibrary.simpleMessage("Дата добавления"),
    "dateModified" : MessageLookupByLibrary.simpleMessage("Дата изменения"),
    "debug" : MessageLookupByLibrary.simpleMessage("Дебаг"),
    "delete" : MessageLookupByLibrary.simpleMessage("Удалить"),
    "deletion" : MessageLookupByLibrary.simpleMessage("Удаление"),
    "deletionError" : MessageLookupByLibrary.simpleMessage("Ошибка при удалении"),
    "deletionPromptDescriptionP1" : MessageLookupByLibrary.simpleMessage("Вы точно хотите удалить "),
    "deletionPromptDescriptionP2" : MessageLookupByLibrary.simpleMessage(" выбранные треки?"),
    "details" : MessageLookupByLibrary.simpleMessage("Детали"),
    "devAnimationsSlowMo" : MessageLookupByLibrary.simpleMessage("Замедление анимаций"),
    "devErrorSnackbar" : MessageLookupByLibrary.simpleMessage("Показать снакбар с ошибкой"),
    "devImportantSnackbar" : MessageLookupByLibrary.simpleMessage("Показать важный снакбар"),
    "devModeGreet" : MessageLookupByLibrary.simpleMessage("Готово! Теперь вы разработчик"),
    "devStopService" : MessageLookupByLibrary.simpleMessage("Остановить сервис"),
    "devTestToast" : MessageLookupByLibrary.simpleMessage("Тестовый тост"),
    "edit" : MessageLookupByLibrary.simpleMessage("Редактировать"),
    "editMetadata" : MessageLookupByLibrary.simpleMessage("Изменить информацию"),
    "errorDetails" : MessageLookupByLibrary.simpleMessage("Информация об ошибке"),
    "errorMessage" : MessageLookupByLibrary.simpleMessage("Упс! Произошла ошибка"),
    "found" : MessageLookupByLibrary.simpleMessage("Найдено"),
    "general" : MessageLookupByLibrary.simpleMessage("Общие"),
    "goToAlbum" : MessageLookupByLibrary.simpleMessage("Открыть альбом"),
    "grant" : MessageLookupByLibrary.simpleMessage("Предоставить"),
    "minutesShorthand" : MessageLookupByLibrary.simpleMessage("мин"),
    "modified" : MessageLookupByLibrary.simpleMessage("Изменено"),
    "noMusic" : MessageLookupByLibrary.simpleMessage("На вашем устройстве нету музыки"),
    "numberOfTracks" : MessageLookupByLibrary.simpleMessage("Количество треков"),
    "onThePathToDevMode" : MessageLookupByLibrary.simpleMessage("Сейчас должно что-то произойти..."),
    "onThePathToDevModeClicksRemaining" : m1,
    "onThePathToDevModeLastClick" : MessageLookupByLibrary.simpleMessage("остался всего 1 клик..."),
    "openAppSettingsError" : MessageLookupByLibrary.simpleMessage("Произошла ошибка при открытии настроек приложения"),
    "playNext" : MessageLookupByLibrary.simpleMessage("Включить следующим"),
    "playbackErrorMessage" : MessageLookupByLibrary.simpleMessage("Произошла ошибка при воспроизведении, удаление трека"),
    "playlist" : MessageLookupByLibrary.simpleMessage("Плейлист"),
    "pressOnceAgainToExit" : MessageLookupByLibrary.simpleMessage("Нажмите еще раз для выхода"),
    "quitDevMode" : MessageLookupByLibrary.simpleMessage("Выйти из режима разработчика"),
    "quitDevModeDescription" : MessageLookupByLibrary.simpleMessage("Перестать быть разработчиком?"),
    "refresh" : MessageLookupByLibrary.simpleMessage("Обновить"),
    "remove" : MessageLookupByLibrary.simpleMessage("Убрать"),
    "reset" : MessageLookupByLibrary.simpleMessage("Сбросить"),
    "save" : MessageLookupByLibrary.simpleMessage("Сохранить"),
    "searchClearHistory" : MessageLookupByLibrary.simpleMessage("Очистить историю поиска?"),
    "searchHistory" : MessageLookupByLibrary.simpleMessage("История поиска"),
    "searchHistoryPlaceholder" : MessageLookupByLibrary.simpleMessage("Здесь будет отображаться история вашего поиска"),
    "searchHistoryRemoveEntryDescriptionP1" : MessageLookupByLibrary.simpleMessage("Вы точно хотите убрать запрос "),
    "searchHistoryRemoveEntryDescriptionP2" : MessageLookupByLibrary.simpleMessage(" из истории поиска?"),
    "searchNothingFound" : MessageLookupByLibrary.simpleMessage("Ничего не найдено"),
    "searchingForTracks" : MessageLookupByLibrary.simpleMessage("Ищем треки..."),
    "secondsShorthand" : MessageLookupByLibrary.simpleMessage("с"),
    "settingLightMode" : MessageLookupByLibrary.simpleMessage("Светлая тема"),
    "settings" : MessageLookupByLibrary.simpleMessage("Настройки"),
    "shuffled" : MessageLookupByLibrary.simpleMessage("Перемешано"),
    "songInformation" : MessageLookupByLibrary.simpleMessage("Информация о треке"),
    "sort" : MessageLookupByLibrary.simpleMessage("Сортировка"),
    "theme" : MessageLookupByLibrary.simpleMessage("Тема"),
    "title" : MessageLookupByLibrary.simpleMessage("Название"),
    "tracks" : MessageLookupByLibrary.simpleMessage("Треки"),
    "tracksPlural" : m2,
    "unknownRoute" : MessageLookupByLibrary.simpleMessage("Неизвестная страница!"),
    "upNext" : MessageLookupByLibrary.simpleMessage("Далее"),
    "year" : MessageLookupByLibrary.simpleMessage("Год")
  };
}
