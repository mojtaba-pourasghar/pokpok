# فیلم‌نامه‌ی ضبط صدای پوپو

> این فایل خودکار از `assets/content/voice_lines.json` ساخته می‌شود (`python3 tools/voice/make_recording_script.py`). متن‌ها را در همان JSON اصلاح کنید.

## گوینده

- **شخصیت:** پوپو — خرس کوچولوی نارنجی؛ صدای گرم، شاد و آرام، مناسب کودک ۲ تا ۸ سال
- **مخاطب:** کودکان ۳ تا ۸ سال. آهسته‌تر از گفت‌وگوی معمولی، با مکث کوتاه بعد از هر جمله.
- **تلفظ:** فارسی معیار و روشن، بدون لهجه‌ی غلیظ.
- **ممنوع:** نام پاسخ درست را در پرسش‌ها با تأکید نگویید؛ در دلگرمی‌ها هیچ لحن سرزنش‌آمیزی نباشد.

## مشخصات فنی

- هر جمله یک فایل جدا، با **دقیقاً** همان نام ستون «فایل».
- ضبط: WAV، ۴۸ کیلوهرتز، ۲۴ بیت، مونو، اتاق بی‌پژواک، فاصله‌ی ثابت از میکروفون.
- تحویل نهایی (اسکریپت `tools/voice/import_recordings.sh` خودش می‌سازد): MP3 مونو 96 kbps، بلندی -16 LUFS، 80 میلی‌ثانیه سکوت اول و 150 میلی‌ثانیه آخر.
- از هر جمله‌ی مهم دو برداشت ضبط کنید؛ بهترین را با همان نام تحویل دهید.

تعداد کل جمله‌ها: **68**

## صفحه‌ها و خوشامد

*لحن:* گرم و صمیمی، با لبخند. آرام شروع کنید و انتهای جمله را بالا ببرید.

| # | فایل | متن | کجا پخش می‌شود |
|---|---|---|---|
| 1 | `app_splash_welcome.mp3` | سلام! من پوپو هستم. ببین، لمس کن، کشف کن! | splash.shown |
| 2 | `app_intro_1.mp3` | سلام دوست کوچولو! من پوپو هستم، یک خرس کوچولو که عاشق بازی است. | intro.page1 |
| 3 | `app_intro_2.mp3` | هر چیزی را که دوست داری لمس کن. ببین چه اتفاقی می‌افتد! | intro.page2 |
| 4 | `app_intro_3.mp3` | می‌توانی چیزها را بکشی و جابه‌جا کنی. بیا با هم دنیا را کشف کنیم! | intro.page3 |
| 5 | `app_profiles_pick.mp3` | کی می‌خواهد بازی کند؟ عکس خودت را لمس کن. | profiles.shown |
| 6 | `app_map_hello.mp3` | کجا برویم؟ یک جا را روی نقشه لمس کن. | map.shown |
| 7 | `app_map_back.mp3` | دوباره سلام! بیا ادامه بدهیم. | map.resume |
| 8 | `world_home_hello.mp3` | این خانه‌ی من است! بیا اتاق‌ها را ببینیم. | world.home.open |
| 9 | `world_city_hello.mp3` | به شهر بازی خوش آمدی! ماشین‌ها را روی جاده ببر. | world.city.open |
| 10 | `world_nature_hello.mp3` | چه طبیعت قشنگی! حیوان‌ها را لمس کن تا صدایشان را بشنوی. | world.nature.open |
| 11 | `world_art_hello.mp3` | وقت نقاشی است! یک رنگ انتخاب کن و بکش. | world.art.open |
| 12 | `world_music_hello.mp3` | بیا موسیقی بسازیم! کلیدها را بزن. | world.music.open |
| 13 | `world_build_hello.mp3` | کارگاه ساخت‌وساز! قطعه‌ها را بکش و چیزی بساز. | world.build.open |
| 14 | `scene_home_living.mp3` | این اتاق پذیرایی است. چراغ را روشن کن! | scene.home.living.open |
| 15 | `scene_home_kitchen.mp3` | آشپزخانه! میوه‌ها را در بشقاب بگذار. | scene.home.kitchen.open |
| 16 | `scene_home_bedroom.mp3` | اتاق خواب! اسباب‌بازی‌ها را جابه‌جا کن. | scene.home.bedroom.open |
| 17 | `scene_home_bathroom.mp3` | حمام! اردک را در وان بگذار. | scene.home.bathroom.open |
| 18 | `scene_city_street.mp3` | ماشین را بگیر و روی جاده حرکت بده. | scene.city.street.open |
| 19 | `scene_city_park.mp3` | پارک! اینجا بازی کنیم. | scene.city.park.open |
| 20 | `scene_nature_forest.mp3` | جنگل! درخت‌ها و حیوان‌ها را لمس کن. | scene.nature.forest.open |
| 21 | `scene_nature_garden.mp3` | باغ! با آب‌پاش به گل‌ها آب بده. | scene.nature.garden.open |
| 22 | `scene_nature_pond.mp3` | برکه! ماهی و اردک را پیدا کن. | scene.nature.pond.open |
| 23 | `scene_nature_farm.mp3` | مزرعه! به حیوان‌ها غذا بده. | scene.nature.farm.open |
| 24 | `art_hello.mp3` | یک رنگ انتخاب کن و با انگشتت بکش. | art.open |
| 25 | `art_saved.mp3` | آفرین! نقاشی‌ات ذخیره شد. | art.saved |
| 26 | `art_clear_ask.mp3` | همه‌ی نقاشی پاک شود؟ | art.clear |
| 27 | `art_gallery.mp3` | این‌ها نقاشی‌های تو هستند! | art.gallery |
| 28 | `music_hello.mp3` | یک ساز انتخاب کن و بزن! | music.open |
| 29 | `music_record.mp3` | دکمه‌ی قرمز را بزن تا آهنگت را ضبط کنم. | music.record.hint |
| 30 | `music_recording.mp3` | دارم گوش می‌دهم... بزن! | music.record.start |
| 31 | `music_saved.mp3` | آهنگ تو ذخیره شد! دکمه‌ی پخش را بزن. | music.saved |
| 32 | `build_hello.mp3` | قطعه‌ها را از پایین بکش و روی زمین بگذار. | build.open |
| 33 | `build_gears.mp3` | چرخ‌دنده‌ها کنار هم می‌چرخند! چند تا کنار هم بگذار. | build.gears |
| 34 | `build_remove.mp3` | برای برداشتن، قطعه را روی سطل بکش. | build.remove.hint |
| 35 | `puzzle_shapes.mp3` | هر شکل را روی سایه‌ی خودش بگذار. | puzzle.shapes.open |
| 36 | `puzzle_sort.mp3` | هر چیز را در سبد هم‌رنگش بگذار. | puzzle.sort.open |
| 37 | `puzzle_pattern.mp3` | بعدی چیست؟ الگو را کامل کن. | puzzle.pattern.open |
| 38 | `puzzle_match.mp3` | جفت‌ها را پیدا کن. کارت‌ها را برگردان. | puzzle.match.open |
| 39 | `puzzle_try.mp3` | نزدیک بود! یک بار دیگر امتحان کن. | puzzle.try |
| 40 | `puzzle_try_2.mp3` | اشکالی ندارد، دوباره امتحان کن. | puzzle.try |
| 41 | `play_cook_hello.mp3` | بیا سوپ بپزیم! سبزی‌ها را در قابلمه بریز. | play.cook.open |
| 42 | `play_shop_hello.mp3` | فروشگاه! چیزهای فهرست را در سبد بگذار. | play.shop.open |
| 43 | `play_garden_hello.mp3` | دانه را بکار و با آب‌پاش آبش بده. | play.garden.open |
| 44 | `play_pet_hello.mp3` | سگ کوچولو گرسنه است! به او غذا بده. | play.pet.open |
| 45 | `play_tidy_hello.mp3` | اتاق به هم ریخته! اسباب‌بازی‌ها را در سبد بگذار. | play.tidy.open |
| 46 | `play_cook_done.mp3` | به‌به! سوپ آماده شد! | play.cook.done |
| 47 | `play_shop_done.mp3` | همه را خریدی! آفرین! | play.shop.done |
| 48 | `play_garden_done.mp3` | وای! دانه گل شد! | play.garden.done |
| 49 | `play_pet_done.mp3` | سگ کوچولو سیر شد و خوشحال است! | play.pet.done |
| 50 | `play_tidy_done.mp3` | اتاق مرتب شد! چه عالی! | play.tidy.done |
| 51 | `praise_1.mp3` | آفرین! | praise |
| 52 | `praise_2.mp3` | چه عالی! | praise |
| 53 | `praise_3.mp3` | تو فوق‌العاده‌ای! | praise |
| 54 | `praise_4.mp3` | هورا! | praise |
| 55 | `praise_5.mp3` | خیلی خوب بود! | praise |
| 56 | `praise_6.mp3` | باریکلا! | praise |
| 57 | `sticker_new.mp3` | یک برچسب تازه گرفتی! در دفتر خاطره‌هایت است. | sticker.earned |
| 58 | `rewards_hello.mp3` | این‌ها خاطره‌های تو هستند! | rewards.open |
| 59 | `rewards_empty.mp3` | هنوز برچسبی نداری. بیا بازی کنیم! | rewards.empty |
| 60 | `library_hello.mp3` | چه بازی‌ای دوست داری؟ | library.open |
| 61 | `parent_ask.mp3` | این بخش برای بزرگ‌ترهاست. از مامان یا بابا کمک بگیر. | parent.gate |

## وقتی کودک مکث می‌کند

*لحن:* صبور و نرم.

| # | فایل | متن | کجا پخش می‌شود |
|---|---|---|---|
| 1 | `idle_1.mp3` | این چیه؟ لمسش کن! | idle |
| 2 | `idle_2.mp3` | ببین اینجا چی هست! | idle |
| 3 | `idle_3.mp3` | می‌خواهی این را جابه‌جا کنی؟ | idle |

## توقف، ادامه، خروج

*لحن:* آرام و ساده.

| # | فایل | متن | کجا پخش می‌شود |
|---|---|---|---|
| 1 | `session_pause.mp3` | بازی ایستاد. هر وقت خواستی ادامه بده. | pause |
| 2 | `session_resume.mp3` | برگشتی! بیا ادامه بدهیم. | resume |
| 3 | `session_bye.mp3` | خداحافظ! زود برگرد. | exit |
| 4 | `session_sleepy.mp3` | پوپو کمی خسته است... شاید وقت استراحت باشد. | time.limit |
