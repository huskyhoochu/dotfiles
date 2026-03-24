# Source Classification Guide (Game Research)

## URL Pattern → Type Mapping

### Video Sources
| Pattern | Platform |
|---------|----------|
| `youtube.com/watch?v=` | YouTube |
| `youtu.be/` | YouTube (short URL) |
| `youtube.com/shorts/` | YouTube Shorts |
| `twitch.tv/videos/` | Twitch VOD |
| `clips.twitch.tv/` | Twitch Clip |
| `bilibili.com/video/` | Bilibili |
| `vimeo.com/` | Vimeo |

### Review / Critic Sources
| Pattern | Platform |
|---------|----------|
| `metacritic.com` | Metacritic |
| `opencritic.com` | OpenCritic |
| `ign.com` | IGN |
| `gamespot.com` | GameSpot |
| `kotaku.com` | Kotaku |
| `polygon.com` | Polygon |
| `eurogamer.net` | Eurogamer |
| `pcgamer.com` | PC Gamer |
| `rockpapershotgun.com` | Rock Paper Shotgun |
| `destructoid.com` | Destructoid |
| `pushsquare.com` | Push Square (PlayStation) |
| `nintendolife.com` | Nintendo Life |
| `purexbox.com` | Pure Xbox |
| `thegamer.com` | TheGamer |
| `gamesradar.com` | GamesRadar+ |
| `gameinformer.com` | Game Informer |
| `game.donga.com` | Game Donga (Korean) |
| `gamemeca.com` | 게임메카 (Korean) |
| `thisisgame.com` | 디스이즈게임 (Korean) |
| `gamevu.co.kr` | 게임뷰 (Korean) |

### Community / Forum Sources
| Pattern | Platform |
|---------|----------|
| `reddit.com/r/` | Reddit |
| `store.steampowered.com/app/*/reviews` | Steam Reviews |
| `steamcommunity.com` | Steam Community |
| `resetera.com` | ResetEra |
| `neogaf.com` | NeoGAF |
| `news.ycombinator.com` | Hacker News |
| `github.com/*/discussions` | GitHub Discussions |
| `github.com/*/issues` | GitHub Issues |
| `ruliweb.com` | 루리웹 (Korean) |
| `inven.co.kr` | 인벤 (Korean) |
| `gall.dcinside.com` | DCInside (Korean) |
| `arca.live` | 아카라이브 (Korean) |
| `fmkorea.com` | FM코리아 (Korean) |
| `clien.net` | 클리앙 (Korean) |
| `nexon.com/community` | Nexon Community (Korean) |
| URL contains `forum` | Generic forum |
| URL contains `community` | Generic community |
| URL contains `discuss` | Generic discussion |

### Official / Publisher Sources
| Pattern | Platform |
|---------|----------|
| `store.steampowered.com/app/` | Steam Store Page |
| `playstation.com` | PlayStation Official |
| `xbox.com` | Xbox Official |
| `nintendo.com` | Nintendo Official |
| `epicgames.com/store` | Epic Games Store |
| `ea.com` | EA Official |
| `ubisoft.com` | Ubisoft Official |
| `blizzard.com` | Blizzard Official |
| `riotgames.com` | Riot Games Official |

### Article / Document Sources
Everything not matching the above patterns falls into this category. Includes:
- News articles
- Blog posts
- Developer blogs / dev diaries
- Patch notes on non-official sites
- Academic/industry analysis

## Priority Rules

When more URLs are available than the extraction limits:
1. **Review aggregators first** (Metacritic, OpenCritic) — they provide consolidated scoring data
2. Prefer major outlet reviews (IGN, GameSpot, PC Gamer) over smaller blogs
3. Prefer recent content over older content
4. Prefer diverse platforms over multiple links from the same domain
5. Official sources (Steam, publisher sites) for factual data (specs, pricing, release dates)
6. Korean sources (루리웹, 인벤, 게임메카) when the query is in Korean or about Korean gaming
