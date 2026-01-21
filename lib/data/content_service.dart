import 'package:shared_preferences/shared_preferences.dart';

/// Age group for content filtering
enum AgeGroup {
  toddler, // 4-6 years
  junior, // 7-9 years
  senior, // 10-12 years
}

extension AgeGroupExtension on AgeGroup {
  String get label {
    switch (this) {
      case AgeGroup.toddler:
        return '4-6 years';
      case AgeGroup.junior:
        return '7-9 years';
      case AgeGroup.senior:
        return '10-12 years';
    }
  }

  String get emoji {
    switch (this) {
      case AgeGroup.toddler:
        return '🧒';
      case AgeGroup.junior:
        return '👦';
      case AgeGroup.senior:
        return '🧑';
    }
  }

  int get maxNumber {
    switch (this) {
      case AgeGroup.toddler:
        return 10;
      case AgeGroup.junior:
        return 50;
      case AgeGroup.senior:
        return 100;
    }
  }

  int get maxTable {
    switch (this) {
      case AgeGroup.toddler:
        return 5;
      case AgeGroup.junior:
        return 10;
      case AgeGroup.senior:
        return 20;
    }
  }
}

/// Service for managing offline educational content
class ContentService {
  // Singleton instance
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  static const String _ageGroupKey = 'selected_age_group';
  static const String _activityTimeKey = 'activity_time';

  AgeGroup _ageGroup = AgeGroup.toddler;
  final Map<String, int> _activityTimes = {};
  bool _isInitialized = false;

  AgeGroup get ageGroup => _ageGroup;
  Map<String, int> get activityTimes => Map.unmodifiable(_activityTimes);
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent re-initialization

    final prefs = await SharedPreferences.getInstance();
    final ageIndex = prefs.getInt(_ageGroupKey) ?? 0;
    _ageGroup = AgeGroup.values[ageIndex];

    // Load activity times
    for (final activity in [
      'abc',
      'numbers',
      'tables',
      'animals',
      'places',
      'poems',
      'stories',
      'math',
      'spelling',
    ]) {
      _activityTimes[activity] =
          prefs.getInt('${_activityTimeKey}_$activity') ?? 0;
    }
    _isInitialized = true;
  }

  Future<void> setAgeGroup(AgeGroup group) async {
    _ageGroup = group;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ageGroupKey, group.index);
  }

  Future<void> recordActivityTime(String activity, int seconds) async {
    _activityTimes[activity] = (_activityTimes[activity] ?? 0) + seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '${_activityTimeKey}_$activity',
      _activityTimes[activity]!,
    );
  }

  int getTotalTime() {
    return _activityTimes.values.fold(0, (a, b) => a + b);
  }

  // ============ ALPHABET CONTENT ============
  static const List<Map<String, String>> alphabet = [
    {'letter': 'A', 'word': 'Apple', 'emoji': '🍎', 'hindi': 'सेब'},
    {'letter': 'B', 'word': 'Ball', 'emoji': '⚽', 'hindi': 'गेंद'},
    {'letter': 'C', 'word': 'Cat', 'emoji': '🐱', 'hindi': 'बिल्ली'},
    {'letter': 'D', 'word': 'Dog', 'emoji': '🐕', 'hindi': 'कुत्ता'},
    {'letter': 'E', 'word': 'Elephant', 'emoji': '🐘', 'hindi': 'हाथी'},
    {'letter': 'F', 'word': 'Fish', 'emoji': '🐟', 'hindi': 'मछली'},
    {'letter': 'G', 'word': 'Grapes', 'emoji': '🍇', 'hindi': 'अंगूर'},
    {'letter': 'H', 'word': 'House', 'emoji': '🏠', 'hindi': 'घर'},
    {'letter': 'I', 'word': 'Ice cream', 'emoji': '🍦', 'hindi': 'आइसक्रीम'},
    {'letter': 'J', 'word': 'Jug', 'emoji': '🫖', 'hindi': 'जग'},
    {'letter': 'K', 'word': 'Kite', 'emoji': '🪁', 'hindi': 'पतंग'},
    {'letter': 'L', 'word': 'Lion', 'emoji': '🦁', 'hindi': 'शेर'},
    {'letter': 'M', 'word': 'Moon', 'emoji': '🌙', 'hindi': 'चाँद'},
    {'letter': 'N', 'word': 'Nest', 'emoji': '🪺', 'hindi': 'घोंसला'},
    {'letter': 'O', 'word': 'Orange', 'emoji': '🍊', 'hindi': 'संतरा'},
    {'letter': 'P', 'word': 'Parrot', 'emoji': '🦜', 'hindi': 'तोता'},
    {'letter': 'Q', 'word': 'Queen', 'emoji': '👸', 'hindi': 'रानी'},
    {'letter': 'R', 'word': 'Rainbow', 'emoji': '🌈', 'hindi': 'इंद्रधनुष'},
    {'letter': 'S', 'word': 'Sun', 'emoji': '☀️', 'hindi': 'सूरज'},
    {'letter': 'T', 'word': 'Tree', 'emoji': '🌳', 'hindi': 'पेड़'},
    {'letter': 'U', 'word': 'Umbrella', 'emoji': '☂️', 'hindi': 'छाता'},
    {'letter': 'V', 'word': 'Van', 'emoji': '🚐', 'hindi': 'वैन'},
    {'letter': 'W', 'word': 'Watch', 'emoji': '⌚', 'hindi': 'घड़ी'},
    {'letter': 'X', 'word': 'Xylophone', 'emoji': '🎵', 'hindi': 'जाइलोफोन'},
    {'letter': 'Y', 'word': 'Yak', 'emoji': '🦬', 'hindi': 'याक'},
    {'letter': 'Z', 'word': 'Zebra', 'emoji': '🦓', 'hindi': 'ज़ेबरा'},
  ];

  // ============ NUMBER CONTENT ============
  static const List<Map<String, dynamic>> numbers = [
    {
      'number': 1,
      'word': 'One',
      'hindi': 'एक',
      'emoji': '1️⃣',
      'objects': '🍎',
    },
    {
      'number': 2,
      'word': 'Two',
      'hindi': 'दो',
      'emoji': '2️⃣',
      'objects': '🍎🍎',
    },
    {
      'number': 3,
      'word': 'Three',
      'hindi': 'तीन',
      'emoji': '3️⃣',
      'objects': '🍎🍎🍎',
    },
    {
      'number': 4,
      'word': 'Four',
      'hindi': 'चार',
      'emoji': '4️⃣',
      'objects': '🍎🍎🍎🍎',
    },
    {
      'number': 5,
      'word': 'Five',
      'hindi': 'पाँच',
      'emoji': '5️⃣',
      'objects': '🍎🍎🍎🍎🍎',
    },
    {
      'number': 6,
      'word': 'Six',
      'hindi': 'छह',
      'emoji': '6️⃣',
      'objects': '⭐⭐⭐⭐⭐⭐',
    },
    {
      'number': 7,
      'word': 'Seven',
      'hindi': 'सात',
      'emoji': '7️⃣',
      'objects': '⭐⭐⭐⭐⭐⭐⭐',
    },
    {
      'number': 8,
      'word': 'Eight',
      'hindi': 'आठ',
      'emoji': '8️⃣',
      'objects': '⭐⭐⭐⭐⭐⭐⭐⭐',
    },
    {
      'number': 9,
      'word': 'Nine',
      'hindi': 'नौ',
      'emoji': '9️⃣',
      'objects': '⭐⭐⭐⭐⭐⭐⭐⭐⭐',
    },
    {
      'number': 10,
      'word': 'Ten',
      'hindi': 'दस',
      'emoji': '🔟',
      'objects': '⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐',
    },
    {
      'number': 11,
      'word': 'Eleven',
      'hindi': 'ग्यारह',
      'emoji': '1️⃣1️⃣',
      'objects': '🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟',
    },
    {
      'number': 12,
      'word': 'Twelve',
      'hindi': 'बारह',
      'emoji': '1️⃣2️⃣',
      'objects': '🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟',
    },
    {
      'number': 13,
      'word': 'Thirteen',
      'hindi': 'तेरह',
      'emoji': '1️⃣3️⃣',
      'objects': '🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵',
    },
    {
      'number': 14,
      'word': 'Fourteen',
      'hindi': 'चौदह',
      'emoji': '1️⃣4️⃣',
      'objects': '🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵',
    },
    {
      'number': 15,
      'word': 'Fifteen',
      'hindi': 'पंद्रह',
      'emoji': '1️⃣5️⃣',
      'objects': '🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵',
    },
    {
      'number': 16,
      'word': 'Sixteen',
      'hindi': 'सोलह',
      'emoji': '1️⃣6️⃣',
      'objects': '🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢',
    },
    {
      'number': 17,
      'word': 'Seventeen',
      'hindi': 'सत्रह',
      'emoji': '1️⃣7️⃣',
      'objects': '🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢',
    },
    {
      'number': 18,
      'word': 'Eighteen',
      'hindi': 'अठारह',
      'emoji': '1️⃣8️⃣',
      'objects': '🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢',
    },
    {
      'number': 19,
      'word': 'Nineteen',
      'hindi': 'उन्नीस',
      'emoji': '1️⃣9️⃣',
      'objects': '🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡',
    },
    {
      'number': 20,
      'word': 'Twenty',
      'hindi': 'बीस',
      'emoji': '2️⃣0️⃣',
      'objects': '🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡',
    },
  ];

  // ============ ANIMAL CONTENT ============
  static const List<Map<String, String>> animals = [
    {
      'name': 'Lion',
      'emoji': '🦁',
      'hindi': 'शेर',
      'sound': 'Roar!',
      'category': 'wild',
    },
    {
      'name': 'Elephant',
      'emoji': '🐘',
      'hindi': 'हाथी',
      'sound': 'Trumpet!',
      'category': 'wild',
    },
    {
      'name': 'Tiger',
      'emoji': '🐅',
      'hindi': 'बाघ',
      'sound': 'Growl!',
      'category': 'wild',
    },
    {
      'name': 'Monkey',
      'emoji': '🐒',
      'hindi': 'बंदर',
      'sound': 'Ooh ooh!',
      'category': 'wild',
    },
    {
      'name': 'Giraffe',
      'emoji': '🦒',
      'hindi': 'जिराफ',
      'sound': 'Hum!',
      'category': 'wild',
    },
    {
      'name': 'Zebra',
      'emoji': '🦓',
      'hindi': 'ज़ेबरा',
      'sound': 'Bray!',
      'category': 'wild',
    },
    {
      'name': 'Bear',
      'emoji': '🐻',
      'hindi': 'भालू',
      'sound': 'Growl!',
      'category': 'wild',
    },
    {
      'name': 'Fox',
      'emoji': '🦊',
      'hindi': 'लोमड़ी',
      'sound': 'Yip yip!',
      'category': 'wild',
    },
    {
      'name': 'Dog',
      'emoji': '🐕',
      'hindi': 'कुत्ता',
      'sound': 'Woof woof!',
      'category': 'pet',
    },
    {
      'name': 'Cat',
      'emoji': '🐱',
      'hindi': 'बिल्ली',
      'sound': 'Meow!',
      'category': 'pet',
    },
    {
      'name': 'Rabbit',
      'emoji': '🐰',
      'hindi': 'खरगोश',
      'sound': 'Squeak!',
      'category': 'pet',
    },
    {
      'name': 'Parrot',
      'emoji': '🦜',
      'hindi': 'तोता',
      'sound': 'Squawk!',
      'category': 'pet',
    },
    {
      'name': 'Fish',
      'emoji': '🐟',
      'hindi': 'मछली',
      'sound': 'Blub blub!',
      'category': 'pet',
    },
    {
      'name': 'Cow',
      'emoji': '🐄',
      'hindi': 'गाय',
      'sound': 'Moo!',
      'category': 'farm',
    },
    {
      'name': 'Pig',
      'emoji': '🐷',
      'hindi': 'सूअर',
      'sound': 'Oink!',
      'category': 'farm',
    },
    {
      'name': 'Horse',
      'emoji': '🐴',
      'hindi': 'घोड़ा',
      'sound': 'Neigh!',
      'category': 'farm',
    },
    {
      'name': 'Sheep',
      'emoji': '🐑',
      'hindi': 'भेड़',
      'sound': 'Baa!',
      'category': 'farm',
    },
    {
      'name': 'Hen',
      'emoji': '🐔',
      'hindi': 'मुर्गी',
      'sound': 'Cluck!',
      'category': 'farm',
    },
    {
      'name': 'Duck',
      'emoji': '🦆',
      'hindi': 'बत्तख',
      'sound': 'Quack!',
      'category': 'farm',
    },
    {
      'name': 'Peacock',
      'emoji': '🦚',
      'hindi': 'मोर',
      'sound': 'Scream!',
      'category': 'bird',
    },
    {
      'name': 'Eagle',
      'emoji': '🦅',
      'hindi': 'बाज',
      'sound': 'Screech!',
      'category': 'bird',
    },
    {
      'name': 'Owl',
      'emoji': '🦉',
      'hindi': 'उल्लू',
      'sound': 'Hoot!',
      'category': 'bird',
    },
    {
      'name': 'Penguin',
      'emoji': '🐧',
      'hindi': 'पेंगुइन',
      'sound': 'Honk!',
      'category': 'bird',
    },
    {
      'name': 'Butterfly',
      'emoji': '🦋',
      'hindi': 'तितली',
      'sound': 'Flutter!',
      'category': 'insect',
    },
  ];

  // ============ PLACES CONTENT ============
  static const List<Map<String, String>> places = [
    {
      'name': 'Taj Mahal',
      'emoji': '🕌',
      'city': 'Agra',
      'hindi': 'ताज महल',
      'fact': 'Made of white marble',
    },
    {
      'name': 'Red Fort',
      'emoji': '🏰',
      'city': 'Delhi',
      'hindi': 'लाल किला',
      'fact': 'Built by Shah Jahan',
    },
    {
      'name': 'Gateway of India',
      'emoji': '🚪',
      'city': 'Mumbai',
      'hindi': 'गेटवे ऑफ इंडिया',
      'fact': 'Built in 1924',
    },
    {
      'name': 'Qutub Minar',
      'emoji': '🗼',
      'city': 'Delhi',
      'hindi': 'कुतुब मीनार',
      'fact': 'Tallest brick minaret',
    },
    {
      'name': 'Hawa Mahal',
      'emoji': '🏛️',
      'city': 'Jaipur',
      'hindi': 'हवा महल',
      'fact': 'Palace of Winds',
    },
    {
      'name': 'India Gate',
      'emoji': '🎖️',
      'city': 'Delhi',
      'hindi': 'इंडिया गेट',
      'fact': 'War memorial',
    },
    {
      'name': 'Golden Temple',
      'emoji': '🛕',
      'city': 'Amritsar',
      'hindi': 'स्वर्ण मंदिर',
      'fact': 'Covered in gold',
    },
    {
      'name': 'Victoria Memorial',
      'emoji': '🏛️',
      'city': 'Kolkata',
      'hindi': 'विक्टोरिया मेमोरियल',
      'fact': 'White marble building',
    },
    {
      'name': 'Mysore Palace',
      'emoji': '👑',
      'city': 'Mysore',
      'hindi': 'मैसूर पैलेस',
      'fact': 'Lit with 100,000 bulbs',
    },
    {
      'name': 'Konark Sun Temple',
      'emoji': '☀️',
      'city': 'Odisha',
      'hindi': 'कोणार्क मंदिर',
      'fact': 'Shaped like chariot',
    },
  ];

  // ============ POEMS CONTENT ============
  static const List<Map<String, dynamic>> poems = [
    // English Poems
    {
      'title': 'Twinkle Twinkle Little Star',
      'language': 'english',
      'emoji': '⭐',
      'lines': [
        'Twinkle, twinkle, little star,',
        'How I wonder what you are!',
        'Up above the world so high,',
        'Like a diamond in the sky.',
        'Twinkle, twinkle, little star,',
        'How I wonder what you are!',
      ],
    },
    {
      'title': 'Row Row Row Your Boat',
      'language': 'english',
      'emoji': '🚣',
      'lines': [
        'Row, row, row your boat,',
        'Gently down the stream.',
        'Merrily, merrily, merrily, merrily,',
        'Life is but a dream.',
      ],
    },
    {
      'title': 'Jack and Jill',
      'language': 'english',
      'emoji': '💧',
      'lines': [
        'Jack and Jill went up the hill,',
        'To fetch a pail of water.',
        'Jack fell down and broke his crown,',
        'And Jill came tumbling after.',
      ],
    },
    {
      'title': 'Humpty Dumpty',
      'language': 'english',
      'emoji': '🥚',
      'lines': [
        'Humpty Dumpty sat on a wall,',
        'Humpty Dumpty had a great fall.',
        'All the king\'s horses and all the king\'s men,',
        'Couldn\'t put Humpty together again.',
      ],
    },
    {
      'title': 'Baa Baa Black Sheep',
      'language': 'english',
      'emoji': '🐑',
      'lines': [
        'Baa, baa, black sheep,',
        'Have you any wool?',
        'Yes sir, yes sir,',
        'Three bags full.',
        'One for the master,',
        'One for the dame,',
        'And one for the little boy,',
        'Who lives down the lane.',
      ],
    },
    // Hindi Poems
    {
      'title': 'मछली जल की रानी है',
      'language': 'hindi',
      'emoji': '🐟',
      'lines': [
        'मछली जल की रानी है,',
        'जीवन उसका पानी है।',
        'हाथ लगाओ डर जाएगी,',
        'बाहर निकालो मर जाएगी।',
      ],
      'transliteration': [
        'Machhli jal ki rani hai,',
        'Jeevan uska paani hai.',
        'Haath lagao dar jayegi,',
        'Bahar nikalo mar jayegi.',
      ],
    },
    {
      'title': 'चंदा मामा दूर के',
      'language': 'hindi',
      'emoji': '🌙',
      'lines': [
        'चंदा मामा दूर के,',
        'पुए पकाएं बूर के।',
        'आप खाएं थाली में,',
        'मुन्ने को दें प्याली में।',
      ],
      'transliteration': [
        'Chanda mama door ke,',
        'Puye pakaye boor ke.',
        'Aap khaye thali mein,',
        'Munne ko de pyali mein.',
      ],
    },
    {
      'title': 'लकड़ी की काठी',
      'language': 'hindi',
      'emoji': '🐴',
      'lines': [
        'लकड़ी की काठी, काठी पे घोड़ा,',
        'घोड़े की दुम पे जो मारा हथौड़ा,',
        'दौड़ा दौड़ा दौड़ा, घोड़ा दौड़ा दौड़ा,',
        'दौड़ते दौड़ते थक गया घोड़ा।',
      ],
      'transliteration': [
        'Lakdi ki kathi, kathi pe ghoda,',
        'Ghode ki dum pe jo mara hathoda,',
        'Dauda dauda dauda, ghoda dauda dauda,',
        'Daudte daudte thak gaya ghoda.',
      ],
    },
    {
      'title': 'नानी तेरी मोरनी',
      'language': 'hindi',
      'emoji': '🦚',
      'lines': [
        'नानी तेरी मोरनी को मोर ले गए,',
        'बाकी जो बचा था काले चोर ले गए।',
        'नानी रोई धार धार, अम्मी रोई झार झार,',
        'इक रोती थी बुढ़िया, चार रोती थी छोरिया।',
      ],
      'transliteration': [
        'Nani teri morni ko mor le gaye,',
        'Baki jo bacha tha kaale chor le gaye.',
        'Nani royi dhar dhar, ammi royi jhar jhar,',
        'Ik roti thi budhiya, char roti thi chhoriya.',
      ],
    },
    {
      'title': 'आलू कचालू बेटा',
      'language': 'hindi',
      'emoji': '🥔',
      'lines': [
        'आलू कचालू बेटा कहाँ गए थे,',
        'बंदर की झोपड़ी में सो रहे थे।',
        'बंदर ने लात मारी रो रहे थे,',
        'मम्मी ने प्यार किया हंस रहे थे।',
      ],
      'transliteration': [
        'Aloo kachalu beta kahan gaye the,',
        'Bandar ki jhopdi mein so rahe the.',
        'Bandar ne laat mari ro rahe the,',
        'Mummy ne pyar kiya hans rahe the.',
      ],
    },
  ];

  // Get content based on age group
  List<Map<String, dynamic>> getNumbersForAge() {
    final max = _ageGroup.maxNumber;
    return numbers.where((n) => (n['number'] as int) <= max).toList();
  }

  int getMaxTableForAge() => _ageGroup.maxTable;

  List<Map<String, String>> getAnimalsForAge() {
    switch (_ageGroup) {
      case AgeGroup.toddler:
        return animals
            .where((a) => ['pet', 'farm'].contains(a['category']))
            .toList();
      case AgeGroup.junior:
        return animals;
      case AgeGroup.senior:
        return animals;
    }
  }
}
