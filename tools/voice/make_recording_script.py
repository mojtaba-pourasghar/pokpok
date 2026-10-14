#!/usr/bin/env python3
"""
فیلم‌نامه‌ی ضبط صدای گوینده را از assets/content/voice_lines.json می‌سازد:

    python3 tools/voice/make_recording_script.py

خروجی:
  docs/voice/RECORDING_SCRIPT.md   برای گوینده و کارگردان صدا (گروه‌بندی‌شده با راهنمای لحن)
  docs/voice/recording_list.csv    برای استودیو: شناسه، نام فایل، متن، رویداد، وضعیت

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

SECTIONS = OrderedDict([
    ("app.", ("صفحه‌ها و خوشامد", "گرم و صمیمی، با لبخند. آرام شروع کنید و انتهای جمله را بالا ببرید.")),
    ("cat.", ("دسته‌بندی‌ها", "کنجکاو و دعوت‌کننده، مثل باز کردن یک جعبه‌ی هدیه.")),
    ("who.", ("بازی «این صدا مال کیه؟»", "پرسش‌ها کنجکاو و آهسته‌تر؛ هرگز نام پاسخ را با تأکید نگویید. راهنمایی‌ها آرام و مهربان. تشویق‌ها شاد.")),
    ("find.", ("بازی «صدای مخفی را پیدا کن»", "مثل یک ماجراجویی؛ پرسش‌ها با هیجان کم، راهنمایی‌ها آرام.")),
    ("seq.", ("بازی «ترتیب صداها»", "شمرده و واضح؛ کودک باید وقت فکر کردن داشته باشد.")),
    ("mission.", ("مأموریت شنیداری", "نجوامانند و رازآلود برای پرسش‌ها («چشم‌هایت را ببند...»)، شاد برای تشویق.")),
    ("listen.", ("دعوت به گوش دادن", "کوتاه و آرام، انگار می‌خواهید همه ساکت شوند. بعد از این جمله صدای بازی پخش می‌شود.")),
    ("question.", ("پرسش عمومی", "کنجکاو، با آهنگ پرسشی روشن.")),
    ("feedback.correct", ("تشویق پس از پاسخ درست", "پرانرژی و واقعی، نه اغراق‌آمیز. هر کدام را با رنگ کمی متفاوت بخوانید.")),
    ("feedback.wrong", ("دلگرمی پس از پاسخ اشتباه", "بسیار مهربان و آرام؛ هیچ نشانی از ناامیدی یا سرزنش نباشد.")),
    ("replay.", ("راهنمای تکرار صدا", "آرام و راهنما.")),
    ("idle.", ("وقتی کودک مکث می‌کند", "صبور و نرم.")),
    ("level.", ("پایان مرحله و مرحله‌ی بعد", "شاد و تشویق‌کننده.")),
    ("result.", ("ستاره‌ها", "شاد؛ برای یک ستاره هم دلگرم‌کننده.")),
    ("mode.", ("پایان یک بازی", "جشن کوچک.")),
    ("all.", ("پایان همه‌ی مراحل", "جشن بزرگ، با افتخار.")),
    ("session.", ("توقف، ادامه، خروج", "آرام و ساده.")),
    ("badge.", ("مدال‌ها", "باافتخار و شاد.")),
    ("snd.", ("نام صداها (کتابخانه‌ی صداها)", "آموزشی و روشن؛ نام صدا را واضح بگویید.")),
])


def section_of(line_id):
    for prefix in SECTIONS:
        if line_id.startswith(prefix):
            return prefix
    return "app."


def main():
    with open(SRC, encoding="utf-8") as f:
        data = json.load(f)
    lines = data["lines"]
    groups = OrderedDict((p, []) for p in SECTIONS)
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
        "- **تلفظ:** فارسی معیار و روشن، بدون لهجه‌ی غلیظ.",
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
        title, note = SECTIONS[prefix]
        md += ["## %s" % title, "", "*لحن:* %s" % note, "", "| # | فایل | متن | کجا پخش می‌شود |", "|---|---|---|---|"]
        for i, l in enumerate(items, 1):
            where = l.get("event", "")
            if l.get("note"):
                where += " — " + l["note"]
            md.append("| %d | `%s` | %s | %s |" % (i, os.path.basename(l["file"]), l["text"], where))
        md.append("")

    with open(os.path.join(OUT, "RECORDING_SCRIPT.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md))

    with open(os.path.join(OUT, "recording_list.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["id", "file", "text", "event", "screen", "group", "delay_ms", "recorded"])  # recorded: yes | tts | no
        for l in lines:
            name = os.path.basename(l["file"])
            w.writerow([l["id"], name, l["text"], l.get("event", ""), l.get("screen", ""), l.get("group", ""),
                        l.get("delayMs", 0),
                        "tts" if name in tts and name in recorded else ("yes" if name in recorded else "no")])

    names = [os.path.basename(l["file"]) for l in lines]
    print("%d lines → docs/voice/RECORDING_SCRIPT.md, docs/voice/recording_list.csv "
          "(%d recorded, %d temporary TTS)"
          % (len(lines), len([n for n in names if n in recorded and n not in tts]),
             len([n for n in names if n in recorded and n in tts])))


if __name__ == "__main__":
    main()
