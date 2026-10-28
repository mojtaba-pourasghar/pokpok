# فیلم‌نامه‌ی ضبط صدای پوپو

> این فایل خودکار از `assets/content/voice_lines.json` ساخته می‌شود (`python3 tools/voice/make_recording_script.py`). متن‌ها را در همان JSON اصلاح کنید.

## گوینده

- **شخصیت:** پوپو — روباه کوچولوی دختر؛ صدای دخترانه‌ی گرم، شاد و آرام، مناسب کودک ۲ تا ۸ سال
- **مخاطب:** کودکان ۳ تا ۸ سال. آهسته‌تر از گفت‌وگوی معمولی، با مکث کوتاه بعد از هر جمله.
- **تلفظ:** فارسی معیار و روشن، بدون لهجه‌ی غلیظ.
- **ممنوع:** نام پاسخ درست را در پرسش‌ها با تأکید نگویید؛ در دلگرمی‌ها هیچ لحن سرزنش‌آمیزی نباشد.

## مشخصات فنی

- هر جمله یک فایل جدا، با **دقیقاً** همان نام ستون «فایل».
- ضبط: WAV، ۴۸ کیلوهرتز، ۲۴ بیت، مونو، اتاق بی‌پژواک، فاصله‌ی ثابت از میکروفون.
- تحویل نهایی (اسکریپت `tools/voice/import_recordings.sh` خودش می‌سازد): MP3 مونو 96 kbps، بلندی -16 LUFS، 80 میلی‌ثانیه سکوت اول و 150 میلی‌ثانیه آخر.
- از هر جمله‌ی مهم دو برداشت ضبط کنید؛ بهترین را با همان نام تحویل دهید.

تعداد کل جمله‌ها: **518**

## صفحه‌ها و خوشامد

*لحن:* گرم و صمیمی، با لبخند. آرام شروع کنید و انتهای جمله را بالا ببرید.

| # | فایل | متن | کجا پخش می‌شود |
|---|---|---|---|
| 1 | `app_splash_welcome.mp3` | سلام! من پوپو هستم. ببین، لمس کن، کشف کن! | splash.shown |
| 2 | `app_intro_1.mp3` | سلام دوست کوچولو! من پوپو هستم، یک روباه کوچولو که عاشق بازی است. | intro.page1 |
| 3 | `app_intro_2.mp3` | هر چیزی را که دوست داری لمس کن. ببین چه اتفاقی می‌افتد! | intro.page2 |
| 4 | `app_intro_3.mp3` | می‌توانی چیزها را بکشی و جابه‌جا کنی. بیا با هم دنیا را کشف کنیم! | intro.page3 |
| 5 | `app_profiles_pick.mp3` | کی می‌خواهد بازی کند؟ عکس خودت را لمس کن. | profiles.shown |
| 6 | `praise_1.mp3` | آفرین! | praise |
| 7 | `praise_2.mp3` | چه عالی! | praise |
| 8 | `praise_3.mp3` | تو فوق‌العاده‌ای! | praise |
| 9 | `praise_4.mp3` | هورا! | praise |
| 10 | `praise_5.mp3` | خیلی خوب بود! | praise |
| 11 | `praise_6.mp3` | باریکلا! | praise |
| 12 | `sticker_new.mp3` | یک برچسب تازه گرفتی! در دفتر خاطره‌هایت است. | sticker.earned |
| 13 | `parent_ask.mp3` | این بخش برای بزرگ‌ترهاست. از مامان یا بابا کمک بگیر. | parent.gate |
| 14 | `full_locked.mp3` | این‌جا مال نسخه‌ی کامله. از مامان یا بابا بخواه برات بازش کنن! | paywall.shown |
| 15 | `notice_new.mp3` | یه خبر تازه داریم! بیا ببین. | notice.shown |
| 16 | `c1_intro.mp3` | طوفان آشپزخانه‌ی خاله خرسی را به هم ریخته و برای جشن هیچ غذایی نمانده. بیا با هم آشپزی کنیم! | c1.intro |
| 17 | `c1_film_1.mp3` | آب‌پرتقال شیرین و ترش | c1.film.1 |
| 18 | `c1_film_2.mp3` | نان ترد و گرم | c1.film.2 |
| 19 | `c1_film_3.mp3` | سوپ داغ و خوشمزه | c1.film.3 |
| 20 | `c1_film_4.mp3` | و کیک تولد با شمع‌های روشن! | c1.film.4 |
| 21 | `c1_next.mp3` | بانی در باغ تشنه است... بیا برویم پیشش! | c1.next |
| 22 | `c1s1_mission.mp3` | خاله خرسی تشنه است. بیا برایش آب‌پرتقال درست کنیم! | c1s1.mission |
| 23 | `c1s1_s1.mp3` | پرتقال‌های رسیده را از درخت بچین. | c1s1.s1 |
| 24 | `c1s1_s2.mp3` | پرتقال را از وسط نصف کن. انگشتت را روی خط بکش. | c1s1.s2 |
| 25 | `c1s1_s3.mp3` | پرتقال را روی آب‌گیری فشار بده! تند تند بزن. | c1s1.s3 |
| 26 | `c1s1_s4.mp3` | حالا آب‌میوه را در لیوان بریز. تا خط پر کن، نه بیشتر! | c1s1.s4 |
| 27 | `item_juice_made.mp3` | آفرین! آب‌پرتقال آماده شد! | item.juice.made |
| 28 | `c1s2_mission.mp3` | برای ناهار نان لازم داریم. بیا نان بپزیم! | c1s2.mission |
| 29 | `c1s2_s1.mp3` | آرد را در کاسه بریز. | c1s2.s1 |
| 30 | `c1s2_s2.mp3` | کمی آب هم اضافه کن. | c1s2.s2 |
| 31 | `c1s2_s3.mp3` | خمیر را ورز بده! با هر ضربه نرم‌تر می‌شود. | c1s2.s3 |
| 32 | `c1s2_s4.mp3` | نان را در فر گذاشتیم. وقتی طلایی شد، بزن! | c1s2.s4 |
| 33 | `item_bread_made.mp3` | آفرین! نان آماده شد! | item.bread.made |
| 34 | `c1s3_mission.mp3` | باد سرد می‌آید. یک سوپ گرم بپزیم! | c1s3.mission |
| 35 | `c1s3_s1.mp3` | سبزی‌های سالم را در سبد بگذار و خراب‌ها را در سطل. | c1s3.s1 |
| 36 | `c1s3_s2.mp3` | هویج را خرد کن. | c1s3.s2 |
| 37 | `c1s3_s3.mp3` | سه تکه هویج در قابلمه بینداز. | c1s3.s3 |
| 38 | `c1s3_s4.mp3` | سوپ را هم بزن. انگشتت را دور قابلمه بچرخان. | c1s3.s4 |
| 39 | `item_soup_made.mp3` | آفرین! سوپ سبزیجات آماده شد! | item.soup.made |
| 40 | `c1s4_mission.mp3` | امروز تولد خاله خرسی است! بیا کیک بپزیم. | c1s4.mission |
| 41 | `c1s4_s1.mp3` | تخم‌مرغ‌ها را بشکن. روی هر کدام بزن. | c1s4.s1 |
| 42 | `c1s4_s2.mp3` | آرد را اضافه کن. | c1s4.s2 |
| 43 | `c1s4_s3.mp3` | خوب هم بزن تا خمیر کیک صاف شود. | c1s4.s3 |
| 44 | `c1s4_s4.mp3` | کیک را با رنگ‌های خوشمزه تزئین کن. | c1s4.s4 |
| 45 | `c1s4_s5.mp3` | چهار شمع روی کیک بگذار. | c1s4.s5 |
| 46 | `item_cake_made.mp3` | آفرین! کیک تولد آماده شد! | item.cake.made |
| 47 | `c2_intro.mp3` | بانی تشنه است و باغش خشک شده. کمکش کنیم باغ دوباره سبز شود! | c2.intro |
| 48 | `c2_film_1.mp3` | آب‌پاش، گل‌ها را سیراب کرد | c2.film.1 |
| 49 | `c2_film_2.mp3` | گلدان گل، زنبورها را آورد | c2.film.2 |
| 50 | `c2_film_3.mp3` | مرغ‌ها تخم گذاشتند | c2.film.3 |
| 51 | `c2_film_4.mp3` | و ساندویچ پنیر برای پیک‌نیک! | c2.film.4 |
| 52 | `c2_next.mp3` | کارگاه آقا سنجاب خراب شده... بیا کمکش کنیم! | c2.next |
| 53 | `c2s1_mission.mp3` | بانی خیلی تشنه است و حرف نمی‌زند! اول یک چیزی برای نوشیدن بهش بده. | c2s1.mission |
| 54 | `c2s1_s1.mp3` | از کوله‌پشتی چیزی بده که تشنگی را برطرف کند. | c2s1.s1 |
| 55 | `c2s1_s1_done.mp3` | به به! بانی سرحال شد. | c2s1.s1.done |
| 56 | `c2s1_s1_why.mp3` | این برای رفع تشنگی نیست. | c2s1.s1.why |
| 57 | `c2s1_s2.mp3` | تکه‌های آب‌پاش را سر جایشان بگذار. | c2s1.s2 |
| 58 | `c2s1_s3.mp3` | دسته‌ی چاه را بچرخان تا آب بالا بیاید. | c2s1.s3 |
| 59 | `c2s1_s4.mp3` | آب‌پاش را پر کن. | c2s1.s4 |
| 60 | `item_watering_can_made.mp3` | آفرین! آب‌پاش آماده شد! | item.watering_can.made |
| 61 | `c2s2_mission.mp3` | بانی می‌خواهد یک گل قشنگ بکارد. | c2s2.mission |
| 62 | `c2s2_s1.mp3` | خاک را با بیلچه بکن. | c2s2.s1 |
| 63 | `c2s2_s2.mp3` | سه دانه در خاک بکار. | c2s2.s2 |
| 64 | `c2s2_s3.mp3` | دانه‌ها تشنه‌اند! از کوله چیزی بیاور که با آن آب بدهیم. | c2s2.s3 |
| 65 | `c2s2_s3_done.mp3` | آفرین! دانه‌ها آب خوردند. | c2s2.s3.done |
| 66 | `c2s2_s3_why.mp3` | با این نمی‌شود آب داد. | c2s2.s3.why |
| 67 | `c2s2_s4.mp3` | جوانه دارد بزرگ می‌شود... وقتی گل باز شد بزن! | c2s2.s4 |
| 68 | `item_flower_pot_made.mp3` | آفرین! گلدان گل آماده شد! | item.flower_pot.made |
| 69 | `c2s3_mission.mp3` | مرغ‌های بانی لانه ندارند و گم شده‌اند! | c2s3.mission |
| 70 | `c2s3_s1.mp3` | کاه جمع کن. | c2s3.s1 |
| 71 | `c2s3_s2.mp3` | کاه‌ها را در لانه بگذار. | c2s3.s2 |
| 72 | `c2s3_s3.mp3` | مرغ‌های گم‌شده را پیدا کن. پشت بوته‌ها را ببین! | c2s3.s3 |
| 73 | `item_eggs_made.mp3` | آفرین! تخم‌مرغ آماده شد! | item.eggs.made |
| 74 | `c2s4_mission.mp3` | وقت پیک‌نیک است! یک ساندویچ خوشمزه درست کنیم. | c2s4.mission |
| 75 | `c2s4_s1.mp3` | گاو را آرام بدوش. با هر ضربه شیر می‌آید. | c2s4.s1 |
| 76 | `c2s4_s2.mp3` | شیر را هم بزن تا پنیر شود. | c2s4.s2 |
| 77 | `c2s4_s3.mp3` | برای ساندویچ نان لازم داریم! از کوله بیاور. | c2s4.s3 |
| 78 | `c2s4_s3_done.mp3` | نان رسید! | c2s4.s3.done |
| 79 | `c2s4_s3_why.mp3` | این نان نیست. | c2s4.s3.why |
| 80 | `c2s4_s4.mp3` | ساندویچ را لایه‌لایه بچین: نان، کاهو، پنیر، نان. | c2s4.s4 |
| 81 | `item_sandwich_made.mp3` | آفرین! ساندویچ پنیر آماده شد! | item.sandwich.made |
| 82 | `c3_intro.mp3` | طوفان کارگاه آقا سنجاب را خراب کرده و ابزارهایش پخش شده‌اند. بیا ابزار بسازیم! | c3.intro |
| 83 | `c3_film_1.mp3` | چکش، میخ را فرو کرد: تق تق! | c3.film.1 |
| 84 | `c3_film_2.mp3` | چراغ‌قوه تاریکی را روشن کرد | c3.film.2 |
| 85 | `c3_film_3.mp3` | گاری جعبه‌ها را برد | c3.film.3 |
| 86 | `c3_film_4.mp3` | و ماشین با کلید روشن شد: برووووم! | c3.film.4 |
| 87 | `c3_next.mp3` | کوکو همه‌ی رنگ‌هایش را گم کرده... | c3.next |
| 88 | `c3s1_mission.mp3` | آقا سنجاب چکشش را گم کرده. تکه‌هایش این‌جا پخش شده‌اند! | c3s1.mission |
| 89 | `c3s1_s1.mp3` | سر چکش را در کارگاه شلوغ پیدا کن. | c3s1.s1 |
| 90 | `c3s1_s2.mp3` | دسته‌ی چوبی را هم پیدا کن. | c3s1.s2 |
| 91 | `c3s1_s3.mp3` | سر و دسته را به هم وصل کن. | c3s1.s3 |
| 92 | `c3s1_s4.mp3` | پیچ را سفت کن. | c3s1.s4 |
| 93 | `item_hammer_made.mp3` | آفرین! چکش آماده شد! | item.hammer.made |
| 94 | `c3s2_mission.mp3` | گوشه‌ی کارگاه خیلی تاریک است! | c3s2.mission |
| 95 | `c3s2_s1.mp3` | باتری‌ها را در چراغ‌قوه بگذار. | c3s2.s1 |
| 96 | `c3s2_s2.mp3` | لامپ را بپیچان. | c3s2.s2 |
| 97 | `c3s2_s3.mp3` | کلید را بزن! | c3s2.s3 |
| 98 | `c3s2_s4.mp3` | با نور، جعبه‌های گم‌شده را در تاریکی پیدا کن. | c3s2.s4 |
| 99 | `item_flashlight_made.mp3` | آفرین! چراغ‌قوه آماده شد! | item.flashlight.made |
| 100 | `c3s3_mission.mp3` | جعبه‌ها خیلی سنگین‌اند. یک گاری لازم داریم! | c3s3.mission |
| 101 | `c3s3_s1.mp3` | تخته‌ها باید با میخ به هم وصل شوند. چه وسیله‌ای لازم است؟ | c3s3.s1 |
| 102 | `c3s3_s1_done.mp3` | تق تق! تخته‌ها وصل شدند. | c3s3.s1.done |
| 103 | `c3s3_s1_why.mp3` | با این نمی‌شود میخ زد. | c3s3.s1.why |
| 104 | `c3s3_s2.mp3` | میخ‌ها را با چکش بکوب! | c3s3.s2 |
| 105 | `c3s3_s3.mp3` | دو چرخ به گاری وصل کن. | c3s3.s3 |
| 106 | `item_cart_made.mp3` | آفرین! گاری آماده شد! | item.cart.made |
| 107 | `c3s4_mission.mp3` | آقا سنجاب یک ماشین قدیمی دارد. بیا درستش کنیم! | c3s4.mission |
| 108 | `c3s4_s1.mp3` | چهار چرخ به ماشین وصل کن. بشمار! | c3s4.s1 |
| 109 | `c3s4_s2.mp3` | ماشین را رنگ کن. | c3s4.s2 |
| 110 | `c3s4_s3.mp3` | کلید را بچرخان تا ماشین روشن شود! | c3s4.s3 |
| 111 | `item_toy_car_made.mp3` | آفرین! ماشین اسباب‌بازی آماده شد! | item.toy_car.made |
| 112 | `c4_intro.mp3` | کوکو همه‌ی رنگ‌هایش را در طوفان گم کرده و تزئینات جشن بی‌رنگ مانده‌اند. | c4.intro |
| 113 | `c4_film_1.mp3` | قرمز و زرد، نارنجی شد! | c4.film.1 |
| 114 | `c4_film_2.mp3` | کاسه‌ی گلی آب را نگه داشت | c4.film.2 |
| 115 | `c4_film_3.mp3` | فانوس با لامپ چراغ‌قوه روشن شد | c4.film.3 |
| 116 | `c4_film_4.mp3` | و ماسک‌ها و پرچم‌ها رنگی شدند! | c4.film.4 |
| 117 | `c4_next.mp3` | مادربزرگ جغد راه خانه‌اش را در شب گم کرده... | c4.next |
| 118 | `c4s1_mission.mp3` | اول یک قلم‌مو و رنگ می‌خواهیم! | c4s1.mission |
| 119 | `c4s1_s1.mp3` | موهای قلم‌مو را به دسته وصل کن. | c4s1.s1 |
| 120 | `c4s1_s2.mp3` | قرمز و زرد را با هم مخلوط کن. چه رنگی شد؟ | c4s1.s2 |
| 121 | `c4s1_s3.mp3` | حالا آبی و زرد! | c4s1.s3 |
| 122 | `item_paints_made.mp3` | آفرین! رنگ‌ها آماده شد! | item.paints.made |
| 123 | `c4s2_mission.mp3` | کوکو یک کاسه برای آب رنگ‌ها می‌خواهد. | c4s2.mission |
| 124 | `c4s2_s1.mp3` | گل رس خشک است! با چه خیسش کنیم؟ | c4s2.s1 |
| 125 | `c4s2_s1_done.mp3` | شُر شُر! گل نرم شد. | c4s2.s1.done |
| 126 | `c4s2_s1_why.mp3` | با این نمی‌شود خیس کرد. | c4s2.s1.why |
| 127 | `c4s2_s2.mp3` | گل را ورز بده. | c4s2.s2 |
| 128 | `c4s2_s3.mp3` | چرخ سفالگری را بچرخان تا کاسه شکل بگیرد. | c4s2.s3 |
| 129 | `c4s2_s4.mp3` | کاسه را رنگ کن. | c4s2.s4 |
| 130 | `item_clay_bowl_made.mp3` | آفرین! کاسه‌ی گلی آماده شد! | item.clay_bowl.made |
| 131 | `c4s3_mission.mp3` | برای شب جشن فانوس رنگی لازم داریم. | c4s3.mission |
| 132 | `c4s3_s1.mp3` | کاغذ را روی خط‌ها ببُر. | c4s3.s1 |
| 133 | `c4s3_s2.mp3` | فانوس را رنگ کن. | c4s3.s2 |
| 134 | `c4s3_s3.mp3` | فانوس نور ندارد! چه چیزی لامپ دارد؟ | c4s3.s3 |
| 135 | `c4s3_s3_done.mp3` | روشن شد! چه قشنگ. | c4s3.s3.done |
| 136 | `c4s3_s3_why.mp3` | این نور ندارد. | c4s3.s3.why |
| 137 | `item_lantern_made.mp3` | آفرین! فانوس آماده شد! | item.lantern.made |
| 138 | `c4s4_mission.mp3` | برای جشن ماسک و پرچم درست کنیم! | c4s4.mission |
| 139 | `c4s4_s1.mp3` | ماسک را با قیچی ببُر. | c4s4.s1 |
| 140 | `c4s4_s2.mp3` | ماسک را رنگ کن. | c4s4.s2 |
| 141 | `c4s4_s3.mp3` | پنج پرچم به نخ آویزان کن. | c4s4.s3 |
| 142 | `item_mask_made.mp3` | آفرین! ماسک آماده شد! | item.mask.made |
| 143 | `c5_intro.mp3` | مادربزرگ جغد راه خانه‌اش را در جنگلِ شب گم کرده. نترس، با هم پیدایش می‌کنیم! | c5.intro |
| 144 | `c5_film_1.mp3` | نقشه راه را نشان داد | c5.film.1 |
| 145 | `c5_film_2.mp3` | چادر ما را از باران حفظ کرد | c5.film.2 |
| 146 | `c5_film_3.mp3` | کرم‌های شب‌تاب مسیر را روشن کردند | c5.film.3 |
| 147 | `c5_film_4.mp3` | و با تلسکوپ ماه را دیدیم! | c5.film.4 |
| 148 | `c5_next.mp3` | سازهای گروه میمی شکسته‌اند... | c5.next |
| 149 | `c5s1_mission.mp3` | تکه‌های نقشه در باد پخش شده‌اند! | c5s1.mission |
| 150 | `c5s1_s1.mp3` | تکه‌های نقشه را کنار هم بچین. | c5s1.s1 |
| 151 | `c5s1_s2.mp3` | با انگشت راه را از خانه‌ی جغد تا درخت بزرگ دنبال کن. | c5s1.s2 |
| 152 | `item_map_made.mp3` | آفرین! نقشه‌ی جنگل آماده شد! | item.map.made |
| 153 | `c5s2_mission.mp3` | باران دارد می‌آید! یک چادر بزنیم. | c5s2.mission |
| 154 | `c5s2_s1.mp3` | پارچه و ستون‌های چادر را سر جایشان بگذار. | c5s2.s1 |
| 155 | `c5s2_s2.mp3` | میخ‌های چادر را با چه بکوبیم؟ | c5s2.s2 |
| 156 | `c5s2_s2_done.mp3` | تق تق! چادر محکم شد. | c5s2.s2.done |
| 157 | `c5s2_s2_why.mp3` | با این نمی‌شود میخ زد. | c5s2.s2.why |
| 158 | `c5s2_s3.mp3` | همه‌ی میخ‌ها را بکوب. | c5s2.s3 |
| 159 | `item_tent_made.mp3` | آفرین! چادر آماده شد! | item.tent.made |
| 160 | `c5s3_mission.mp3` | مسیر خیلی تاریک است و مادربزرگ سردش است. | c5s3.mission |
| 161 | `c5s3_s1.mp3` | با چه چیزی تاریکی را روشن کنیم؟ | c5s3.s1 |
| 162 | `c5s3_s1_done.mp3` | روشن شد! | c5s3.s1.done |
| 163 | `c5s3_s1_why.mp3` | این نور ندارد. | c5s3.s1.why |
| 164 | `c5s3_s2.mp3` | کرم‌های شب‌تاب را در تاریکی پیدا کن و در شیشه بگذار. | c5s3.s2 |
| 165 | `c5s3_s3.mp3` | مادربزرگ جغد سردش است. از کوله چیزی بده که گرمش کند. | c5s3.s3 |
| 166 | `c5s3_s3_done.mp3` | آخیش! گرم شدم، ممنون عزیزم. | c5s3.s3.done |
| 167 | `c5s3_s3_why.mp3` | این گرم نمی‌کند. | c5s3.s3.why |
| 168 | `item_firefly_jar_made.mp3` | آفرین! شیشه‌ی کرم شب‌تاب آماده شد! | item.firefly_jar.made |
| 169 | `c5s4_mission.mp3` | مادربزرگ جغد می‌خواهد ستاره‌ها را نشانت بدهد. | c5s4.mission |
| 170 | `c5s4_s1.mp3` | مقوا را لوله کن. | c5s4.s1 |
| 171 | `c5s4_s2.mp3` | عدسی‌ها را از بزرگ به کوچک بگذار. | c5s4.s2 |
| 172 | `c5s4_s3.mp3` | تلسکوپ را تنظیم کن تا تصویر واضح شود. | c5s4.s3 |
| 173 | `item_telescope_made.mp3` | آفرین! تلسکوپ آماده شد! | item.telescope.made |
| 174 | `c6_intro.mp3` | میمی می‌خواهد در جشن بخواند، اما سازهای گروه در طوفان شکسته‌اند. | c6.intro |
| 175 | `c6_film_1.mp3` | طبل: بوم بوم! | c6.film.1 |
| 176 | `c6_film_2.mp3` | زایلوفون: زیر و بم | c6.film.2 |
| 177 | `c6_film_3.mp3` | نی: فووو | c6.film.3 |
| 178 | `c6_film_4.mp3` | و آهنگ جشن با همه‌ی سازها! | c6.film.4 |
| 179 | `c6_next.mp3` | پل شهر شکسته و اتوبوس لاکی خراب است... | c6.next |
| 180 | `c6s1_mission.mp3` | اول یک طبل محکم بسازیم! | c6s1.mission |
| 181 | `c6s1_s1.mp3` | برای بدنه‌ی طبل یک کاسه لازم داریم. | c6s1.s1 |
| 182 | `c6s1_s1_done.mp3` | این کاسه عالی است! | c6s1.s1.done |
| 183 | `c6s1_s1_why.mp3` | این کاسه نیست. | c6s1.s1.why |
| 184 | `c6s1_s2.mp3` | پوست طبل را روی کاسه بکش. | c6s1.s2 |
| 185 | `c6s1_s3.mp3` | طناب‌ها را سفت کن. هر بار بزن! | c6s1.s3 |
| 186 | `item_drum_made.mp3` | آفرین! طبل آماده شد! | item.drum.made |
| 187 | `c6s2_mission.mp3` | زایلوفون تیغه‌های رنگی دارد. | c6s2.mission |
| 188 | `c6s2_s1.mp3` | تیغه‌ها را از بلند به کوتاه بچین. | c6s2.s1 |
| 189 | `c6s2_s2.mp3` | تیغه‌ها با میخ به پایه وصل می‌شوند. چه وسیله‌ای لازم است؟ | c6s2.s2 |
| 190 | `c6s2_s2_done.mp3` | تق تق! | c6s2.s2.done |
| 191 | `c6s2_s2_why.mp3` | با این نمی‌شود میخ زد. | c6s2.s2.why |
| 192 | `c6s2_s3.mp3` | آهنگ میمی را تکرار کن! | c6s2.s3 |
| 193 | `item_xylophone_made.mp3` | آفرین! زایلوفون آماده شد! | item.xylophone.made |
| 194 | `c6s3_mission.mp3` | نی صدای پرنده‌ها را دارد. | c6s3.mission |
| 195 | `c6s3_s1.mp3` | نی را ببُر. | c6s3.s1 |
| 196 | `c6s3_s2.mp3` | جای سوراخ‌ها را لمس کن. | c6s3.s2 |
| 197 | `c6s3_s3.mp3` | فوت کن... حالا بزن! | c6s3.s3 |
| 198 | `item_flute_made.mp3` | آفرین! نی آماده شد! | item.flute.made |
| 199 | `c6s4_mission.mp3` | با سازهایی که ساختی آهنگ جشن را بسازیم! | c6s4.mission |
| 200 | `c6s4_s1.mp3` | آهنگ را تکرار کن. اول گوش کن! | c6s4.s1 |
| 201 | `item_song_made.mp3` | آفرین! آهنگ جشن آماده شد! | item.song.made |
| 202 | `c7_intro.mp3` | پل شهر شکسته و اتوبوس لاکی خراب شده. هیچ‌کس نمی‌تواند به جشن برسد! | c7.intro |
| 203 | `c7_film_1.mp3` | پل دوباره ساخته شد | c7.film.1 |
| 204 | `c7_film_2.mp3` | چراغ راهنمایی: قرمز بایست، سبز برو | c7.film.2 |
| 205 | `c7_film_3.mp3` | اتوبوس روشن شد: بوق بوق! | c7.film.3 |
| 206 | `c7_film_4.mp3` | و همه کارت دعوت گرفتند! | c7.film.4 |
| 207 | `c7_next.mp3` | همه آماده‌اند... وقت جشن بزرگ است! | c7.next |
| 208 | `c7s1_mission.mp3` | پل شکسته! ماشین‌ها نمی‌توانند رد شوند. | c7s1.mission |
| 209 | `c7s1_s1.mp3` | تخته‌ها سنگین‌اند. با چه بیاوریمشان؟ | c7s1.s1 |
| 210 | `c7s1_s1_done.mp3` | گاری تخته‌ها را آورد! | c7s1.s1.done |
| 211 | `c7s1_s1_why.mp3` | این بار نمی‌برد. | c7s1.s1.why |
| 212 | `c7s1_s2.mp3` | تخته‌ها را در جاهای خالی پل بگذار. | c7s1.s2 |
| 213 | `c7s1_s3.mp3` | تخته‌ها را با چه محکم کنیم؟ | c7s1.s3 |
| 214 | `c7s1_s3_done.mp3` | تق تق! پل محکم شد. | c7s1.s3.done |
| 215 | `c7s1_s3_why.mp3` | با این نمی‌شود میخ زد. | c7s1.s3.why |
| 216 | `item_bridge_made.mp3` | آفرین! پل آماده شد! | item.bridge.made |
| 217 | `c7s2_mission.mp3` | چراغ راهنمایی خاموش است و ماشین‌ها گیج شده‌اند. | c7s2.mission |
| 218 | `c7s2_s1.mp3` | چراغ‌ها را به ترتیب بچین: قرمز، زرد، سبز. | c7s2.s1 |
| 219 | `c7s2_s2.mp3` | رنگ چراغ‌ها رفته! چه چیزی رنگ دارد؟ | c7s2.s2 |
| 220 | `c7s2_s2_done.mp3` | رنگی شد! | c7s2.s2.done |
| 221 | `c7s2_s2_why.mp3` | این رنگ ندارد. | c7s2.s2.why |
| 222 | `c7s2_s3.mp3` | چراغ را عوض کن: قرمز، زرد، سبز! | c7s2.s3 |
| 223 | `item_traffic_light_made.mp3` | آفرین! چراغ راهنمایی آماده شد! | item.traffic_light.made |
| 224 | `c7s3_mission.mp3` | اتوبوس لاکی پنچر و کثیف و بی‌بنزین است! | c7s3.mission |
| 225 | `c7s3_s1.mp3` | پیچ‌های لاستیک نو را ببند. | c7s3.s1 |
| 226 | `c7s3_s2.mp3` | اتوبوس را بشور. گل‌ها را پاک کن! | c7s3.s2 |
| 227 | `c7s3_s3.mp3` | باک را پر کن. | c7s3.s3 |
| 228 | `c7s3_s4.mp3` | حالا روشنش کن! | c7s3.s4 |
| 229 | `item_bus_made.mp3` | آفرین! اتوبوس آماده شد! | item.bus.made |
| 230 | `c7s4_mission.mp3` | باید همه را به جشن دعوت کنیم! | c7s4.mission |
| 231 | `c7s4_s1.mp3` | عکس دوستان را روی کارت درست کن. | c7s4.s1 |
| 232 | `c7s4_s2.mp3` | نامه‌ها را در صندوق بینداز. | c7s4.s2 |
| 233 | `c7s4_s3.mp3` | خانه‌ها دورند. با چه نامه‌ها را برسانیم؟ | c7s4.s3 |
| 234 | `c7s4_s3_done.mp3` | برووووم! نامه‌ها رسیدند. | c7s4.s3.done |
| 235 | `c7s4_s3_why.mp3` | این حرکت نمی‌کند. | c7s4.s3.why |
| 236 | `c7s4_s4.mp3` | ماشین را در مسیر بران. | c7s4.s4 |
| 237 | `item_invitation_made.mp3` | آفرین! کارت دعوت آماده شد! | item.invitation.made |
| 238 | `c8_intro.mp3` | همه‌چیز آماده است! با چیزهایی که ساختی جشن بزرگ جنگل را برپا کنیم. | c8.intro |
| 239 | `c8_film_1.mp3` | میز جشن پر از غذاهای تو | c8.film.1 |
| 240 | `c8_film_2.mp3` | میدان با فانوس و پرچم‌های تو | c8.film.2 |
| 241 | `c8_film_3.mp3` | کنسرت با سازهای تو | c8.film.3 |
| 242 | `c8_film_4.mp3` | و تو قهرمان جنگل شدی! | c8.film.4 |
| 243 | `c8s1_mission.mp3` | مهمان‌ها گرسنه‌اند! هر کدام غذای دلخواهش را می‌خواهد. | c8s1.mission |
| 244 | `c8s1_s1.mp3` | به هر مهمان غذای دلخواهش را بده. | c8s1.s1 |
| 245 | `item_feast_made.mp3` | آفرین! میز جشن آماده شد! | item.feast.made |
| 246 | `c8s2_mission.mp3` | میدان جشن را قشنگ کنیم! | c8s2.mission |
| 247 | `c8s2_s1.mp3` | هر تزئین را به دوستی بده که می‌خواهد. | c8s2.s1 |
| 248 | `c8s2_s2.mp3` | پرچم‌ها را آویزان کن. | c8s2.s2 |
| 249 | `item_decorations_made.mp3` | آفرین! تزئینات جشن آماده شد! | item.decorations.made |
| 250 | `c8s3_mission.mp3` | وقت کنسرت میمی است! | c8s3.mission |
| 251 | `c8s3_s1.mp3` | سازها را به نوازنده‌ها بده. | c8s3.s1 |
| 252 | `c8s3_s2.mp3` | با گروه بنواز! | c8s3.s2 |
| 253 | `item_concert_made.mp3` | آفرین! کنسرت جشن آماده شد! | item.concert.made |
| 254 | `c8s4_mission.mp3` | آخرین کار: مهمان‌ها را بیاوریم و آتش‌بازی کنیم! | c8s4.mission |
| 255 | `c8s4_s1.mp3` | مهمان‌ها دورند. با چه بیاوریمشان؟ | c8s4.s1 |
| 256 | `c8s4_s1_done.mp3` | بوق بوق! همه رسیدند. | c8s4.s1.done |
| 257 | `c8s4_s1_why.mp3` | این همه را نمی‌آورد. | c8s4.s1.why |
| 258 | `c8s4_s2.mp3` | برای دیدن نمایش ستاره‌ها چه لازم است؟ | c8s4.s2 |
| 259 | `c8s4_s2_done.mp3` | وای! ستاره‌ها! | c8s4.s2.done |
| 260 | `c8s4_s2_why.mp3` | با این نمی‌شود دور را دید. | c8s4.s2.why |
| 261 | `c8s4_s3.mp3` | آتش‌بازی کن! روی آسمان بزن. | c8s4.s3 |
| 262 | `item_medal_made.mp3` | آفرین! مدال قهرمان جنگل آماده شد! | item.medal.made |
| 263 | `k_bubbles_mission.mp3` | بیا یک حباب‌ساز بسازیم! | k_bubbles.mission |
| 264 | `k_bubbles_s1.mp3` | صابون را در کاسه بریز. | k_bubbles.s1 |
| 265 | `k_bubbles_s2.mp3` | هم بزن. | k_bubbles.s2 |
| 266 | `k_bubbles_s3.mp3` | حباب‌ها را بترکان! | k_bubbles.s3 |
| 267 | `item_bubbles_made.mp3` | آفرین! حباب‌ساز آماده شد! | item.bubbles.made |
| 268 | `k_necklace_mission.mp3` | یک گردنبند رنگی بسازیم. | k_necklace.mission |
| 269 | `k_necklace_s1.mp3` | مهره‌ها را به نخ بکش. | k_necklace.s1 |
| 270 | `k_necklace_s2.mp3` | مهره‌ها را رنگ کن. | k_necklace.s2 |
| 271 | `item_necklace_made.mp3` | آفرین! گردنبند مهره‌ای آماده شد! | item.necklace.made |
| 272 | `k_kite_mission.mp3` | روز بادی است! بادبادک بسازیم. | k_kite.mission |
| 273 | `k_kite_s1.mp3` | کاغذ بادبادک را ببُر. | k_kite.s1 |
| 274 | `k_kite_s2.mp3` | بادبادک را رنگ کن. | k_kite.s2 |
| 275 | `k_kite_s3.mp3` | بادبادک را در باد بالا ببر. | k_kite.s3 |
| 276 | `item_kite_made.mp3` | آفرین! بادبادک آماده شد! | item.kite.made |
| 277 | `k_robot_mission.mp3` | یک ربات دوست بسازیم! | k_robot.mission |
| 278 | `k_robot_s1.mp3` | سر و بدنه‌ی ربات را وصل کن. | k_robot.s1 |
| 279 | `k_robot_s2.mp3` | باتری‌ها را بگذار. | k_robot.s2 |
| 280 | `k_robot_s3.mp3` | ربات را رنگ کن. | k_robot.s3 |
| 281 | `k_robot_s4.mp3` | ربات را تا گل راه ببر. | k_robot.s4 |
| 282 | `item_robot_made.mp3` | آفرین! ربات آماده شد! | item.robot.made |
| 283 | `k_dollhouse_mission.mp3` | یک خانه‌ی کوچک برای عروسک‌ها! | k_dollhouse.mission |
| 284 | `k_dollhouse_s1.mp3` | اتاق‌ها را روی هم بچین. | k_dollhouse.s1 |
| 285 | `k_dollhouse_s2.mp3` | دیوارها را رنگ کن. | k_dollhouse.s2 |
| 286 | `k_dollhouse_s3.mp3` | چراغ اتاق‌ها را روشن کن. | k_dollhouse.s3 |
| 287 | `item_dollhouse_made.mp3` | آفرین! خانه‌ی عروسکی آماده شد! | item.dollhouse.made |
| 288 | `k_rocket_mission.mp3` | به فضا برویم! | k_rocket.mission |
| 289 | `k_rocket_s1.mp3` | بدنه‌ی موشک را بگذار. | k_rocket.s1 |
| 290 | `k_rocket_s2.mp3` | موشک را رنگ کن. | k_rocket.s2 |
| 291 | `k_rocket_s3.mp3` | شمارش معکوس: ستاره‌ها را از بزرگ به کوچک بزن! | k_rocket.s3 |
| 292 | `k_rocket_s4.mp3` | در فضا ستاره جمع کن. | k_rocket.s4 |
| 293 | `item_rocket_made.mp3` | آفرین! موشک آماده شد! | item.rocket.made |
| 294 | `k_submarine_mission.mp3` | زیر دریا چه خبر است؟ | k_submarine.mission |
| 295 | `k_submarine_s1.mp3` | پنجره‌ی زیردریایی را بگذار. | k_submarine.s1 |
| 296 | `k_submarine_s2.mp3` | زیردریایی را رنگ کن. | k_submarine.s2 |
| 297 | `k_submarine_s3.mp3` | با چراغ زیردریایی ماهی‌ها را پیدا کن. | k_submarine.s3 |
| 298 | `item_submarine_made.mp3` | آفرین! زیردریایی آماده شد! | item.submarine.made |
| 299 | `k_train_mission.mp3` | چووو چووو! یک قطار بسازیم. | k_train.mission |
| 300 | `k_train_s1.mp3` | ریل‌ها را بچین. | k_train.s1 |
| 301 | `k_train_s2.mp3` | چرخ‌های قطار را بگذار. | k_train.s2 |
| 302 | `k_train_s3.mp3` | قطار را رنگ کن. | k_train.s3 |
| 303 | `k_train_s4.mp3` | قطار را روی ریل ببر. | k_train.s4 |
| 304 | `item_train_made.mp3` | آفرین! قطار آماده شد! | item.train.made |
| 305 | `tool_magnifier_safety.mp3` | ذره‌بین را هیچ‌وقت رو به خورشید نگیر. | tool.magnifier.safety |
| 306 | `r_bug_book_mission.mp3` | با ذره‌بین حشره‌ها را پیدا کنیم! | r_bug_book.mission |
| 307 | `r_bug_book_s1.mp3` | حشره‌های کوچک را با ذره‌بین پیدا کن. | r_bug_book.s1 |
| 308 | `item_bug_book_made.mp3` | آفرین! دفترچه‌ی حشره‌ها آماده شد! | item.bug_book.made |
| 309 | `tool_saw_safety.mp3` | با اره همیشه با یک بزرگ‌تر کار می‌کنیم. | tool.saw.safety |
| 310 | `r_bird_house_mission.mp3` | برای پرنده‌ها خانه بسازیم. | r_bird_house.mission |
| 311 | `r_bird_house_s1.mp3` | تخته را با اره ببُر. | r_bird_house.s1 |
| 312 | `r_bird_house_s2.mp3` | دیوارها را بچین. | r_bird_house.s2 |
| 313 | `r_bird_house_s3.mp3` | خانه را رنگ کن. | r_bird_house.s3 |
| 314 | `item_bird_house_made.mp3` | آفرین! خانه‌ی پرنده آماده شد! | item.bird_house.made |
| 315 | `tool_glue_gun_safety.mp3` | سر چسب‌تفنگی داغ است؛ به آن دست نمی‌زنیم. | tool.glue_gun.safety |
| 316 | `r_photo_frame_mission.mp3` | یک قاب برای عکس یادگاری! | r_photo_frame.mission |
| 317 | `r_photo_frame_s1.mp3` | ستاره‌ها را دور قاب بچسبان. | r_photo_frame.s1 |
| 318 | `r_photo_frame_s2.mp3` | قاب را رنگ کن. | r_photo_frame.s2 |
| 319 | `item_photo_frame_made.mp3` | آفرین! قاب عکس آماده شد! | item.photo_frame.made |
| 320 | `tool_big_oven_safety.mp3` | در فر داغ است؛ با دستکش بازش می‌کنیم. | tool.big_oven.safety |
| 321 | `r_pizza_mission.mp3` | بیا پیتزا بپزیم! | r_pizza.mission |
| 322 | `r_pizza_s1.mp3` | گوجه‌ها را روی خمیر بگذار. | r_pizza.s1 |
| 323 | `r_pizza_s2.mp3` | پنیر بریز. | r_pizza.s2 |
| 324 | `r_pizza_s3.mp3` | وقتی پنیر آب شد بزن! | r_pizza.s3 |
| 325 | `item_pizza_made.mp3` | آفرین! پیتزا آماده شد! | item.pizza.made |
| 326 | `r_cookie_mission.mp3` | کلوچه‌ی تازه! | r_cookie.mission |
| 327 | `r_cookie_s1.mp3` | خمیر کلوچه را هم بزن. | r_cookie.s1 |
| 328 | `r_cookie_s2.mp3` | وقتی طلایی شد بزن! | r_cookie.s2 |
| 329 | `item_cookie_made.mp3` | آفرین! کلوچه آماده شد! | item.cookie.made |
| 330 | `tool_sewing_machine_safety.mp3` | انگشت‌ها را از سوزن دور نگه می‌داریم. | tool.sewing_machine.safety |
| 331 | `r_rag_doll_mission.mp3` | یک عروسک نرم بدوزیم. | r_rag_doll.mission |
| 332 | `r_rag_doll_s1.mp3` | پدال را بزن تا چرخ بدوزد: تق تق تق! | r_rag_doll.s1 |
| 333 | `r_rag_doll_s2.mp3` | لباس عروسک را رنگ کن. | r_rag_doll.s2 |
| 334 | `item_rag_doll_made.mp3` | آفرین! عروسک پارچه‌ای آماده شد! | item.rag_doll.made |
| 335 | `tool_drill_safety.mp3` | دریل را فقط بزرگ‌ترها روشن می‌کنند و ما کمک می‌کنیم. | tool.drill.safety |
| 336 | `r_windmill_mission.mp3` | یک آسیاب بادی بسازیم. | r_windmill.mission |
| 337 | `r_windmill_s1.mp3` | با دریل سوراخ کن. | r_windmill.s1 |
| 338 | `r_windmill_s2.mp3` | پره‌ها را وصل کن. | r_windmill.s2 |
| 339 | `r_windmill_s3.mp3` | فوت کن تا بچرخد! | r_windmill.s3 |
| 340 | `item_windmill_made.mp3` | آفرین! آسیاب بادی آماده شد! | item.windmill.made |
| 341 | `tool_wrench_safety.mp3` | آچار را محکم و آرام می‌چرخانیم. | tool.wrench.safety |
| 342 | `r_bicycle_mission.mp3` | یک دوچرخه برای پوپو! | r_bicycle.mission |
| 343 | `r_bicycle_s1.mp3` | چرخ‌ها را وصل کن. | r_bicycle.s1 |
| 344 | `r_bicycle_s2.mp3` | پیچ‌ها را با آچار سفت کن. | r_bicycle.s2 |
| 345 | `r_bicycle_s3.mp3` | دوچرخه را رنگ کن. | r_bicycle.s3 |
| 346 | `item_bicycle_made.mp3` | آفرین! دوچرخه آماده شد! | item.bicycle.made |
| 347 | `tool_magnet_safety.mp3` | آهن‌ربا را نزدیک گوشی و تلویزیون نمی‌بریم. | tool.magnet.safety |
| 348 | `r_magnet_fish_mission.mp3` | بیا ماهیگیری کنیم! | r_magnet_fish.mission |
| 349 | `r_magnet_fish_s1.mp3` | چیزهایی که آهن‌ربا می‌کشد را جدا کن. | r_magnet_fish.s1 |
| 350 | `r_magnet_fish_s2.mp3` | ماهی‌های آهنی را بگیر! | r_magnet_fish.s2 |
| 351 | `item_magnet_fish_made.mp3` | آفرین! ماهیگیری آهن‌ربایی آماده شد! | item.magnet_fish.made |
| 352 | `item_juice_use.mp3` | آب‌میوه تشنگی را برطرف می‌کند و ویتامین دارد. | item.juice.use |
| 353 | `item_juice_quiz.mp3` | با آب‌میوه چه کار می‌کنیم؟ | item.juice.quiz |
| 354 | `item_juice_taste.mp3` | مزه‌اش شیرین و کمی ترش است! | item.juice.taste |
| 355 | `item_bread_use.mp3` | نان غذای هر روز ماست؛ با آن ساندویچ هم درست می‌کنیم. | item.bread.use |
| 356 | `item_bread_quiz.mp3` | نان را کی می‌خوریم؟ | item.bread.quiz |
| 357 | `item_bread_taste.mp3` | مزه‌اش ترد و گرم است! | item.bread.taste |
| 358 | `item_soup_use.mp3` | سوپ گرم، وقتی سردمان است بدن را گرم می‌کند. | item.soup.use |
| 359 | `item_soup_quiz.mp3` | سوپ گرم به درد کی می‌خورد؟ | item.soup.quiz |
| 360 | `item_soup_taste.mp3` | مزه‌اش شور و داغ است! | item.soup.taste |
| 361 | `item_cake_use.mp3` | کیک برای جشن و تولد است؛ شمع‌ها را فوت می‌کنیم. | item.cake.use |
| 362 | `item_cake_quiz.mp3` | کیک تولد برای چیست؟ | item.cake.quiz |
| 363 | `item_cake_taste.mp3` | مزه‌اش شیرین است! | item.cake.taste |
| 364 | `item_watering_can_use.mp3` | با آب‌پاش به گل‌ها و گیاه‌ها آب می‌دهیم. | item.watering_can.use |
| 365 | `item_watering_can_quiz.mp3` | با آب‌پاش چه کار می‌کنیم؟ | item.watering_can.quiz |
| 366 | `item_flower_pot_use.mp3` | گل بوی خوش دارد و زنبورها از آن شهد می‌گیرند. | item.flower_pot.use |
| 367 | `item_flower_pot_quiz.mp3` | کی سراغ گل می‌آید؟ | item.flower_pot.quiz |
| 368 | `item_flower_pot_taste.mp3` | مزه‌اش خوش‌بو است! | item.flower_pot.taste |
| 369 | `item_eggs_use.mp3` | مرغ تخم می‌گذارد؛ با تخم‌مرغ کیک و نیمرو درست می‌کنیم. | item.eggs.use |
| 370 | `item_eggs_quiz.mp3` | تخم‌مرغ از کجا می‌آید؟ | item.eggs.quiz |
| 371 | `item_eggs_taste.mp3` | مزه‌اش پخته‌اش خوشمزه است است! | item.eggs.taste |
| 372 | `item_sandwich_use.mp3` | ساندویچ یک غذای کامل و راحت برای پیک‌نیک است. | item.sandwich.use |
| 373 | `item_sandwich_quiz.mp3` | ساندویچ را با چه درست کردیم؟ | item.sandwich.quiz |
| 374 | `item_sandwich_taste.mp3` | مزه‌اش نرم و شور است! | item.sandwich.taste |
| 375 | `item_hammer_use.mp3` | با چکش میخ را در چوب فرو می‌کنیم تا تکه‌ها به هم بچسبند. | item.hammer.use |
| 376 | `item_hammer_quiz.mp3` | با چکش چه کار می‌کنیم؟ | item.hammer.quiz |
| 377 | `item_flashlight_use.mp3` | چراغ‌قوه در تاریکی راه را روشن می‌کند. | item.flashlight.use |
| 378 | `item_flashlight_quiz.mp3` | چراغ‌قوه کجا به کار می‌آید؟ | item.flashlight.quiz |
| 379 | `item_cart_use.mp3` | با گاری بارهای سنگین را راحت جابه‌جا می‌کنیم. | item.cart.use |
| 380 | `item_cart_quiz.mp3` | گاری به چه کاری می‌آید؟ | item.cart.quiz |
| 381 | `item_toy_car_use.mp3` | ماشین با موتور روشن می‌شود و ما را به جاهای دور می‌برد. | item.toy_car.use |
| 382 | `item_toy_car_quiz.mp3` | ماشین چطور راه می‌افتد؟ | item.toy_car.quiz |
| 383 | `item_paints_use.mp3` | قرمز و زرد با هم نارنجی می‌شوند؛ آبی و زرد سبز! | item.paints.use |
| 384 | `item_paints_quiz.mp3` | قرمز و زرد با هم چه رنگی می‌شوند؟ | item.paints.quiz |
| 385 | `item_clay_bowl_use.mp3` | کاسه‌ی خوب آب را نگه می‌دارد و چیزی نمی‌ریزد. | item.clay_bowl.use |
| 386 | `item_clay_bowl_quiz.mp3` | کاسه را برای چه می‌سازیم؟ | item.clay_bowl.quiz |
| 387 | `item_lantern_use.mp3` | فانوس با نور رنگی، شب را قشنگ و روشن می‌کند. | item.lantern.use |
| 388 | `item_lantern_quiz.mp3` | فانوس کی روشن می‌شود؟ | item.lantern.quiz |
| 389 | `item_mask_use.mp3` | ماسک را برای بازی و جشن به صورت می‌زنیم. | item.mask.use |
| 390 | `item_mask_quiz.mp3` | ماسک را کجا می‌زنیم؟ | item.mask.quiz |
| 391 | `item_map_use.mp3` | نقشه راه را نشان می‌دهد تا گم نشویم. | item.map.use |
| 392 | `item_map_quiz.mp3` | نقشه به چه درد می‌خورد؟ | item.map.quiz |
| 393 | `item_tent_use.mp3` | چادر زیر باران ما را خشک و گرم نگه می‌دارد. | item.tent.use |
| 394 | `item_tent_quiz.mp3` | چادر کی به کار می‌آید؟ | item.tent.quiz |
| 395 | `item_firefly_jar_use.mp3` | کرم‌های شب‌تاب خودشان نور دارند! | item.firefly_jar.use |
| 396 | `item_firefly_jar_quiz.mp3` | کرم شب‌تاب کی می‌درخشد؟ | item.firefly_jar.quiz |
| 397 | `item_telescope_use.mp3` | با تلسکوپ چیزهای خیلی دور مثل ماه و ستاره‌ها را نزدیک می‌بینیم. | item.telescope.use |
| 398 | `item_telescope_quiz.mp3` | با تلسکوپ چه می‌بینیم؟ | item.telescope.quiz |
| 399 | `item_drum_use.mp3` | طبل با ضربه صدا می‌دهد؛ ضربه‌ی محکم بلند، ضربه‌ی آرام آهسته. | item.drum.use |
| 400 | `item_drum_quiz.mp3` | طبل را چطور می‌نوازیم؟ | item.drum.quiz |
| 401 | `item_xylophone_use.mp3` | تیغه‌ی بلند صدای بم دارد و تیغه‌ی کوتاه صدای زیر. | item.xylophone.use |
| 402 | `item_xylophone_quiz.mp3` | تیغه‌ی کوتاه چه صدایی دارد؟ | item.xylophone.quiz |
| 403 | `item_flute_use.mp3` | نی را با فوت می‌نوازیم؛ سوراخ‌ها نت را عوض می‌کنند. | item.flute.use |
| 404 | `item_flute_quiz.mp3` | نی را چطور می‌نوازیم؟ | item.flute.quiz |
| 405 | `item_song_use.mp3` | آهنگ را با چند ساز با هم می‌نوازیم. | item.song.use |
| 406 | `item_song_quiz.mp3` | آهنگ را با چه ساختیم؟ | item.song.quiz |
| 407 | `item_bridge_use.mp3` | پل دو طرف رودخانه را به هم وصل می‌کند. | item.bridge.use |
| 408 | `item_bridge_quiz.mp3` | پل به چه درد می‌خورد؟ | item.bridge.quiz |
| 409 | `item_traffic_light_use.mp3` | قرمز یعنی بایست، سبز یعنی برو. | item.traffic_light.use |
| 410 | `item_traffic_light_quiz.mp3` | چراغ قرمز یعنی چه؟ | item.traffic_light.quiz |
| 411 | `item_bus_use.mp3` | اتوبوس خیلی‌ها را با هم جابه‌جا می‌کند. | item.bus.use |
| 412 | `item_bus_quiz.mp3` | اتوبوس برای چیست؟ | item.bus.quiz |
| 413 | `item_invitation_use.mp3` | با کارت دعوت دوستانمان را به جشن خبر می‌کنیم. | item.invitation.use |
| 414 | `item_invitation_quiz.mp3` | کارت دعوت برای چیست؟ | item.invitation.quiz |
| 415 | `item_feast_use.mp3` | همه‌ی غذاهایی که ساختی روی یک میز! | item.feast.use |
| 416 | `item_feast_quiz.mp3` | روی میز جشن چه گذاشتیم؟ | item.feast.quiz |
| 417 | `item_feast_taste.mp3` | مزه‌اش خوشمزه است! | item.feast.taste |
| 418 | `item_decorations_use.mp3` | تزئینات میدان را رنگی و شاد می‌کند. | item.decorations.use |
| 419 | `item_decorations_quiz.mp3` | تزئینات برای چیست؟ | item.decorations.quiz |
| 420 | `item_concert_use.mp3` | گروه میمی آهنگ تو را می‌نوازد! | item.concert.use |
| 421 | `item_concert_quiz.mp3` | در کنسرت چه می‌شنویم؟ | item.concert.quiz |
| 422 | `item_medal_use.mp3` | تو با ساخته‌هایت جشن جنگل را نجات دادی! | item.medal.use |
| 423 | `item_medal_quiz.mp3` | چه کسی جشن را نجات داد؟ | item.medal.quiz |
| 424 | `item_bubbles_use.mp3` | با فوت، صابون حباب‌های رنگی می‌شود. | item.bubbles.use |
| 425 | `item_bubbles_quiz.mp3` | حباب چطور درست می‌شود؟ | item.bubbles.quiz |
| 426 | `item_necklace_use.mp3` | مهره‌ها را به ترتیب رنگ به نخ می‌کشیم. | item.necklace.use |
| 427 | `item_necklace_quiz.mp3` | گردنبند را کجا می‌اندازیم؟ | item.necklace.quiz |
| 428 | `item_kite_use.mp3` | باد بادبادک را بالا می‌برد. | item.kite.use |
| 429 | `item_kite_quiz.mp3` | بادبادک با چه بالا می‌رود؟ | item.kite.quiz |
| 430 | `item_robot_use.mp3` | ربات با باتری روشن می‌شود و کارهایی را که بگوییم انجام می‌دهد. | item.robot.use |
| 431 | `item_robot_quiz.mp3` | ربات با چه روشن می‌شود؟ | item.robot.quiz |
| 432 | `item_dollhouse_use.mp3` | در خانه‌ی عروسکی چراغ‌ها روشن می‌شوند و شیر آب باز می‌شود. | item.dollhouse.use |
| 433 | `item_dollhouse_quiz.mp3` | خانه برای چیست؟ | item.dollhouse.quiz |
| 434 | `item_rocket_use.mp3` | موشک با موتورهای قوی به فضا می‌رود. | item.rocket.use |
| 435 | `item_rocket_quiz.mp3` | موشک کجا می‌رود؟ | item.rocket.quiz |
| 436 | `item_submarine_use.mp3` | زیردریایی زیر آب می‌رود و با چراغش ماهی‌ها را می‌بیند. | item.submarine.use |
| 437 | `item_submarine_quiz.mp3` | زیردریایی کجا می‌رود؟ | item.submarine.quiz |
| 438 | `item_train_use.mp3` | قطار روی ریل حرکت می‌کند و سوت می‌کشد: چوووو! | item.train.use |
| 439 | `item_train_quiz.mp3` | قطار روی چه حرکت می‌کند؟ | item.train.quiz |
| 440 | `item_bug_book_use.mp3` | با ذره‌بین حشره‌های کوچک را بزرگ می‌بینیم. | item.bug_book.use |
| 441 | `item_bug_book_quiz.mp3` | ذره‌بین چه کار می‌کند؟ | item.bug_book.quiz |
| 442 | `item_bird_house_use.mp3` | پرنده در خانه‌اش لانه می‌سازد. | item.bird_house.use |
| 443 | `item_bird_house_quiz.mp3` | خانه‌ی پرنده برای کیست؟ | item.bird_house.quiz |
| 444 | `item_photo_frame_use.mp3` | عکس یادگاری را در قاب می‌گذاریم و به دیوار می‌زنیم. | item.photo_frame.use |
| 445 | `item_photo_frame_quiz.mp3` | قاب عکس برای چیست؟ | item.photo_frame.quiz |
| 446 | `item_pizza_use.mp3` | پیتزا را در فر می‌پزیم تا پنیرش آب شود. | item.pizza.use |
| 447 | `item_pizza_quiz.mp3` | پیتزا را کجا می‌پزیم؟ | item.pizza.quiz |
| 448 | `item_pizza_taste.mp3` | مزه‌اش شور و داغ است! | item.pizza.taste |
| 449 | `item_cookie_use.mp3` | کلوچه‌ی تازه ترد و شیرین است. | item.cookie.use |
| 450 | `item_cookie_quiz.mp3` | کلوچه چه مزه‌ای دارد؟ | item.cookie.quiz |
| 451 | `item_cookie_taste.mp3` | مزه‌اش شیرین و ترد است! | item.cookie.taste |
| 452 | `item_rag_doll_use.mp3` | عروسک نرم را بغل می‌کنیم. | item.rag_doll.use |
| 453 | `item_rag_doll_quiz.mp3` | با عروسک چه کار می‌کنیم؟ | item.rag_doll.quiz |
| 454 | `item_windmill_use.mp3` | باد پره‌ها را می‌چرخاند. | item.windmill.use |
| 455 | `item_windmill_quiz.mp3` | چه چیزی آسیاب بادی را می‌چرخاند؟ | item.windmill.quiz |
| 456 | `item_bicycle_use.mp3` | دوچرخه با رکاب زدن حرکت می‌کند: زینگ زینگ! | item.bicycle.use |
| 457 | `item_bicycle_quiz.mp3` | دوچرخه چطور حرکت می‌کند؟ | item.bicycle.quiz |
| 458 | `item_magnet_fish_use.mp3` | آهن‌ربا چیزهای آهنی را به خودش می‌کشد. | item.magnet_fish.use |
| 459 | `item_magnet_fish_quiz.mp3` | آهن‌ربا چه چیزی را می‌کشد؟ | item.magnet_fish.quiz |
| 460 | `order_1.mp3` | بانی تشنه است. چی بهش بدیم؟ | order.1 |
| 461 | `order_2.mp3` | خاله خرسی یک چیز شیرین می‌خواهد. | order.2 |
| 462 | `order_3.mp3` | مادربزرگ جغد سردش است. | order.3 |
| 463 | `order_4.mp3` | میمی یک ساز با صدای بم می‌خواهد. | order.4 |
| 464 | `order_5.mp3` | میمی یک ساز با صدای زیر می‌خواهد. | order.5 |
| 465 | `order_6.mp3` | آقا سنجاب در تاریکی چیزی را گم کرده. | order.6 |
| 466 | `order_7.mp3` | لاکی یک وسیله‌ی نقلیه می‌خواهد. | order.7 |
| 467 | `order_8.mp3` | کوکو یک چیز قشنگ برای تزئین می‌خواهد. | order.8 |
| 468 | `order_9.mp3` | آقا سنجاب باید میخ بزند. | order.9 |
| 469 | `order_10.mp3` | گل‌های بانی تشنه‌اند. | order.10 |
| 470 | `order_11.mp3` | خاله خرسی گرسنه است. | order.11 |
| 471 | `order_12.mp3` | مادربزرگ جغد راه را گم کرده. | order.12 |
| 472 | `order_13.mp3` | کوکو دلش موسیقی می‌خواهد. | order.13 |
| 473 | `combo_1.mp3` | مهمانی کوچک! دوستان آمدند. | combo.1 |
| 474 | `combo_2.mp3` | ربات گل‌ها را آب داد! | combo.2 |
| 475 | `combo_3.mp3` | یک آهنگ دونفره! | combo.3 |
| 476 | `combo_4.mp3` | چادر شب روشن شد. | combo.4 |
| 477 | `combo_5.mp3` | ماشین نامه‌ها را رساند. | combo.5 |
| 478 | `combo_6.mp3` | تماشای شب پرستاره! | combo.6 |
| 479 | `combo_7.mp3` | باد هر دو را چرخاند! | combo.7 |
| 480 | `combo_8.mp3` | ماهی‌گیری زیر آب! | combo.8 |
| 481 | `combo_9.mp3` | ناهار گرم و خوشمزه! | combo.9 |
| 482 | `combo_10.mp3` | رقص با ماسک! | combo.10 |
| 483 | `combo_11.mp3` | موشک در آسمان دیده شد! | combo.11 |
| 484 | `combo_12.mp3` | پرنده‌ها در باغ لانه ساختند. | combo.12 |
| 485 | `combo_13.mp3` | یک نقاشی قاب‌شده! | combo.13 |
| 486 | `combo_14.mp3` | گردش با دوچرخه در جنگل! | combo.14 |
| 487 | `game_hint_1.mp3` | این‌جا را ببین... | game.hint.1 |
| 488 | `game_hint_2.mp3` | بیا با هم انجامش بدهیم. | game.hint.2 |
| 489 | `game_wrong.mp3` | نه این یکی نه؛ دوباره امتحان کن! | game.wrong |
| 490 | `game_quiz_right.mp3` | درست گفتی! | game.quiz.right |
| 491 | `game_quiz_wrong.mp3` | نه عزیزم، به این دقت کن. | game.quiz.wrong |
| 492 | `game_play.mp3` | حالا باهاش بازی کن! | game.play |
| 493 | `game_backpack.mp3` | گذاشتمش در کوله‌پشتی. | game.backpack |
| 494 | `game_stars_3.mp3` | عالی بود! سه ستاره! | game.stars.3 |
| 495 | `game_stars_2.mp3` | خیلی خوب بود! | game.stars.2 |
| 496 | `game_stars_1.mp3` | تمامش کردی، آفرین! | game.stars.1 |
| 497 | `game_fast.mp3` | چه سریع! | game.fast |
| 498 | `game_locked.mp3` | این بخش برای بعد است. اول بخش قبلی را تمام کن. | game.locked |
| 499 | `game_coins_low.mp3` | سکه‌هایت کم است. بیا یک بخش را دوباره بازی کنیم! | game.coins.low |
| 500 | `game_secret.mp3` | یک چیز پنهان پیدا کردی! | game.secret |
| 501 | `game_daily.mp3` | جایزه‌ی امروز! سکه گرفتی. | game.daily |
| 502 | `home_hello.mp3` | سلام! امروز چی بسازیم؟ | home.hello |
| 503 | `workshop_hello.mp3` | به کارگاه ستاره خوش آمدی! با ستاره‌هایت کیت‌های تازه باز می‌شوند. | workshop.hello |
| 504 | `shop_hello.mp3` | این‌جا با سکه ابزار می‌خری و چیزهای تازه می‌سازی. | shop.hello |
| 505 | `shop_bought.mp3` | ابزار تازه! بیا ببینیم چطور کار می‌کند. | shop.bought |
| 506 | `playroom_hello.mp3` | این اتاق بازی توست. همه‌ی ساخته‌هایت این‌جاست! | playroom.hello |
| 507 | `playroom_combo.mp3` | یک ترکیب تازه کشف کردی! | playroom.combo |
| 508 | `playroom_order_done.mp3` | دقیقاً همین را می‌خواستم! ممنون! | playroom.order.done |
| 509 | `playroom_order_wrong.mp3` | این را نمی‌خواهم؛ یک چیز دیگر بده. | playroom.order.wrong |
| 510 | `film_end.mp3` | یک تکه‌ی تازه از نقشه‌ی جشن روشن شد! | film.end |
| 511 | `kit_open.mp3` | یک کیت تازه باز شد! | kit.open |

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
