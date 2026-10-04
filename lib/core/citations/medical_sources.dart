/// Sources for the medical assumptions behind Inner Flare's estimates
/// (App Review Guideline 1.4.1; see docs/features/citations.feature).
///
/// Each URL points at the original publication, not a copy on our own
/// site, so the reader sees who actually said it. Opening one is an
/// explicit user tap that hands the address to the system browser; the
/// app has no internet permission and never fetches these itself. This
/// file is listed in `.url-scan-ignore` for that reason.
///
/// Every number quoted in [estimateExplanations] must match its cited
/// source. Change the wording and the source together, never one alone.
library;

/// One published source, shown as a full citation (readable offline)
/// with a link to the original.
class MedicalSource {
  const MedicalSource({
    required this.id,
    required this.citation,
    required this.url,
  });

  final String id;
  final String citation;
  final String url;
}

/// One estimate the app shows, how it is calculated, and the sources for
/// any assumption that isn't the user's own data.
class EstimateExplanation {
  const EstimateExplanation({
    required this.title,
    required this.method,
    required this.evidence,
    required this.sources,
  });

  final String title;

  /// How the app calculates it, in one or two plain sentences.
  final String method;

  /// What the sources say about the assumption, including its range.
  final String evidence;

  final List<MedicalSource> sources;
}

const wilcox1995 = MedicalSource(
  id: 'wilcox1995',
  citation:
      'Wilcox AJ, Weinberg CR, Baird DD. Timing of sexual intercourse in '
      'relation to ovulation. N Engl J Med. 1995;333:1517-21.',
  url: 'https://www.nejm.org/doi/full/10.1056/NEJM199512073332301',
);

const wilcox2000 = MedicalSource(
  id: 'wilcox2000',
  citation:
      'Wilcox AJ, Dunson D, Baird DD. The timing of the "fertile window" in '
      'the menstrual cycle: day specific estimates from a prospective '
      'study. BMJ. 2000;321:1259.',
  url: 'https://www.bmj.com/content/321/7271/1259',
);

const bull2019 = MedicalSource(
  id: 'bull2019',
  citation:
      'Bull JR, Rowland SP, Scherwitzl EB, et al. Real-world menstrual '
      'cycle characteristics of more than 600,000 menstrual cycles. '
      'npj Digit Med. 2019;2:83.',
  url: 'https://www.nature.com/articles/s41746-019-0152-7',
);

const acogFertilityAwareness = MedicalSource(
  id: 'acogFertilityAwareness',
  citation:
      'American College of Obstetricians and Gynecologists. Fertility '
      'Awareness-Based Methods of Family Planning (patient FAQ).',
  url:
      'https://www.acog.org/womens-health/faqs/'
      'fertility-awareness-based-methods-of-family-planning',
);

const acogAbnormalBleeding = MedicalSource(
  id: 'acogAbnormalBleeding',
  citation:
      'American College of Obstetricians and Gynecologists. Abnormal '
      'Uterine Bleeding (patient FAQ).',
  url: 'https://www.acog.org/womens-health/faqs/abnormal-uterine-bleeding',
);

const figo2023 = MedicalSource(
  id: 'figo2023',
  citation:
      'Jain V, Munro MG, Critchley HOD. Contemporary evaluation of women '
      'and girls with abnormal uterine bleeding: FIGO Systems 1 and 2. '
      'Int J Gynaecol Obstet. 2023;162(Suppl 2):29-42.',
  url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC10952771/',
);

const owhMenstrualCycle = MedicalSource(
  id: 'owhMenstrualCycle',
  citation:
      'U.S. Department of Health and Human Services, Office on Women\'s '
      'Health. Your menstrual cycle.',
  url: 'https://www.womenshealth.gov/menstrual-cycle/your-menstrual-cycle',
);

/// Every source the app cites, in the order first cited.
const List<MedicalSource> medicalSources = [
  owhMenstrualCycle,
  figo2023,
  bull2019,
  acogAbnormalBleeding,
  wilcox1995,
  wilcox2000,
  acogFertilityAwareness,
];

const List<EstimateExplanation> estimateExplanations = [
  EstimateExplanation(
    title: 'Average cycle length and variability',
    method:
        'The number of days between each period start you log. A period '
        'starts on its first day of light, medium or heavy flow. Spotting '
        'counts as part of a period but never starts one, and one day '
        'without flow in the middle of a period does not split it. If you '
        'switch "Period day" on or off for a day on the log screen, your '
        'choice is used instead of this rule for that day. The '
        'average uses your last 6 cycles; variability is how far those '
        'cycles spread around the average (standard deviation).',
    evidence:
        'These come only from your own logged dates. A cycle is counted '
        'from the first day of bleeding in one cycle to the first day of '
        'the next. Large studies count bleeding, not spotting, when '
        'measuring periods. Cycle lengths differ between people and from '
        'cycle to cycle, which is why the app shows variability next to '
        'the average rather than the average alone.',
    sources: [owhMenstrualCycle, figo2023, bull2019],
  ),
  EstimateExplanation(
    title: 'Predicted next period',
    method:
        'Your last logged period start plus your average cycle length. The '
        'shaded range assumes a period lasts 5 days, until the app can '
        'measure your own.',
    evidence:
        'A typical period lasts up to 7 days. In a study of over 600,000 '
        'cycles, bleeding lasted 4 days on average.',
    sources: [acogAbnormalBleeding, bull2019],
  ),
  EstimateExplanation(
    title: 'Predicted fertile window',
    method:
        'Ovulation is assumed to fall 14 days before your predicted next '
        'period. The fertile window is the 5 days before that day plus the '
        'day itself.',
    evidence:
        'Pregnancy is possible only from intercourse in a six-day window '
        'ending on the day of ovulation. Ovulation happens about 14 days '
        'before the next period on average, but the gap ranges from about '
        '7 to 19 days, and in a large study it averaged 12.4 days. The '
        'timing of the fertile window can be highly unpredictable, even '
        'for people whose cycles are usually regular.',
    sources: [wilcox1995, wilcox2000, acogFertilityAwareness, bull2019],
  ),
  EstimateExplanation(
    title: 'Not a method of contraception',
    method:
        'The fertile window is a date estimate from your past cycles. It '
        'does not track ovulation signs such as temperature or cervical '
        'mucus.',
    evidence:
        'Even fertility awareness methods that do track those signs see '
        '12 to 24 pregnancies per 100 people in the first year of typical '
        'use.',
    sources: [acogFertilityAwareness, wilcox2000],
  ),
  EstimateExplanation(
    title: 'Irregular cycles',
    method:
        'If your last 3 cycle lengths differ by more than 7 days between the '
        'shortest and longest, the app says so and shows a range instead '
        'of a single number.',
    evidence:
        'Cycles that vary by more than 7 to 9 days are considered '
        'irregular. The exact limit depends on age: up to 7 days is typical '
        'from 26 to 41, up to 9 days from 18 to 25 and from 42 to 45. The '
        'app uses the stricter 7 days for everyone and is not a diagnosis; '
        'talk to a healthcare provider if your cycles concern you.',
    sources: [acogAbnormalBleeding, figo2023],
  ),
];
