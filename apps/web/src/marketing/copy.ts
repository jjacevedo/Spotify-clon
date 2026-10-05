// Every string the landing page renders. Each one is a verbatim segment of
// replica/launch/landing.md (copy.test.ts checks it), so edit that file first.

type Item = { readonly title: string; readonly body: string };
type QA = { readonly question: string; readonly answer: string };
type Three<T> = readonly [T, T, T];
type Eight<T> = readonly [T, T, T, T, T, T, T, T];
type Nine<T> = readonly [T, T, T, T, T, T, T, T, T];

export type Copy = {
  readonly meta: { readonly title: string; readonly description: string; readonly ogTitle: string };
  readonly header: { readonly wordmark: string; readonly logIn: string };
  readonly hero: {
    readonly headline: string;
    readonly lead: string;
    readonly button: string;
    readonly smallPrint: string;
    readonly mockAlt: string;
    readonly mockCaption: string;
  };
  readonly problem: { readonly heading: string; readonly items: Three<Item> };
  readonly howItWorks: {
    readonly heading: string;
    readonly intro: string;
    readonly steps: Three<Item>;
  };
  readonly features: {
    readonly heading: string;
    readonly intro: string;
    readonly cards: Eight<Item>;
    readonly alsoLabel: string;
    readonly also: Nine<string>;
  };
  readonly status: { readonly worksToday: string; readonly inProgress: string };
  readonly faq: { readonly heading: string; readonly items: Nine<QA> };
  readonly finalCta: {
    readonly heading: string;
    readonly lineWithLogin: string;
    readonly button: string;
    readonly lineWithoutLogin: string;
  };
  readonly footer: { readonly wordmark: string; readonly statusLine: string };
};

export const copy: Copy = {
  meta: {
    title: 'Tunehold: the music you own, on the web, iPhone and Android',
    description:
      'Add a folder of your music and play it on the web, iPhone and Android, offline on your phone too. No server to set up. In development, by invite.',
    ogTitle: 'Tunehold',
  },
  header: {
    wordmark: 'Tunehold',
    logIn: 'Log in',
  },
  hero: {
    headline: 'The music you own, on the web, iPhone and Android',
    lead: 'Bring your CD rips, the albums you bought as files and your own recordings. Tunehold is being built to store each file as you uploaded it and play it in your order, offline on your phone too. No server to set up or keep running.',
    button: 'See how it works',
    smallPrint: 'In development, for its maker and a few friends. Accounts are by invite.',
    mockAlt: 'Early design of the Tunehold library: an album grid with a player bar at the bottom.',
    mockCaption: 'Early design. Tunehold is in development.',
  },
  problem: {
    heading: 'Owning the files is the easy part',
    items: [
      {
        title: 'A server to look after.',
        body: 'Playing your own files from a server at home means a computer that stays on, software to install and keep updated, and a way to reach it from outside. All of that comes before the first song plays.',
      },
      {
        title: 'Uploads that disappeared.',
        body: "Some music services that stored people's own files have dropped the feature, and at least one deleted every upload that was left.",
      },
      {
        title: 'Files spread across devices.',
        body: 'Some albums sit on an old laptop, some on an external drive, a few on your phone. No device has all of it, and a new phone means copying everything again.',
      },
    ],
  },
  howItWorks: {
    heading: 'How it works',
    intro: 'This is how Tunehold is being built to work.',
    steps: [
      {
        title: 'Add a folder.',
        body: "On the web, drop a folder or a few files onto the page. On your phone, pick them. Tunehold reads each file's tags (title, artist, album, track number, cover) and sorts your library by artist and album. You can fix wrong tags in the app.",
      },
      {
        title: 'Press play.',
        body: 'Your library is the same on the web, iPhone and Android. Start an album and keep browsing while it plays.',
      },
      {
        title: 'Listen offline.',
        body: 'Download an album, a playlist or your whole library to your phone, and it plays with no connection.',
      },
    ],
  },
  features: {
    heading: 'What Tunehold is being built to do',
    intro: 'Tunehold is in development. Each card says whether that part works yet.',
    cards: [
      {
        title: 'Add a whole folder',
        body: "Drop in a folder with hundreds of albums. You see what's added and what's left, and you can keep listening while it runs. If an upload is interrupted, it picks up where it stopped. Files already in your library are skipped.",
      },
      {
        title: 'The exact file you added',
        body: 'The stored copy is the file you uploaded, bit for bit. Tunehold makes a separate, lighter copy for streaming.',
      },
      {
        title: 'Downloads for offline',
        body: 'Download a track, an album, a playlist or your whole library to your iPhone or Android phone. Downloaded tracks play straight from the phone, with or without a connection.',
      },
      {
        title: 'Export on demand',
        body: 'Get everything out as files you keep: your audio files as you uploaded them, playlists as M3U8 files and your play history as CSV. Playlists and history come first. Audio export follows later in the build.',
      },
      {
        title: 'Shuffle for big collections',
        body: "Shuffle a playlist, the queue or your whole library, even tens of thousands of tracks. Every track in the set plays once before any of them repeats. Shuffle keeps its place when you close the app or switch devices. You can see what's next and reshuffle.",
      },
      {
        title: 'Play counts and smart playlists',
        body: "See how many times you've played each track, and your full listening history. Smart playlists update themselves from rules you set, like genre, year, date added or play count. Search inside a playlist, and jump through long lists from A to Z.",
      },
      {
        title: 'Playlists and queue',
        body: 'A playlist or album plays its own tracks in the order you set, and stops at the end. Autoplay stays off unless you turn it on, and then it picks only from your library. Drag to reorder, play next or add to the queue.',
      },
      {
        title: 'Quiet and music-only',
        body: "Your library has no ads, no promotional pop-ups and no prompts to rate the app. Home is built from your library and what you've played. Optional notifications stay off unless you turn them on.",
      },
    ],
    alsoLabel: 'Also part of the build:',
    also: [
      'search across your library',
      'album and artist pages built from tags',
      'tag and cover editing',
      'M3U and M3U8 playlist import',
      'picking up on another device where you left off',
      'gapless playback, repeat and a sleep timer',
      'lock-screen controls',
      'keyboard shortcuts on the web',
      'a dark theme',
    ],
  },
  status: {
    worksToday: 'Works today',
    inProgress: 'In progress',
  },
  faq: {
    heading: 'FAQ',
    items: [
      {
        question: 'Can I sign up?',
        answer:
          'Not publicly. Tunehold is in development, for its maker and a few friends, and accounts are by invite. If you have an invite, you create your account on the web. Invited people get the iPhone and Android apps as test builds.',
      },
      {
        question: 'Does Tunehold come with music?',
        answer:
          "No. It has no catalogue and doesn't recommend anything from outside your library. It plays only the files you add, so you use it alongside whatever you already stream.",
      },
      {
        question: 'What can I add?',
        answer:
          'Music you own, as MP3, M4A, FLAC or WAV files: CD rips, albums you bought as files and your own recordings.',
      },
      {
        question: 'Do I need to run a server?',
        answer:
          "No. All you need is a browser or the phone app. Your files are stored in the cloud, so there's no computer at home to leave on.",
      },
      {
        question: 'Does it work offline?',
        answer:
          "It's being built to, on iPhone and Android: anything you've downloaded plays with no connection. The web player needs a connection.",
      },
      {
        question: 'Can I get my music back out?',
        answer:
          'Yes, through export: your audio files as you uploaded them, playlists as M3U8 and play history as CSV. Playlists and history come first in the build, and audio export follows.',
      },
      {
        question: 'Should I keep my original files?',
        answer:
          'Yes. Tunehold is in development, so treat it as a copy you can play on the web and your phone, not your only copy.',
      },
      {
        question: 'Who can see my library?',
        answer:
          "Other people using Tunehold can't see or play your files. Nothing is public, and for now accounts can't share with each other. The person who runs this Tunehold manages the storage your files sit on.",
      },
      {
        question: 'How much space do I get?',
        answer:
          "Each account has a set amount of space, and the app will show how much you've used. If you fill it, everything already in your library keeps playing.",
      },
    ],
  },
  finalCta: {
    heading: 'Start with one album',
    lineWithLogin: 'Have an invite? Log in, add a folder and press play.',
    button: 'Log in',
    lineWithoutLogin: 'Tunehold is in development, for its maker and a few friends.',
  },
  footer: {
    wordmark: 'Tunehold',
    statusLine: 'In development, for its maker and a few friends. Accounts are by invite.',
  },
};
