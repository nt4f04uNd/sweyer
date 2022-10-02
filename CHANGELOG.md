## 1.0.8

- Added favorites
- Added German language support
- Added "Player color theme" setting
- Changed notification stop icon
- Fixed back button on dialogs
- Other bug fixes
- Not important for users:
  - Flutter 3 migration
  - Rewrite theme with ThemeExtensions
  - CI
  - Automatic and golden tests

All the work related to this version can be found in this [project](https://github.com/users/nt4f04uNd/projects/4/views/1)

## 1.0.7

- Fix bug that localization didn't fallback to English as a default language

## 1.0.6

- Fix scrollbar crash
- Not important for users:
  - bump dependencies and enable sound null-safety
  - dropped unmaintained `intl_localizations` package in favour of Flutter's `gen_l10n`

## 1.0.5

- Fixed crash when album art couldn't be loaded on Android 10+
- Fixed that new playlist action in playlists tab could be tapped in selection

## 1.0.4

- Added playlists and artists
- Added more selection actions
- In deletion prompts added a preview of the arts of the content that is being deleted
- Other fixes and cosmetic changes

## 1.0.3

- Fix issue with current song not updated on search route

## 1.0.2

- Selection is now everywhere - all songs, all albums, queue, search route - every content entry is now selectable
- Added play all/shuffle buttons to main screen and albums
- Enhanced the search route by adding filtering by content category
- Now all queues are saved/restored. Prior in a lot of cases the queue was intentionally not restored
- Album origins are now restored, that means if you queue some album, after app reload when song from
  this album will be played, the playing indicator will indicate the album as playing. Prior, the origin
  was saved only for the current app session, when it was added, and was not restored.
- Optimized scrollbar and listviews
- Became media browser service, support for Android Auto
- Fixed that album arts were not re-cached (below Android 10)
- Refactored a lot of code and fixed a lot of other bugs
- Changed player backend (non-UX)

## 1.0.1

- localization (ru, en)
- revamped design, changed logo, some fancy animations
- ability to change primary color in theme settings
- bottom bar is now swipeable
- sidebar can be swiped out from any place on the screen
- albums
- queue system
- deleting songs

## 1.0.0

- basic playback
- dark and light theme