#!/usr/bin/env python3
"""
فیلم‌نامه‌ی ضبط صدای گوینده را از assets/content/voice_lines.json می‌سازد:

    python3 tools/voice/make_recording_script.py

خروجی:
  docs/voice/RECORDING_SCRIPT.md   برای گوینده و کارگردان صدا (گروه‌بندی‌شده با راهنمای لحن)
  docs/voice/recording_list.csv    برای استودیو: شناسه، نام فایل، متن، متن با اعراب، رویداد، وضعیت

منبع حقیقت همان JSON است؛ این فایل‌ها را دستی ویرایش نکنید.
"""
import csv
import json
import os
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "assets", "content", "voice_lines.json")
OUT = os.path.join(ROOT, "docs", "voice")
RECORDED = os.path.join(ROOT, "assets", "audio", "voice")

CHAPTERS = ["آشپزخانه‌ی خاله خرسی", "باغ و مزرعه‌ی بانی", "کارگاه آقا سنجاب", "آتلیه‌ی رنگی کوکو",
            "شب جنگل و مادربزرگ جغد", "گروه موسیقی میمی", "شهر و راننده لاکی", "جشن بزرگ جنگل"]

# (پیشوندهای شناسه، عنوان، راهنمای لحن) — به همان ترتیب داستان
SECTIONS = [
    (("app.", "sticker.", "parent.", "full.", "notice."), "صفحه‌ها و خوشامد",
     "گرم و صمیمی، با لبخند. آرام شروع کنید و انتهای جمله را بالا ببرید."),
    (("praise.",), "تشویق", "پرانرژی و واقعی، نه اغراق‌آمیز. هر کدام را با رنگ کمی متفاوت بخوانید."),
] + [
    ((f"c{n}.", f"c{n}s"), f"فصل {n} — {t}",
     "راهنمای هر گام را شمرده و روشن بگویید (کودک همان لحظه باید کاری بکند)؛ داستان و فیلم را گرم و قصه‌گو.")
    for n, t in enumerate(CHAPTERS, 1)
] + [
    (("item.",), "ساخته‌ها: کاربرد، مزه، پرسش", "آموزشی و کنجکاو؛ پرسش‌ها با آهنگ پرسشی روشن و بدون تأکید روی پاسخ."),
    (("k_", "kit.", "workshop."), "کارگاه ستاره (کیت‌ها)", "شاد و پرانرژی."),
    (("r_", "tool.", "shop."), "فروشگاه ابزار و دستورهای ساخت", "هشدارهای ایمنی آرام و جدی، بقیه شاد."),
    (("playroom.", "order.", "combo."), "اتاق بازی، سفارش‌ها و ترکیب‌ها", "بازیگوش و صمیمی."),
    (("game.", "home.", "film."), "راهنما، ستاره، جایزه", "مهربان؛ در دلگرمی‌ها هیچ لحن سرزنش‌آمیزی نباشد."),
]


def section_of(line_id):
    for i, (prefixes, _, _) in enumerate(SECTIONS):
        if line_id.startswith(prefixes):
            return i
    return 0


def main():
    with open(SRC, encoding="utf-8") as f:
        data = json.load(f)
    lines = data["lines"]
    groups = OrderedDict((i, []) for i in range(len(SECTIONS)))
    for l in lines:
        groups[section_of(l["id"])].append(l)

    recorded = set(os.listdir(RECORDED)) if os.path.isdir(RECORDED) else set()
    tts_path = os.path.join(OUT, "tts_generated.json")
    tts = set()
    if os.path.exists(tts_path):
        with open(tts_path, encoding="utf-8") as f:
            tts = {k + ".mp3" for k in json.load(f).get("files", {})}
    os.makedirs(OUT, exist_ok=True)

    fmt = data.get("format", {})
    md = [
        "# فیلم‌نامه‌ی ضبط صدای پوپو",
        "",
        "> این فایل خودکار از `assets/content/voice_lines.json` ساخته می‌شود "
        "(`python3 tools/voice/make_recording_script.py`). متن‌ها را در همان JSON اصلاح کنید.",
        "",
        "## گوینده",
        "",
        "- **شخصیت:** %s" % data.get("speaker", ""),
        "- **مخاطب:** کودکان ۳ تا ۸ سال. آهسته‌تر از گفت‌وگوی معمولی، با مکث کوتاه بعد از هر جمله.",
        "- **تلفظ:** فارسی معیار و روشن، بدون لهجه‌ی غلیظ. ستون «با اعراب» تلفظ درست هر کلمه را نشان می‌دهد"
        " (کسره‌ی اضافه هم نوشته شده)؛ همان را بخوانید.",
        "- **ممنوع:** نام پاسخ درست را در پرسش‌ها با تأکید نگویید؛ در دلگرمی‌ها هیچ لحن سرزنش‌آمیزی نباشد.",
        "",
        "## مشخصات فنی",
        "",
        "- هر جمله یک فایل جدا، با **دقیقاً** همان نام ستون «فایل».",
        "- ضبط: WAV، ۴۸ کیلوهرتز، ۲۴ بیت، مونو، اتاق بی‌پژواک، فاصله‌ی ثابت از میکروفون.",
        "- تحویل نهایی (اسکریپت `tools/voice/import_recordings.sh` خودش می‌سازد): MP3 مونو %s kbps، "
        "بلندی %s LUFS، %s میلی‌ثانیه سکوت اول و %s میلی‌ثانیه آخر."
        % (fmt.get("bitrateKbps", 96), fmt.get("loudnessLufs", -16),
           fmt.get("silenceMs", {}).get("head", 80), fmt.get("silenceMs", {}).get("tail", 150)),
        "- از هر جمله‌ی مهم دو برداشت ضبط کنید؛ بهترین را با همان نام تحویل دهید.",
        "",
        "تعداد کل جمله‌ها: **%d**" % len(lines),
        "",
    ]
    for prefix, items in groups.items():
        if not items:
            continue
        _, title, note = SECTIONS[prefix]
        md += ["## %s" % title, "", "*لحن:* %s" % note, "",
               "| # | فایل | متن | با اعراب (برای خواندن) | کجا پخش می‌شود |", "|---|---|---|---|---|"]
        for i, l in enumerate(items, 1):
            where = l.get("event", "")
            if l.get("note"):
                where += " — " + l["note"]
            md.append("| %d | `%s` | %s | %s | %s |" % (i, os.path.basename(l["file"]), l["text"], l.get("spoken", l["text"]), where))
        md.append("")

    with open(os.path.join(OUT, "RECORDING_SCRIPT.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md))

    with open(os.path.join(OUT, "recording_list.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["id", "file", "text", "spoken", "event", "screen", "group", "delay_ms", "recorded"])  # recorded: yes | tts | no
        for l in lines:
            name = os.path.basename(l["file"])
            w.writerow([l["id"], name, l["text"], l.get("spoken", l["text"]), l.get("event", ""), l.get("screen", ""), l.get("group", ""),
                        l.get("delayMs", 0),
                        "tts" if name in tts and name in recorded else ("yes" if name in recorded else "no")])

    names = [os.path.basename(l["file"]) for l in lines]
    print("%d lines → docs/voice/RECORDING_SCRIPT.md, docs/voice/recording_list.csv "
          "(%d recorded, %d temporary TTS)"
          % (len(lines), len([n for n in names if n in recorded and n not in tts]),
             len([n for n in names if n in recorded and n in tts])))


if __name__ == "__main__":
    main()
