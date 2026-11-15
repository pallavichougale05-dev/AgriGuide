class SeasonSnapshot {
  final String seasonName;
  final String range;
  final String monthName;
  final int monthInSeason;
  final int seasonLength;
  final List<String> sow;
  final List<String> harvest;
  final String note;
  final String sowLabel;
  final String harvestLabel;
  final String progressLabel;
  final String footer;

  const SeasonSnapshot({
    required this.seasonName,
    required this.range,
    required this.monthName,
    required this.monthInSeason,
    required this.seasonLength,
    required this.sow,
    required this.harvest,
    required this.note,
    required this.sowLabel,
    required this.harvestLabel,
    required this.progressLabel,
    required this.footer,
  });
}

class _Season {
  final int startMonth;
  final int length;
  final String nameEn;
  final String nameMr;
  final String rangeEn;
  final String rangeMr;
  final String noteEn;
  final String noteMr;

  const _Season({
    required this.startMonth,
    required this.length,
    required this.nameEn,
    required this.nameMr,
    required this.rangeEn,
    required this.rangeMr,
    required this.noteEn,
    required this.noteMr,
  });
}

class SeasonGuide {

  // DISPLAY PERIODS

  static const List<_Season> _seasons = [
    _Season(
      startMonth: 6,
      length: 5,
      nameEn: 'Kharif season',
      nameMr: 'खरीप हंगाम',
      rangeEn: 'June to October',
      rangeMr: 'जून ते ऑक्टोबर',
      noteEn:
          'The monsoon crop season. Sowing depends on the onset and distribution of rainfall; do not sow only by the calendar date.',
      noteMr:
          'हा पावसाळी पिकांचा हंगाम आहे. पेरणीचा निर्णय पावसाचे आगमन व वितरण पाहून घ्या; केवळ दिनदर्शिकेवर अवलंबून राहू नका.',
    ),
    _Season(
      startMonth: 11,
      length: 5,
      nameEn: 'Rabi season',
      nameMr: 'रब्बी हंगाम',
      rangeEn: 'November to March (Rabi sowing may begin in October)',
      rangeMr: 'नोव्हेंबर ते मार्च (रब्बी पेरणी ऑक्टोबरमध्येही सुरू होऊ शकते)',
      noteEn:
          'Rabi crop timing depends on soil moisture and assured irrigation. October is treated as a transition month.',
      noteMr:
          'रब्बी पिकांची वेळ जमिनीतील ओलावा व खात्रीशीर सिंचनावर अवलंबून असते. ऑक्टोबर हा संक्रमण महिना मानला आहे.',
    ),
    _Season(
      startMonth: 4,
      length: 2,
      nameEn: 'Summer season',
      nameMr: 'उन्हाळी हंगाम',
      rangeEn: 'April to May (summer activity can extend from March to June)',
      rangeMr: 'एप्रिल ते मे (उन्हाळी पिकांचा कालावधी मार्च ते जूनपर्यंत असू शकतो)',
      noteEn:
          'Summer crop options depend strongly on available irrigation and local conditions. This card lists only activities with a checked source.',
      noteMr:
          'उन्हाळी पिकांची निवड सिंचनाची उपलब्धता व स्थानिक परिस्थितीवर अवलंबून असते. या कार्डमध्ये तपासलेल्या स्रोतांतील उपक्रमच दाखवले आहेत.',
    ),
  ];

  // CROP NAMES [English, Marathi]
  
  static const Map<String, List<String>> _crops = {
    'wheat': ['Wheat', 'गहू'],
    'gram': ['Gram (chickpea)', 'हरभरा'],
    'rabi_maize': ['Rabi maize', 'रब्बी मका'],
    'safflower': ['Safflower', 'करडई'],
    'soybean': ['Soybean', 'सोयाबीन'],
    'cotton': ['Cotton', 'कापूस'],
    'tur': ['Tur (pigeon pea)', 'तूर'],
    'bajra': ['Bajra', 'बाजरी'],
    'moong': ['Moong (green gram)', 'मूग'],
    'urad': ['Urad (black gram)', 'उडीद'],
    'maize': ['Maize', 'मका'],
    'sugarcane_preseasonal': [
      'Sugarcane (pre-seasonal planting)',
      'ऊस (पूर्वहंगामी लागवड)',
    ],
    'sugarcane_suru': [
      'Sugarcane (Suru planting)',
      'ऊस (सुरू हंगामातील लागवड)',
    ],
    'niger': ['Niger', 'रामतिळ'],
  };

  // MONTHLY ACTIVITIES

  static const Map<int, List<String>> _sow = {
    1: ['sugarcane_suru'],
    2: ['sugarcane_suru'],
    3: [],
    4: [],
    5: [],
    6: ['soybean', 'cotton', 'tur', 'moong', 'urad'],
    7: ['soybean', 'tur', 'moong', 'urad', 'maize'],
    8: ['maize', 'niger'],
    9: ['safflower', 'niger', 'gram'],
    10: ['gram', 'safflower', 'rabi_maize', 'sugarcane_preseasonal'],
    11: ['wheat', 'gram', 'rabi_maize', 'sugarcane_preseasonal'],
    12: [],
  };

  static const Map<int, List<String>> _harvest = {
    1: ['cotton'],
    2: ['gram'],
    3: ['gram'],
    4: [],
    5: [],
    6: [],
    7: [],
    8: [],
    9: ['soybean', 'moong', 'urad'],
    10: ['soybean', 'moong', 'urad', 'maize'],
    11: ['cotton', 'tur', 'maize', 'niger'],
    12: ['cotton', 'tur', 'niger'],
  };

  // MONTH NAMES [English, Marathi]
  static const List<List<String>> _months = [
    ['January', 'जानेवारी'],
    ['February', 'फेब्रुवारी'],
    ['March', 'मार्च'],
    ['April', 'एप्रिल'],
    ['May', 'मे'],
    ['June', 'जून'],
    ['July', 'जुलै'],
    ['August', 'ऑगस्ट'],
    ['September', 'सप्टेंबर'],
    ['October', 'ऑक्टोबर'],
    ['November', 'नोव्हेंबर'],
    ['December', 'डिसेंबर'],
  ];

  // SNAPSHOT FOR A DATE

  static SeasonSnapshot snapshot(DateTime date, String languageCode) {
    final bool mr = languageCode.toLowerCase().startsWith('mr');
    final int month = date.month;

    // These display buckets cover all 12 months without overlapping, while the text above explains that real
    // crop-season windows overlap around transition months.
    late final _Season season;
    late final int position;

    if (month >= 6 && month <= 10) {
      season = _seasons[0];
      position = month - season.startMonth;
    } else if (month >= 11 || month <= 3) {
      season = _seasons[1];
      position = month >= 11
          ? month - season.startMonth
          : (12 - season.startMonth) + month;
    } else {
      season = _seasons[2];
      position = month - season.startMonth;
    }

    String cropName(String id) {
      final List<String>? names = _crops[id];
      if (names == null) return id;
      return mr ? names[1] : names[0];
    }

    final int inSeason = position + 1;

    return SeasonSnapshot(
      seasonName: mr ? season.nameMr : season.nameEn,
      range: mr ? season.rangeMr : season.rangeEn,
      monthName: _months[month - 1][mr ? 1 : 0],
      monthInSeason: inSeason,
      seasonLength: season.length,
      sow: (_sow[month] ?? const <String>[]).map(cropName).toList(),
      harvest: (_harvest[month] ?? const <String>[]).map(cropName).toList(),
      note: mr ? season.noteMr : season.noteEn,
      sowLabel: mr ? 'या महिन्यात पेरणी' : 'Sow this month',
      harvestLabel: mr ? 'या महिन्यात काढणी' : 'Harvest this month',
      progressLabel: mr
          ? 'हंगामातील महिना $inSeason / ${season.length}'
          : 'Month $inSeason of ${season.length}',
      footer: mr
          ? 'महाराष्ट्रासाठी सर्वसाधारण ऑफलाइन माहिती. स्थानिक कृषी विज्ञान केंद्र किंवा कृषी विद्यापीठाचा अद्ययावत सल्ला घ्या.'
          : 'General offline information for Maharashtra. check the latest advice from your local KVK or agricultural university.',
    );
  }
}
