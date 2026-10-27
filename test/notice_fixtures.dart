// ساخته‌شده با Node (crypto.sign("sha256", …))، همان راهی که استودیو امضا می‌کند.
// کلید خصوصی این‌ها جایی نگه داشته نشده؛ فقط برای آزمون‌اند.
// ignore_for_file: lines_longer_than_80_chars

const fixturePublicKey = r'''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsFtnpFq9LpOaruhqYaKD
91sWqG/XgFootPNW/vlJioO1ptyBSV8VMHc3yBpbp4DckzC+CDG/YQYP89j9p3m6
Qi3zKK30XChXwA3Ta4vEgc/Sh9y7ywVfdj/iRDHwMwSSu/79Gfw00Y8uDg87sGJB
eXX8fMvPvWEL455gOSEI5ARR8sE30cUytg5MPDXn9aXBtwLo+4Y+O70DjzeG4VTi
Jeh+wTsJhQKQ7Yc4+C2eX/26lzA4bA63ovGSX4YxzR28D7uchdCXBU+geVXbby/e
j9NRBgB2+5+yYqKzn023+HEIFM3ImS4U/ow3Rb2D3N7ZSE/woD9lTTDUWIKfoYVz
RQIDAQAB
-----END PUBLIC KEY-----
''';

const fixtureOtherKey = r'''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzYM8DUQ/oR33mhNmEKrs
75y/P80UrQVJGs0W0cpDzV4YRS0C7MXIa7f+BZxFLrtPdzphLp9A8Nyj7AhzeJaH
fWxtIkw87vhXQEZW9LUXKJGS8SAQO9PwJVaGFCxgDYZkk0wSa89YRS/sxyJrRTDV
1a3gE4TUvE2bFqYffCQiOpR9yghtaPPSzR+VuwPGs0K3te3pwDrGwpkKPurvWSvM
xBSO8GPc+vc6XXrv2AY0dtbsR3m5MO0xai48/j+DME8LTqrpnz2qrXk8yyN+I6V9
Z+fs65sL2mIvOeOOxcLIBtxjv3dQDBBPWFQL+/X4hrL3SwtBBqGqjBGGNTX8f9LX
dwIDAQAB
-----END PUBLIC KEY-----
''';

const fixtureSmallKey = r'''-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8g1QXWwCtVcXm848FNrEpWteQ
lW2ZltyQt9TViohg96rYnU7VOZDJ/052t0my6REKrAhPPMZXunVWh3s/nGT9Otac
yAvKxMlVK1cB82V/dwC3a/oleZtlpyQ8oCvapXi3ejqOJn437aTeGqdjP5TII6Hx
a/wpY2PhEQ1+MXgYwQIDAQAB
-----END PUBLIC KEY-----
''';

/// یک خبر: n1.
const fixtureOne = r'''{"alg":"RSA-SHA256","body":"eyJ2IjoxLCJub3RpY2VzIjpbeyJpZCI6Im4xIiwidGl0bGUiOiLYs9mE2KfZhSIsImJvZHkiOiLYrtio2LEg2KrYp9iy2YcifV19","sig":"ir9MopNCTLunxASSi47ERrE97FHyjzHNM7I653RHpnOtdIC9PEhKfGgNl6zZywuQTLHiBybg8lkqgaByG8K4p55m2VqoXi44WAcmUVQDnND7WccIRN23CXAuvgQVq5TBHv/YsOdKE2U1y/nryhppq6vptNN0yUgESuOXpQscgyZfeM0+SHcHpvAnwosj+eaLFqnpqaE/4hC5Yya3NcscIairbOqK8i4giG9l9S4rRx1YhvwKVJMGDTMWUTlUa0oFSMmSATT/BIrHFCETKmS9BWivZGfSMVeM7PV5YlCrXNKmN+MVAxZRKECXybnwbeyVkQl+6FQ1uYLF94vVJVOp9Q=="}''';

/// n2 (با تصویر و پیوند)، n1، یک خبر گذشته و یک خبر آینده.
const fixtureMany = r'''{"alg":"RSA-SHA256","body":"eyJ2IjoxLCJub3RpY2VzIjpbeyJpZCI6Im4yIiwidGl0bGUiOiLYqti12YjbjNixIiwiaW1hZ2UiOiJub3RpY2VzL2M0ZmZkZThkNTdkNjRiYmM3YTEyMjBkOGJmOTU2MGQyMDg1MTEyNTJkOTE3M2QxMzU5ZjVjZjlhN2IyZjE0ZGMud2VicCIsImltYWdlU2hhMjU2IjoiYzRmZmRlOGQ1N2Q2NGJiYzdhMTIyMGQ4YmY5NTYwZDIwODUxMTI1MmQ5MTczZDEzNTlmNWNmOWE3YjJmMTRkYyIsImxpbmsiOiJodHRwczovL2NhZmViYXphYXIuaXIvYXBwL2NvbS5nb3NoeWFyLmFwcCJ9LHsiaWQiOiJuMSIsInRpdGxlIjoi2LPZhNin2YUiLCJib2R5Ijoi2K7YqNixINiq2KfYstmHIn0seyJpZCI6Im9sZCIsInRpdGxlIjoi2qnZh9mG2YciLCJ1bnRpbCI6MTAwMH0seyJpZCI6ImxhdGVyIiwidGl0bGUiOiLYqNi52K/YpyIsImZyb20iOjkwMDAwMDAwMDAwMDAwMDB9XX0=","sig":"nruYtA3wJfY3xgxekKn2IcIQV0mhjg53bQOgRcE9lnC4cCvqiuN+PmrkyyWlaRf28XK8ER/j4qNPOubRQZqBHwyT+m0afMq3PzeIFGsuYIYKxVQ/eKMLZ8Y4d37T8AqyjlOr911AXmRVnpOgHUo0F6Fbt0TktDbXZ8gyIJmK8r4IHtfyQylEXzj8EDNvZN5SY0EVzePJDihPvdh6B/CrxVIGXw58ayCgXp6P6vdB2So6vwAeXpijrpvuTYt3AK2aVdAoxWavHhFj5PJwPmwcFd8ZfAj1OFRFoRzn4SJa0Q2f6KLnmfv/yusOrEgkrQk0RdYCCVD9vbVylOqvywuTMA=="}''';

/// امضاشده با کلیدی دیگر.
const fixtureForged = r'''{"alg":"RSA-SHA256","body":"eyJ2IjoxLCJub3RpY2VzIjpbeyJpZCI6IngiLCJ0aXRsZSI6Itis2LnZhNuMIn1dfQ==","sig":"UOZNo2HhU3f5pxXPp3nDv/wDmWn+6OY7lR/9UvdPxM1m/E3xgjJiMOduHRbC/C7C63Ci/C+IUWgiiaMqiw4j11+LSAhPBfa3zRZEqC9g7A+p3eUPb2IvM/nr/4Y+nW7asa/ezDmgSmmdsAyctUxQZOOamXTcVoj0CIw5hBwzO/qWKGplm3kNTABbvmsI/R75fukhzoDeUHEhjCfo5nv/97sZbTABKJJ4HtEk3AKgZYl3HoG+mAOUNP7iX8Gjvsm4XH6EXmZRh8Yr8/zxWrXZcL1XcbqqJc0VrBwQd5nOvbLYA7R94bkIA5pamT/ka+alAjEn0Ry/P3kzz47xBW2Dnw=="}''';

const fixtureImage = <int>[82, 73, 70, 70, 1, 2, 3, 4];
const fixtureImageSha = 'c4ffde8d57d64bbc7a1220d8bf9560d208511252d9173d1359f5cf9a7b2f14dc';
