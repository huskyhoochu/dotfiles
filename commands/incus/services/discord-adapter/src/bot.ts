import {
  type ApplicationCommandDataResolvable,
  ApplicationCommandOptionType,
  Client,
  Events,
  GatewayIntentBits,
  type Interaction,
  InteractionContextType,
  type Message,
  MessageFlags,
} from 'discord.js';

const DISCORD_BOT_TOKEN = requireEnv('DISCORD_BOT_TOKEN');
const DISCORD_GUILD_ID = requireEnv('DISCORD_GUILD_ID');
const N8N_WEBHOOK_URL = requireEnv('N8N_WEBHOOK_URL');
const WEBHOOK_SHARED_SECRET = requireEnv('WEBHOOK_SHARED_SECRET');

/** 봇을 호출할 수 있는 Discord 사용자 ID 허용 목록 (쉼표 구분) */
const ALLOWED_USER_IDS = new Set(
  requireEnv('ALLOWED_USER_IDS')
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean),
);

/** Discord typing 표시는 약 10초 후 자동 소멸하므로 그보다 짧은 주기로 갱신한다 */
const TYPING_REFRESH_MS = 8_000;
/** 영상 해석 등 긴 작업 중 표시가 먼저 꺼지지 않게 5분까지 버틴다 */
const TYPING_MAX_MS = 300_000;

/**
 * 슬래시 커맨드는 길드 스코프로 등록한다.
 * 일반 채팅은 별도 경로(chat 이벤트)로 전달된다 — 허용 사용자의 모든 길드 메시지가
 * 범용 챗봇 파이프라인으로 간다. 주의: 커맨드 추가 시 n8n dev-control 워크플로의
 * 라우팅에도 항목을 추가해야 한다 (두 곳 등록 시임).
 */
const SLASH_COMMANDS: ApplicationCommandDataResolvable[] = [
  {
    name: 'issue',
    description:
      '대화 내용을 Forgejo 이슈로 발급합니다 (implement 라벨 없음 — 투입은 별도)',
    contexts: [InteractionContextType.Guild],
    options: [
      {
        name: '저장소',
        description: 'owner/repo 형식 (예: b95labs/drop_manager)',
        type: ApplicationCommandOptionType.String,
        required: true,
      },
      {
        name: '제목',
        description: '이슈 제목 (비우면 대화에서 추론)',
        type: ApplicationCommandOptionType.String,
        required: false,
      },
    ],
  },
  {
    name: 'implement',
    description: '기존 이슈에 implement 라벨을 붙여 에이전트 루프를 투입합니다',
    contexts: [InteractionContextType.Guild],
    options: [
      {
        name: '저장소',
        description: 'owner/repo 형식',
        type: ApplicationCommandOptionType.String,
        required: true,
      },
      {
        name: '번호',
        description: '이슈 번호',
        type: ApplicationCommandOptionType.Integer,
        required: true,
      },
    ],
  },
  {
    name: 'status',
    description: '에이전트 루프 실행 상태와 로그를 조회합니다',
    contexts: [InteractionContextType.Guild],
    options: [
      {
        name: '실행_id',
        description: 'run-id',
        type: ApplicationCommandOptionType.String,
        required: true,
      },
    ],
  },
  {
    name: 'runs',
    description: '최근 에이전트 루프 실행 목록을 봅니다',
    contexts: [InteractionContextType.Guild],
  },
  {
    name: 'cancel',
    description: '진행 중인 에이전트 루프를 중지합니다',
    contexts: [InteractionContextType.Guild],
    options: [
      {
        name: '실행_id',
        description: 'run-id',
        type: ApplicationCommandOptionType.String,
        required: true,
      },
    ],
  },
  {
    name: 'issues',
    description: '저장소의 열린 이슈 목록을 봅니다',
    contexts: [InteractionContextType.Guild],
    options: [
      {
        name: '저장소',
        description: 'owner/repo 형식',
        type: ApplicationCommandOptionType.String,
        required: true,
      },
    ],
  },
  {
    name: 'pr',
    description: '저장소의 열린 PR 목록을 봅니다',
    contexts: [InteractionContextType.Guild],
    options: [
      {
        name: '저장소',
        description: 'owner/repo 형식',
        type: ApplicationCommandOptionType.String,
        required: true,
      },
    ],
  },
  {
    name: 'help',
    description: '봇 사용법과 커맨드 목록을 보여줍니다',
    contexts: [InteractionContextType.Guild],
  },
];

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    console.error(`[fatal] 환경변수 ${name}가 설정되지 않습니다.`);
    process.exit(1);
  }
  return value;
}

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
});

client.once(Events.ClientReady, (readyClient) => {
  console.log(`[ready] 로그인 완료: ${readyClient.user.tag}`);
  readyClient.guilds.cache
    .get(DISCORD_GUILD_ID)
    ?.commands.set(SLASH_COMMANDS)
    .then((registered) => {
      console.log(`[ready] 길드 슬래시 커맨드 ${registered.size}개 등록 완료`);
    })
    .catch((error) => {
      console.error('[ready] 슬래시 커맨드 등록 실패', error);
    });
});

client.on(Events.Error, (error) => {
  console.error('[client error]', error);
});

client.rest.on('rateLimited', (info) => {
  console.warn('[rateLimited]', {
    route: info.route,
    method: info.method,
    timeToReset: info.timeToReset,
  });
});

client.on(Events.MessageCreate, (message) => {
  handleMessage(message).catch((error) => {
    console.error('[handleMessage error]', error);
  });
});

client.on(Events.InteractionCreate, (interaction) => {
  handleInteraction(interaction).catch((error) => {
    console.error('[handleInteraction error]', error);
  });
});

interface TypingTarget {
  id: string;
  sendTyping(): Promise<void>;
}

const typingLoops = new Map<
  string,
  { refresh: NodeJS.Timeout; expire: NodeJS.Timeout }
>();

function startTypingLoop(channel: TypingTarget): void {
  stopTypingLoop(channel.id);
  channel.sendTyping().catch(() => {});
  const refresh = setInterval(() => {
    channel.sendTyping().catch(() => {});
  }, TYPING_REFRESH_MS);
  const expire = setTimeout(() => stopTypingLoop(channel.id), TYPING_MAX_MS);
  typingLoops.set(channel.id, { refresh, expire });
}

function stopTypingLoop(channelId: string): void {
  const loop = typingLoops.get(channelId);
  if (!loop) return;
  clearInterval(loop.refresh);
  clearTimeout(loop.expire);
  typingLoops.delete(channelId);
}

/** 메시지 본문에서 봇 멘션 토큰을 제거한다 */
function stripBotMention(content: string): string {
  if (!client.user) return content;
  return content
    .replaceAll(`<@${client.user.id}>`, '')
    .replaceAll(`<@!${client.user.id}>`, '')
    .trim();
}

/**
 * 슬래시 커맨드 처리. deferReply 로 ACK 한 뒤 n8n 에 넘긴다.
 * 응답은 n8n 이 interaction token 으로 원본 답장을 직접 수정한다 (유효 15분).
 */
async function handleInteraction(interaction: Interaction): Promise<void> {
  if (!interaction.isChatInputCommand()) return;

  if (!ALLOWED_USER_IDS.has(interaction.user.id)) {
    await interaction.reply({
      content: '허용 목록에 없는 사용자입니다.',
      flags: MessageFlags.Ephemeral,
    });
    return;
  }

  await interaction.deferReply();

  const option = interaction.options.getString('저장소');
  const payload = {
    event_type: 'command' as const,
    command: interaction.commandName,
    message_id: interaction.id,
    channel_id: interaction.channelId,
    author_id: interaction.user.id,
    content: [
      option ?? '',
      String(interaction.options.getInteger('번호') ?? ''),
      interaction.options.getString('제목') ??
        interaction.options.getString('실행_id') ??
        '',
    ]
      .filter((v) => v !== '' && v !== 'null')
      .join('\n'),
    application_id: interaction.applicationId,
    interaction_token: interaction.token,
    timestamp: interaction.createdAt.toISOString(),
  };

  console.log('[event] 커맨드 수신', { command: payload.command });

  await forwardToN8n(payload);
}

/**
 * 일반 채팅: 허용 사용자의 모든 길드 메시지를 범용 챗봇 파이프라인으로 보낸다.
 * 봇 자신의 메시지는 typing 종료 신호로만 쓰인다.
 */
async function handleMessage(message: Message): Promise<void> {
  if (!client.user) return;

  // 봇 자신의 메시지 = n8n 의 답변 도착 신호 → typing 종료
  if (message.author.id === client.user.id) {
    stopTypingLoop(message.channelId);
    return;
  }
  if (message.author.bot) return;
  if (!ALLOWED_USER_IDS.has(message.author.id)) return;
  if (!message.channel.isTextBased() || message.channel.isDMBased()) return;

  const channel = message.channel;
  const eventType = channel.isThread() ? ('thread' as const) : ('chat' as const);
  const target: TypingTarget = channel;

  console.log('[event] 메시지 수신', {
    eventType,
    targetChannelId: target.id,
    contentLength: message.content.length,
  });

  startTypingLoop(target);

  const payload = {
    event_type: eventType,
    command: null,
    message_id: message.id,
    thread_id: null,
    channel_id: message.channelId,
    author_id: message.author.id,
    content: stripBotMention(message.content),
    application_id: null,
    interaction_token: null,
    timestamp: message.createdAt.toISOString(),
  };

  await forwardToN8n(payload);
}

async function forwardToN8n(payload: Record<string, unknown>): Promise<void> {
  try {
    const response = await fetch(N8N_WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Adapter-Secret': WEBHOOK_SHARED_SECRET,
      },
      body: JSON.stringify(payload),
    });
    if (!response.ok) {
      console.error(
        `[forwardToN8n] n8n 응답 실패: ${response.status} ${response.statusText}`,
      );
    }
  } catch (error) {
    console.error('[forwardToN8n] 요청 실패', error);
  }
}

client.login(DISCORD_BOT_TOKEN).catch((error) => {
  console.error('[fatal] Discord 로그인 실패', error);
  // 재시도는 Restart=on-failure 에 위임한다
  process.exit(1);
});
